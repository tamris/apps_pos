import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/admin_dashboard_model.dart';
import '../../../data/models/admin_shift_model.dart';
import '../../../data/models/admin_transaction_model.dart';
import '../../../data/models/admin_open_bill_model.dart';
import '../../../data/models/admin_menu_sales_model.dart';
import '../../../data/models/cash_movement_model.dart';
import '../../../data/models/expense_category_model.dart';
import '../../../data/models/cash_flow_summary_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../routes/app_routes.dart';

class AdminController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  // Active Tab Index (0: Dashboard, 1: Penjualan Menu, 2: Transaksi & Void, 3: Audit Shift, 4: Pesanan & Meja)
  final RxInt selectedTabIndex = 0.obs;

  // Sidebar Collapse / Expand State (Tablet / Desktop)
  // Default closed (collapsed 68px rail) for a cleaner, wider view upon initial entry
  final RxBool isSidebarCollapsed = true.obs;
  void toggleSidebar() => isSidebarCollapsed.value = !isSidebarCollapsed.value;

  // --- TAB 1: FINANCIAL & OPERATIONAL DASHBOARD ---
  final Rx<AdminDashboardModel> dashboardData = AdminDashboardModel.empty().obs;
  final RxString selectedDashboardDate = DateFormat('yyyy-MM-dd').format(DateTime.now()).obs;
  final RxBool isLoadingDashboard = false.obs;
  final RxList<AdminTransactionModel> dashboardRecentTransactions = <AdminTransactionModel>[].obs;
  final RxBool isLoadingDashboardRecentTrx = false.obs;

  // --- TAB 2: MENU SALES ANALYTICS & REPORTS ---
  final RxList<AdminMenuSalesItemModel> menuSalesItems = <AdminMenuSalesItemModel>[].obs;
  final Rx<AdminMenuSalesSummaryModel> menuSalesSummary = AdminMenuSalesSummaryModel.empty().obs;
  final Rx<AdminMenuSalesPeriodModel> menuSalesPeriod = AdminMenuSalesPeriodModel.empty().obs;
  final RxList<AdminMenuSalesCategoryModel> menuSalesCategories = <AdminMenuSalesCategoryModel>[].obs;
  final RxList<AdminMenuSalesItemModel> topSellingMenuItems = <AdminMenuSalesItemModel>[].obs;
  final RxString selectedMenuPeriod = 'this_month'.obs; // 'today', 'yesterday', 'this_week', 'this_month', 'last_month', 'this_year', 'all', 'custom'
  final Rx<DateTime?> menuCustomStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> menuCustomEndDate = Rx<DateTime?>(null);
  final Rx<int?> selectedMenuCategoryId = Rx<int?>(null);
  final RxString selectedMenuSortBy = 'quantity'.obs; // 'quantity', 'revenue', 'profit', 'name'
  final RxString selectedMenuSortDir = 'desc'.obs; // 'desc', 'asc'
  final RxString selectedMenuSource = 'all'.obs; // 'all', 'pos', 'self_order'
  final RxString menuSearchQuery = ''.obs;
  final TextEditingController menuSearchController = TextEditingController();
  final RxBool isLoadingMenuSales = false.obs;
  final RxBool isLoadingMenuDetail = false.obs;
  final Rx<AdminMenuSalesDetailModel?> selectedMenuDetail = Rx<AdminMenuSalesDetailModel?>(null);

  List<AdminMenuSalesItemModel> get filteredMenuSalesItems {
    final query = menuSearchQuery.value.trim().toLowerCase();
    final catId = selectedMenuCategoryId.value;

    return menuSalesItems.where((item) {
      if (catId != null && item.categoryId != catId) return false;
      if (query.isNotEmpty) {
        final matchesName = item.productName.toLowerCase().contains(query);
        final matchesSku = item.sku.toLowerCase().contains(query);
        final matchesCat = item.categoryName.toLowerCase().contains(query);
        if (!matchesName && !matchesSku && !matchesCat) return false;
      }
      return true;
    }).toList();
  }

  // --- TAB 3: TRANSACTIONS & VOID AUTHORITY ---
  final RxList<AdminTransactionModel> transactions = <AdminTransactionModel>[].obs;
  final RxString selectedTrxStatus = 'all'.obs; // 'all', 'completed', 'pending', 'cancelled'
  final RxString selectedTrxOrderSource = 'all'.obs; // 'all', 'pos', 'self_order'
  final RxString selectedTrxPaymentMethod = 'all'.obs; // 'all', 'cash', 'qris', 'transfer'
  final Rx<String?> selectedTrxDate =
      Rx<String?>(DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final Rx<DateTime?> selectedTrxStartDate = Rx<DateTime?>(DateTime.now());
  final Rx<DateTime?> selectedTrxEndDate = Rx<DateTime?>(DateTime.now());
  final RxString trxSearchQuery = ''.obs;
  final TextEditingController trxSearchController = TextEditingController();
  final RxBool isLoadingTransactions = false.obs;

  // --- TAB 3: SHIFT AUDIT & Z-REPORT ---
  final RxList<AdminShiftModel> shifts = <AdminShiftModel>[].obs;
  final RxString selectedShiftStatus = 'all'.obs; // 'all', 'open', 'closed', 'balanced', 'discrepancy'
  final Rx<String?> selectedShiftDate = Rx<String?>(null);
  final Rx<DateTime?> selectedShiftStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedShiftEndDate = Rx<DateTime?>(null);
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

      // Date range filtering (client-side safety)
      if (selectedShiftStartDate.value != null &&
          selectedShiftEndDate.value != null &&
          s.startTime != null) {
        try {
          final shiftDt = DateTime.parse(s.startTime!);
          final shiftDay = DateTime(shiftDt.year, shiftDt.month, shiftDt.day);
          final startDay = DateTime(
            selectedShiftStartDate.value!.year,
            selectedShiftStartDate.value!.month,
            selectedShiftStartDate.value!.day,
          );
          final endDay = DateTime(
            selectedShiftEndDate.value!.year,
            selectedShiftEndDate.value!.month,
            selectedShiftEndDate.value!.day,
          );
          if (shiftDay.isBefore(startDay) || shiftDay.isAfter(endDay)) {
            return false;
          }
        } catch (_) {}
      }
      return true;
    }).toList();
  }

  // --- TAB 4: OPEN BILLS & LIVE ONLINE ORDERS MONITORING ---
  final RxList<AdminOpenBillModel> openBills = <AdminOpenBillModel>[].obs;
  final RxInt openBillsTotalActive = 0.obs;
  final RxDouble openBillsTotalAmount = 0.0.obs;
  final RxBool isLoadingOpenBills = false.obs;
  final RxString openBillSearchQuery = ''.obs;
  final TextEditingController openBillSearchController = TextEditingController();
  final RxString selectedOpenBillFilter = 'all'.obs;

  // Active Mode for Tab 4: 'tables' (Meja Belum Lunas), 'online' (Pesanan Online)
  final RxString selectedActiveOrderMode = 'tables'.obs;

  List<AdminOpenBillModel> get activeOnlineOrders =>
      openBills.where((b) => b.isSelfOrder).toList();

  List<AdminOpenBillModel> get activeTableBills =>
      openBills.where((b) => !b.isSelfOrder).toList();

  List<AdminOpenBillModel> get filteredOpenBills {
    final query = openBillSearchQuery.value.trim().toLowerCase();
    final mode = selectedActiveOrderMode.value;
    final filter = selectedOpenBillFilter.value;

    return openBills.where((b) {
      // 1. Mode Filter (Online vs Tables)
      if (mode == 'online' && !b.isSelfOrder) return false;
      if (mode == 'tables' && b.isSelfOrder) return false;

      // 2. Status Filter
      if (filter == 'critical' && b.elapsedMinutes < 60) return false;
      if (filter == 'fresh' && b.elapsedMinutes >= 30) return false;
      if (filter == 'self_order' && !b.isSelfOrder) return false;
      if (filter == 'pos' && b.isSelfOrder) return false;
      if (filter == 'unpaid' && b.isPaid) return false;
      if (filter == 'paid' && !b.isPaid) return false;
      if (filter == 'cooking' && b.status.toLowerCase() != 'processing' && b.status.toLowerCase() != 'cooking') return false;
      if (filter == 'ready' && b.status.toLowerCase() != 'ready') return false;

      // 3. Search Query
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

  // --- TAB 5: CASH FLOW & EXPENSE MANAGEMENT ---
  final RxList<CashMovementModel> cashFlowMovements = <CashMovementModel>[].obs;
  final Rx<CashFlowSummaryModel> cashFlowSummary = CashFlowSummaryModel.empty().obs;
  final RxList<ExpenseCategoryModel> adminExpenseCategories = <ExpenseCategoryModel>[].obs;
  final RxString selectedCashFlowPeriod = 'month'.obs; // 'month', 'today', 'custom'
  final Rx<DateTime?> cashFlowCustomStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> cashFlowCustomEndDate = Rx<DateTime?>(null);
  final RxString selectedCashFlowType = 'all'.obs; // 'all', 'in', 'out'
  final RxString selectedCashFlowSource = 'all'.obs; // 'all', 'drawer', 'bank', 'petty_cash'
  final Rx<int?> selectedCashFlowCategoryId = Rx<int?>(null);
  final RxString cashFlowSearchQuery = ''.obs;
  final TextEditingController cashFlowSearchController = TextEditingController();
  final RxBool isLoadingCashFlow = false.obs;
  final RxBool isLoadingCashFlowSummary = false.obs;
  final RxBool isLoadingAdminCategories = false.obs;
  final RxBool isSubmittingGeneralExpense = false.obs;

  List<CashMovementModel> get filteredCashFlowMovements {
    final query = cashFlowSearchQuery.value.trim().toLowerCase();
    final type = selectedCashFlowType.value;
    final source = selectedCashFlowSource.value;
    final catId = selectedCashFlowCategoryId.value;

    return cashFlowMovements.where((m) {
      if (type != 'all' && m.type != type) return false;
      if (source != 'all' && m.source != source) return false;
      if (catId != null && m.categoryId != catId) return false;
      if (query.isNotEmpty) {
        final matchesNumber = m.movementNumber.toLowerCase().contains(query);
        final matchesNotes = m.notes.toLowerCase().contains(query);
        final matchesCat = m.categoryName.toLowerCase().contains(query);
        final matchesCashier = m.cashierName.toLowerCase().contains(query);
        if (!matchesNumber && !matchesNotes && !matchesCat && !matchesCashier) {
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
    menuSearchController.dispose();
    trxSearchController.dispose();
    shiftSearchController.dispose();
    openBillSearchController.dispose();
    cashFlowSearchController.dispose();
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
        fetchMenuSales();
        fetchMenuCategories();
        break;
      case 3:
        fetchShifts();
        break;
      case 4:
        fetchOpenBills();
        break;
      case 5:
        fetchCashFlow();
        fetchCashFlowSummary();
        fetchAdminExpenseCategories();
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

    // Fetch dashboard-specific transactions and open bills for this dashboard date
    fetchDashboardTransactions(date: targetDate);
    fetchOpenBills();
  }

  Future<void> fetchDashboardTransactions({String? date}) async {
    isLoadingDashboardRecentTrx.value = true;
    try {
      final targetDate = date ?? selectedDashboardDate.value;
      final response = await _apiProvider.get(
        ApiConstants.adminTransactions,
        queryParameters: {
          'date': targetDate,
          'per_page': 20,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        dashboardRecentTransactions.assignAll(
          list.map((e) => AdminTransactionModel.fromJson(e)).toList(),
        );
      }
    } catch (_) {
      // Ignored for dashboard background sync
    } finally {
      isLoadingDashboardRecentTrx.value = false;
    }
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
      if (selectedTrxDate.value == null || selectedTrxDate.value!.isEmpty) {
        // No date filter - fetch all transactions
      } else if (selectedTrxStartDate.value != null) {
        final s = DateFormat('yyyy-MM-dd').format(selectedTrxStartDate.value!);
        final e = selectedTrxEndDate.value != null
            ? DateFormat('yyyy-MM-dd').format(selectedTrxEndDate.value!)
            : s;
        if (s == e) {
          params['date'] = s;
        } else {
          params['start_date'] = s;
          params['end_date'] = e;
          params['date'] = s;
        }
      } else if (selectedTrxDate.value != null && selectedTrxDate.value!.isNotEmpty) {
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

  void setTrxDateRange(DateTime? start, DateTime? end) {
    selectedTrxStartDate.value = start;
    selectedTrxEndDate.value = end;
    if (start != null) {
      final s = DateFormat('yyyy-MM-dd').format(start);
      final e = end != null ? DateFormat('yyyy-MM-dd').format(end) : s;
      selectedTrxDate.value = s == e ? s : '$s..$e';
    } else {
      selectedTrxDate.value = null;
    }
    fetchTransactions();
  }

  void clearTrxFilters() {
    final now = DateTime.now();
    selectedTrxStatus.value = 'all';
    selectedTrxOrderSource.value = 'all';
    selectedTrxPaymentMethod.value = 'all';
    selectedTrxDate.value = DateFormat('yyyy-MM-dd').format(now);
    selectedTrxStartDate.value = now;
    selectedTrxEndDate.value = now;
    trxSearchQuery.value = '';
    trxSearchController.clear();
    fetchTransactions();
  }

  void resetTrxDateToDefault() {
    final now = DateTime.now();
    selectedTrxDate.value = DateFormat('yyyy-MM-dd').format(now);
    selectedTrxStartDate.value = now;
    selectedTrxEndDate.value = now;
    fetchTransactions();
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

      if (selectedShiftStartDate.value != null && selectedShiftEndDate.value != null) {
        final startStr = DateFormat('yyyy-MM-dd').format(selectedShiftStartDate.value!);
        final endStr = DateFormat('yyyy-MM-dd').format(selectedShiftEndDate.value!);
        if (startStr == endStr) {
          params['date'] = startStr;
        } else {
          params['start_date'] = startStr;
          params['end_date'] = endStr;
          params['date'] = startStr; // fallback for backend endpoints requiring single date
        }
      } else if (selectedShiftDate.value != null && selectedShiftDate.value!.isNotEmpty) {
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

  void setShiftDateRange(DateTime start, DateTime end) {
    selectedShiftStartDate.value = start;
    selectedShiftEndDate.value = end;
    selectedShiftDate.value = DateFormat('yyyy-MM-dd').format(start);
    fetchShifts();
  }

  void clearShiftDateFilter() {
    selectedShiftStartDate.value = null;
    selectedShiftEndDate.value = null;
    selectedShiftDate.value = null;
    fetchShifts();
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

  // ==========================================
  // 5. MENU SALES ANALYTICS LOGIC
  // ==========================================
  Future<void> fetchMenuSales({bool refresh = false}) async {
    isLoadingMenuSales.value = true;

    try {
      final queryParams = <String, dynamic>{
        'per_page': 'all',
        'sort_by': selectedMenuSortBy.value,
        'sort_dir': selectedMenuSortDir.value,
      };

      if (selectedMenuPeriod.value == 'custom' && menuCustomStartDate.value != null) {
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(menuCustomStartDate.value!);
        if (menuCustomEndDate.value != null) {
          queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(menuCustomEndDate.value!);
        } else {
          queryParams['end_date'] = queryParams['start_date'];
        }
      } else {
        queryParams['range'] = selectedMenuPeriod.value;
      }

      if (selectedMenuCategoryId.value != null) {
        queryParams['category_id'] = selectedMenuCategoryId.value;
      }

      if (menuSearchQuery.value.trim().isNotEmpty) {
        queryParams['search'] = menuSearchQuery.value.trim();
      }

      if (selectedMenuSource.value != 'all') {
        queryParams['source'] = selectedMenuSource.value;
      }

      final response = await _apiProvider.get(
        ApiConstants.adminMenuSales,
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data;
        if (data['summary'] != null) {
          menuSalesSummary.value = AdminMenuSalesSummaryModel.fromJson(data['summary']);
        }
        if (data['period'] != null) {
          menuSalesPeriod.value = AdminMenuSalesPeriodModel.fromJson(data['period']);
        }
        if (data['data'] != null && data['data'] is List) {
          final list = (data['data'] as List)
              .map((e) => AdminMenuSalesItemModel.fromJson(e as Map<String, dynamic>))
              .toList();
          menuSalesItems.assignAll(list);
        } else {
          menuSalesItems.clear();
        }
      } else {
        AppSnackbar.warning('Info', response.data?['message'] ?? 'Gagal memuat penjualan menu.');
      }
    } catch (e) {
      AppSnackbar.danger('Kendala Penjualan Menu', ApiProvider.getErrorMessage(e));
    } finally {
      isLoadingMenuSales.value = false;
    }
  }

  Future<void> fetchMenuCategories() async {
    try {
      final queryParams = <String, dynamic>{};
      if (selectedMenuPeriod.value == 'custom' && menuCustomStartDate.value != null) {
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(menuCustomStartDate.value!);
        if (menuCustomEndDate.value != null) {
          queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(menuCustomEndDate.value!);
        }
      } else {
        queryParams['range'] = selectedMenuPeriod.value;
      }

      final response = await _apiProvider.get(
        ApiConstants.adminMenuSalesCategories,
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['success'] == true) {
        if (response.data['data'] != null && response.data['data'] is List) {
          final list = (response.data['data'] as List)
              .map((e) => AdminMenuSalesCategoryModel.fromJson(e as Map<String, dynamic>))
              .toList();
          menuSalesCategories.assignAll(list);
        }
      }
    } catch (_) {}
  }

  Future<void> fetchTopSelling({int limit = 5}) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (selectedMenuPeriod.value == 'custom' && menuCustomStartDate.value != null) {
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(menuCustomStartDate.value!);
        if (menuCustomEndDate.value != null) {
          queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(menuCustomEndDate.value!);
        }
      } else {
        queryParams['range'] = selectedMenuPeriod.value;
      }

      final response = await _apiProvider.get(
        ApiConstants.adminMenuSalesTop,
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['success'] == true) {
        if (response.data['data'] != null && response.data['data'] is List) {
          final list = (response.data['data'] as List)
              .map((e) => AdminMenuSalesItemModel.fromJson(e as Map<String, dynamic>))
              .toList();
          topSellingMenuItems.assignAll(list);
        }
      }
    } catch (_) {}
  }

  Future<void> fetchMenuSalesDetail(int productId) async {
    isLoadingMenuDetail.value = true;
    selectedMenuDetail.value = null;

    try {
      final queryParams = <String, dynamic>{};
      if (selectedMenuPeriod.value == 'custom' && menuCustomStartDate.value != null) {
        queryParams['start_date'] = DateFormat('yyyy-MM-dd').format(menuCustomStartDate.value!);
        if (menuCustomEndDate.value != null) {
          queryParams['end_date'] = DateFormat('yyyy-MM-dd').format(menuCustomEndDate.value!);
        }
      } else {
        queryParams['range'] = selectedMenuPeriod.value;
      }

      final response = await _apiProvider.get(
        ApiConstants.adminMenuSalesDetail(productId),
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['success'] == true) {
        selectedMenuDetail.value = AdminMenuSalesDetailModel.fromJson(response.data);
      } else {
        AppSnackbar.warning('Info', response.data?['message'] ?? 'Gagal memuat detail menu.');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Memuat Detail', ApiProvider.getErrorMessage(e));
    } finally {
      isLoadingMenuDetail.value = false;
    }
  }

  void changeMenuPeriod(String range, {DateTime? start, DateTime? end}) {
    selectedMenuPeriod.value = range;
    menuCustomStartDate.value = start;
    menuCustomEndDate.value = end;
    fetchMenuSales();
    fetchMenuCategories();
  }

  void setMenuCategory(int? categoryId) {
    selectedMenuCategoryId.value = categoryId;
    fetchMenuSales();
  }

  void setMenuSort(String sortBy) {
    if (selectedMenuSortBy.value == sortBy) {
      selectedMenuSortDir.value = selectedMenuSortDir.value == 'desc' ? 'asc' : 'desc';
    } else {
      selectedMenuSortBy.value = sortBy;
      selectedMenuSortDir.value = 'desc';
    }
    fetchMenuSales();
  }

  void setMenuSource(String source) {
    selectedMenuSource.value = source;
    fetchMenuSales();
  }

  void clearMenuFilters() {
    selectedMenuPeriod.value = 'this_month';
    menuCustomStartDate.value = null;
    menuCustomEndDate.value = null;
    selectedMenuCategoryId.value = null;
    menuSearchQuery.value = '';
    menuSearchController.clear();
    selectedMenuSource.value = 'all';
    selectedMenuSortBy.value = 'quantity';
    selectedMenuSortDir.value = 'desc';
    fetchMenuSales();
    fetchMenuCategories();
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
        await fetchMenuSales(refresh: true);
        await fetchMenuCategories();
        break;
      case 3:
        await fetchShifts();
        break;
      case 4:
        await fetchOpenBills();
        break;
      case 5:
        await Future.wait([
          fetchCashFlow(),
          fetchCashFlowSummary(),
          fetchAdminExpenseCategories(),
        ]);
        break;
    }
  }

  // ==========================================
  // 6. CASH FLOW & EXPENSE MANAGEMENT LOGIC
  // ==========================================

  Future<void> fetchCashFlow({bool showLoader = true}) async {
    if (showLoader) isLoadingCashFlow.value = true;
    try {
      final Map<String, dynamic> params = {'limit': 100};

      if (selectedCashFlowType.value != 'all') {
        params['type'] = selectedCashFlowType.value;
      }
      if (selectedCashFlowSource.value != 'all') {
        params['source'] = selectedCashFlowSource.value;
      }
      if (selectedCashFlowCategoryId.value != null) {
        params['category_id'] = selectedCashFlowCategoryId.value;
      }
      if (cashFlowSearchQuery.value.trim().isNotEmpty) {
        params['search'] = cashFlowSearchQuery.value.trim();
      }

      // Period filter
      if (selectedCashFlowPeriod.value == 'today') {
        params['date'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
      } else if (selectedCashFlowPeriod.value == 'month') {
        final now = DateTime.now();
        params['start_date'] = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
        params['end_date'] = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month + 1, 0));
      } else if (selectedCashFlowPeriod.value == 'custom' &&
          cashFlowCustomStartDate.value != null &&
          cashFlowCustomEndDate.value != null) {
        params['start_date'] = DateFormat('yyyy-MM-dd').format(cashFlowCustomStartDate.value!);
        params['end_date'] = DateFormat('yyyy-MM-dd').format(cashFlowCustomEndDate.value!);
      }

      final response = await _apiProvider.get(
        ApiConstants.adminCashFlow,
        queryParameters: params,
      );

      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        cashFlowMovements.assignAll(
          list.map((e) => CashMovementModel.fromJson(e)).toList(),
        );
      } else {
        AppSnackbar.warning('Info', response.data?['message'] ?? 'Gagal memuat riwayat arus kas.');
      }
    } catch (e) {
      AppSnackbar.danger('Kendala Arus Kas', ApiProvider.getErrorMessage(e));
    } finally {
      isLoadingCashFlow.value = false;
    }
  }

  Future<void> fetchCashFlowSummary() async {
    isLoadingCashFlowSummary.value = true;
    try {
      final Map<String, dynamic> params = {
        'period': selectedCashFlowPeriod.value,
      };

      if (selectedCashFlowPeriod.value == 'custom' &&
          cashFlowCustomStartDate.value != null &&
          cashFlowCustomEndDate.value != null) {
        params['start_date'] = DateFormat('yyyy-MM-dd').format(cashFlowCustomStartDate.value!);
        params['end_date'] = DateFormat('yyyy-MM-dd').format(cashFlowCustomEndDate.value!);
      }

      final response = await _apiProvider.get(
        ApiConstants.adminCashFlowSummary,
        queryParameters: params,
      );

      if (response.data != null && response.data['success'] == true) {
        cashFlowSummary.value = CashFlowSummaryModel.fromJson(response.data['data']);
      }
    } catch (_) {
      // Non-blocking fallback
    } finally {
      isLoadingCashFlowSummary.value = false;
    }
  }

  Future<void> fetchAdminExpenseCategories() async {
    isLoadingAdminCategories.value = true;
    try {
      final response = await _apiProvider.get(ApiConstants.adminExpenseCategories);
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        adminExpenseCategories.assignAll(
          list.map((e) => ExpenseCategoryModel.fromJson(e)).toList(),
        );
      }
    } catch (_) {
      // Non-blocking fallback
    } finally {
      isLoadingAdminCategories.value = false;
    }
  }

  void changeCashFlowPeriod(String period, {DateTime? customStart, DateTime? customEnd}) {
    selectedCashFlowPeriod.value = period;
    if (period == 'custom') {
      cashFlowCustomStartDate.value = customStart;
      cashFlowCustomEndDate.value = customEnd;
    }
    fetchCashFlow();
    fetchCashFlowSummary();
  }

  void setCashFlowCategory(int? categoryId) {
    selectedCashFlowCategoryId.value = categoryId;
    fetchCashFlow();
  }

  void resetCashFlowDateToDefault() {
    selectedCashFlowPeriod.value = 'month';
    cashFlowCustomStartDate.value = null;
    cashFlowCustomEndDate.value = null;
    fetchCashFlow();
    fetchCashFlowSummary();
  }

  void clearCashFlowFilters() {
    selectedCashFlowType.value = 'all';
    selectedCashFlowSource.value = 'all';
    selectedCashFlowCategoryId.value = null;
    selectedCashFlowPeriod.value = 'month';
    cashFlowCustomStartDate.value = null;
    cashFlowCustomEndDate.value = null;
    cashFlowSearchController.clear();
    cashFlowSearchQuery.value = '';
    fetchCashFlow();
    fetchCashFlowSummary();
  }

  Future<bool> storeGeneralExpense({
    required String type, // 'in' or 'out'
    required String source, // 'bank', 'drawer', 'petty_cash'
    required double amount,
    int? categoryId,
    String? categoryName,
    required String notes,
    DateTime? movementDate,
    File? receiptImage,
  }) async {
    isSubmittingGeneralExpense.value = true;
    try {
      final mapData = <String, dynamic>{
        'type': type,
        'source': source,
        'amount': amount,
        'notes': notes,
      };

      if (categoryId != null) {
        mapData['category_id'] = categoryId;
      }
      if (categoryName != null && categoryName.isNotEmpty) {
        mapData['category_name'] = categoryName;
      }
      if (movementDate != null) {
        mapData['movement_date'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(movementDate);
      }
      if (receiptImage != null && receiptImage.existsSync()) {
        mapData['receipt_image'] = await dio.MultipartFile.fromFile(
          receiptImage.path,
          filename: receiptImage.path.split(Platform.pathSeparator).last,
        );
      }

      final formData = dio.FormData.fromMap(mapData);
      final response = await _apiProvider.post(
        ApiConstants.adminCashFlow,
        data: formData,
      );

      if (response.data != null && response.data['success'] == true) {
        AppSnackbar.success('Berhasil', response.data['message'] ?? 'Catatan arus kas berhasil disimpan.');
        fetchCashFlow(showLoader: false);
        fetchCashFlowSummary();
        return true;
      } else {
        AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal menyimpan catatan arus kas.');
        return false;
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Menyimpan', ApiProvider.getErrorMessage(e));
      return false;
    } finally {
      isSubmittingGeneralExpense.value = false;
    }
  }

  Future<bool> deleteCashMovement(int id) async {
    try {
      final response = await _apiProvider.delete(ApiConstants.adminCashFlowDetail(id));
      if (response.data != null && response.data['success'] == true) {
        AppSnackbar.success('Berhasil', response.data['message'] ?? 'Catatan arus kas berhasil dihapus.');
        cashFlowMovements.removeWhere((m) => m.id == id);
        fetchCashFlowSummary();
        return true;
      } else {
        AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal menghapus catatan arus kas.');
        return false;
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Menghapus', ApiProvider.getErrorMessage(e));
      return false;
    }
  }

  Future<bool> saveExpenseCategory({
    int? id,
    required String name,
    required String type,
    String? description,
    bool isActive = true,
  }) async {
    try {
      final payload = {
        'name': name.trim(),
        'type': type,
        'description': description?.trim(),
        'is_active': isActive ? 1 : 0,
      };

      final response = id != null
          ? await _apiProvider.put(ApiConstants.adminExpenseCategoryDetail(id), data: payload)
          : await _apiProvider.post(ApiConstants.adminExpenseCategories, data: payload);

      if (response.data != null && response.data['success'] == true) {
        AppSnackbar.success('Berhasil', response.data['message'] ?? 'Kategori berhasil disimpan.');
        fetchAdminExpenseCategories();
        return true;
      } else {
        AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal menyimpan kategori.');
        return false;
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Menyimpan Kategori', ApiProvider.getErrorMessage(e));
      return false;
    }
  }

  Future<bool> deleteExpenseCategory(int id) async {
    try {
      final response = await _apiProvider.delete(ApiConstants.adminExpenseCategoryDetail(id));
      if (response.data != null && response.data['success'] == true) {
        AppSnackbar.success('Berhasil', response.data['message'] ?? 'Kategori berhasil dihapus.');
        adminExpenseCategories.removeWhere((c) => c.id == id);
        return true;
      } else {
        AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal menghapus kategori.');
        return false;
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Menghapus Kategori', ApiProvider.getErrorMessage(e));
      return false;
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
