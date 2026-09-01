class OpenBillDetailItem {
  final int id;
  final int productId;
  final String name;
  final int quantity;
  final double price;
  final double subtotal;
  final String? notes;

  OpenBillDetailItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.notes,
  });

  factory OpenBillDetailItem.fromJson(Map<String, dynamic> json) {
    return OpenBillDetailItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: json['product_id'] is int
          ? json['product_id']
          : int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? 'Menu',
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      price: (json['price'] != null)
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
      subtotal: (json['subtotal'] != null)
          ? double.tryParse(json['subtotal'].toString()) ?? 0.0
          : 0.0,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
      'notes': notes,
    };
  }
}

class OpenBillModel {
  final int id;
  final String invoiceNumber;
  final String orderType;
  final String? tableNumber;
  final String? customerName;
  final double total;
  final double subtotal;
  final double discount;
  final double tax;
  final int itemsCount;
  final String createdAt;
  final List<OpenBillDetailItem> details;

  OpenBillModel({
    required this.id,
    required this.invoiceNumber,
    this.orderType = 'dine_in',
    this.tableNumber,
    this.customerName,
    required this.total,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.tax = 0.0,
    this.itemsCount = 0,
    required this.createdAt,
    this.details = const [],
  });

  String get billTitle {
    if (tableNumber != null && tableNumber!.isNotEmpty) {
      return 'Meja $tableNumber';
    }
    if (customerName != null && customerName!.isNotEmpty) {
      return customerName!;
    }
    return invoiceNumber;
  }

  factory OpenBillModel.fromJson(Map<String, dynamic> json) {
    var detailsList = <OpenBillDetailItem>[];
    if (json['details'] != null && json['details'] is List) {
      detailsList = (json['details'] as List)
          .map((i) => OpenBillDetailItem.fromJson(i))
          .toList();
    }

    return OpenBillModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      invoiceNumber: json['invoice_number'] ?? '',
      orderType: json['order_type'] ?? 'dine_in',
      tableNumber: json['table_number']?.toString(),
      customerName: json['customer_name']?.toString(),
      total: (json['total'] != null)
          ? double.tryParse(json['total'].toString()) ?? 0.0
          : 0.0,
      subtotal: (json['subtotal'] != null)
          ? double.tryParse(json['subtotal'].toString()) ?? 0.0
          : 0.0,
      discount: (json['discount'] != null)
          ? double.tryParse(json['discount'].toString()) ?? 0.0
          : 0.0,
      tax: (json['tax'] != null)
          ? double.tryParse(json['tax'].toString()) ?? 0.0
          : 0.0,
      itemsCount: json['items_count'] is int
          ? json['items_count']
          : int.tryParse(json['items_count']?.toString() ?? '0') ?? detailsList.length,
      createdAt: json['created_at']?.toString() ?? '',
      details: detailsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'order_type': orderType,
      'table_number': tableNumber,
      'customer_name': customerName,
      'total': total,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'items_count': itemsCount,
      'created_at': createdAt,
      'details': details.map((d) => d.toJson()).toList(),
    };
  }
}
