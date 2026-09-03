import 'dart:async';
import 'package:get/get.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/sound_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../modules/online_orders/controllers/online_orders_controller.dart';
import '../../modules/pos/controllers/pos_controller.dart';
import '../../routes/app_routes.dart';
import '../models/online_order_model.dart';
import '../providers/api_provider.dart';
import 'storage_service.dart';

class OnlineOrderPollingService extends GetxService {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final StorageService _storageService = Get.find<StorageService>();

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
    // Inisialisasi awal hanya jika user sudah login
    if (_storageService.hasToken) {
      initCheck();
    }
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }

  /// Cek inisialisasi awal sekali saat aplikasi dibuka
  Future<void> initCheck() async {
    await checkNewOrders();
  }

  /// Mulai timer berkala unified heartbeat (pesanan online + open bills)
  void startPolling() {
    stopPolling();
    if (!_storageService.hasToken) return;

    // Cek langsung saat dinyalakan
    checkNewOrders();

    // Jalankan timer berkala adaptif
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    _pollingTimer?.cancel();
    // 12 detik saat toko online buka, 20 detik saat toko online jeda (sangat hemat kuota)
    final interval = isOnlineOrderActive.value
        ? const Duration(seconds: 12)
        : const Duration(seconds: 20);

    _pollingTimer = Timer(interval, () async {
      await checkNewOrders();
      if (_storageService.hasToken) {
        _scheduleNextPoll();
      }
    });
  }

  /// Hentikan total timer berkala (0 request ke backend)
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Cek pesanan baru masuk & update open bills count (Unified Heartbeat)
  Future<void> checkNewOrders() async {
    if (_isChecking || !_storageService.hasToken) return;
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
        final rawActive = data['is_online_order_active'] ?? data['is_active'];
        final isActive = rawActive == null ? true : (rawActive == true || rawActive == 1 || rawActive == '1');

        activeOrdersCount.value = activeCount;
        isOnlineOrderActive.value = isActive;

        // Sinkronisasi badge open bills count secara otomatis & efisien
        if (data['open_bills_count'] != null) {
          final openCount = (data['open_bills_count'] as num).toInt();
          if (Get.isRegistered<PosController>()) {
            Get.find<PosController>().updateOpenBillsCount(openCount);
          }
        }

        // Jika ada pesanan baru dan bukan saat inisialisasi pertama kali
        if (hasNew && _lastOrderId > 0) {
          final newOrders = (data['new_orders'] as List? ?? []);
          if (newOrders.isNotEmpty) {
            final latest = newOrders.last;
            final totalFormatted = latest['formatted_total'] ?? '';

            // 1. Play Crisp Bell Notification Sound & Haptic Alert
            SoundService.playOrderNotificationSound();

            // 2. Show Clean, Simple & Overflow-Proof Alert Pop-Up
            AppSnackbar.showOnlineOrderAlert(
              totalFormatted: totalFormatted,
              onTap: () {
                if (Get.currentRoute != AppRoutes.onlineOrders) {
                  Get.toNamed(AppRoutes.onlineOrders);
                }
              },
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
    if (!_storageService.hasToken) return;
    try {
      final response = await _apiProvider.get(ApiConstants.onlineOrdersStats);
      if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
        final stats = OnlineOrderStatsModel.fromJson(response.data['data']);
        liveStats.value = stats;
        activeOrdersCount.value = stats.active;
        pendingOrdersCount.value = stats.pending;
        isOnlineOrderActive.value = stats.isOnlineOrderActive;

        if (!stats.isOnlineOrderActive) {
          stopPolling();
        }
      }
    } catch (_) {}
  }
}
