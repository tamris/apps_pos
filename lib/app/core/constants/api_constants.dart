class ApiConstants {
  // Default Base URL for Android Emulator (10.0.2.2) or Physical Device via LAN
  // This can be modified dynamically at runtime in Settings
  static const String defaultBaseUrl = 'https://nolicoffee.appslab.my.id/api';
  static const String defaultStorageUrl = 'https://nolicoffee.appslab.my.id/storage';

  // Auth Endpoints
  static const String cashiers = '/auth/cashiers';
  static const String pinLogin = '/auth/pin-login';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // POS Endpoints
  static const String bootstrap = '/pos/bootstrap';
  static const String addons = '/pos/addons';
  
  // Shift Management
  static const String currentShift = '/pos/shift/current';
  static const String startShift = '/pos/shift/start';
  static const String endShift = '/pos/shift/end';

  // Checkout & Transactions
  static const String checkout = '/pos/checkout';
  static const String todayTransactions = '/pos/transactions/today';
  static String receiptData(int transactionId) => '/pos/transactions/$transactionId/receipt';
  static String updatePaymentMethod(int transactionId) => '/pos/transactions/$transactionId/payment-method';

  // Open Bills
  static const String openBills = '/pos/open-bills';
  static String openBillDetail(int id) => '/pos/open-bills/$id';
  static String cancelOpenBill(int id) => '/pos/open-bills/$id/cancel';

  // Offline Sync
  static const String syncOffline = '/pos/sync-offline';

  // Menu Availability
  static const String availability = '/pos/availability';
  static String toggleProductAvailability(int id) => '/pos/products/$id/toggle-availability';
  static String toggleCategoryAvailability(int id) => '/pos/categories/$id/toggle-availability';

  // Online Orders (Self-Order / Web Order)
  static const String onlineOrders = '/pos/online-orders';
  static const String onlineOrdersCheckNew = '/pos/online-orders/check-new';
  static const String onlineOrdersStats = '/pos/online-orders/stats';
  static const String onlineOrdersToggleActive = '/pos/online-orders/toggle-active';
  static String onlineOrderDetail(int id) => '/pos/online-orders/$id';
  static String updateOnlineOrderStatus(int id) => '/pos/online-orders/$id/status';
  static String onlineOrderReceipt(int id) => '/pos/online-orders/$id/receipt';
  static String onlineOrderKitchen(int id) => '/pos/online-orders/$id/kitchen';

  // Admin & Owner Endpoints
  static const String adminDashboard = '/admin/dashboard';
  static const String adminShiftHistory = '/admin/shifts/history';
  static String adminShiftDetail(int id) => '/admin/shifts/$id';
  static const String adminTransactions = '/admin/transactions';
  static String adminTransactionDetail(int id) => '/admin/transactions/$id';
  static String adminVoidTransaction(int id) => '/admin/transactions/$id/void';
  static const String adminOpenBills = '/admin/open-bills';

  // POS Cash Flow & Drawer Management
  static const String posCashFlowCategories = '/pos/cash-flow/categories';
  static const String posCashFlowCurrent = '/pos/cash-flow/current';
  static const String posCashFlowStore = '/pos/cash-flow';
  static String posCashFlowReceipt(int id) => '/pos/cash-flow/$id/receipt';

  // Admin Menu Sales Analytics
  static const String adminMenuSales = '/admin/menu-sales';
  static const String adminMenuSalesTop = '/admin/menu-sales/top';
  static const String adminMenuSalesCategories = '/admin/menu-sales/categories';
  static String adminMenuSalesDetail(int id) => '/admin/menu-sales/$id';

  // Admin Cash Flow & Expense Management
  static const String adminCashFlow = '/admin/cash-flow';
  static const String adminCashFlowSummary = '/admin/cash-flow/summary';
  static String adminCashFlowDetail(int id) => '/admin/cash-flow/$id';
  static const String adminExpenseCategories = '/admin/expense-categories';
  static String adminExpenseCategoryDetail(int id) => '/admin/expense-categories/$id';
}
