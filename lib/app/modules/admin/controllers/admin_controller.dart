import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../data/models/admin_dashboard_model.dart';
import '../../../data/models/admin_shift_model.dart';
import '../../../data/models/admin_transaction_model.dart';
import '../../../data/models/admin_open_bill_model.dart';
import '../../../data/models/admin_menu_sales_model.dart';
import '../../../data/models/cash_movement_model.dart';
import '../../../data/models/expense_category_model.dart';
import '../../../data/models/cash_flow_summary_model.dart';
import '../../../data/models/admin_product_model.dart';
import '../../../data/models/product_ingredient_model.dart';
import '../../../data/models/hpp_calculation_model.dart';
import '../../../data/models/hpp_summary_model.dart';
import '../../../data/models/admin_category_model.dart';
import '../../../data/models/admin_ingredient_model.dart';
import '../../../data/models/admin_stock_mutation_model.dart';
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

  // --- MENU SALES INFINITE SCROLL / PAGINATION STATE ---
  int menuCurrentPage = 1;
  final RxBool hasMoreMenuSales = true.obs;
  final RxBool isLoadingMoreMenuSales = false.obs;
  final ScrollController menuScrollController = ScrollController();

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

  // --- TRANSACTIONS INFINITE SCROLL / PAGINATION & SUMMARY STATE ---
  int trxCurrentPage = 1;
  final RxBool hasMoreTrx = true.obs;
  final RxBool isLoadingMoreTrx = false.obs;
  final ScrollController trxScrollController = ScrollController();
  final RxInt totalTrxCount = 0.obs;
  final RxInt completedTrxCount = 0.obs;
  final RxDouble totalTrxRevenue = 0.0.obs;
  final RxDouble totalTrxProfit = 0.0.obs;
  final RxDouble totalTrxAov = 0.0.obs;
  final RxDouble totalTrxProfitMargin = 0.0.obs;
  final RxBool hasServerTrxSummary = false.obs;

  // --- PRODUCTS TOTAL STATE ---
  final RxInt totalProductCount = 0.obs;

  // --- TAB 3: SHIFT AUDIT & Z-REPORT ---
  final RxList<AdminShiftModel> shifts = <AdminShiftModel>[].obs;
  final RxString selectedShiftStatus = 'all'.obs; // 'all', 'open', 'closed', 'balanced', 'discrepancy'
  final Rx<String?> selectedShiftDate = Rx<String?>(null);
  final Rx<DateTime?> selectedShiftStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedShiftEndDate = Rx<DateTime?>(null);
  final RxString shiftSearchQuery = ''.obs;
  final TextEditingController shiftSearchController = TextEditingController();
  final RxBool isLoadingShifts = false.obs;

  // --- SHIFTS INFINITE SCROLL / PAGINATION STATE ---
  int shiftCurrentPage = 1;
  final RxBool hasMoreShifts = true.obs;
  final RxBool isLoadingMoreShifts = false.obs;
  final ScrollController shiftScrollController = ScrollController();

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
  final RxString selectedCashFlowSource = 'all'.obs; // 'all', 'cash', 'bank'
  final Rx<int?> selectedCashFlowCategoryId = Rx<int?>(null);
  final RxString cashFlowSearchQuery = ''.obs;
  final TextEditingController cashFlowSearchController = TextEditingController();
  final RxBool isLoadingCashFlow = false.obs;
  final RxBool isLoadingCashFlowSummary = false.obs;
  final RxBool isLoadingAdminCategories = false.obs;
  final RxBool isSubmittingGeneralExpense = false.obs;

  // --- CASH FLOW INFINITE SCROLL / PAGINATION STATE ---
  int cashFlowCurrentPage = 1;
  final RxBool hasMoreCashFlow = true.obs;
  final RxBool isLoadingMoreCashFlow = false.obs;
  final ScrollController cashFlowScrollController = ScrollController();

  List<CashMovementModel> get filteredCashFlowMovements {
    final query = cashFlowSearchQuery.value.trim().toLowerCase();
    final type = selectedCashFlowType.value;
    final source = selectedCashFlowSource.value;
    final catId = selectedCashFlowCategoryId.value;

    return cashFlowMovements.where((m) {
      if (type != 'all' && m.type != type) return false;
      if (source != 'all') {
        if (source == 'cash') {
          if (!m.isCash) return false;
        } else if (source == 'bank') {
          if (!m.isBank) return false;
        } else if (m.source != source) {
          return false;
        }
      }
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

  // --- TAB 6: MASTER PRODUK & RESEP ---
  final RxInt productManagementSubTab = 0.obs; // 0: Katalog Produk, 1: Analisis Margin & AI Resep
  void setProductManagementSubTab(int val) => productManagementSubTab.value = val;

  final RxList<AdminProductModel> products = <AdminProductModel>[].obs;
  final RxList<AdminCategoryModel> productCategories = <AdminCategoryModel>[].obs;
  final RxBool isLoadingProducts = false.obs;
  final RxBool isLoadingProductCategories = false.obs;
  final RxBool isSubmittingProduct = false.obs;
  final RxBool isDeletingProduct = false.obs;
  final RxString productSearchQuery = ''.obs;
  final TextEditingController productSearchController = TextEditingController();
  final Rx<int?> selectedProductCategoryId = Rx<int?>(null);
  final RxString selectedProductStatus = 'all'.obs; // 'all', 'active', 'inactive', 'archived'
  final RxString selectedProductSort = 'name'.obs; // 'name', 'price_asc', 'price_desc', 'margin_desc', 'margin_asc'
  final RxBool hasProductSearch = false.obs;

  // --- PRODUCTS INFINITE SCROLL / PAGINATION STATE ---
  int productCurrentPage = 1;
  final RxBool hasMoreProducts = true.obs;
  final RxBool isLoadingMoreProducts = false.obs;
  final ScrollController productScrollController = ScrollController();

  List<AdminProductModel> get filteredProducts {
    final q = productSearchQuery.value.trim().toLowerCase();
    final catId = selectedProductCategoryId.value;
    final status = selectedProductStatus.value;

    final list = products.where((p) {
      if (catId != null && p.categoryId != catId) return false;
      if (status == 'active' && (!p.isActive || p.isArchived)) return false;
      if (status == 'inactive' && (p.isActive || p.isArchived)) return false;
      if (status == 'archived' && !p.isArchived) return false;
      if (status == 'all' && p.isArchived) return false;

      if (q.isNotEmpty) {
        final matchName = p.name.toLowerCase().contains(q);
        final matchSku = p.sku.toLowerCase().contains(q);
        final matchBarcode = p.barcode?.toLowerCase().contains(q) ?? false;
        final matchCat = p.categoryName.toLowerCase().contains(q);
        if (!matchName && !matchSku && !matchBarcode && !matchCat) return false;
      }
      return true;
    }).toList();

    switch (selectedProductSort.value) {
      case 'price_asc':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'margin_desc':
        list.sort((a, b) => b.marginPercent.compareTo(a.marginPercent));
        break;
      case 'margin_asc':
        list.sort((a, b) => a.marginPercent.compareTo(b.marginPercent));
        break;
      case 'name':
      default:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    return list;
  }

  // --- TAB 7: HPP, HEALTH CHECK & STRATEGI RESEP ---
  final Rx<HppSummaryModel> hppSummary = HppSummaryModel.empty().obs;
  final RxBool isLoadingHppSummary = false.obs;
  final RxBool isCalculatingHpp = false.obs;
  final RxBool isGeneratingAiRecipe = false.obs;

  // Simulator HPP State
  final RxString simulationProductName = ''.obs;
  final RxList<ProductIngredientModel> simulationIngredients = <ProductIngredientModel>[].obs;
  final RxDouble simulationSellingPrice = 0.0.obs;
  final RxDouble simulationOperationalCost = 1000.0.obs;
  final RxDouble simulationKenaikanPersen = 0.0.obs;
  final RxInt simulationTargetMonthlyUnits = 3000.obs;
  final RxDouble simulationTargetMonthlyProfit = 5000000.0.obs;
  final RxInt simulationOperationalDays = 30.obs;
  final Rx<HppCalculationModel?> simulationCalculationResult = Rx<HppCalculationModel?>(null);

  // --- TAB: INGREDIENTS & STOCK INVENTORY ---
  final RxList<AdminIngredientModel> ingredients = <AdminIngredientModel>[].obs;
  final Rx<AdminIngredientSummaryModel> ingredientSummary = AdminIngredientSummaryModel.empty().obs;
  final RxBool isLoadingIngredients = false.obs;
  final RxBool isLoadingMoreIngredients = false.obs;
  final RxBool hasMoreIngredients = false.obs;
  int ingredientCurrentPage = 1;
  final ScrollController ingredientScrollController = ScrollController();
  final TextEditingController ingredientSearchController = TextEditingController();
  final RxString ingredientSearchQuery = ''.obs;
  final RxBool hasIngredientSearch = false.obs;
  final RxString selectedIngredientStatus = 'all'.obs; // 'all', 'safe', 'low_stock', 'out_of_stock'
  final RxString selectedIngredientSort = 'name'.obs; // 'name', 'stock_asc', 'stock_desc', 'value_desc'
  Timer? _ingredientSearchDebounce;

  List<AdminIngredientModel> get filteredIngredients {
    final query = ingredientSearchQuery.value.trim().toLowerCase();
    final status = selectedIngredientStatus.value;
    final sort = selectedIngredientSort.value;

    var list = ingredients.where((ing) {
      if (status == 'safe' && !ing.isSafe) return false;
      if (status == 'low_stock' && !ing.isLowStock) return false;
      if (status == 'out_of_stock' && !ing.isOutOfStock) return false;

      if (query.isNotEmpty) {
        final matchesName = ing.name.toLowerCase().contains(query);
        final matchesSku = ing.sku.toLowerCase().contains(query);
        final matchesCategory = ing.category.toLowerCase().contains(query);
        if (!matchesName && !matchesSku && !matchesCategory) return false;
      }
      return true;
    }).toList();

    switch (sort) {
      case 'stock_asc':
        list.sort((a, b) => a.stock.compareTo(b.stock));
        break;
      case 'stock_desc':
        list.sort((a, b) => b.stock.compareTo(a.stock));
        break;
      case 'value_desc':
        list.sort((a, b) => b.totalInventoryValue.compareTo(a.totalInventoryValue));
        break;
      case 'name':
      default:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
    }
    return list;
  }

  void onIngredientSearchChanged(String val) {
    hasIngredientSearch.value = val.isNotEmpty;
    _ingredientSearchDebounce?.cancel();
    _ingredientSearchDebounce = Timer(const Duration(milliseconds: 250), () {
      ingredientSearchQuery.value = val;
      fetchIngredients(showLoader: false);
    });
  }

  void clearIngredientSearch() {
    _ingredientSearchDebounce?.cancel();
    ingredientSearchController.clear();
    hasIngredientSearch.value = false;
    ingredientSearchQuery.value = '';
    fetchIngredients(showLoader: false);
  }

  void clearIngredientFilters() {
    clearIngredientSearch();
    selectedIngredientStatus.value = 'all';
    selectedIngredientSort.value = 'name';
    fetchIngredients(showLoader: false);
  }

  // --- SEARCH DEBOUNCERS & INSTANT INDICATORS ---
  Timer? _cashFlowSearchDebounce;
  Timer? _trxSearchDebounce;
  Timer? _shiftSearchDebounce;
  Timer? _menuSearchDebounce;
  Timer? _openBillSearchDebounce;
  Timer? _productSearchDebounce;

  final RxBool hasCashFlowSearch = false.obs;
  final RxBool hasTrxSearch = false.obs;
  final RxBool hasShiftSearch = false.obs;
  final RxBool hasMenuSearch = false.obs;
  final RxBool hasOpenBillSearch = false.obs;

  void onCashFlowSearchChanged(String val) {
    hasCashFlowSearch.value = val.isNotEmpty;
    _cashFlowSearchDebounce?.cancel();
    _cashFlowSearchDebounce = Timer(const Duration(milliseconds: 250), () {
      cashFlowSearchQuery.value = val;
    });
  }

  void clearCashFlowSearch() {
    _cashFlowSearchDebounce?.cancel();
    cashFlowSearchController.clear();
    hasCashFlowSearch.value = false;
    cashFlowSearchQuery.value = '';
    fetchCashFlow();
    fetchCashFlowSummary();
  }

  void submitCashFlowSearch() {
    _cashFlowSearchDebounce?.cancel();
    cashFlowSearchQuery.value = cashFlowSearchController.text;
    fetchCashFlow();
    fetchCashFlowSummary();
  }

  void onTrxSearchChanged(String val) {
    hasTrxSearch.value = val.isNotEmpty;
    _trxSearchDebounce?.cancel();
    _trxSearchDebounce = Timer(const Duration(milliseconds: 250), () {
      trxSearchQuery.value = val;
    });
  }

  void clearTrxSearch() {
    _trxSearchDebounce?.cancel();
    trxSearchController.clear();
    hasTrxSearch.value = false;
    trxSearchQuery.value = '';
    fetchTransactions();
  }

  void submitTrxSearch() {
    _trxSearchDebounce?.cancel();
    trxSearchQuery.value = trxSearchController.text;
    fetchTransactions();
  }

  void onShiftSearchChanged(String val) {
    hasShiftSearch.value = val.isNotEmpty;
    _shiftSearchDebounce?.cancel();
    _shiftSearchDebounce = Timer(const Duration(milliseconds: 250), () {
      shiftSearchQuery.value = val;
    });
  }

  void clearShiftSearch() {
    _shiftSearchDebounce?.cancel();
    shiftSearchController.clear();
    hasShiftSearch.value = false;
    shiftSearchQuery.value = '';
    fetchShifts();
  }

  void submitShiftSearch() {
    _shiftSearchDebounce?.cancel();
    shiftSearchQuery.value = shiftSearchController.text;
    fetchShifts();
  }

  void onMenuSearchChanged(String val) {
    hasMenuSearch.value = val.isNotEmpty;
    _menuSearchDebounce?.cancel();
    _menuSearchDebounce = Timer(const Duration(milliseconds: 250), () {
      menuSearchQuery.value = val;
    });
  }

  void clearMenuSearch() {
    _menuSearchDebounce?.cancel();
    menuSearchController.clear();
    hasMenuSearch.value = false;
    menuSearchQuery.value = '';
  }

  void submitMenuSearch() {
    _menuSearchDebounce?.cancel();
    menuSearchQuery.value = menuSearchController.text;
  }

  void onOpenBillSearchChanged(String val) {
    hasOpenBillSearch.value = val.isNotEmpty;
    _openBillSearchDebounce?.cancel();
    _openBillSearchDebounce = Timer(const Duration(milliseconds: 250), () {
      openBillSearchQuery.value = val;
    });
  }

  void clearOpenBillSearch() {
    _openBillSearchDebounce?.cancel();
    openBillSearchController.clear();
    hasOpenBillSearch.value = false;
    openBillSearchQuery.value = '';
  }

  void submitOpenBillSearch() {
    _openBillSearchDebounce?.cancel();
    openBillSearchQuery.value = openBillSearchController.text;
  }

  void onProductSearchChanged(String val) {
    hasProductSearch.value = val.isNotEmpty;
    _productSearchDebounce?.cancel();
    _productSearchDebounce = Timer(const Duration(milliseconds: 250), () {
      productSearchQuery.value = val;
    });
  }

  void clearProductSearch() {
    _productSearchDebounce?.cancel();
    productSearchController.clear();
    hasProductSearch.value = false;
    productSearchQuery.value = '';
  }

  void clearProductFilters() {
    clearProductSearch();
    selectedProductCategoryId.value = null;
    selectedProductStatus.value = 'all';
    selectedProductSort.value = 'name';
  }

  @override
  void onInit() {
    super.onInit();
    trxScrollController.addListener(_onTrxScroll);
    productScrollController.addListener(_onProductScroll);
    shiftScrollController.addListener(_onShiftScroll);
    cashFlowScrollController.addListener(_onCashFlowScroll);
    menuScrollController.addListener(_onMenuScroll);
    ingredientScrollController.addListener(_onIngredientScroll);

    fetchDashboard();
    fetchTransactions();
    fetchOpenBills();

    // Auto re-fetch products when status filter changes (e.g. switching to Arsip)
    ever(selectedProductStatus, (_) {
      if (selectedTabIndex.value == 6) {
        fetchAdminProducts(showLoader: false);
      }
    });

    // Auto re-fetch ingredients when status or sort changes
    ever(selectedIngredientStatus, (_) {
      if (selectedTabIndex.value == 8) {
        fetchIngredients(showLoader: false);
      }
    });
    ever(selectedIngredientSort, (_) {
      if (selectedTabIndex.value == 8) {
        fetchIngredients(showLoader: false);
      }
    });
  }

  @override
  void onClose() {
    trxScrollController.removeListener(_onTrxScroll);
    trxScrollController.dispose();
    productScrollController.removeListener(_onProductScroll);
    productScrollController.dispose();
    shiftScrollController.removeListener(_onShiftScroll);
    shiftScrollController.dispose();
    cashFlowScrollController.removeListener(_onCashFlowScroll);
    cashFlowScrollController.dispose();
    menuScrollController.removeListener(_onMenuScroll);
    menuScrollController.dispose();
    ingredientScrollController.removeListener(_onIngredientScroll);
    ingredientScrollController.dispose();

    _cashFlowSearchDebounce?.cancel();
    _trxSearchDebounce?.cancel();
    _shiftSearchDebounce?.cancel();
    _menuSearchDebounce?.cancel();
    _openBillSearchDebounce?.cancel();
    _productSearchDebounce?.cancel();
    _ingredientSearchDebounce?.cancel();
    menuSearchController.dispose();
    trxSearchController.dispose();
    shiftSearchController.dispose();
    openBillSearchController.dispose();
    cashFlowSearchController.dispose();
    productSearchController.dispose();
    ingredientSearchController.dispose();
    super.onClose();
  }

  void _onIngredientScroll() {
    if (!ingredientScrollController.hasClients) return;
    final maxScroll = ingredientScrollController.position.maxScrollExtent;
    final currentScroll = ingredientScrollController.position.pixels;
    if (currentScroll >= (maxScroll - 300)) {
      if (!isLoadingIngredients.value && !isLoadingMoreIngredients.value && hasMoreIngredients.value) {
        loadMoreIngredients();
      }
    }
  }

  void _onTrxScroll() {
    if (!trxScrollController.hasClients) return;
    final maxScroll = trxScrollController.position.maxScrollExtent;
    final currentScroll = trxScrollController.position.pixels;
    if (currentScroll >= (maxScroll - 300)) {
      if (!isLoadingTransactions.value && !isLoadingMoreTrx.value && hasMoreTrx.value) {
        loadMoreTransactions();
      }
    }
  }

  void _onProductScroll() {
    if (!productScrollController.hasClients) return;
    final maxScroll = productScrollController.position.maxScrollExtent;
    final currentScroll = productScrollController.position.pixels;
    if (currentScroll >= (maxScroll - 300)) {
      if (!isLoadingProducts.value && !isLoadingMoreProducts.value && hasMoreProducts.value) {
        loadMoreProducts();
      }
    }
  }

  void _onShiftScroll() {
    if (!shiftScrollController.hasClients) return;
    final maxScroll = shiftScrollController.position.maxScrollExtent;
    final currentScroll = shiftScrollController.position.pixels;
    if (currentScroll >= (maxScroll - 300)) {
      if (!isLoadingShifts.value && !isLoadingMoreShifts.value && hasMoreShifts.value) {
        loadMoreShifts();
      }
    }
  }

  void _onCashFlowScroll() {
    if (!cashFlowScrollController.hasClients) return;
    final maxScroll = cashFlowScrollController.position.maxScrollExtent;
    final currentScroll = cashFlowScrollController.position.pixels;
    if (currentScroll >= (maxScroll - 300)) {
      if (!isLoadingCashFlow.value && !isLoadingMoreCashFlow.value && hasMoreCashFlow.value) {
        loadMoreCashFlow();
      }
    }
  }

  void _onMenuScroll() {
    if (!menuScrollController.hasClients) return;
    final maxScroll = menuScrollController.position.maxScrollExtent;
    final currentScroll = menuScrollController.position.pixels;
    if (currentScroll >= (maxScroll - 300)) {
      if (!isLoadingMenuSales.value && !isLoadingMoreMenuSales.value && hasMoreMenuSales.value) {
        loadMoreMenuSales();
      }
    }
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
      case 6:
        fetchAdminProducts();
        fetchAdminProductCategories();
        fetchHppSummary(showLoader: false);
        break;
      case 7:
        // Tab Pengaturan
        break;
      case 8:
        fetchIngredients();
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
  Map<String, dynamic> _buildTrxQueryParams({int page = 1}) {
    final Map<String, dynamic> params = {
      'per_page': 20,
      'page': page,
    };

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
      }
    } else if (selectedTrxDate.value != null && selectedTrxDate.value!.isNotEmpty) {
      if (selectedTrxDate.value!.contains('..')) {
        final parts = selectedTrxDate.value!.split('..');
        params['start_date'] = parts[0];
        params['end_date'] = parts[1];
      } else {
        params['date'] = selectedTrxDate.value;
      }
    }
    if (trxSearchQuery.value.trim().isNotEmpty) {
      params['search'] = trxSearchQuery.value.trim();
    }
    return params;
  }

  Future<void> fetchTransactions() async {
    isLoadingTransactions.value = true;
    trxCurrentPage = 1;
    hasMoreTrx.value = true;

    try {
      final params = _buildTrxQueryParams(page: 1);
      final response = await _apiProvider.get(
        ApiConstants.adminTransactions,
        queryParameters: params,
      );

      if (response.data != null && response.data['success'] == true) {
        final rawData = response.data['data'];
        final List list = (rawData is Map && rawData['data'] != null)
            ? rawData['data']
            : (rawData is List ? rawData : []);
        final items = list.map((e) => AdminTransactionModel.fromJson(e)).toList();
        transactions.assignAll(items);

        final meta = response.data['meta'];
        if (meta is Map) {
          final curPage = int.tryParse(meta['current_page']?.toString() ?? '1') ?? 1;
          final lastPage = int.tryParse(meta['last_page']?.toString() ?? '1') ?? 1;
          hasMoreTrx.value = curPage < lastPage;
          totalTrxCount.value = int.tryParse(meta['total']?.toString() ?? '0') ?? items.length;
        } else if (rawData is Map) {
          final nextUrl = rawData['next_page_url'];
          final curPage = int.tryParse(rawData['current_page']?.toString() ?? '1') ?? 1;
          final lastPage = int.tryParse(rawData['last_page']?.toString() ?? '1') ?? 1;
          hasMoreTrx.value = (nextUrl != null) || (curPage < lastPage);
          totalTrxCount.value = int.tryParse(rawData['total']?.toString() ?? '0') ?? items.length;
        } else {
          hasMoreTrx.value = items.length >= 20;
          totalTrxCount.value = items.length;
        }

        final summary = response.data['summary'];
        if (summary is Map) {
          if (summary['total_transactions'] != null) {
            totalTrxCount.value = int.tryParse(summary['total_transactions'].toString()) ?? totalTrxCount.value;
          }
          if (summary['completed_count'] != null) {
            completedTrxCount.value = int.tryParse(summary['completed_count'].toString()) ?? 0;
          }
          if (summary['total_revenue'] != null) {
            totalTrxRevenue.value = double.tryParse(summary['total_revenue'].toString()) ?? 0.0;
          }
          if (summary['total_profit'] != null) {
            totalTrxProfit.value = double.tryParse(summary['total_profit'].toString()) ?? 0.0;
          }
          if (summary['aov'] != null) {
            totalTrxAov.value = double.tryParse(summary['aov'].toString()) ?? 0.0;
          }
          if (summary['profit_margin'] != null) {
            totalTrxProfitMargin.value = double.tryParse(summary['profit_margin'].toString()) ?? 0.0;
          }
          hasServerTrxSummary.value = true;
        } else {
          hasServerTrxSummary.value = false;
        }
      } else {
        AppSnackbar.warning('Info', response.data?['message'] ?? 'Gagal memuat transaksi.');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Transaksi', ApiProvider.getErrorMessage(e));
    } finally {
      isLoadingTransactions.value = false;
    }
  }

  /// Muat transaksi halaman berikutnya secara lazy load (Infinite Scroll)
  Future<void> loadMoreTransactions() async {
    if (isLoadingTransactions.value || isLoadingMoreTrx.value || !hasMoreTrx.value) {
      return;
    }

    isLoadingMoreTrx.value = true;
    try {
      final nextPage = trxCurrentPage + 1;
      final params = _buildTrxQueryParams(page: nextPage);
      final response = await _apiProvider.get(
        ApiConstants.adminTransactions,
        queryParameters: params,
      );

      if (response.data != null && response.data['success'] == true) {
        final rawData = response.data['data'];
        final List list = (rawData is Map && rawData['data'] != null)
            ? rawData['data']
            : (rawData is List ? rawData : []);
        final newTxs = list.map((e) => AdminTransactionModel.fromJson(e)).toList();

        if (newTxs.isEmpty) {
          hasMoreTrx.value = false;
        } else {
          final existingInvoices = transactions.map((t) => t.invoiceNumber.trim().toLowerCase()).toSet();
          final existingIds = transactions.where((t) => t.id > 0).map((t) => t.id).toSet();

          final uniqueNewTxs = newTxs.where((t) {
            final invMatch = existingInvoices.contains(t.invoiceNumber.trim().toLowerCase());
            final idMatch = t.id > 0 && existingIds.contains(t.id);
            return !invMatch && !idMatch;
          }).toList();

          transactions.addAll(uniqueNewTxs);
          trxCurrentPage = nextPage;

          final meta = response.data['meta'];
          if (meta is Map) {
            final curPage = int.tryParse(meta['current_page']?.toString() ?? '$nextPage') ?? nextPage;
            final lastPage = int.tryParse(meta['last_page']?.toString() ?? '$curPage') ?? curPage;
            hasMoreTrx.value = curPage < lastPage;
            final parsedTotal = int.tryParse(meta['total']?.toString() ?? '0') ?? 0;
            if (parsedTotal > 0) {
              totalTrxCount.value = parsedTotal;
            }
          } else if (rawData is Map) {
            final nextUrl = rawData['next_page_url'];
            final curPage = int.tryParse(rawData['current_page']?.toString() ?? '$nextPage') ?? nextPage;
            final lastPage = int.tryParse(rawData['last_page']?.toString() ?? '$curPage') ?? curPage;
            hasMoreTrx.value = (nextUrl != null) || (curPage < lastPage);
            final parsedTotal = int.tryParse(rawData['total']?.toString() ?? '0') ?? 0;
            if (parsedTotal > 0) {
              totalTrxCount.value = parsedTotal;
            }
          } else {
            hasMoreTrx.value = newTxs.length >= 20;
          }
        }
      } else {
        hasMoreTrx.value = false;
      }
    } catch (_) {
      // Non-blocking fallback
    } finally {
      isLoadingMoreTrx.value = false;
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
    hasTrxSearch.value = false;
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
  Map<String, dynamic> _buildShiftQueryParams({int page = 1}) {
    final Map<String, dynamic> params = {
      'limit': 20,
      'page': page,
    };

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
      }
    } else if (selectedShiftDate.value != null && selectedShiftDate.value!.isNotEmpty) {
      if (selectedShiftDate.value!.contains('..')) {
        final parts = selectedShiftDate.value!.split('..');
        params['start_date'] = parts[0];
        params['end_date'] = parts[1];
      } else {
        params['date'] = selectedShiftDate.value;
      }
    }

    if (shiftSearchQuery.value.trim().isNotEmpty) {
      params['search'] = shiftSearchQuery.value.trim();
    }

    return params;
  }

  Future<void> fetchShifts() async {
    isLoadingShifts.value = true;
    shiftCurrentPage = 1;
    hasMoreShifts.value = true;

    try {
      final params = _buildShiftQueryParams(page: 1);
      final response = await _apiProvider.get(
        ApiConstants.adminShiftHistory,
        queryParameters: params,
      );

      if (response.data != null && response.data['success'] == true) {
        final rawData = response.data['data'];
        final List list = (rawData is Map && rawData['data'] != null)
            ? rawData['data']
            : (rawData is List ? rawData : []);
        final items = list.map((e) => AdminShiftModel.fromJson(e)).toList();
        shifts.assignAll(items);

        final meta = response.data['meta'];
        if (meta is Map) {
          final curPage = int.tryParse(meta['current_page']?.toString() ?? '1') ?? 1;
          final lastPage = int.tryParse(meta['last_page']?.toString() ?? '1') ?? 1;
          hasMoreShifts.value = curPage < lastPage;
        } else if (rawData is Map) {
          final curPage = int.tryParse(rawData['current_page']?.toString() ?? '1') ?? 1;
          final lastPage = int.tryParse(rawData['last_page']?.toString() ?? '1') ?? 1;
          hasMoreShifts.value = curPage < lastPage;
        } else {
          hasMoreShifts.value = items.length >= 20;
        }
      } else {
        AppSnackbar.warning('Info', response.data?['message'] ?? 'Gagal memuat riwayat shift.');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Shift', ApiProvider.getErrorMessage(e));
    } finally {
      isLoadingShifts.value = false;
    }
  }

  /// Muat shift halaman berikutnya secara lazy load (Infinite Scroll)
  Future<void> loadMoreShifts() async {
    if (isLoadingShifts.value || isLoadingMoreShifts.value || !hasMoreShifts.value) {
      return;
    }

    isLoadingMoreShifts.value = true;
    try {
      final nextPage = shiftCurrentPage + 1;
      final params = _buildShiftQueryParams(page: nextPage);
      final response = await _apiProvider.get(
        ApiConstants.adminShiftHistory,
        queryParameters: params,
      );

      if (response.data != null && response.data['success'] == true) {
        final rawData = response.data['data'];
        final List list = (rawData is Map && rawData['data'] != null)
            ? rawData['data']
            : (rawData is List ? rawData : []);
        final newShifts = list.map((e) => AdminShiftModel.fromJson(e)).toList();

        if (newShifts.isEmpty) {
          hasMoreShifts.value = false;
        } else {
          final existingIds = shifts.map((s) => s.id).toSet();
          final uniqueNew = newShifts.where((s) => !existingIds.contains(s.id)).toList();
          shifts.addAll(uniqueNew);
          shiftCurrentPage = nextPage;

          final meta = response.data['meta'];
          if (meta is Map) {
            final curPage = int.tryParse(meta['current_page']?.toString() ?? '$nextPage') ?? nextPage;
            final lastPage = int.tryParse(meta['last_page']?.toString() ?? '$curPage') ?? curPage;
            hasMoreShifts.value = curPage < lastPage;
          } else if (rawData is Map) {
            final curPage = int.tryParse(rawData['current_page']?.toString() ?? '$nextPage') ?? nextPage;
            final lastPage = int.tryParse(rawData['last_page']?.toString() ?? '$curPage') ?? curPage;
            hasMoreShifts.value = curPage < lastPage;
          } else {
            hasMoreShifts.value = newShifts.length >= 20;
          }
        }
      } else {
        hasMoreShifts.value = false;
      }
    } catch (_) {
      // Non-blocking fallback
    } finally {
      isLoadingMoreShifts.value = false;
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
  Map<String, dynamic> _buildMenuSalesQueryParams({int page = 1}) {
    final queryParams = <String, dynamic>{
      'per_page': 20,
      'page': page,
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

    return queryParams;
  }

  Future<void> fetchMenuSales({bool refresh = false}) async {
    isLoadingMenuSales.value = true;
    menuCurrentPage = 1;
    hasMoreMenuSales.value = true;

    try {
      final queryParams = _buildMenuSalesQueryParams(page: 1);

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

          final meta = data['meta'];
          if (meta is Map) {
            final curPage = int.tryParse(meta['current_page']?.toString() ?? '1') ?? 1;
            final lastPage = int.tryParse(meta['last_page']?.toString() ?? '1') ?? 1;
            hasMoreMenuSales.value = curPage < lastPage;
          } else {
            hasMoreMenuSales.value = list.length >= 20;
          }
        } else {
          menuSalesItems.clear();
          hasMoreMenuSales.value = false;
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

  /// Muat penjualan menu halaman berikutnya secara lazy load (Infinite Scroll)
  Future<void> loadMoreMenuSales() async {
    if (isLoadingMenuSales.value || isLoadingMoreMenuSales.value || !hasMoreMenuSales.value) {
      return;
    }

    isLoadingMoreMenuSales.value = true;
    try {
      final nextPage = menuCurrentPage + 1;
      final queryParams = _buildMenuSalesQueryParams(page: nextPage);

      final response = await _apiProvider.get(
        ApiConstants.adminMenuSales,
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data;
        if (data['data'] != null && data['data'] is List) {
          final list = (data['data'] as List)
              .map((e) => AdminMenuSalesItemModel.fromJson(e as Map<String, dynamic>))
              .toList();

          if (list.isEmpty) {
            hasMoreMenuSales.value = false;
          } else {
            final existingIds = menuSalesItems.map((m) => m.productId).toSet();
            final uniqueNew = list.where((m) => !existingIds.contains(m.productId)).toList();
            menuSalesItems.addAll(uniqueNew);
            menuCurrentPage = nextPage;

            final meta = data['meta'];
            if (meta is Map) {
              final curPage = int.tryParse(meta['current_page']?.toString() ?? '$nextPage') ?? nextPage;
              final lastPage = int.tryParse(meta['last_page']?.toString() ?? '$curPage') ?? curPage;
              hasMoreMenuSales.value = curPage < lastPage;
            } else {
              hasMoreMenuSales.value = list.length >= 20;
            }
          }
        } else {
          hasMoreMenuSales.value = false;
        }
      } else {
        hasMoreMenuSales.value = false;
      }
    } catch (_) {
      // Non-blocking fallback
    } finally {
      isLoadingMoreMenuSales.value = false;
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
    hasMenuSearch.value = false;
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
      case 6:
        if (productManagementSubTab.value == 0) {
          await Future.wait([
            fetchAdminProducts(),
            fetchAdminProductCategories(),
          ]);
        } else {
          await Future.wait([
            fetchHppSummary(),
            fetchAdminProductCategories(),
          ]);
        }
        break;
      case 7:
        // Tab Pengaturan
        break;
      case 8:
        await fetchIngredients(showLoader: false);
        break;
    }
  }

  // ==========================================
  // 6. CASH FLOW & EXPENSE MANAGEMENT LOGIC
  // ==========================================

  Map<String, dynamic> _buildCashFlowQueryParams({int page = 1}) {
    final Map<String, dynamic> params = {
      'limit': 20,
      'page': page,
    };

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

    return params;
  }

  Future<void> fetchCashFlow({bool showLoader = true}) async {
    if (showLoader) isLoadingCashFlow.value = true;
    cashFlowCurrentPage = 1;
    hasMoreCashFlow.value = true;

    try {
      final params = _buildCashFlowQueryParams(page: 1);
      final response = await _apiProvider.get(
        ApiConstants.adminCashFlow,
        queryParameters: params,
      );

      if (response.data != null && response.data['success'] == true) {
        final rawData = response.data['data'];
        final List list = (rawData is Map && rawData['data'] != null)
            ? rawData['data']
            : (rawData is List ? rawData : []);
        final items = list.map((e) => CashMovementModel.fromJson(e)).toList();
        cashFlowMovements.assignAll(items);

        final meta = response.data['meta'];
        if (meta is Map) {
          final curPage = int.tryParse(meta['current_page']?.toString() ?? '1') ?? 1;
          final lastPage = int.tryParse(meta['last_page']?.toString() ?? '1') ?? 1;
          hasMoreCashFlow.value = curPage < lastPage;
        } else if (rawData is Map) {
          final curPage = int.tryParse(rawData['current_page']?.toString() ?? '1') ?? 1;
          final lastPage = int.tryParse(rawData['last_page']?.toString() ?? '1') ?? 1;
          hasMoreCashFlow.value = curPage < lastPage;
        } else {
          hasMoreCashFlow.value = items.length >= 20;
        }
      } else {
        AppSnackbar.warning('Info', response.data?['message'] ?? 'Gagal memuat riwayat arus kas.');
      }
    } catch (e) {
      AppSnackbar.danger('Kendala Arus Kas', ApiProvider.getErrorMessage(e));
    } finally {
      isLoadingCashFlow.value = false;
    }
  }

  /// Muat arus kas halaman berikutnya secara lazy load (Infinite Scroll)
  Future<void> loadMoreCashFlow() async {
    if (isLoadingCashFlow.value || isLoadingMoreCashFlow.value || !hasMoreCashFlow.value) {
      return;
    }

    isLoadingMoreCashFlow.value = true;
    try {
      final nextPage = cashFlowCurrentPage + 1;
      final params = _buildCashFlowQueryParams(page: nextPage);
      final response = await _apiProvider.get(
        ApiConstants.adminCashFlow,
        queryParameters: params,
      );

      if (response.data != null && response.data['success'] == true) {
        final rawData = response.data['data'];
        final List list = (rawData is Map && rawData['data'] != null)
            ? rawData['data']
            : (rawData is List ? rawData : []);
        final newMovements = list.map((e) => CashMovementModel.fromJson(e)).toList();

        if (newMovements.isEmpty) {
          hasMoreCashFlow.value = false;
        } else {
          final existingIds = cashFlowMovements.map((m) => m.id).toSet();
          final uniqueNew = newMovements.where((m) => !existingIds.contains(m.id)).toList();
          cashFlowMovements.addAll(uniqueNew);
          cashFlowCurrentPage = nextPage;

          final meta = response.data['meta'];
          if (meta is Map) {
            final curPage = int.tryParse(meta['current_page']?.toString() ?? '$nextPage') ?? nextPage;
            final lastPage = int.tryParse(meta['last_page']?.toString() ?? '$curPage') ?? curPage;
            hasMoreCashFlow.value = curPage < lastPage;
          } else if (rawData is Map) {
            final curPage = int.tryParse(rawData['current_page']?.toString() ?? '$nextPage') ?? nextPage;
            final lastPage = int.tryParse(rawData['last_page']?.toString() ?? '$curPage') ?? curPage;
            hasMoreCashFlow.value = curPage < lastPage;
          } else {
            hasMoreCashFlow.value = newMovements.length >= 20;
          }
        }
      } else {
        hasMoreCashFlow.value = false;
      }
    } catch (_) {
      // Non-blocking fallback
    } finally {
      isLoadingMoreCashFlow.value = false;
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
    hasCashFlowSearch.value = false;
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

  // ==========================================
  // 7. PRODUCT & RECIPE MASTER LOGIC
  // ==========================================

  Map<String, dynamic> _buildProductQueryParams({int page = 1}) {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': 20,
      'paginate': true,
    };
    if (selectedProductCategoryId.value != null) {
      queryParams['category_id'] = selectedProductCategoryId.value;
    }
    if (selectedProductStatus.value == 'active') {
      queryParams['status'] = 'active';
      queryParams['is_active'] = true;
    } else if (selectedProductStatus.value == 'inactive') {
      queryParams['status'] = 'inactive';
      queryParams['is_active'] = false;
    } else if (selectedProductStatus.value == 'archived') {
      queryParams['status'] = 'archived';
      queryParams['is_archived'] = true;
    }
    if (productSearchQuery.value.trim().isNotEmpty) {
      queryParams['search'] = productSearchQuery.value.trim();
    }

    return queryParams;
  }

  Future<void> fetchAdminProducts({bool showLoader = true}) async {
    if (showLoader) isLoadingProducts.value = true;
    productCurrentPage = 1;
    hasMoreProducts.value = true;

    try {
      final queryParams = _buildProductQueryParams(page: 1);
      final response = await _apiProvider.get(
        ApiConstants.adminProducts,
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['success'] == true) {
        final rawData = response.data['data'];
        final List list = (rawData is Map && rawData['data'] != null)
            ? rawData['data']
            : (rawData is List ? rawData : []);
        final items = list
            .whereType<Map>()
            .map((item) => AdminProductModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        products.assignAll(items);

        final meta = response.data['meta'];
        if (meta is Map) {
          final curPage = int.tryParse(meta['current_page']?.toString() ?? '1') ?? 1;
          final lastPage = int.tryParse(meta['last_page']?.toString() ?? '1') ?? 1;
          hasMoreProducts.value = curPage < lastPage;
          totalProductCount.value = int.tryParse(meta['total']?.toString() ?? '0') ?? items.length;
        } else {
          hasMoreProducts.value = items.length >= 20;
          totalProductCount.value = items.length;
        }
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Memuat Produk', ApiProvider.getErrorMessage(e));
    } finally {
      isLoadingProducts.value = false;
    }
  }

  /// Muat produk halaman berikutnya secara lazy load (Infinite Scroll)
  Future<void> loadMoreProducts() async {
    if (isLoadingProducts.value || isLoadingMoreProducts.value || !hasMoreProducts.value) {
      return;
    }

    isLoadingMoreProducts.value = true;
    try {
      final nextPage = productCurrentPage + 1;
      final queryParams = _buildProductQueryParams(page: nextPage);
      final response = await _apiProvider.get(
        ApiConstants.adminProducts,
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['success'] == true) {
        final rawData = response.data['data'];
        final List list = (rawData is Map && rawData['data'] != null)
            ? rawData['data']
            : (rawData is List ? rawData : []);
        final newItems = list
            .whereType<Map>()
            .map((item) => AdminProductModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        if (newItems.isEmpty) {
          hasMoreProducts.value = false;
        } else {
          final existingIds = products.map((p) => p.id).toSet();
          final uniqueNew = newItems.where((p) => !existingIds.contains(p.id)).toList();
          products.addAll(uniqueNew);
          productCurrentPage = nextPage;

          final meta = response.data['meta'];
          if (meta is Map) {
            final curPage = int.tryParse(meta['current_page']?.toString() ?? '$nextPage') ?? nextPage;
            final lastPage = int.tryParse(meta['last_page']?.toString() ?? '$curPage') ?? curPage;
            hasMoreProducts.value = curPage < lastPage;
            final parsedTotal = int.tryParse(meta['total']?.toString() ?? '0') ?? 0;
            if (parsedTotal > 0) {
              totalProductCount.value = parsedTotal;
            }
          } else {
            hasMoreProducts.value = newItems.length >= 20;
          }
        }
      } else {
        hasMoreProducts.value = false;
      }
    } catch (_) {
      // Non-blocking fallback
    } finally {
      isLoadingMoreProducts.value = false;
    }
  }

  Future<void> fetchAdminProductCategories() async {
    isLoadingProductCategories.value = true;
    try {
      final response = await _apiProvider.get(ApiConstants.adminCategories);
      if (response.data != null && response.data['success'] == true) {
        final rawData = response.data['data'];
        if (rawData is List) {
          productCategories.value = rawData
              .whereType<Map>()
              .map((item) => AdminCategoryModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Memuat Kategori', ApiProvider.getErrorMessage(e));
    } finally {
      isLoadingProductCategories.value = false;
    }
  }

  Future<AdminProductModel?> fetchProductDetail(int id) async {
    try {
      final response = await _apiProvider.get(ApiConstants.adminProductDetail(id));
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map) {
          return AdminProductModel.fromJson(Map<String, dynamic>.from(data));
        }
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Memuat Detail', ApiProvider.getErrorMessage(e));
    }
    return null;
  }

  Future<bool> storeProduct({
    required String name,
    required int categoryId,
    required double price,
    String? sku,
    String? barcode,
    String? description,
    bool isActive = true,
    double? hargaBeli,
    double? operationalCost,
    List<ProductIngredientModel>? ingredients,
    String modeAlokasiOps = 'manual',
    int targetPenjualanBulanan = 3000,
    double kenaikanPersen = 0.0,
    String? selectedTier,
    File? imageFile,
  }) async {
    isSubmittingProduct.value = true;
    try {
      final mapData = <String, dynamic>{
        'name': name.trim(),
        'category_id': categoryId,
        'price': price,
        if (sku != null && sku.trim().isNotEmpty) 'sku': sku.trim(),
        if (barcode != null && barcode.trim().isNotEmpty) 'barcode': barcode.trim(),
        if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
        'is_active': isActive ? 1 : 0,
        if (hargaBeli != null) 'harga_beli': hargaBeli,
        if (operationalCost != null) 'operational_cost': operationalCost,
        'mode_alokasi_ops': modeAlokasiOps,
        'target_penjualan_bulanan': targetPenjualanBulanan,
        'kenaikan_persen': kenaikanPersen,
        if (selectedTier != null) 'selected_tier': selectedTier,
      };

      if (ingredients != null && ingredients.isNotEmpty) {
        final ingList = ingredients.map((i) => i.toJson()).toList();
        if (imageFile != null) {
          mapData['ingredients'] = jsonEncode(ingList);
        } else {
          mapData['ingredients'] = ingList;
        }
      }

      dynamic payloadData;
      if (imageFile != null && imageFile.existsSync()) {
        mapData['image'] = await dio.MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split(Platform.pathSeparator).last,
        );
        payloadData = dio.FormData.fromMap(mapData);
      } else {
        payloadData = mapData;
      }

      final response = await _apiProvider.post(
        ApiConstants.adminProducts,
        data: payloadData,
      );

      if (response.data != null && response.data['success'] == true) {
        AppSnackbar.success('Berhasil', response.data['message'] ?? 'Menu berhasil ditambahkan.');
        await fetchAdminProducts(showLoader: false);
        await fetchAdminProductCategories();
        fetchHppSummary(showLoader: false);
        return true;
      } else {
        AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal menambahkan menu.');
        return false;
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Menyimpan Menu', ApiProvider.getErrorMessage(e));
      return false;
    } finally {
      isSubmittingProduct.value = false;
    }
  }

  Future<bool> updateProduct(
    int id, {
    required String name,
    required int categoryId,
    required double price,
    String? sku,
    String? barcode,
    String? description,
    bool isActive = true,
    double? hargaBeli,
    double? operationalCost,
    List<ProductIngredientModel>? ingredients,
    String modeAlokasiOps = 'manual',
    int targetPenjualanBulanan = 3000,
    double kenaikanPersen = 0.0,
    String? selectedTier,
    File? imageFile,
  }) async {
    isSubmittingProduct.value = true;
    try {
      final mapData = <String, dynamic>{
        'name': name.trim(),
        'category_id': categoryId,
        'price': price,
        if (sku != null && sku.trim().isNotEmpty) 'sku': sku.trim(),
        if (barcode != null && barcode.trim().isNotEmpty) 'barcode': barcode.trim(),
        if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
        'is_active': isActive ? 1 : 0,
        if (hargaBeli != null) 'harga_beli': hargaBeli,
        if (operationalCost != null) 'operational_cost': operationalCost,
        'mode_alokasi_ops': modeAlokasiOps,
        'target_penjualan_bulanan': targetPenjualanBulanan,
        'kenaikan_persen': kenaikanPersen,
        if (selectedTier != null) 'selected_tier': selectedTier,
      };

      if (ingredients != null) {
        final ingList = ingredients.map((i) => i.toJson()).toList();
        if (imageFile != null) {
          mapData['ingredients'] = jsonEncode(ingList);
        } else {
          mapData['ingredients'] = ingList;
        }
      }

      dynamic payloadData;
      if (imageFile != null && imageFile.existsSync()) {
        mapData['image'] = await dio.MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split(Platform.pathSeparator).last,
        );
        payloadData = dio.FormData.fromMap(mapData);
      } else {
        payloadData = mapData;
      }

      final response = await _apiProvider.post(
        ApiConstants.adminProductDetail(id),
        data: payloadData,
      );

      if (response.data != null && response.data['success'] == true) {
        AppSnackbar.success('Berhasil', response.data['message'] ?? 'Menu berhasil diperbarui.');
        await fetchAdminProducts(showLoader: false);
        await fetchAdminProductCategories();
        fetchHppSummary(showLoader: false);
        return true;
      } else {
        AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal memperbarui menu.');
        return false;
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Memperbarui Menu', ApiProvider.getErrorMessage(e));
      return false;
    } finally {
      isSubmittingProduct.value = false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    isDeletingProduct.value = true;
    try {
      final response = await _apiProvider.delete(ApiConstants.adminProductDetail(id));
      if (response.data != null && response.data['success'] == true) {
        AppSnackbar.success('Berhasil', response.data['message'] ?? 'Menu berhasil dihapus.');
        products.removeWhere((p) => p.id == id);
        fetchHppSummary(showLoader: false);
        return true;
      } else {
        AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal menghapus menu.');
        return false;
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Menghapus Menu', ApiProvider.getErrorMessage(e));
      return false;
    } finally {
      isDeletingProduct.value = false;
    }
  }

  Future<void> toggleProductStatus(AdminProductModel product) async {
    final newStatus = !product.isActive;
    try {
      final response = await _apiProvider.post(
        ApiConstants.adminProductDetail(product.id),
        data: {
          'name': product.name,
          'category_id': product.categoryId,
          'price': product.price,
          'is_active': newStatus ? 1 : 0,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final idx = products.indexWhere((p) => p.id == product.id);
        if (idx != -1) {
          products[idx] = product.copyWith(isActive: newStatus);
        }
        AppSnackbar.success(
          'Status Diperbarui',
          "Menu '${product.name}' ${newStatus ? 'diaktifkan' : 'dinonaktifkan'}.",
        );
        fetchHppSummary(showLoader: false);
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Mengubah Status', ApiProvider.getErrorMessage(e));
    }
  }

  Future<void> toggleArchiveProduct(AdminProductModel product) async {
    final willArchive = !product.isArchived;
    try {
      if (willArchive) {
        // Soft delete the product to archive it
        final response = await _apiProvider.delete(ApiConstants.adminProductDetail(product.id));
        if (response.data != null && response.data['success'] == true) {
          if (selectedProductStatus.value == 'archived') {
            final idx = products.indexWhere((p) => p.id == product.id);
            if (idx != -1) products[idx] = product.copyWith(isArchived: true);
          } else {
            products.removeWhere((p) => p.id == product.id);
          }
          AppSnackbar.success(
            'Menu Diarsipkan',
            response.data['message'] ?? "Menu '${product.name}' berhasil diarsipkan.",
          );
          fetchHppSummary(showLoader: false);
        } else {
          AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal mengarsipkan menu.');
        }
      } else {
        // Restore product from archive
        final response = await _apiProvider.post(ApiConstants.adminProductRestore(product.id));
        if (response.data != null && response.data['success'] == true) {
          if (selectedProductStatus.value == 'archived') {
            products.removeWhere((p) => p.id == product.id);
          } else {
            final idx = products.indexWhere((p) => p.id == product.id);
            if (idx != -1) products[idx] = product.copyWith(isArchived: false);
          }
          AppSnackbar.success(
            'Menu Dipulihkan',
            response.data['message'] ?? "Menu '${product.name}' berhasil dipulihkan dari arsip.",
          );
          fetchHppSummary(showLoader: false);
        } else {
          AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal memulihkan menu dari arsip.');
        }
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Memperbarui Status Arsip', ApiProvider.getErrorMessage(e));
    }
  }

  // ==========================================
  // 8. HPP, HEALTH CHECK & RECIPE STRATEGY LOGIC
  // ==========================================

  Future<void> fetchHppSummary({bool showLoader = true}) async {
    if (showLoader) isLoadingHppSummary.value = true;
    try {
      final response = await _apiProvider.get(ApiConstants.adminHppSummary);
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map) {
          hppSummary.value = HppSummaryModel.fromJson(Map<String, dynamic>.from(data));
        }
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Memuat Ringkasan HPP', ApiProvider.getErrorMessage(e));
    } finally {
      isLoadingHppSummary.value = false;
    }
  }

  Future<HppCalculationModel?> calculateHppSimulation({
    List<ProductIngredientModel>? ingredients,
    double? sellingPrice,
    double? operationalCost,
    double? kenaikanPersen,
    int? targetMonthlyUnits,
    double? targetMonthlyProfit,
    int? operationalDays,
    String modeAlokasiOps = 'manual',
    List<Map<String, dynamic>>? biayaTetapItems,
  }) async {
    isCalculatingHpp.value = true;
    final targetIngredients = ingredients ?? simulationIngredients;
    final price = sellingPrice ?? simulationSellingPrice.value;
    final opsCost = operationalCost ?? simulationOperationalCost.value;
    final markup = kenaikanPersen ?? simulationKenaikanPersen.value;
    final units = targetMonthlyUnits ?? simulationTargetMonthlyUnits.value;
    final targetProfit = targetMonthlyProfit ?? simulationTargetMonthlyProfit.value;
    final days = operationalDays ?? simulationOperationalDays.value;

    try {
      final payload = {
        'ingredients': targetIngredients.map((i) => i.toJson()).toList(),
        'selling_price': price,
        'operational_cost': opsCost,
        'kenaikan_persen': markup,
        'target_penjualan_bulanan': units,
        'target_laba_bulanan': targetProfit,
        'hari_operasional_sebulan': days,
        'mode_alokasi_ops': modeAlokasiOps,
        if (biayaTetapItems != null) 'biaya_tetap_items': biayaTetapItems,
      };

      final response = await _apiProvider.post(
        ApiConstants.adminHppCalculate,
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map) {
          final result = HppCalculationModel.fromJson(Map<String, dynamic>.from(data));
          simulationCalculationResult.value = result;
          return result;
        }
      }
    } catch (e) {
      AppSnackbar.danger('Kalkulasi HPP Gagal', ApiProvider.getErrorMessage(e));
    } finally {
      isCalculatingHpp.value = false;
    }
    return null;
  }

  Future<bool> generateAiRecipe(String productName) async {
    final cleanName = productName.trim();
    if (cleanName.length < 3) {
      AppSnackbar.warning('Nama Terlalu Pendek', 'Masukkan nama menu minimal 3 karakter.');
      return false;
    }

    isGeneratingAiRecipe.value = true;
    try {
      final response = await _apiProvider.post(
        ApiConstants.adminHppAiRecipe,
        data: {'product_name': cleanName},
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        if (data is Map) {
          final rawIngredients = data['ingredients'];
          if (rawIngredients is List) {
            final parsed = rawIngredients
                .whereType<Map>()
                .map((i) => ProductIngredientModel.fromJson(Map<String, dynamic>.from(i)))
                .toList();

            simulationProductName.value = cleanName;
            simulationIngredients.value = parsed;

            // Jika ada summary & pricing tiers langsung terisi
            if (data['summary'] is Map) {
              final calcResult = HppCalculationModel.fromJson(Map<String, dynamic>.from(data));
              simulationCalculationResult.value = calcResult;
              if (calcResult.pricingTiers['standar'] != null) {
                simulationSellingPrice.value = calcResult.pricingTiers['standar']!.harga;
              }
            } else {
              await calculateHppSimulation(ingredients: parsed);
            }

            AppSnackbar.success(
              'Estimasi Resep Selesai',
              "Formulasi takaran bahan baku untuk '$cleanName' berhasil dibuat.",
            );
            return true;
          }
        }
      } else {
        AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal membuat estimasi resep.');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Estimasi Resep', ApiProvider.getErrorMessage(e));
    } finally {
      isGeneratingAiRecipe.value = false;
    }
    return false;
  }

  void resetSimulation() {
    simulationProductName.value = '';
    simulationIngredients.clear();
    simulationSellingPrice.value = 0.0;
    simulationOperationalCost.value = 1000.0;
    simulationKenaikanPersen.value = 0.0;
    simulationCalculationResult.value = null;
  }

  // ==========================================
  // 8. INGREDIENTS & INVENTORY MANAGEMENT LOGIC
  // ==========================================
  Future<void> fetchIngredients({bool showLoader = true}) async {
    if (showLoader) {
      isLoadingIngredients.value = true;
    }
    ingredientCurrentPage = 1;

    try {
      final queryParams = <String, dynamic>{
        'page': 1,
        'per_page': 50,
      };

      if (ingredientSearchQuery.value.trim().isNotEmpty) {
        queryParams['search'] = ingredientSearchQuery.value.trim();
      }

      if (selectedIngredientStatus.value != 'all') {
        queryParams['status'] = selectedIngredientStatus.value;
      }

      if (selectedIngredientSort.value != 'name') {
        queryParams['sort'] = selectedIngredientSort.value;
      }

      final response = await _apiProvider.get(
        ApiConstants.adminIngredients,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;

        // 1. Parse Summary KPI
        if (resData['summary'] != null && resData['summary'] is Map) {
          ingredientSummary.value = AdminIngredientSummaryModel.fromJson(
            Map<String, dynamic>.from(resData['summary']),
          );
        }

        // 2. Parse Items
        final dynamic rawList = resData['data'];
        List<dynamic> itemsList = [];
        if (rawList is List) {
          itemsList = rawList;
          hasMoreIngredients.value = false;
        } else if (rawList is Map && rawList['data'] is List) {
          itemsList = rawList['data'];
          final currentPage = rawList['current_page'] ?? 1;
          final lastPage = rawList['last_page'] ?? 1;
          hasMoreIngredients.value = currentPage < lastPage;
        }

        ingredients.assignAll(
          itemsList.map((e) => AdminIngredientModel.fromJson(Map<String, dynamic>.from(e))).toList(),
        );

        // Fallback: If summary was empty or all 0, compute from ingredients
        if (ingredientSummary.value.totalIngredients == 0 && ingredients.isNotEmpty) {
          double totalVal = 0;
          int lowCount = 0;
          int outCount = 0;
          for (final ing in ingredients) {
            totalVal += ing.totalInventoryValue;
            if (ing.isOutOfStock) {
              outCount++;
            } else if (ing.isLowStock) {
              lowCount++;
            }
          }
          ingredientSummary.value = AdminIngredientSummaryModel(
            totalIngredients: ingredients.length,
            lowStockCount: lowCount,
            outOfStockCount: outCount,
            totalInventoryValue: totalVal,
          );
        }
      }
    } catch (e) {
      debugPrint('[AdminController] Error fetchIngredients: $e');
      AppSnackbar.danger('Gagal Memuat Bahan Baku', ApiProvider.getErrorMessage(e));
    } finally {
      isLoadingIngredients.value = false;
    }
  }

  Future<void> loadMoreIngredients() async {
    if (isLoadingMoreIngredients.value || !hasMoreIngredients.value) return;

    isLoadingMoreIngredients.value = true;
    final nextPage = ingredientCurrentPage + 1;

    try {
      final queryParams = <String, dynamic>{
        'page': nextPage,
        'per_page': 50,
      };

      if (ingredientSearchQuery.value.trim().isNotEmpty) {
        queryParams['search'] = ingredientSearchQuery.value.trim();
      }
      if (selectedIngredientStatus.value != 'all') {
        queryParams['status'] = selectedIngredientStatus.value;
      }
      if (selectedIngredientSort.value != 'name') {
        queryParams['sort'] = selectedIngredientSort.value;
      }

      final response = await _apiProvider.get(
        ApiConstants.adminIngredients,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data;
        final dynamic rawList = resData['data'];
        List<dynamic> itemsList = [];

        if (rawList is Map && rawList['data'] is List) {
          itemsList = rawList['data'];
          final lastPage = rawList['last_page'] ?? nextPage;
          hasMoreIngredients.value = nextPage < lastPage;
          ingredientCurrentPage = nextPage;
        }

        final newItems = itemsList
            .map((e) => AdminIngredientModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        ingredients.addAll(newItems);
      }
    } catch (e) {
      debugPrint('[AdminController] Error loadMoreIngredients: $e');
    } finally {
      isLoadingMoreIngredients.value = false;
    }
  }

  Future<bool> createIngredient(Map<String, dynamic> data) async {
    try {
      final response = await _apiProvider.post(
        ApiConstants.adminIngredients,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppSnackbar.success('Berhasil', 'Bahan baku berhasil ditambahkan');
        await fetchIngredients(showLoader: false);
        return true;
      } else {
        AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal menambah bahan baku');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Tambah Bahan', ApiProvider.getErrorMessage(e));
    }
    return false;
  }

  Future<bool> updateIngredient(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiProvider.put(
        ApiConstants.adminIngredientDetail(id),
        data: data,
      );

      if (response.statusCode == 200) {
        AppSnackbar.success('Berhasil', 'Data bahan baku berhasil diperbarui');
        await fetchIngredients(showLoader: false);
        return true;
      } else {
        AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal memperbarui bahan');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Perbarui Bahan', ApiProvider.getErrorMessage(e));
    }
    return false;
  }

  Future<bool> deleteIngredient(int id) async {
    try {
      final response = await _apiProvider.delete(
        ApiConstants.adminIngredientDetail(id),
      );

      if (response.statusCode == 200) {
        AppSnackbar.success('Berhasil', 'Bahan baku berhasil dihapus');
        ingredients.removeWhere((item) => item.id == id);
        await fetchIngredients(showLoader: false);
        return true;
      } else {
        AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal menghapus bahan');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Hapus Bahan', ApiProvider.getErrorMessage(e));
    }
    return false;
  }

  Future<bool> restockIngredient(
    int id, {
    required double amount,
    required double totalCost,
    String notes = '',
    bool recordToExpense = false,
  }) async {
    try {
      final response = await _apiProvider.post(
        ApiConstants.adminIngredientRestock(id),
        data: {
          'amount': amount,
          'total_cost': totalCost,
          'notes': notes,
          'record_to_expense': recordToExpense,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppSnackbar.success('Restock Berhasil', 'Stok bahan berhasil ditambahkan ke inventaris');
        await fetchIngredients(showLoader: false);
        return true;
      } else {
        AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal melakukan restock');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Restock', ApiProvider.getErrorMessage(e));
    }
    return false;
  }

  Future<bool> opnameIngredient({
    required int id,
    required double actualStock,
    required String reason,
    String notes = '',
  }) async {
    try {
      final response = await _apiProvider.post(
        ApiConstants.adminIngredientOpname,
        data: {
          'notes': notes,
          'items': [
            {
              'ingredient_id': id,
              'actual_stock': actualStock,
              'reason': reason,
            }
          ],
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppSnackbar.success('Opname Selesai', 'Penyesuaian stok fisik berhasil dicatat');
        await fetchIngredients(showLoader: false);
        return true;
      } else {
        AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal mencatat opname');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Opname', ApiProvider.getErrorMessage(e));
    }
    return false;
  }

  Future<AdminStockMutationPaginatedResult> fetchIngredientMutationsPaginated(
    int ingredientId, {
    String? type,
    String? startDate,
    String? endDate,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'ingredient_id': ingredientId,
        'per_page': perPage,
        'page': page,
      };
      if (type != null && type.isNotEmpty && type != 'all') {
        params['type'] = type;
      }
      if (startDate != null && startDate.isNotEmpty) {
        params['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        params['end_date'] = endDate;
      }

      final response = await _apiProvider.get(
        ApiConstants.adminIngredientMutations,
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data['data'];
        List<dynamic> items = [];
        int currentPage = 1;
        int lastPage = 1;
        int total = 0;

        if (raw is List) {
          items = raw;
          total = items.length;
        } else if (raw is Map) {
          if (raw['data'] is List) {
            items = raw['data'];
          }
          currentPage = (raw['current_page'] as num?)?.toInt() ?? 1;
          lastPage = (raw['last_page'] as num?)?.toInt() ?? 1;
          total = (raw['total'] as num?)?.toInt() ?? items.length;
        }

        final list = items
            .map((e) => AdminStockMutationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        double totalIn = 0.0;
        double totalOut = 0.0;
        double netChange = 0.0;

        if (response.data['summary'] != null && response.data['summary'] is Map) {
          final s = response.data['summary'];
          totalIn = (s['total_in'] as num?)?.toDouble() ?? 0.0;
          totalOut = (s['total_out'] as num?)?.toDouble() ?? 0.0;
          netChange = (s['net_change'] as num?)?.toDouble() ?? (totalIn - totalOut);
        }

        return AdminStockMutationPaginatedResult(
          items: list,
          currentPage: currentPage,
          lastPage: lastPage,
          total: total,
          hasMore: currentPage < lastPage,
          totalIn: totalIn,
          totalOut: totalOut,
          netChange: netChange,
        );
      }
    } catch (e) {
      debugPrint('[AdminController] Error fetchIngredientMutations: $e');
      AppSnackbar.danger('Gagal Memuat Mutasi', ApiProvider.getErrorMessage(e));
    }
    return const AdminStockMutationPaginatedResult(
      items: [],
      currentPage: 1,
      lastPage: 1,
      total: 0,
      hasMore: false,
    );
  }

  Future<List<AdminStockMutationModel>> fetchIngredientMutations(
    int ingredientId, {
    String? type,
    String? startDate,
    String? endDate,
    int page = 1,
    int perPage = 50,
  }) async {
    final result = await fetchIngredientMutationsPaginated(
      ingredientId,
      type: type,
      startDate: startDate,
      endDate: endDate,
      page: page,
      perPage: perPage,
    );
    return result.items;
  }

  Future<bool> attachIngredientToProduct({
    required int ingredientId,
    required int productId,
    required double amount,
    String? unit,
  }) async {
    try {
      final response = await _apiProvider.post(
        ApiConstants.adminIngredientAttachProduct(ingredientId),
        data: {
          'product_id': productId,
          'amount': amount,
          if (unit != null) 'unit': unit,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppSnackbar.success('Berhasil Ditautkan', response.data?['message'] ?? 'Bahan baku berhasil ditautkan ke resep menu');
        await Future.wait([
          fetchIngredients(showLoader: false),
          fetchAdminProducts(showLoader: false),
          fetchHppSummary(showLoader: false),
        ]);
        return true;
      } else {
        AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal menautkan bahan baku');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Menautkan', ApiProvider.getErrorMessage(e));
    }
    return false;
  }

  Future<bool> detachIngredientFromProduct({
    required int ingredientId,
    required int productId,
  }) async {
    try {
      final response = await _apiProvider.delete(
        ApiConstants.adminIngredientDetachProduct(ingredientId, productId),
      );

      if (response.statusCode == 200) {
        AppSnackbar.success('Berhasil Dihapus', response.data?['message'] ?? 'Bahan baku berhasil dihapus dari resep menu');
        await Future.wait([
          fetchIngredients(showLoader: false),
          fetchAdminProducts(showLoader: false),
          fetchHppSummary(showLoader: false),
        ]);
        return true;
      } else {
        AppSnackbar.warning('Perhatian', response.data?['message'] ?? 'Gagal menghapus tautan');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Menghapus Tautan', ApiProvider.getErrorMessage(e));
    }
    return false;
  }

  Future<bool> detachIngredientFromAllProducts({
    required int ingredientId,
  }) async {
    try {
      final response = await _apiProvider.delete(
        ApiConstants.adminIngredientDetachAllProducts(ingredientId),
      );

      if (response.statusCode == 200) {
        AppSnackbar.success(
          'Berhasil Diputuskan',
          response.data?['message'] ?? 'Kaitan bahan baku dengan semua menu berhasil diputuskan.',
        );
        await Future.wait([
          fetchIngredients(showLoader: false),
          fetchAdminProducts(showLoader: false),
          fetchHppSummary(showLoader: false),
        ]);
        return true;
      } else {
        AppSnackbar.warning(
          'Perhatian',
          response.data?['message'] ?? 'Gagal memutuskan kaitan menu.',
        );
      }
    } catch (e) {
      AppSnackbar.danger(
        'Gagal Memutuskan Kaitan',
        ApiProvider.getErrorMessage(e),
      );
    }
    return false;
  }

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
