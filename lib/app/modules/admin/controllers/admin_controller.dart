import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/admin_dashboard_model.dart';
import '../../../data/models/admin_shift_model.dart';
import '../../../data/models/admin_transaction_model.dart';
import '../../../data/models/admin_open_bill_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../routes/app_routes.dart';

class AdminController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  // Active Tab Index (0: Dashboard, 1: Transaksi & Void, 2: Audit Shift, 3: Meja Aktif)
  final RxInt selectedTabIndex = 0.obs;

  // Sidebar Collapse / Expand State (Tablet / Desktop)
  // Default closed (collapsed 68px rail) for a cleaner, wider view upon initial entry
  final RxBool isSidebarCollapsed = true.obs;
  void toggleSidebar() => isSidebarCollapsed.value = !isSidebarCollapsed.value;

  // --- TAB 1: FINANCIAL & OPERATIONAL DASHBOARD ---
  final Rx<AdminDashboardModel> dashboardData = AdminDashboardModel.empty().obs;
  final RxString selectedDashboardDate = DateFormat('yyyy-MM-dd').format(DateTime.now()).obs;
  final RxBool isLoadingDashboard = false.obs;

  // --- TAB 2: TRANSACTIONS & VOID AUTHORITY ---
  final RxList<AdminTransactionModel> transactions = <AdminTransactionModel>[].obs;
  final RxString selectedTrxStatus = 'all'.obs; // 'all', 'completed', 'pending', 'cancelled'
  final RxString selectedTrxOrderSource = 'all'.obs; // 'all', 'pos', 'self_order'
  final RxString selectedTrxPaymentMethod = 'all'.obs; // 'all', 'cash', 'qris', 'transfer'
  final Rx<String?> selectedTrxDate = Rx<String?>(null);
  final RxString trxSearchQuery = ''.obs;
  final TextEditingController trxSearchController = TextEditingController();
  final RxBool isLoadingTransactions = false.obs;

  // --- TAB 3: SHIFT AUDIT & Z-REPORT ---
  final RxList<AdminShiftModel> shifts = <AdminShiftModel>[].obs;
  final RxString selectedShiftStatus = 'all'.obs; // 'all', 'open', 'closed', 'balanced', 'discrepancy'
  final Rx<String?> selectedShiftDate = Rx<String?>(null);
  final RxString shiftSearchQuery = ''.obs;
  final TextEditingController shiftSearchController = TextEditingController();
  final RxBool isLoadingShifts = false.obs;

  List<AdminShiftModel> get filteredShifts {
    return shifts.where((s) {
      if (shiftSearchQuery.value.isNotEmpty) {
        final q = shiftSearchQuery.value.toLowerCase().trim();
        final matchesName = s.cashierName.toLowerCase().contains(q);
        final matchesId = '#${s.id}'.contains(q) || s.id.toString().contains(q);
        if (!matchesName && !matchesId) return false;
      }
      if (selectedShiftStatus.value == 'open') {
        return s.isOpen;
      } else if (selectedShiftStatus.value == 'closed') {
        return !s.isOpen;
      } else if (selectedShiftStatus.value == 'discrepancy') {
        return s.isShortage || s.isOverage;
      } else if (selectedShiftStatus.value == 'balanced') {
        return !s.isOpen && s.isBalanced;
      }
      return true;
    }).toList();
  }

  // --- TAB 4: OPEN BILLS MONITORING ---
  final RxList<AdminOpenBillModel> openBills = <AdminOpenBillModel>[].obs;
  final RxInt openBillsTotalActive = 0.obs;
  final RxDouble openBillsTotalAmount = 0.0.obs;
  final RxBool isLoadingOpenBills = false.obs;
  final RxString openBillSearchQuery = ''.obs;
  final TextEditingController openBillSearchController = TextEditingController();
  final RxString selectedOpenBillFilter = 'all'.obs;

  List<AdminOpenBillModel> get filteredOpenBills {
    final query = openBillSearchQuery.value.trim().toLowerCase();
    final filter = selectedOpenBillFilter.value;

    return openBills.where((b) {
      // 1. Status Filter
      if (filter == 'critical' && b.elapsedMinutes < 60) return false;
      if (filter == 'fresh' && b.elapsedMinutes >= 30) return false;
      if (filter == 'self_order' && !b.isSelfOrder) return false;
      if (filter == 'pos' && b.isSelfOrder) return false;

      // 2. Search Query
      if (query.isNotEmpty) {
        final matchesTable = b.tableNumber.toLowerCase().contains(query) ||
            'meja ${b.tableNumber}'.toLowerCase().contains(query);
        final matchesCustomer = b.customerName.toLowerCase().contains(query);
        final matchesInvoice = b.invoiceNumber.toLowerCase().contains(query);
        final matchesCashier = b.cashierName.toLowerCase().contains(query);

        if (!matchesTable && !matchesCustomer && !matchesInvoice && !matchesCashier) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchDashboard();
    fetchTransactions();
    fetchOpenBills();
  }

  @override
  void onClose() {
    trxSearchController.dispose();
    shiftSearchController.dispose();
    openBillSearchController.dispose();
    super.onClose();
  }

  void switchTab(int index) {
    selectedTabIndex.value = index;
    switch (index) {
      case 0:
        fetchDashboard();
        break;
      case 1:
        fetchTransactions();
        break;
      case 2:
        fetchShifts();
        break;
      case 3:
        fetchOpenBills();
        break;
    }
  }

  // ==========================================
  // 1. DASHBOARD LOGIC
  // ==========================================
  Future<void> fetchDashboard({String? date}) async {
    final targetDate = date ?? selectedDashboardDate.value;
    selectedDashboardDate.value = targetDate;
    isLoadingDashboard.value = true;

    try {
      final response = await _apiProvider.get(
        ApiConstants.adminDashboard,
        queryParameters: {'date': targetDate},
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        dashboardData.value = AdminDashboardModel.fromJson(data);
      } else {
        AppSnackbar.warning('Info', response.data?['message'] ?? 'Gagal memuat data dashboard.');
      }
    } catch (e) {
      AppSnackbar.danger('Kendala Dashboard', ApiProvider.getErrorMessage(e));
    } finally {
      isLoadingDashboard.value = false;
    }

    // Sync transactions and open bills for this dashboard date
    selectedTrxDate.value = targetDate;
    fetchTransactions();
    fetchOpenBills();
  }

  void changeDashboardDate(DateTime dt) {
    final formatted = DateFormat('yyyy-MM-dd').format(dt);
    fetchDashboard(date: formatted);
  }

  // ==========================================
  // 2. TRANSACTIONS & VOID LOGIC
  // ==========================================
  Future<void> fetchTransactions() async {
    isLoadingTransactions.value = true;

    try {
      final Map<String, dynamic> params = {'per_page': 50};

      if (selectedTrxStatus.value != 'all') {
        params['status'] = selectedTrxStatus.value;
      }
      if (selectedTrxOrderSource.value != 'all') {
        params['order_source'] = selectedTrxOrderSource.value;
      }
      if (selectedTrxPaymentMethod.value != 'all') {
        params['payment_method'] = selectedTrxPaymentMethod.value;
      }
      if (selectedTrxDate.value != null && selectedTrxDate.value!.isNotEmpty) {
        params['date'] = selectedTrxDate.value;
      }
      if (trxSearchQuery.value.trim().isNotEmpty) {
        params['search'] = trxSearchQuery.value.trim();
      }

      final response = await _apiProvider.get(
        ApiConstants.adminTransactions,
        queryParameters: params,
      );

      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        transactions.assignAll(list.map((e) => AdminTransactionModel.fromJson(e)).toList());
      } else {
        AppSnackbar.warning('Info', response.data?['message'] ?? 'Gagal memuat transaksi.');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Transaksi', ApiProvider.getErrorMessage(e));
    } finally {
      isLoadingTransactions.value = false;
    }
  }

  Future<AdminTransactionModel?> fetchTransactionDetail(int id) async {
    try {
      final response = await _apiProvider.get(ApiConstants.adminTransactionDetail(id));
      if (response.data != null && response.data['success'] == true) {
        return AdminTransactionModel.fromJson(response.data['data']);
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Detail', ApiProvider.getErrorMessage(e));
    }
    return null;
  }

  /// Eksekusi pembatalan transaksi dengan hak otoritas admin / owner
  Future<bool> voidTransaction(int transactionId, String reason) async {
    try {
      final response = await _apiProvider.post(
        ApiConstants.adminVoidTransaction(transactionId),
        data: {'reason': reason},
      );

      if (response.data != null && response.data['success'] == true) {
        AppSnackbar.success(
          'Void Berhasil',
          response.data['message'] ?? 'Transaksi berhasil dibatalkan dan shift diperbarui.',
        );

        // Refresh transaksi & dashboard secara bersamaan
        fetchTransactions();
        fetchDashboard();
        if (shifts.isNotEmpty) {
          fetchShifts();
        }
        return true;
      } else {
        AppSnackbar.danger('Gagal Void', response.data?['message'] ?? 'Tidak dapat membatalkan transaksi.');
        return false;
      }
    } catch (e) {
      AppSnackbar.danger('Kendala Pembatalan', ApiProvider.getErrorMessage(e));
      return false;
    }
  }

  // ==========================================
  // 3. SHIFT AUDIT & Z-REPORT LOGIC
  // ==========================================
  Future<void> fetchShifts() async {
    isLoadingShifts.value = true;

    try {
      final Map<String, dynamic> params = {'limit': 50};

      if (selectedShiftStatus.value == 'open' || selectedShiftStatus.value == 'closed') {
        params['status'] = selectedShiftStatus.value;
      }
      if (selectedShiftDate.value != null && selectedShiftDate.value!.isNotEmpty) {
        params['date'] = selectedShiftDate.value;
      }

      final response = await _apiProvider.get(
        ApiConstants.adminShiftHistory,
        queryParameters: params,
      );

      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        shifts.assignAll(list.map((e) => AdminShiftModel.fromJson(e)).toList());
      } else {
        AppSnackbar.warning('Info', response.data?['message'] ?? 'Gagal memuat riwayat shift.');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Shift', ApiProvider.getErrorMessage(e));
    } finally {
      isLoadingShifts.value = false;
    }
  }

  Future<AdminShiftDetailModel?> fetchShiftDetail(int id) async {
    try {
      final response = await _apiProvider.get(ApiConstants.adminShiftDetail(id));
      if (response.data != null && response.data['success'] == true) {
        return AdminShiftDetailModel.fromJson(response.data['data']);
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Detail Shift', ApiProvider.getErrorMessage(e));
    }
    return null;
  }

  // ==========================================
  // 4. OPEN BILLS MONITORING LOGIC
  // ==========================================
  Future<void> fetchOpenBills() async {
    isLoadingOpenBills.value = true;

    try {
      final response = await _apiProvider.get(ApiConstants.adminOpenBills);

      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        openBills.assignAll(list.map((e) => AdminOpenBillModel.fromJson(e)).toList());
        openBillsTotalActive.value = (response.data['total_active'] as num?)?.toInt() ?? list.length;
        openBillsTotalAmount.value = (response.data['total_amount'] as num?)?.toDouble() ?? 0.0;
      } else {
        AppSnackbar.warning('Info', response.data?['message'] ?? 'Gagal memuat open bills.');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Open Bills', ApiProvider.getErrorMessage(e));
    } finally {
      isLoadingOpenBills.value = false;
    }
  }

  /// Trigger pull-to-refresh berdasarkan tab yang aktif saat ini
  Future<void> refreshCurrentTab() async {
    switch (selectedTabIndex.value) {
      case 0:
        await fetchDashboard();
        break;
      case 1:
        await fetchTransactions();
        break;
      case 2:
        await fetchShifts();
        break;
      case 3:
        await fetchOpenBills();
        break;
    }
  }

  /// Logout admin / owner dan kembali ke halaman PIN Login
  Future<void> logout() async {
    final storageService = Get.find<StorageService>();
    try {
      if (!storageService.isOfflineToken) {
        await _apiProvider.post(ApiConstants.logout);
      }
    } catch (_) {}
    await storageService.clearAuth();
    Get.offAllNamed(AppRoutes.pinLogin);
  }
}
