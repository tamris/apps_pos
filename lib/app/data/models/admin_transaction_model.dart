class AdminTransactionCancelledInfo {
  final String? cancelledAt;
  final String cancelledReason;
  final int? cancelledById;
  final String cancelledByName;

  AdminTransactionCancelledInfo({
    this.cancelledAt,
    required this.cancelledReason,
    this.cancelledById,
    required this.cancelledByName,
  });

  factory AdminTransactionCancelledInfo.fromJson(Map<String, dynamic> json) {
    final by = json['cancelled_by'] is Map ? json['cancelled_by'] : {};
    return AdminTransactionCancelledInfo(
      cancelledAt: json['cancelled_at']?.toString(),
      cancelledReason: json['cancelled_reason']?.toString() ?? 'Dibatalkan oleh Admin',
      cancelledById: (json['cancelled_by_id'] as num?)?.toInt() ?? (by['id'] as num?)?.toInt(),
      cancelledByName: json['cancelled_by_name']?.toString() ?? by['name']?.toString() ?? 'Admin',
    );
  }
}

class AdminTransactionItemDetail {
  final int id;
  final int productId;
  final String productName;
  final String categoryName;
  final int quantity;
  final double price;
  final double subtotal;
  final String? notes;
  final List<Map<String, dynamic>> addons;

  AdminTransactionItemDetail({
    required this.id,
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.notes,
    this.addons = const [],
  });

  factory AdminTransactionItemDetail.fromJson(Map<String, dynamic> json) {
    final rawAddons = (json['addons'] as List?) ?? [];
    return AdminTransactionItemDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      productName: json['product_name']?.toString() ?? 'Menu Item',
      categoryName: json['category_name']?.toString() ?? '-',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString(),
      addons: rawAddons.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }
}

class AdminTransactionModel {
  final int id;
  final String invoiceNumber;
  final String customerName;
  final String? customerPhone;
  final String? tableNumber;
  final String orderType;
  final String orderSource;
  final String paymentMethod;
  final String paymentStatus;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double paid;
  final double change;
  final String status;
  final String? createdAt;
  final String cashierName;
  final int? cashierId;
  final int? shiftId;
  final String? shiftStatus;
  final AdminTransactionCancelledInfo? cancelledInfo;
  final List<AdminTransactionItemDetail> items;

  AdminTransactionModel({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    this.customerPhone,
    this.tableNumber,
    required this.orderType,
    required this.orderSource,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paid,
    required this.change,
    required this.status,
    this.createdAt,
    required this.cashierName,
    this.cashierId,
    this.shiftId,
    this.shiftStatus,
    this.cancelledInfo,
    this.items = const [],
  });

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isCancelled => status == 'cancelled';
  bool get isSelfOrder => orderSource == 'self_order';

  factory AdminTransactionModel.fromJson(Map<String, dynamic> json) {
    final cashier = json['cashier'] is Map ? json['cashier'] : {};
    final shift = json['shift'] is Map ? json['shift'] : {};
    final rawItems = (json['items'] as List?) ?? [];

    return AdminTransactionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? 'Pelanggan',
      customerPhone: json['customer_phone']?.toString(),
      tableNumber: json['table_number']?.toString(),
      orderType: json['order_type']?.toString() ?? 'dine_in',
      orderSource: json['order_source']?.toString() ?? 'pos',
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      paymentStatus: json['payment_status']?.toString() ?? 'paid',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paid: (json['paid'] as num?)?.toDouble() ?? 0.0,
      change: (json['change'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'completed',
      createdAt: json['created_at']?.toString(),
      cashierName: cashier['name']?.toString() ?? 'Kasir',
      cashierId: (cashier['id'] as num?)?.toInt(),
      shiftId: (shift['id'] as num?)?.toInt(),
      shiftStatus: shift['status']?.toString(),
      cancelledInfo: json['cancelled_info'] != null
          ? AdminTransactionCancelledInfo.fromJson(json['cancelled_info'])
          : null,
      items: rawItems.map((e) => AdminTransactionItemDetail.fromJson(e)).toList(),
    );
  }
}
