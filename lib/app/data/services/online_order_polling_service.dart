import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/app_snackbar.dart';
import '../../modules/online_orders/controllers/online_orders_controller.dart';
import '../models/online_order_model.dart';
import '../providers/api_provider.dart';

class OnlineOrderPollingService extends GetxService {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  Timer? _pollingTimer;
  int _lastOrderId = 0;
  bool _isChecking = false;

  final RxInt activeOrdersCount = 0.obs;
  final RxInt pendingOrdersCount = 0.obs;
  final RxBool isOnlineOrderActive = true.obs;
  final Rx<OnlineOrderStatsModel> liveStats = OnlineOrderStatsModel.empty().obs;

  @override
  void onInit() {
    super.onInit();
    startPolling();
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }

  void startPolling() {
    stopPolling();
    // Immediate initial check
    checkNewOrders();
    // Poll every 12 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      checkNewOrders();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> checkNewOrders() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final response = await _apiProvider.get(
        ApiConstants.onlineOrdersCheckNew,
        queryParameters: {'last_order_id': _lastOrderId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final hasNew = data['has_new_orders'] == true;
        final latestId = (data['latest_order_id'] as num?)?.toInt() ?? _lastOrderId;
        final activeCount = (data['active_orders_count'] as num?)?.toInt() ?? 0;
        final isActive = data['is_online_order_active'] == true;

        activeOrdersCount.value = activeCount;
        isOnlineOrderActive.value = isActive;

        // Jika ada pesanan baru dan bukan saat inisialisasi pertama kali
        if (hasNew && _lastOrderId > 0) {
          final newOrders = (data['new_orders'] as List? ?? []);
          if (newOrders.isNotEmpty) {
            final latest = newOrders.last;
            final custName = latest['customer_name'] ?? 'Pelanggan';
            final table = latest['table_number'];
            final totalFormatted = latest['formatted_total'] ?? '';
            final location = table != null ? 'Meja $table' : 'Take Away';

            // Haptic alert feedback
            try {
              HapticFeedback.heavyImpact();
            } catch (_) {}

            AppSnackbar.info(
              '🛎️ Pesanan Online Masuk!',
              '$location • $custName ($totalFormatted)',
            );

            // Jika sedang membuka layar OnlineOrdersView, trigger auto refresh
            if (Get.isRegistered<OnlineOrdersController>()) {
              Get.find<OnlineOrdersController>().fetchOrders(silent: true);
            }
          }
        }

        // Update last order ID tracking
        if (latestId > _lastOrderId) {
          _lastOrderId = latestId;
        }
      }
    } catch (_) {
      // Polling network fail-safe, silent continue
    } finally {
      _isChecking = false;
    }
  }

  Future<void> refreshStats() async {
    try {
      final response = await _apiProvider.get(ApiConstants.onlineOrdersStats);
      if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
        final stats = OnlineOrderStatsModel.fromJson(response.data['data']);
        liveStats.value = stats;
        activeOrdersCount.value = stats.active;
        pendingOrdersCount.value = stats.pending;
        isOnlineOrderActive.value = stats.isOnlineOrderActive;
      }
    } catch (_) {}
  }
}
