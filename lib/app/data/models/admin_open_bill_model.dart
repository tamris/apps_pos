class AdminOpenBillModel {
  final int id;
  final String invoiceNumber;
  final String tableNumber;
  final String customerName;
  final String orderType;
  final String orderSource;
  final String status;
  final String paymentStatus;
  final double total;
  final int itemsCount;
  final String? itemsSummary;
  final String? formattedTime;
  final String? createdAt;
  final int rawElapsedMinutes;
  final String cashierName;

  AdminOpenBillModel({
    required this.id,
    required this.invoiceNumber,
    required this.tableNumber,
    required this.customerName,
    required this.orderType,
    required this.orderSource,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    required this.total,
    required this.itemsCount,
    this.itemsSummary,
    this.formattedTime,
    this.createdAt,
    required this.rawElapsedMinutes,
    required this.cashierName,
  });

  bool get isSelfOrder =>
      orderSource.toLowerCase().contains('self') ||
      orderSource.toLowerCase().contains('online');

  bool get isPaid => paymentStatus.toLowerCase() == 'paid';

  int get elapsedMinutes {
    if (rawElapsedMinutes > 0) return rawElapsedMinutes;
    if (createdAt != null && createdAt!.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt!).toLocal();
        final diff = DateTime.now().difference(dt).inMinutes;
        if (diff >= 0) return diff;
      } catch (_) {}
    }
    return 0;
  }

  factory AdminOpenBillModel.fromJson(Map<String, dynamic> json) {
    final rawTable = json['table_number']?.toString().trim() ?? '';
    final tableNum = (rawTable.isEmpty || rawTable == '-') ? '-' : rawTable;

    return AdminOpenBillModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      tableNumber: tableNum,
      customerName: json['customer_name']?.toString() ?? 'Tamu Meja',
      orderType: json['order_type']?.toString() ?? 'dine_in',
      orderSource: json['order_source']?.toString() ?? 'pos',
      status: json['status']?.toString() ?? 'pending',
      paymentStatus: json['payment_status']?.toString() ?? 'unpaid',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      itemsCount: (json['items_count'] as num?)?.toInt() ?? 0,
      itemsSummary: json['items_summary']?.toString(),
      formattedTime: json['formatted_time']?.toString(),
      createdAt: json['created_at']?.toString(),
      rawElapsedMinutes: (json['elapsed_minutes'] as num?)?.toInt() ?? 0,
      cashierName: json['cashier_name']?.toString() ?? 'Kasir',
    );
  }
}
