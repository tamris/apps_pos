import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'storage_service.dart';
import '../models/shift_model.dart';
import '../providers/api_provider.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_snackbar.dart';
import '../../modules/pos/controllers/pos_controller.dart';
import '../../modules/shift/controllers/shift_controller.dart';
import '../../modules/transactions/controllers/transactions_controller.dart';
import '../../modules/open_bills/controllers/open_bills_controller.dart';

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

  /// Melakukan sinkronisasi batch semua transaksi offline dan shift offline yang tersimpan ke backend
  Future<bool> syncPendingTransactions() async {
    final queue = _storageService.getOfflineQueue();
    final activeShift = _storageService.activeShift;

    // Jika tidak ada antrean transaksi dan tidak ada shift offline yang perlu disinkronkan
    if (queue.isEmpty && (activeShift == null || activeShift.id > 0)) {
      AppSnackbar.info(
        'Sinkronisasi',
        'Tidak ada data offline yang perlu disinkronkan.',
      );
      return true;
    }

    isSyncing.value = true;
    try {
      // 1. Pastikan terautentikasi (Silent re-auth jika kasir masih menggunakan offline token)
      final bool isAuthenticated = await _apiProvider.ensureAuthenticated();
      if (!isAuthenticated && _storageService.isOfflineToken) {
        AppSnackbar.danger(
          'Gagal Sinkronisasi',
          'Tidak dapat terhubung ke server atau sesi kasir belum terautentikasi.',
        );
        return false;
      }

      // 2. Sinkronisasi Shift Offline (jika kasir membuka shift saat offline / id <= 0)
      if (activeShift != null && activeShift.id <= 0) {
        try {
          final shiftCheck = await _apiProvider.get(ApiConstants.currentShift);
          bool serverHasShift = false;
          if (shiftCheck.data != null && shiftCheck.data['success'] == true) {
            serverHasShift = shiftCheck.data['has_active_shift'] == true;
          }

          if (!serverHasShift) {
            // Buka shift resmi di server dengan modal awal yang diinput kasir saat offline
            final startRes = await _apiProvider.post(
              ApiConstants.startShift,
              data: {'starting_cash': activeShift.startingCash},
            );
            if (startRes.data != null && startRes.data['success'] == true) {
              final realShift = ShiftModel.fromJson(startRes.data['data']);
              await _storageService.saveActiveShift(realShift);
              if (Get.isRegistered<ShiftController>()) {
                final shiftCtrl = Get.find<ShiftController>();
                shiftCtrl.currentShift.value = realShift;
                shiftCtrl.hasActiveShift.value = true;
              }
            }
          }
        } catch (_) {
          // Lanjutkan jika ada kendala spesifik shift
        }
      }

      // 2b. Sinkronisasi Offline Open Bills (jika ada bill meja offline yang masih aktif)
      final offlineBills = _storageService.getOfflineOpenBills();
      if (offlineBills.isNotEmpty) {
        for (final bill in offlineBills) {
          try {
            final billPayload = {
              'order_type': bill['order_type'] ?? 'dine_in',
              'table_number': bill['table_number'],
              'customer_name': bill['customer_name'],
              'discount_percent': bill['discount_percent'] ?? 0.0,
              'tax_percent': bill['tax_percent'] ?? 0.0,
              'items': (bill['details'] as List? ?? []).map((d) {
                int pId = int.tryParse(d['product_id']?.toString() ?? d['id']?.toString() ?? '0') ?? 0;
                if (pId <= 0 && Get.isRegistered<PosController>()) {
                  final pos = Get.find<PosController>();
                  final name = d['name']?.toString() ?? '';
                  final match = pos.products.firstWhereOrNull((p) => p.name.toLowerCase() == name.toLowerCase());
                  if (match != null) {
                    pId = match.id;
                  } else if (pos.products.isNotEmpty) {
                    pId = pos.products.first.id;
                  }
                }
                if (pId <= 0) pId = 1;
                return {
                  'id': pId,
                  'quantity': d['quantity'] ?? 1,
                  'notes': d['notes'],
                  'addons': d['addons'] ?? [],
                };
              }).toList(),
            };

            final billRes = await _apiProvider.post(ApiConstants.openBills, data: billPayload);
            if (billRes.data != null && billRes.data['success'] == true) {
              await _storageService.removeOfflineOpenBill(bill['id']);
            }
          } catch (_) {}
        }
      }

      // Jika hanya ada shift offline tanpa transaksi
      if (queue.isEmpty) {
        if (Get.isRegistered<PosController>()) {
          Get.find<PosController>().fetchBootstrap(isSilent: true);
        }
        if (Get.isRegistered<OpenBillsController>()) {
          Get.find<OpenBillsController>().fetchOpenBills();
        }
        AppSnackbar.success(
          'Sinkronisasi Shift Berhasil',
          'Shift dan data kasir offline berhasil disinkronkan ke server.',
        );
        return true;
      }

      // 3. Sanitasi data transaksi: perbaiki product_id jika <= 0
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

      // 4. Kirim transaksi offline ke server
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
          '$syncedCount transaksi offline berhasil disinkronkan dan masuk ke shift kasir.',
        );

        // 5. Refresh master data & status shift dari server
        if (Get.isRegistered<PosController>()) {
          Get.find<PosController>().fetchBootstrap(isSilent: true);
        }
        if (Get.isRegistered<ShiftController>()) {
          Get.find<ShiftController>().fetchCurrentShift();
        }
        if (Get.isRegistered<TransactionsController>()) {
          Get.find<TransactionsController>().fetchTodayTransactions(silent: true);
        }
        if (Get.isRegistered<OpenBillsController>()) {
          Get.find<OpenBillsController>().fetchOpenBills();
        }

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
