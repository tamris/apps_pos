import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/online_order_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/esc_pos_printer_service.dart';
import '../../../data/services/online_order_polling_service.dart';

class OnlineOrdersController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final EscPosPrinterService printerService = Get.find<EscPosPrinterService>();
  final OnlineOrderPollingService pollingService = Get.find<OnlineOrderPollingService>();

  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;
  final RxList<OnlineOrderModel> orders = <OnlineOrderModel>[].obs;
  final Rx<OnlineOrderStatsModel> stats = OnlineOrderStatsModel.empty().obs;
  final RxString selectedTab = 'active'.obs; // active, pending, processing, ready, completed, cancelled
  final RxString searchQuery = ''.obs;
  final RxBool isStoreOnlineActive = true.obs;

  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Sinkronkan status awal dengan service polling global
    isStoreOnlineActive.value = pollingService.isOnlineOrderActive.value;
    fetchOrders();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Ambil daftar pesanan online dari backend
  Future<void> fetchOrders({bool silent = false}) async {
    if (!silent) isLoading.value = true;

    try {
      final queryParams = <String, dynamic>{
        'status': selectedTab.value,
      };
      if (searchQuery.value.trim().isNotEmpty) {
        queryParams['search'] = searchQuery.value.trim();
      }

      final response = await _apiProvider.get(
        ApiConstants.onlineOrders,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final List rawData = response.data['data'] ?? [];
        final parsed = rawData.map((e) => OnlineOrderModel.fromJson(e)).toList();
        orders.assignAll(parsed);

        if (response.data['stats'] != null) {
          final statsData = OnlineOrderStatsModel.fromJson(response.data['stats']);
          stats.value = statsData;
          isStoreOnlineActive.value = statsData.isOnlineOrderActive;
          pollingService.isOnlineOrderActive.value = statsData.isOnlineOrderActive;
          pollingService.liveStats.value = statsData;
          pollingService.activeOrdersCount.value = statsData.active;
          pollingService.pendingOrdersCount.value = statsData.pending;
        }
      }
    } catch (e) {
      if (!silent) {
        AppSnackbar.danger('Gagal Memuat Pesanan', ApiProvider.getErrorMessage(e));
      }
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  /// Ganti Tab Status (Aktif, Menunggu, Sedang Dimasak, Siap, Selesai, Dibatalkan)
  void changeTab(String tab) {
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
    fetchOrders();
  }

  /// Cari pesanan berdasarkan nama / meja / invoice
  void onSearch(String val) {
    searchQuery.value = val;
    fetchOrders(silent: true);
  }

  /// Bersihkan pencarian
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchOrders(silent: true);
  }

  /// Update status pesanan online (Terima, Masak, Siap, Selesai, Tolak)
  Future<bool> updateOrderStatus(
    OnlineOrderModel order,
    String newStatus, {
    String? reason,
    bool autoPrintKitchen = false,
  }) async {
    isUpdating.value = true;
    try {
      final response = await _apiProvider.post(
        ApiConstants.updateOnlineOrderStatus(order.id),
        data: {
          'status': newStatus,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );

      if (response.statusCode == 200) {
        try {
          HapticFeedback.mediumImpact();
        } catch (_) {}

        final msg = response.data['message'] ?? 'Status pesanan berhasil diperbarui.';
        AppSnackbar.success('Berhasil', msg);

        // Jika opsi auto print dapur saat menerima pesanan aktif
        if (autoPrintKitchen && (newStatus == 'processing' || newStatus == 'ready')) {
          printKitchenSlip(order);
        }

        // Refresh daftar & stats
        await fetchOrders(silent: true);
        await pollingService.checkNewOrders();
        return true;
      } else {
        AppSnackbar.danger('Gagal Mengubah Status', response.data?['message'] ?? 'Terjadi kesalahan.');
        return false;
      }
    } catch (e) {
      AppSnackbar.danger('Gagal', ApiProvider.getErrorMessage(e));
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  /// Toggle penerimaan pesanan online (Buka / Tutup toko online)
  Future<void> toggleOnlineOrderStoreActive() async {
    final nextState = !isStoreOnlineActive.value;
    try {
      final response = await _apiProvider.post(
        ApiConstants.onlineOrdersToggleActive,
        data: {'is_active': nextState},
      );

      if (response.statusCode == 200) {
        bool finalStatus = nextState;
        if (response.data != null) {
          final rawVal = response.data['is_active'] ??
              response.data['data']?['is_active'] ??
              response.data['is_online_order_active'];
          if (rawVal != null) {
            finalStatus = rawVal == true || rawVal == 1 || rawVal == '1';
          }
        }

        isStoreOnlineActive.value = finalStatus;
        pollingService.isOnlineOrderActive.value = finalStatus;
        if (finalStatus) {
          pollingService.startPolling();
        } else {
          pollingService.stopPolling();
        }

        final msg = response.data?['message'] ??
            (finalStatus ? 'Pesanan online DIBUKA' : 'Pesanan online DIJEDA');
        AppSnackbar.info('Status Toko Online', msg);
        await fetchOrders(silent: true);
      }
    } catch (e) {
      AppSnackbar.danger('Gagal', ApiProvider.getErrorMessage(e));
    }
  }

  /// Cetak Tiket Dapur untuk Pesanan Online
  Future<void> printKitchenSlip(OnlineOrderModel order) async {
    try {
      final response = await _apiProvider.get(ApiConstants.onlineOrderKitchen(order.id));
      if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
        final kitchenPayload = response.data['data']['kitchen_payload'] ?? response.data['data'];
        if (kitchenPayload != null) {
          final success = await printerService.printKitchenReceipt(Map<String, dynamic>.from(kitchenPayload));
          if (success) {
            AppSnackbar.success('Cetak Dapur', 'Tiket dapur untuk pesanan ${order.shortOrderNumber} berhasil dicetak.');
          }
        }
      }
    } catch (e) {
      AppSnackbar.danger('Cetak Gagal', 'Gagal mencetak tiket dapur. Pastikan printer terhubung.');
    }
  }

  /// Cetak Struk Kasir untuk Pesanan Online
  Future<void> printCustomerReceipt(OnlineOrderModel order) async {
    try {
      final response = await _apiProvider.get(ApiConstants.onlineOrderReceipt(order.id));
      if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
        final receiptPayload = response.data['data']['receipt_payload'];
        if (receiptPayload != null) {
          final success = await printerService.printReceipt(Map<String, dynamic>.from(receiptPayload));
          if (success) {
            AppSnackbar.success('Cetak Struk', 'Struk pesanan ${order.shortOrderNumber} berhasil dicetak.');
          }
        }
      }
    } catch (e) {
      AppSnackbar.danger('Cetak Gagal', 'Gagal mencetak struk. Pastikan printer terhubung.');
    }
  }
}
