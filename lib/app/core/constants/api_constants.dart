class ApiConstants {
  // Default Base URL for Android Emulator (10.0.2.2) or Physical Device via LAN
  // This can be modified dynamically at runtime in Settings
  static const String defaultBaseUrl = 'https://ethical-ape-oddly.ngrok-free.app/api';
  static const String defaultStorageUrl = 'https://ethical-ape-oddly.ngrok-free.app/storage';

  // Auth Endpoints
  static const String cashiers = '/auth/cashiers';
  static const String pinLogin = '/auth/pin-login';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // POS Endpoints
  static const String bootstrap = '/pos/bootstrap';
  
  // Shift Management
  static const String currentShift = '/pos/shift/current';
  static const String startShift = '/pos/shift/start';
  static const String endShift = '/pos/shift/end';

  // Checkout & Transactions
  static const String checkout = '/pos/checkout';
  static const String todayTransactions = '/pos/transactions/today';
  static String receiptData(int transactionId) => '/pos/transactions/$transactionId/receipt';

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
}
