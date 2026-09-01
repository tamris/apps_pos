import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'storage_service.dart';
import '../providers/api_provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snackbar.dart';
import '../../modules/pos/controllers/pos_controller.dart';

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

  /// Bersihkan antrean offline secara manual
  Future<void> clearOfflineQueue() async {
    await _storageService.clearOfflineQueue();
    _refreshCount();
  }

  /// Tampilkan Dialog Pengelolaan Antrean Offline
  void showSyncDialog(BuildContext context) {
    _refreshCount();
    final count = pendingCount.value;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.cloud_sync_rounded, color: AppColors.warning, size: 22),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sinkronisasi Offline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terdapat $count transaksi offline yang tersimpan di perangkat ini.',
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pastikan perangkat terhubung ke internet dan backend aktif untuk menyinkronkan data transaksi.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Tutup', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.cloud_upload_rounded, size: 18),
            label: const Text('Sinkronkan Sekarang'),
            onPressed: () {
              Get.back();
              syncPendingTransactions();
            },
          ),
        ],
      ),
    );
  }

  /// Melakukan sinkronisasi batch semua transaksi offline yang tersimpan ke backend
  Future<bool> syncPendingTransactions() async {
    final queue = _storageService.getOfflineQueue();
    if (queue.isEmpty) {
      AppSnackbar.info(
        'Sinkronisasi',
        'Tidak ada antrean transaksi offline yang perlu disinkronkan.',
      );
      return true;
    }

    // Sanitasi data: perbaiki jika ada product_id = 0 agar tidak melanggar foreign key MySQL
    final sanitizedQueue = queue.map((rawTx) {
      final tx = Map<String, dynamic>.from(rawTx);
      if (tx['items'] != null && tx['items'] is List) {
        final itemsList = (tx['items'] as List).map((rawItem) {
          final item = Map<String, dynamic>.from(rawItem);
          int pId = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
          if (pId <= 0 && Get.isRegistered<PosController>()) {
            final pos = Get.find<PosController>();
            final name = item['name']?.toString() ?? '';
            final match = pos.products.firstWhereOrNull((p) => p.name.toLowerCase() == name.toLowerCase());
            if (match != null) {
              pId = match.id;
            } else if (pos.products.isNotEmpty) {
              pId = pos.products.first.id;
            }
          }
          if (pId <= 0) pId = 1;
          item['id'] = pId;
          return item;
        }).toList();
        tx['items'] = itemsList;
      }
      return tx;
    }).toList();

    isSyncing.value = true;
    try {
      final response = await _apiProvider.post(
        ApiConstants.syncOffline,
        data: {
          'transactions': sanitizedQueue,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        await _storageService.clearOfflineQueue();
        _refreshCount();
        final syncedCount = response.data['synced_count'] ?? queue.length;
        AppSnackbar.success(
          'Sinkronisasi Berhasil',
          '$syncedCount transaksi offline berhasil dikirim ke server.',
        );
        return true;
      } else {
        AppSnackbar.danger(
          'Gagal Sinkronisasi',
          response.data['message'] ?? 'Gagal memproses sinkronisasi di server.',
        );
        return false;
      }
    } catch (e) {
      final errorMsg = ApiProvider.getErrorMessage(e);
      AppSnackbar.danger(
        'Gagal Sinkronisasi',
        errorMsg,
      );
      return false;
    } finally {
      isSyncing.value = false;
      _refreshCount();
    }
  }
}
