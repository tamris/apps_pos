import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'storage_service.dart';
import '../providers/api_provider.dart';
import '../../core/constants/api_constants.dart';

class OfflineSyncService extends GetxService {
  final StorageService _storageService = Get.find<StorageService>();
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final Uuid _uuid = const Uuid();

  final RxInt pendingCount = 0.obs;
  final RxBool isSyncing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _refreshCount();
  }

  void _refreshCount() {
    pendingCount.value = _storageService.getOfflineQueue().length;
  }

  /// Simpan transaksi ke antrean offline jika koneksi server gagal / offline mode
  Future<String> enqueueTransaction({
    required String orderType,
    String? tableNumber,
    String? customerName,
    required String paymentMethod,
    double discountPercent = 0.0,
    double taxPercent = 0.0,
    required double paid,
    required List<Map<String, dynamic>> items,
  }) async {
    final offlineId = 'OFF-${DateTime.now().millisecondsSinceEpoch}-${_uuid.v4().substring(0, 5).toUpperCase()}';
    final payload = {
      'offline_id': offlineId,
      'order_type': orderType,
      'table_number': tableNumber,
      'customer_name': customerName,
      'payment_method': paymentMethod,
      'discount_percent': discountPercent,
      'tax_percent': taxPercent,
      'paid': paid,
      'items': items,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _storageService.addOfflineTransaction(payload);
    _refreshCount();
    return offlineId;
  }

  /// Melakukan sinkronisasi batch semua transaksi offline yang tersimpan ke backend
  Future<bool> syncPendingTransactions() async {
    final queue = _storageService.getOfflineQueue();
    if (queue.isEmpty) {
      Get.snackbar(
        'Sinkronisasi',
        'Tidak ada antrean transaksi offline yang perlu disinkronkan.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    }

    isSyncing.value = true;
    try {
      final response = await _apiProvider.post(
        ApiConstants.syncOffline,
        data: {
          'transactions': queue,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        await _storageService.clearOfflineQueue();
        _refreshCount();
        final syncedCount = response.data['synced_count'] ?? queue.length;
        Get.snackbar(
          'Sinkronisasi Berhasil',
          '$syncedCount transaksi offline berhasil dikirim ke server.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        Get.snackbar(
          'Gagal Sinkronisasi',
          response.data['message'] ?? 'Gagal memproses sinkronisasi di server.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      final errorMsg = ApiProvider.getErrorMessage(e);
      Get.snackbar(
        'Gagal Sinkronisasi',
        errorMsg,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isSyncing.value = false;
      _refreshCount();
    }
  }
}
