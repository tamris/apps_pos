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
  final RxInt pendingTxCount = 0.obs;
  final RxInt pendingShiftCount = 0.obs;
  final RxBool isSyncing = false.obs;
  final Rx<DateTime?> lastSyncTime = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    lastSyncTime.value = _storageService.lastSyncTime;
    refreshCount();

    // 1. Reaktif: Otomatis sinkronisasi saat koneksi berubah dari offline ke online
    ever(_apiProvider.isOnline, (bool online) {
      if (online && pendingCount.value > 0 && !isSyncing.value) {
        syncPendingTransactions(isSilent: true);
      }
    });

    // 2. Inisialisasi: Jika saat aplikasi dimuat sudah online dan ada antrean pending, sinkronkan
    Future.delayed(const Duration(seconds: 2), () {
      if (_apiProvider.isOnline.value && pendingCount.value > 0 && !isSyncing.value) {
        syncPendingTransactions(isSilent: true);
      }
    });
  }

  void refreshCount() {
    final queueCount = _storageService.getOfflineQueue().length;
    final closedShiftCount = _storageService.getOfflineClosedShifts().length;
    pendingTxCount.value = queueCount;
    pendingShiftCount.value = closedShiftCount;
    pendingCount.value = queueCount + closedShiftCount;
  }

  List<Map<String, dynamic>> getPendingTransactions() => _storageService.getOfflineQueue();
  List<Map<String, dynamic>> getPendingClosedShifts() => _storageService.getOfflineClosedShifts();

  /// Simpan transaksi ke antrean offline jika koneksi server gagal / offline mode
  Future<String> enqueueTransaction({
    required String orderType,
    String? tableNumber,
    String? customerName,
    required String paymentMethod,
    double discountPercent = 0.0,
    double taxPercent = 0.0,
    double? total,
    required double paid,
    required List<Map<String, dynamic>> items,
    int? openBillId,
    int? shiftId,
  }) async {
    final offlineId = 'OFF-${DateTime.now().millisecondsSinceEpoch}-${_uuid.v4().substring(0, 5).toUpperCase()}';

    double calculatedTotal = total ?? 0.0;
    if (calculatedTotal <= 0) {
      double sub = 0;
      for (final itm in items) {
        final p = (itm['price'] as num?)?.toDouble() ?? 0.0;
        final qty = int.tryParse(itm['quantity']?.toString() ?? '1') ?? 1;
        sub += p * qty;
      }
      calculatedTotal = sub - (sub * discountPercent / 100) + (sub * taxPercent / 100);
      if (calculatedTotal <= 0) calculatedTotal = paid;
    }

    final payload = {
      'offline_id': offlineId,
      'order_type': orderType,
      'table_number': tableNumber,
      'customer_name': customerName,
      'payment_method': paymentMethod,
      'discount_percent': discountPercent,
      'tax_percent': taxPercent,
      'total': calculatedTotal,
      'paid': paid,
      'items': items,
      'created_at': DateTime.now().toIso8601String(),
      if (openBillId != null) 'open_bill_id': openBillId,
      'shift_id': shiftId ?? _storageService.activeShift?.id,
    };

    await _storageService.addOfflineTransaction(payload);
    refreshCount();
    return offlineId;
  }

  /// Bersihkan antrean offline secara manual
  Future<void> clearOfflineQueue() async {
    await _storageService.clearOfflineQueue();
    await _storageService.clearOfflineClosedShifts();
    refreshCount();
  }

  /// Tampilkan Dialog Pengelolaan Antrean Offline
  void showSyncDialog(BuildContext context) {
    refreshCount();
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
              'Terdapat $count data offline (transaksi & shift kasir) yang tersimpan di perangkat ini.',
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
  Future<bool> syncPendingTransactions({bool isSilent = false}) async {
    // Re-entrancy Lock: Cegah eksekusi ganda jika proses sinkronisasi sedang berjalan di background
    if (isSyncing.value) {
      return false;
    }

    final queue = _storageService.getOfflineQueue();
    final activeShift = _storageService.activeShift;
    final closedShifts = _storageService.getOfflineClosedShifts();

    // Jika tidak ada antrean transaksi, shift aktif offline, dan shift tertutup
    if (queue.isEmpty && (activeShift == null || activeShift.id > 0) && closedShifts.isEmpty) {
      if (_apiProvider.isOnline.value) {
        final now = DateTime.now();
        await _storageService.saveLastSyncTime(now);
        lastSyncTime.value = now;
      }
      if (!isSilent) {
        AppSnackbar.info(
          'Sinkronisasi',
          'Semua data sudah tersinkronisasi dengan server.',
        );
      }
      return true;
    }

    isSyncing.value = true;
    try {
      // 1. Pastikan terautentikasi (Silent re-auth jika kasir masih menggunakan offline token)
      final bool isAuthenticated = await _apiProvider.ensureAuthenticated();
      if (!isAuthenticated && _storageService.isOfflineToken) {
        if (!isSilent) {
          AppSnackbar.danger(
            'Gagal Sinkronisasi',
            'Tidak dapat terhubung ke server atau sesi kasir belum terautentikasi.',
          );
        }
        return false;
      }

      // 2a. Sinkronisasi Shift Aktif Offline (jika kasir membuka shift saat offline dan masih aktif)
      if (activeShift != null && activeShift.id <= 0) {
        try {
          final shiftCheck = await _apiProvider.get(ApiConstants.currentShift);
          bool serverHasShift = false;
          if (shiftCheck.data != null && shiftCheck.data['success'] == true) {
            serverHasShift = shiftCheck.data['has_active_shift'] == true;
          }

          if (!serverHasShift) {
            // Buka shift resmi di server dengan modal awal & waktu mulai yang diinput kasir saat offline
            final startRes = await _apiProvider.post(
              ApiConstants.startShift,
              data: {
                'starting_cash': activeShift.startingCash,
                if (activeShift.startTime != null) 'start_time': activeShift.startTime,
              },
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
          } else if (shiftCheck.data != null && shiftCheck.data['data'] != null) {
            // Shift aktif sudah ada di server, sinkronkan data shift lokal ke shift server
            final realShift = ShiftModel.fromJson(shiftCheck.data['data']);
            await _storageService.saveActiveShift(realShift);
            if (Get.isRegistered<ShiftController>()) {
              final shiftCtrl = Get.find<ShiftController>();
              shiftCtrl.currentShift.value = realShift;
              shiftCtrl.hasActiveShift.value = true;
            }
          }
        } catch (_) {
          // Lanjutkan jika ada kendala spesifik shift
        }
      }
      // 2b. Jika shift dibuka dan DITUTUP saat offline, buka shift terlebih dahulu di server agar transaksi offline terasosiasi
      else if (closedShifts.isNotEmpty) {
        try {
          final shiftCheck = await _apiProvider.get(ApiConstants.currentShift);
          bool serverHasShift = false;
          if (shiftCheck.data != null && shiftCheck.data['success'] == true) {
            serverHasShift = shiftCheck.data['has_active_shift'] == true;
          }

          if (!serverHasShift) {
            final firstClosed = closedShifts.first;
            final startingCash = (firstClosed['summary']?['starting_cash'] as num?)?.toDouble() ?? 0.0;
            final startTime = firstClosed['start_time']?.toString();
            await _apiProvider.post(
              ApiConstants.startShift,
              data: {
                'starting_cash': startingCash,
                if (startTime != null) 'start_time': startTime,
              },
            );
          }
        } catch (_) {}
      }

      // 3. Sinkronisasi Offline Open Bills (jika ada bill meja offline yang masih aktif)
      final offlineBills = _storageService.getOfflineOpenBills();
      if (offlineBills.isNotEmpty) {
        for (final bill in offlineBills) {
          try {
            final bId = int.tryParse(bill['id']?.toString() ?? '0') ?? 0;
            final billPayload = {
              'order_type': bill['order_type'] ?? 'dine_in',
              'table_number': bill['table_number'],
              'customer_name': bill['customer_name'],
              'discount_percent': bill['discount_percent'] ?? 0.0,
              'tax_percent': bill['tax_percent'] ?? 0.0,
              if (bId > 0) 'open_bill_id': bId,
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
              await _storageService.removeOfflineOpenBill(bId);
            }
          } catch (_) {}
        }
      }

      // 4. Sinkronisasi Transaksi Offline (jika ada)
      if (queue.isNotEmpty) {
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

        final response = await _apiProvider.post(
          ApiConstants.syncOffline,
          data: {
            'transactions': sanitizedQueue,
          },
        );

        if (response.data != null && response.data['success'] == true) {
          await _storageService.clearOfflineQueue();
          await _storageService.clearOfflineCompletedServerBillIds();
        }
      } else {
        await _storageService.clearOfflineCompletedServerBillIds();
      }

      // 5. Sinkronisasi Offline Closed Shifts (Tutup shift resmi di server)
      if (closedShifts.isNotEmpty) {
        for (final cs in closedShifts) {
          try {
            final actualCash = (cs['summary']?['actual_cash'] as num?)?.toDouble() ?? 0.0;
            final notes = cs['notes']?.toString() ?? '';
            final endTime = cs['end_time']?.toString();
            final shiftId = int.tryParse(cs['shift_id']?.toString() ?? '0');

            await _apiProvider.post(
              ApiConstants.endShift,
              data: {
                'actual_cash': actualCash,
                'notes': notes,
                if (endTime != null) 'end_time': endTime,
                if (shiftId != null && shiftId > 0) 'shift_id': shiftId,
              },
            );
          } catch (_) {}
        }
        await _storageService.clearOfflineClosedShifts();
      }

      refreshCount();

      final now = DateTime.now();
      await _storageService.saveLastSyncTime(now);
      lastSyncTime.value = now;

      // Tampilkan notifikasi keberhasilan sinkronisasi
      final totalSynced = queue.length + closedShifts.length;
      if (totalSynced > 0) {
        String msg;
        if (queue.isNotEmpty && closedShifts.isNotEmpty) {
          msg = '${queue.length} transaksi & ${closedShifts.length} shift kasir berhasil disinkronkan ke server.';
        } else if (queue.isNotEmpty) {
          msg = '${queue.length} transaksi offline berhasil disinkronkan ke server.';
        } else {
          msg = 'Shift kasir offline berhasil disinkronkan ke server.';
        }

        AppSnackbar.success(
          'Sinkronisasi Berhasil',
          msg,
        );
      } else if (!isSilent) {
        AppSnackbar.info(
          'Sinkronisasi',
          'Tidak ada data offline yang perlu disinkronkan.',
        );
      }

      // 6. Refresh master data & status shift dari server
      if (Get.isRegistered<PosController>()) {
        Get.find<PosController>().fetchBootstrap(isSilent: true);
        Get.find<PosController>().fetchOpenBillsCount();
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
    } catch (e) {
      final errorMsg = ApiProvider.getErrorMessage(e);
      if (!isSilent) {
        AppSnackbar.danger(
          'Gagal Sinkronisasi',
          errorMsg,
        );
      }
      return false;
    } finally {
      isSyncing.value = false;
      refreshCount();
    }
  }
}
