import 'dart:convert';
import '../../core/utils/date_formatter.dart';
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
    dynamic rawAddons = json['addons'] ??
        json['order_item_addons'] ??
        json['orderItemAddons'] ??
        json['item_addons'] ??
        json['selected_addons'] ??
        json['order_addons'];

    if (rawAddons is String && rawAddons.trim().isNotEmpty) {
      try {
        rawAddons = jsonDecode(rawAddons);
      } catch (_) {}
    }

    if (rawAddons != null && rawAddons is List) {
      for (final i in rawAddons) {
        if (i is Map) {
          addonsList.add(AddonModel.fromJson(Map<String, dynamic>.from(i)));
        } else if (i is String && i.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(i);
            if (decoded is Map) {
              addonsList.add(AddonModel.fromJson(Map<String, dynamic>.from(decoded)));
            } else {
              addonsList.add(AddonModel(id: 0, name: i.trim(), price: 0.0));
            }
          } catch (_) {
            addonsList.add(AddonModel(id: 0, name: i.trim(), price: 0.0));
          }
        }
      }
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
  String get formattedTime => DateFormatter.formatHourMinute(time);

  bool get isDineIn => orderType.toLowerCase() == 'dine_in';
  bool get isTakeAway => orderType.toLowerCase() == 'take_away';
  bool get hasCustomer => customerName != null && customerName!.trim().isNotEmpty;
  bool get hasTable => tableNumber != null && tableNumber!.trim().isNotEmpty;

  String get cleanTableNumber {
    if (!hasTable) return '';
    return tableNumber!.trim().replaceFirst(RegExp(r'^(meja|table)\s*', caseSensitive: false), '');
  }

  String get displayCustomerName {
    if (hasCustomer) return customerName!.trim();
    return '';
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    var detailsList = <TransactionDetailModel>[];
    if (json['details'] != null && json['details'] is List) {
      detailsList = (json['details'] as List)
          .map((i) => TransactionDetailModel.fromJson(
              i is Map<String, dynamic> ? i : Map<String, dynamic>.from(i)))
          .toList();
    }

    // Resolve Table Number
    String? resolvedTableNumber;
    final rawTable = json['table_number'] ??
        json['tableNumber'] ??
        json['no_meja'] ??
        json['table_no'];
    if (rawTable != null && rawTable.toString().trim().isNotEmpty) {
      resolvedTableNumber = rawTable.toString().trim();
    } else if (json['table'] != null) {
      if (json['table'] is Map) {
        final t = json['table'];
        final tVal = t['number'] ?? t['name'] ?? t['no'];
        if (tVal != null && tVal.toString().trim().isNotEmpty) {
          resolvedTableNumber = tVal.toString().trim();
        }
      } else if (json['table'].toString().trim().isNotEmpty) {
        resolvedTableNumber = json['table'].toString().trim();
      }
    }

    // Resolve Customer Name
    String? resolvedCustomerName;
    final rawCust = json['customer_name'] ??
        json['customerName'] ??
        json['nama_pelanggan'] ??
        json['customer'];
    if (rawCust != null && rawCust is! Map && rawCust.toString().trim().isNotEmpty) {
      resolvedCustomerName = rawCust.toString().trim();
    } else if (rawCust is Map) {
      final cName = rawCust['name'] ?? rawCust['nama'];
      if (cName != null && cName.toString().trim().isNotEmpty) {
        resolvedCustomerName = cName.toString().trim();
      }
    }

    return TransactionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      invoiceNumber: json['invoice_number'] ?? '',
      status: json['status'] ?? 'completed',
      orderType: json['order_type'] ?? 'dine_in',
      tableNumber: resolvedTableNumber,
      customerName: resolvedCustomerName,
      paymentMethod: (json['payment_method'] != null && json['payment_method'].toString().trim().isNotEmpty)
          ? json['payment_method'].toString().trim()
          : ((json['status']?.toString().toLowerCase() == 'pending') ? 'unpaid' : 'cash'),
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

class TransactionStatsModel {
  final int all;
  final int completed;
  final int pending;
  final int cancelled;

  TransactionStatsModel({
    required this.all,
    required this.completed,
    required this.pending,
    required this.cancelled,
  });

  factory TransactionStatsModel.fromJson(Map<String, dynamic> json) {
    return TransactionStatsModel(
      all: (json['all'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
    );
  }

  factory TransactionStatsModel.empty() {
    return TransactionStatsModel(
      all: 0,
      completed: 0,
      pending: 0,
      cancelled: 0,
    );
  }
}

