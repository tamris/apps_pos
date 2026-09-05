class AdminShiftModel {
  final int id;
  final String cashierName;
  final String cashierEmail;
  final int cashierId;
  final String? startTime;
  final String? endTime;
  final String status;
  final double startingCash;
  final double cashSales;
  final double qrisSales;
  final double transferSales;
  final double totalSales;
  final int totalTransactions;
  final double expectedCash;
  final double? actualCash;
  final double? difference;
  final String discrepancyStatus;
  final String notes;

  AdminShiftModel({
    required this.id,
    required this.cashierName,
    required this.cashierEmail,
    required this.cashierId,
    this.startTime,
    this.endTime,
    required this.status,
    required this.startingCash,
    required this.cashSales,
    required this.qrisSales,
    required this.transferSales,
    required this.totalSales,
    required this.totalTransactions,
    required this.expectedCash,
    this.actualCash,
    this.difference,
    required this.discrepancyStatus,
    required this.notes,
  });

  bool get isOpen => status == 'open';
  bool get isBalanced => discrepancyStatus == 'balanced';
  bool get isShortage => discrepancyStatus == 'shortage';
  bool get isOverage => discrepancyStatus == 'overage';

  factory AdminShiftModel.fromJson(Map<String, dynamic> json) {
    final cashier = json['cashier'] is Map ? json['cashier'] : {};
    return AdminShiftModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      cashierName: cashier['name']?.toString() ?? 'Kasir',
      cashierEmail: cashier['email']?.toString() ?? '',
      cashierId: (cashier['id'] as num?)?.toInt() ?? 0,
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      status: json['status']?.toString() ?? 'closed',
      startingCash: (json['starting_cash'] as num?)?.toDouble() ?? 0.0,
      cashSales: (json['cash_sales'] as num?)?.toDouble() ?? 0.0,
      qrisSales: (json['qris_sales'] as num?)?.toDouble() ?? 0.0,
      transferSales: (json['transfer_sales'] as num?)?.toDouble() ?? 0.0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: (json['total_transactions'] as num?)?.toInt() ?? 0,
      expectedCash: (json['expected_cash'] as num?)?.toDouble() ?? 0.0,
      actualCash: (json['actual_cash'] as num?)?.toDouble(),
      difference: (json['difference'] as num?)?.toDouble(),
      discrepancyStatus: json['discrepancy_status']?.toString() ?? 'balanced',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class AdminShiftTransactionItemModel {
  final int id;
  final String invoiceNumber;
  final double total;
  final String paymentMethod;
  final String orderType;
  final String status;
  final String? createdAt;

  AdminShiftTransactionItemModel({
    required this.id,
    required this.invoiceNumber,
    required this.total,
    required this.paymentMethod,
    required this.orderType,
    required this.status,
    this.createdAt,
  });

  factory AdminShiftTransactionItemModel.fromJson(Map<String, dynamic> json) {
    return AdminShiftTransactionItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      orderType: json['order_type']?.toString() ?? 'dine_in',
      status: json['status']?.toString() ?? 'completed',
      createdAt: json['created_at']?.toString(),
    );
  }
}

class AdminShiftDetailModel extends AdminShiftModel {
  final List<AdminShiftTransactionItemModel> transactions;

  AdminShiftDetailModel({
    required super.id,
    required super.cashierName,
    required super.cashierEmail,
    required super.cashierId,
    super.startTime,
    super.endTime,
    required super.status,
    required super.startingCash,
    required super.cashSales,
    required super.qrisSales,
    required super.transferSales,
    required super.totalSales,
    required super.totalTransactions,
    required super.expectedCash,
    super.actualCash,
    super.difference,
    required super.discrepancyStatus,
    required super.notes,
    required this.transactions,
  });

  factory AdminShiftDetailModel.fromJson(Map<String, dynamic> json) {
    final cashier = json['cashier'] is Map ? json['cashier'] : {};
    final rawTrx = (json['transactions'] as List?) ?? [];
    return AdminShiftDetailModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      cashierName: cashier['name']?.toString() ?? 'Kasir',
      cashierEmail: cashier['email']?.toString() ?? '',
      cashierId: (cashier['id'] as num?)?.toInt() ?? 0,
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      status: json['status']?.toString() ?? 'closed',
      startingCash: (json['starting_cash'] as num?)?.toDouble() ?? 0.0,
      cashSales: (json['cash_sales'] as num?)?.toDouble() ?? 0.0,
      qrisSales: (json['qris_sales'] as num?)?.toDouble() ?? 0.0,
      transferSales: (json['transfer_sales'] as num?)?.toDouble() ?? 0.0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: (json['total_transactions'] as num?)?.toInt() ?? 0,
      expectedCash: (json['expected_cash'] as num?)?.toDouble() ?? 0.0,
      actualCash: (json['actual_cash'] as num?)?.toDouble(),
      difference: (json['difference'] as num?)?.toDouble(),
      discrepancyStatus: json['discrepancy_status']?.toString() ?? 'balanced',
      notes: json['notes']?.toString() ?? '',
      transactions: rawTrx.map((e) => AdminShiftTransactionItemModel.fromJson(e)).toList(),
    );
  }
}
