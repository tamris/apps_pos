import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/esc_pos_printer_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../views/widgets/receipt_view_dialog.dart';

class TransactionsController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final EscPosPrinterService _printerService = Get.find<EscPosPrinterService>();

  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final Rx<TransactionStatsModel> stats = TransactionStatsModel.empty().obs;
  final RxString selectedTab = 'completed'.obs; // 'completed', 'pending', 'cancelled', 'all'
  RxString get selectedStatus => selectedTab;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchTodayTransactions();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Ambil riwayat transaksi hari ini kasir beserta live stats
  Future<void> fetchTodayTransactions({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final response = await _apiProvider.get(
        ApiConstants.todayTransactions,
        queryParameters: {
          if (searchQuery.value.trim().isNotEmpty) 'search': searchQuery.value.trim(),
          'status': selectedTab.value,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final List list = (data is Map && data['data'] != null) ? data['data'] : (data is List ? data : []);
        transactions.assignAll(list.map((e) => TransactionModel.fromJson(e)).toList());

        if (response.data['stats'] != null) {
          stats.value = TransactionStatsModel.fromJson(response.data['stats']);
        }
      }
    } catch (e) {
      if (!silent) {
        AppSnackbar.danger('Riwayat Transaksi', ApiProvider.getErrorMessage(e));
      }
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  /// Ambil data struk dan cetak ulang / tampilkan preview
  Future<void> printOrPreviewReceipt(int transactionId) async {
    try {
      final response = await _apiProvider.get(ApiConstants.receiptData(transactionId));
      if (response.data != null && response.data['success'] == true) {
        final payload = response.data['data'];
        if (_printerService.isConnected.value) {
          await _printerService.printReceipt(payload);
        } else {
          ReceiptViewDialog.show(payload);
        }
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Cetak Ulang', ApiProvider.getErrorMessage(e));
    }
  }

  /// Tampilkan Pratinjau Kertas Struk
  Future<void> previewReceipt(int transactionId) async {
    try {
      final response = await _apiProvider.get(ApiConstants.receiptData(transactionId));
      if (response.data != null && response.data['success'] == true) {
        final payload = response.data['data'];
        ReceiptViewDialog.show(payload);
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Pratinjau Struk', ApiProvider.getErrorMessage(e));
    }
  }

  /// Ganti Tab Status (Selesai, Open Bill, Dibatalkan, Semua)
  void changeTab(String tab) {
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
    fetchTodayTransactions();
  }

  /// Cari transaksi berdasarkan nama / meja / invoice (silent agar tidak kedip skeleton)
  void onSearch(String val) {
    searchQuery.value = val;
    fetchTodayTransactions(silent: true);
  }

  /// Bersihkan pencarian
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchTodayTransactions(silent: true);
  }

  void onSearchChanged(String query) => onSearch(query);
  void onStatusChanged(String status) => changeTab(status);
}
