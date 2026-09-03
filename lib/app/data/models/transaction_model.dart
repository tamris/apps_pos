import 'addon_model.dart';

class TransactionDetailModel {
  final String name;
  final int quantity;
  final double price;
  final double subtotal;
  final String? notes;
  final List<AddonModel> addons;

  TransactionDetailModel({
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.notes,
    this.addons = const [],
  });

  factory TransactionDetailModel.fromJson(Map<String, dynamic> json) {
    var addonsList = <AddonModel>[];
    if (json['addons'] != null && json['addons'] is List) {
      addonsList = (json['addons'] as List)
          .map((i) => AddonModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }

    return TransactionDetailModel(
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
      addons: addonsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
      'notes': notes,
      'addons': addons.map((a) => a.toJson()).toList(),
    };
  }
}

class TransactionModel {
  final int id;
  final String invoiceNumber;
  final String status;
  final String orderType;
  final String? tableNumber;
  final String? customerName;
  final String paymentMethod;
  final double total;
  final double paid;
  final double change;
  final int itemsCount;
  final String time;
  final String date;
  final List<TransactionDetailModel> details;

  TransactionModel({
    required this.id,
    required this.invoiceNumber,
    required this.status,
    required this.orderType,
    this.tableNumber,
    this.customerName,
    required this.paymentMethod,
    required this.total,
    this.paid = 0.0,
    this.change = 0.0,
    this.itemsCount = 0,
    required this.time,
    required this.date,
    this.details = const [],
  });

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    var detailsList = <TransactionDetailModel>[];
    if (json['details'] != null && json['details'] is List) {
      detailsList = (json['details'] as List)
          .map((i) => TransactionDetailModel.fromJson(i))
          .toList();
    }

    return TransactionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      invoiceNumber: json['invoice_number'] ?? '',
      status: json['status'] ?? 'completed',
      orderType: json['order_type'] ?? 'dine_in',
      tableNumber: json['table_number']?.toString(),
      customerName: json['customer_name']?.toString(),
      paymentMethod: json['payment_method'] ?? 'cash',
      total: (json['total'] != null)
          ? double.tryParse(json['total'].toString()) ?? 0.0
          : 0.0,
      paid: (json['paid'] != null)
          ? double.tryParse(json['paid'].toString()) ?? 0.0
          : 0.0,
      change: (json['change'] != null)
          ? double.tryParse(json['change'].toString()) ?? 0.0
          : 0.0,
      itemsCount: json['items_count'] is int
          ? json['items_count']
          : int.tryParse(json['items_count']?.toString() ?? '0') ?? detailsList.length,
      time: json['time']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      details: detailsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'status': status,
      'order_type': orderType,
      'table_number': tableNumber,
      'customer_name': customerName,
      'payment_method': paymentMethod,
      'total': total,
      'paid': paid,
      'change': change,
      'items_count': itemsCount,
      'time': time,
      'date': date,
      'details': details.map((d) => d.toJson()).toList(),
    };
  }
}
