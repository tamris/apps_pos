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
    String itemName = json['name']?.toString() ?? json['product_name']?.toString() ?? '';
    if (itemName.isEmpty && json['product'] != null && json['product'] is Map) {
      itemName = json['product']['name']?.toString() ?? 'Menu';
    }
    if (itemName.isEmpty) itemName = 'Menu';

    int prodId = 0;
    if (json['product_id'] != null) {
      prodId = int.tryParse(json['product_id'].toString()) ?? 0;
    } else if (json['product'] != null && json['product'] is Map) {
      prodId = int.tryParse(json['product']['id']?.toString() ?? '0') ?? 0;
    }

    final qty = int.tryParse((json['quantity'] ?? json['qty'] ?? '1').toString()) ?? 1;
    final prc = double.tryParse((json['price'] ?? json['unit_price'] ?? '0').toString()) ?? 0.0;
    final sub = double.tryParse((json['subtotal'] ?? json['total_price'] ?? (qty * prc)).toString()) ?? (qty * prc);

    return OpenBillDetailItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      productId: prodId,
      name: itemName,
      quantity: qty,
      price: prc,
      subtotal: sub,
      notes: json['notes']?.toString() ?? json['note']?.toString(),
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
    final rawDetails = json['details'] ?? json['items'] ?? json['order_items'] ?? json['transaction_details'];
    if (rawDetails != null && rawDetails is List) {
      detailsList = rawDetails
          .map((i) => OpenBillDetailItem.fromJson(i is Map<String, dynamic> ? i : Map<String, dynamic>.from(i)))
          .toList();
    }

    final tot = double.tryParse((json['total'] ?? json['grand_total'] ?? json['total_amount'] ?? '0').toString()) ?? 0.0;
    final sub = double.tryParse((json['subtotal'] ?? '0').toString()) ?? (tot > 0 ? tot : 0.0);
    final disc = double.tryParse((json['discount'] ?? json['discount_amount'] ?? '0').toString()) ?? 0.0;
    final tx = double.tryParse((json['tax'] ?? json['tax_amount'] ?? '0').toString()) ?? 0.0;

    return OpenBillModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      invoiceNumber: json['invoice_number']?.toString() ?? json['order_number']?.toString() ?? '',
      orderType: json['order_type']?.toString() ?? 'dine_in',
      tableNumber: json['table_number']?.toString() ?? json['table']?.toString(),
      customerName: json['customer_name']?.toString() ?? json['customer']?.toString(),
      total: tot,
      subtotal: sub,
      discount: disc,
      tax: tx,
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
