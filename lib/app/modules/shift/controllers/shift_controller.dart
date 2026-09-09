import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../../data/models/shift_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/esc_pos_printer_service.dart';
import '../../../data/services/offline_sync_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../routes/app_routes.dart';
import '../../pos/controllers/pos_controller.dart';
import '../../transactions/controllers/transactions_controller.dart';

class ShiftController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final StorageService _storageService = Get.find<StorageService>();

  final Rx<ShiftModel?> currentShift = Rx<ShiftModel?>(null);
  final RxBool hasActiveShift = false.obs;
  final RxBool isLoading = false.obs;

  /// Apakah koneksi ke server sedang offline
  bool get isConnectionOffline => !_apiProvider.isOnline.value || _storageService.isOfflineToken;

  /// Jumlah data offline yang belum disinkronkan ke server (transaksi & shift kasir)
  int get offlineTransactionsCount {
    if (Get.isRegistered<OfflineSyncService>()) {
      return Get.find<OfflineSyncService>().pendingCount.value;
    }
    final queueLen = _storageService.getOfflineQueue().length;
    final closedShiftCount = _storageService.getOfflineClosedShifts().length;
    return queueLen + closedShiftCount;
  }

  /// Apakah ada transaksi offline yang belum disinkronkan ke server
  bool get hasPendingOfflineTransactions => offlineTransactionsCount > 0;

  /// Menentukan apakah shift sedang berjalan dalam mode offline lokal murni (tanpa koneksi server)
  bool get isShiftOffline {
    final shift = currentShift.value;
    if (shift == null) return false;
    if (shift.id <= 0) return true;
    if (_storageService.isOfflineToken) return true;
    if (!_apiProvider.isOnline.value) return true;
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    // Load from cache first (kecuali kasir sudah menutup shift offline)
    final closedShifts = _storageService.getOfflineClosedShifts();
    if (closedShifts.isNotEmpty) {
      currentShift.value = null;
      hasActiveShift.value = false;
      _storageService.saveActiveShift(null);
    } else {
      final cached = _storageService.activeShift;
      if (cached != null) {
        currentShift.value = cached;
        hasActiveShift.value = cached.isOpen;
      }
    }
    fetchCurrentShift();
  }

  /// Ambil status shift aktif kasir saat ini
  Future<void> fetchCurrentShift() async {
    try {
      if (_storageService.isOfflineToken) {
        await _apiProvider.ensureAuthenticated();
      }
      if (_storageService.isOfflineToken) {
        final closedShifts = _storageService.getOfflineClosedShifts();
        if (closedShifts.isNotEmpty) {
          currentShift.value = null;
          hasActiveShift.value = false;
          await _storageService.saveActiveShift(null);
          return;
        }
        final cached = _storageService.activeShift;
        if (cached != null) {
          currentShift.value = cached;
          hasActiveShift.value = cached.isOpen;
        }
        return;
      }

      final response = await _apiProvider.get(ApiConstants.currentShift);
      if (response.data != null && response.data['success'] == true) {
        final closedShifts = _storageService.getOfflineClosedShifts();

        // GUARD KUNCI: Jika kasir sudah menutup shift secara offline,
        // JANGAN PERNAH menerima atau memasang kembali shift lama dari server!
        if (closedShifts.isNotEmpty) {
          currentShift.value = null;
          hasActiveShift.value = false;
          await _storageService.saveActiveShift(null);

          // Segera sinkronkan shift lama yang ditutup ke server di latar belakang
          if (Get.isRegistered<OfflineSyncService>()) {
            final syncService = Get.find<OfflineSyncService>();
            if (!syncService.isSyncing.value) {
              syncService.syncPendingTransactions(isSilent: true);
            }
          }
          return;
        }

        hasActiveShift.value = response.data['has_active_shift'] == true;
        if (response.data['data'] != null) {
          var shift = ShiftModel.fromJson(response.data['data']);

          // Jika ada antrean transaksi offline yang belum disinkronkan,
          // akumulasikan agar kasir tetap melihat omset dan status offline yang riil
          final queue = _storageService.getOfflineQueue();
          if (queue.isNotEmpty) {
            // Karena server berhasil dihubungi (online), segera sinkronkan transaksi offline di latar belakang
            if (Get.isRegistered<OfflineSyncService>()) {
              final syncService = Get.find<OfflineSyncService>();
              if (!syncService.isSyncing.value) {
                syncService.syncPendingTransactions(isSilent: true).then((success) {
                  if (success) {
                    fetchCurrentShift();
                  }
                });
              }
            }

            double offCash = 0;
            double offQris = 0;
            double offTransfer = 0;
            double offTotal = 0;
            int thisShiftOfflineCount = 0;

            final shiftStartTime = DateTime.tryParse(shift.startTime ?? '') ?? DateTime.now();

            for (final q in queue) {
              final txCreatedAt = DateTime.tryParse(q['created_at']?.toString() ?? '') ?? DateTime.now();

              // Guard: Hanya akumulasikan transaksi yang dibuat selama shift aktif ini berjalan.
              // Transaksi kemarin (shift sebelumnya) tidak boleh mencemari omset atau kas shift saat ini.
              if (txCreatedAt.isBefore(shiftStartTime.subtract(const Duration(seconds: 5)))) {
                continue;
              }

              thisShiftOfflineCount++;
              double txTotal = (q['total'] as num?)?.toDouble() ?? 0.0;
              if (txTotal <= 0 && q['items'] != null && q['items'] is List) {
                double sub = 0;
                for (final itm in (q['items'] as List)) {
                  final p = (itm['price'] as num?)?.toDouble() ?? 0.0;
                  final qty = int.tryParse(itm['quantity']?.toString() ?? '1') ?? 1;
                  sub += p * qty;
                }
                final disc = (q['discount_percent'] as num?)?.toDouble() ?? 0.0;
                final tax = (q['tax_percent'] as num?)?.toDouble() ?? 0.0;
                txTotal = sub - (sub * disc / 100) + (sub * tax / 100);
              }
              if (txTotal <= 0) {
                txTotal = (q['paid'] as num?)?.toDouble() ?? 0.0;
              }

              final method = q['payment_method']?.toString().toLowerCase() ?? '';
              offTotal += txTotal;
              if (method.contains('cash') || method.contains('tunai')) {
                offCash += txTotal;
              } else if (method.contains('qris')) {
                offQris += txTotal;
              } else {
                offTransfer += txTotal;
              }
            }
            shift = shift.copyWith(
              cashSales: shift.cashSales + offCash,
              qrisSales: shift.qrisSales + offQris,
              transferSales: shift.transferSales + offTransfer,
              totalSales: shift.totalSales + offTotal,
              totalTransactions: shift.totalTransactions + thisShiftOfflineCount,
              expectedCash: shift.expectedCash + offCash,
              offlineTransactionsCount: thisShiftOfflineCount,
              isOffline: false, // Server online terhubung
            );
          }

          currentShift.value = shift;
          await _storageService.saveActiveShift(shift);
        } else {
          // Jika ada shift offline yang belum disinkronkan, jangan sembarangan ditimpa null
          final cached = _storageService.activeShift;
          if (cached != null && cached.id <= 0) {
            currentShift.value = cached;
            hasActiveShift.value = cached.isOpen;
          } else {
            currentShift.value = null;
            hasActiveShift.value = false;
            await _storageService.saveActiveShift(null);
          }
        }
      }
    } catch (e) {
      if (ApiProvider.isNetworkError(e)) {
        _apiProvider.isOnline.value = false;
      }
      // Pertahankan status shift lokal jika offline / request gagal
      final cached = _storageService.activeShift;
      if (cached != null) {
        currentShift.value = cached;
        hasActiveShift.value = cached.isOpen;
      }
    }
  }

  /// Catat transaksi penjualan ke shift aktif secara real-time saat offline
  void recordOfflineSale({required double amount, required String paymentMethod}) {
    final current = currentShift.value ?? _storageService.activeShift;
    if (current != null && current.isOpen) {
      final updated = current.recordSale(
        amount: amount,
        paymentMethod: paymentMethod,
      );
      currentShift.value = updated;
      hasActiveShift.value = true;
      _storageService.saveActiveShift(updated);
    }
  }

  /// Sesuaikan omset per metode dan kas di laci saat kasir mengubah metode pembayaran transaksi offline
  void switchOfflineSalePaymentMethod({
    required double amount,
    required String oldPaymentMethod,
    required String newPaymentMethod,
  }) {
    final current = currentShift.value ?? _storageService.activeShift;
    if (current != null) {
      final updated = current.switchSalePaymentMethod(
        amount: amount,
        oldPaymentMethod: oldPaymentMethod,
        newPaymentMethod: newPaymentMethod,
      );
      currentShift.value = updated;
      _storageService.saveActiveShift(updated);
    }
  }

  /// Buka Shift Kasir dengan Modal Awal
  Future<bool> startShift(double startingCash) async {
    isLoading.value = true;
    try {
      // 1. Cek Konektivitas ke Server & Auto Re-Auth jika kasir dalam offline token
      bool isConnected = false;
      try {
        if (_storageService.isOfflineToken) {
          await _apiProvider.ensureAuthenticated();
        }
        isConnected = await _apiProvider.checkConnection();
      } catch (_) {
        isConnected = false;
      }

      // 2. Pre-Sync Protection: Jika ada internet, sinkronkan antrean offline lama terlebih dahulu
      // agar transaksi dari shift sebelumnya tidak tercampur ke shift baru!
      if (isConnected && !_storageService.isOfflineToken) {
        final closedShifts = _storageService.getOfflineClosedShifts();
        final offlineQueue = _storageService.getOfflineQueue();
        if (closedShifts.isNotEmpty || offlineQueue.isNotEmpty) {
          if (Get.isRegistered<OfflineSyncService>()) {
            await Get.find<OfflineSyncService>().syncPendingTransactions(isSilent: true);
          }
        }
      }

      // Jika kasir dalam mode offline token atau offline murni
      if (!isConnected || _storageService.isOfflineToken) {
        final closedShifts = _storageService.getOfflineClosedShifts();
        if (closedShifts.isNotEmpty) {
          AppSnackbar.danger(
            'Tidak Dapat Buka Shift',
            'Shift sebelumnya telah ditutup secara offline dan belum tersinkronisasi. Silakan hubungkan internet terlebih dahulu agar data shift sebelumnya terunggah sebelum membuka shift baru.',
          );
          return false;
        }
        return _startOfflineShift(startingCash);
      }

      final response = await _apiProvider.post(
        ApiConstants.startShift,
        data: {'starting_cash': startingCash},
      );

      if (response.data != null && response.data['success'] == true) {
        final shift = ShiftModel.fromJson(response.data['data']);
        currentShift.value = shift;
        hasActiveShift.value = true;
        await _storageService.saveActiveShift(shift);

        AppSnackbar.success(
          'Shift Kasir Dibuka',
          response.data['message'] ?? 'Shift kasir berhasil dibuka dengan sukses.',
        );
        return true;
      } else {
        AppSnackbar.danger(
          'Gagal Buka Shift',
          response.data['message'] ?? 'Terjadi kesalahan saat membuka shift.',
        );
        return false;
      }
    } catch (e) {
      if (_isNetworkError(e)) {
        final closedShifts = _storageService.getOfflineClosedShifts();
        if (closedShifts.isNotEmpty) {
          AppSnackbar.danger(
            'Tidak Dapat Buka Shift',
            'Koneksi terputus dan shift sebelumnya belum tersinkronisasi ke server. Silakan hubungkan internet terlebih dahulu sebelum membuka shift baru.',
          );
          return false;
        }
        return _startOfflineShift(startingCash);
      }

      AppSnackbar.danger('Gagal Buka Shift', ApiProvider.getErrorMessage(e));
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  bool _startOfflineShift(double startingCash) {
    final user = _storageService.user;
    final offlineShift = ShiftModel(
      id: -1,
      userId: user?.id,
      status: 'open',
      startTime: DateTime.now().toIso8601String(),
      startingCash: startingCash,
      expectedCash: startingCash,
      isOffline: true,
      offlineTransactionsCount: 0,
    );
    currentShift.value = offlineShift;
    hasActiveShift.value = true;
    _storageService.saveActiveShift(offlineShift);

    AppSnackbar.warning(
      'Shift Kasir Dibuka (Offline)',
      'Shift dibuka dalam mode offline lokal dengan modal awal kasir.',
    );
    return true;
  }

  /// Tutup Shift Kasir dengan Uang Fisik Riil
  Future<bool> endShift(double actualCash, String notes) async {
    isLoading.value = true;
    try {
      // Guard: Cek apakah ada open bill offline yang masih belum selesai di meja
      final offlineBills = _storageService.getOfflineOpenBills();
      if (offlineBills.isNotEmpty) {
        AppSnackbar.danger(
          'Gagal Tutup Shift',
          'Tidak dapat menutup shift! Masih ada ${offlineBills.length} Bill Aktif (Open Bill) offline di meja yang belum diselesaikan.',
          actionLabel: 'Lihat Bill',
          onAction: () => Get.toNamed(AppRoutes.openBills),
        );
        return false;
      }

      // 1. Cek Konektivitas ke Server & Auto Re-Auth jika kasir dalam offline token
      bool isConnected = false;
      try {
        if (_storageService.isOfflineToken) {
          await _apiProvider.ensureAuthenticated();
        }
        isConnected = await _apiProvider.checkConnection();
      } catch (_) {
        isConnected = false;
      }

      // 2. KONDISI ONLINE: Sinkronkan seluruh transaksi offline & tutup shift resmi di server
      if (isConnected && !_storageService.isOfflineToken) {
        final offlineQueue = _storageService.getOfflineQueue();
        final active = currentShift.value ?? _storageService.activeShift;
        final isLocalOffline = active != null && (active.isOffline || active.id <= 0);

        // Jika ada transaksi offline yang tertunda atau shift aktif dibuat secara offline:
        if (offlineQueue.isNotEmpty || isLocalOffline) {
          if (Get.isRegistered<OfflineSyncService>()) {
            final syncService = Get.find<OfflineSyncService>();
            AppSnackbar.info(
              'Sinkronisasi Transaksi',
              'Menyinkronkan transaksi offline ke server sebelum menutup shift...',
            );

            final syncOk = await syncService.syncPendingTransactions(isSilent: true);
            if (!syncOk) {
              AppSnackbar.danger(
                'Gagal Tutup Shift',
                'Gagal menyinkronkan transaksi offline ke server. Mohon periksa koneksi internet dan coba lagi.',
              );
              return false;
            }

            // Ambil data shift terkini dari server setelah recalculateTotals
            await fetchCurrentShift();
          }
        }

        final response = await _apiProvider.post(
          ApiConstants.endShift,
          data: {
            'actual_cash': actualCash,
            'notes': notes,
          },
        );

        if (response.data != null && response.data['success'] == true) {
          // Cetak struk rekapitulasi shift jika server mengembalikan receipt_payload
          if (response.data['receipt_payload'] != null && Get.isRegistered<EscPosPrinterService>()) {
            final printer = Get.find<EscPosPrinterService>();
            if (printer.isConnected.value) {
              await printer.printShiftReport(response.data['receipt_payload']);
            }
          }

          currentShift.value = null;
          hasActiveShift.value = false;
          await _storageService.saveActiveShift(null);
          await _storageService.clearOfflineCompletedServerBillIds();

          if (Get.isRegistered<OfflineSyncService>()) {
            Get.find<OfflineSyncService>().refreshCount();
          }

          AppSnackbar.success(
            'Shift Kasir Ditutup',
            response.data['message'] ?? 'Shift kasir berhasil ditutup dan transaksi offline telah tersinkronkan.',
          );

          if (Get.isRegistered<PosController>()) {
            Get.find<PosController>().fetchBootstrap(isSilent: true);
            Get.find<PosController>().fetchOpenBillsCount();
          }
          if (Get.isRegistered<TransactionsController>()) {
            Get.find<TransactionsController>().fetchTodayTransactions(silent: true);
          }

          return true;
        } else {
          final msg = response.data['message']?.toString() ?? 'Terjadi kesalahan saat menutup shift.';
          final isOpenBillError = msg.toLowerCase().contains('bill') || msg.toLowerCase().contains('meja');

          if (isOpenBillError) {
            AppSnackbar.danger(
              'Gagal Tutup Shift',
              msg,
              actionLabel: 'Lihat Bill',
              onAction: () => Get.toNamed(AppRoutes.openBills),
            );
          } else {
            AppSnackbar.danger('Gagal Tutup Shift', msg);
          }
          return false;
        }
      }

      // 3. KONDISI OFFLINE: Simpan ke antrean offline lokal
      return await _endOfflineShift(actualCash, notes);
    } catch (e) {
      if (_isNetworkError(e)) {
        return await _endOfflineShift(actualCash, notes);
      }

      final errorMsg = ApiProvider.getErrorMessage(e);
      final isOpenBillError = errorMsg.toLowerCase().contains('bill') || errorMsg.toLowerCase().contains('meja');

      if (isOpenBillError) {
        AppSnackbar.danger(
          'Gagal Tutup Shift',
          errorMsg,
          actionLabel: 'Lihat Bill',
          onAction: () => Get.toNamed(AppRoutes.openBills),
        );
      } else {
        AppSnackbar.danger('Gagal Tutup Shift', errorMsg);
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Proses penutupan shift kasir saat offline (antrean lokal & cetak struk)
  Future<bool> _endOfflineShift(double actualCash, String notes) async {
    final current = currentShift.value ?? _storageService.activeShift;
    if (current == null) {
      AppSnackbar.danger('Gagal Tutup Shift', 'Tidak ditemukan shift aktif untuk ditutup.');
      return false;
    }

    final difference = actualCash - current.expectedCash;
    final nowIso = DateTime.now().toIso8601String();
    final nowFormatted = DateFormatter.formatDateTime(nowIso);
    final startFormatted = DateFormatter.formatDateTime(current.startTime);

    // Payload lengkap untuk antrean offline closed shifts
    final closedShiftPayload = {
      'shift_id': current.id > 0 ? current.id : '#SFT-OFF-${DateTime.now().millisecondsSinceEpoch}',
      'user_id': current.userId ?? _storageService.user?.id,
      'cashier_name': _storageService.user?.name ?? 'Kasir',
      'start_time': current.startTime ?? nowIso,
      'end_time': nowIso,
      'status': 'closed',
      'summary': {
        'starting_cash': current.startingCash,
        'cash_sales': current.cashSales,
        'qris_sales': current.qrisSales,
        'transfer_sales': current.transferSales,
        'total_sales': current.totalSales,
        'total_transactions': current.totalTransactions,
        'expected_cash': current.expectedCash,
        'actual_cash': actualCash,
        'difference': difference,
      },
      'notes': notes,
      'is_offline': true,
    };

    // 1. Simpan ke antrean offline closed shifts
    await _storageService.addOfflineClosedShift(closedShiftPayload);

    // 2. Cetak Struk Rekapitulasi Shift Kasir
    final posCtrl = Get.isRegistered<PosController>() ? Get.find<PosController>() : null;
    final cafeSettings = posCtrl?.cafeSettings.value;
    final shopName = (cafeSettings?.shopName.isNotEmpty == true) ? cafeSettings!.shopName : 'NOLI COFFEE & SPACE';
    final address = (cafeSettings?.address.isNotEmpty == true) ? cafeSettings!.address : '';
    final phone = cafeSettings?.phone ?? '';

    final receiptPayload = {
      'header': {
        'shop_name': shopName,
        'address': address,
        'phone': phone,
      },
      'cashier_name': _storageService.user?.name ?? 'Kasir',
      'shift_id': current.id > 0 ? '#SFT-${current.id.toString().padLeft(5, '0')}' : 'OFFLINE',
      'start_time': startFormatted,
      'end_time': nowFormatted,
      'status': 'closed',
      'summary': closedShiftPayload['summary'],
      'notes': notes,
    };

    if (Get.isRegistered<EscPosPrinterService>()) {
      final printer = Get.find<EscPosPrinterService>();
      if (printer.isConnected.value) {
        await printer.printShiftReport(receiptPayload);
      }
    }

    // 3. Bersihkan active shift lokal
    currentShift.value = null;
    hasActiveShift.value = false;
    await _storageService.saveActiveShift(null);

    AppSnackbar.warning(
      'Shift Kasir Ditutup (Offline)',
      'Shift berhasil ditutup di perangkat dan rekapitulasi tersimpan di antrean offline.',
    );
    return true;
  }

  bool _isNetworkError(dynamic e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;
    }
    return true;
  }
}
