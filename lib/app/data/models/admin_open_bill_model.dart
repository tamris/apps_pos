class AdminOpenBillModel {
  final int id;
  final String invoiceNumber;
  final String tableNumber;
  final String customerName;
  final String orderType;
  final String orderSource;
  final double total;
  final int itemsCount;
  final String? createdAt;
  final int elapsedMinutes;
  final String cashierName;

  AdminOpenBillModel({
    required this.id,
    required this.invoiceNumber,
    required this.tableNumber,
    required this.customerName,
    required this.orderType,
    required this.orderSource,
    required this.total,
    required this.itemsCount,
    this.createdAt,
    required this.elapsedMinutes,
    required this.cashierName,
  });

  bool get isSelfOrder => orderSource == 'self_order';

  factory AdminOpenBillModel.fromJson(Map<String, dynamic> json) {
    return AdminOpenBillModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      tableNumber: json['table_number']?.toString() ?? '-',
      customerName: json['customer_name']?.toString() ?? 'Tamu Meja',
      orderType: json['order_type']?.toString() ?? 'dine_in',
      orderSource: json['order_source']?.toString() ?? 'pos',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString(),
      elapsedMinutes: (json['elapsed_minutes'] as num?)?.toInt() ?? 0,
      cashierName: json['cashier_name']?.toString() ?? 'Kasir',
    );
  }
}
