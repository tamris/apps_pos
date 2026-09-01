import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

class OnlineOrderStatsModel {
  final int active;
  final int pending;
  final int processing;
  final int ready;
  final int completedToday;
  final int cancelledToday;
  final double revenueToday;
  final String formattedRevenueToday;
  final bool isOnlineOrderActive;

  OnlineOrderStatsModel({
    required this.active,
    required this.pending,
    required this.processing,
    required this.ready,
    required this.completedToday,
    required this.cancelledToday,
    required this.revenueToday,
    required this.formattedRevenueToday,
    required this.isOnlineOrderActive,
  });

  factory OnlineOrderStatsModel.fromJson(Map<String, dynamic> json) {
    final revenue = (json['revenue_today'] as num?)?.toDouble() ?? 0.0;
    return OnlineOrderStatsModel(
      active: (json['active'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      processing: (json['processing'] as num?)?.toInt() ?? 0,
      ready: (json['ready'] as num?)?.toInt() ?? 0,
      completedToday: (json['completed_today'] as num?)?.toInt() ?? 0,
      cancelledToday: (json['cancelled_today'] as num?)?.toInt() ?? 0,
      revenueToday: revenue,
      formattedRevenueToday: json['formatted_revenue_today'] ?? CurrencyFormatter.format(revenue),
      isOnlineOrderActive: json['is_online_order_active'] == true,
    );
  }

  factory OnlineOrderStatsModel.empty() {
    return OnlineOrderStatsModel(
      active: 0,
      pending: 0,
      processing: 0,
      ready: 0,
      completedToday: 0,
      cancelledToday: 0,
      revenueToday: 0.0,
      formattedRevenueToday: 'Rp 0',
      isOnlineOrderActive: true,
    );
  }
}

class OnlineOrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final double price;
  final double subtotal;
  final String notes;

  OnlineOrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.notes,
  });

  factory OnlineOrderItemModel.fromJson(Map<String, dynamic> json) {
    return OnlineOrderItemModel(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? json['name'] ?? 'Menu',
      productImage: json['product_image'] ?? json['image_url'],
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] ?? '',
    );
  }

  String get formattedPrice => CurrencyFormatter.format(price);
  String get formattedSubtotal => CurrencyFormatter.format(subtotal);
}

class OnlineOrderModel {
  final int id;
  final String invoiceNumber;
  final String shortOrderNumber;
  final String? orderToken;
  final String orderSource;
  final String orderType;
  final String? tableNumber;
  final String customerName;
  final String customerPhone;
  final String status;
  final String statusLabel;
  final String paymentStatus;
  final String paymentMethod;
  final double subtotal;
  final double discountPercent;
  final double discountAmount;
  final double taxPercent;
  final double taxAmount;
  final double total;
  final double paid;
  final double change;
  final int itemsCount;
  final int totalQty;
  final List<OnlineOrderItemModel> items;
  final String createdAt;
  final String? timeAgo;
  final String? cancelledReason;
  final String? cancelledAt;

  OnlineOrderModel({
    required this.id,
    required this.invoiceNumber,
    required this.shortOrderNumber,
    this.orderToken,
    required this.orderSource,
    required this.orderType,
    this.tableNumber,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.statusLabel,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.subtotal,
    required this.discountPercent,
    required this.discountAmount,
    required this.taxPercent,
    required this.taxAmount,
    required this.total,
    required this.paid,
    required this.change,
    required this.itemsCount,
    required this.totalQty,
    required this.items,
    required this.createdAt,
    this.timeAgo,
    this.cancelledReason,
    this.cancelledAt,
  });

  factory OnlineOrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return OnlineOrderModel(
      id: json['id'] ?? 0,
      invoiceNumber: json['invoice_number'] ?? '',
      shortOrderNumber: json['short_order_number'] ?? '#${json['id']}',
      orderToken: json['order_token'],
      orderSource: json['order_source'] ?? 'self_order',
      orderType: json['order_type'] ?? 'dine_in',
      tableNumber: json['table_number']?.toString(),
      customerName: json['customer_name'] ?? 'Pelanggan',
      customerPhone: json['customer_phone'] ?? '',
      status: json['status'] ?? 'pending',
      statusLabel: json['status_label'] ?? _getDefaultStatusLabel(json['status']),
      paymentStatus: json['payment_status'] ?? 'paid',
      paymentMethod: json['payment_method'] ?? 'qris',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxPercent: (json['tax_percent'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      paid: (json['paid'] as num?)?.toDouble() ?? 0.0,
      change: (json['change'] as num?)?.toDouble() ?? 0.0,
      itemsCount: (json['items_count'] as num?)?.toInt() ?? rawItems.length,
      totalQty: (json['total_qty'] as num?)?.toInt() ?? 0,
      items: rawItems.map((e) => OnlineOrderItemModel.fromJson(e)).toList(),
      createdAt: json['created_at'] ?? '',
      timeAgo: json['time_ago'],
      cancelledReason: json['cancelled_reason'],
      cancelledAt: json['cancelled_at'],
    );
  }

  static String _getDefaultStatusLabel(String? status) {
    switch (status) {
      case 'processing':
        return 'Sedang Disiapkan';
      case 'ready':
        return 'Siap Diantar/Diambil';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'pending':
      default:
        return 'Menunggu Diproses';
    }
  }

  // Getters & Helpers
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isReady => status == 'ready';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => isPending || isProcessing || isReady;

  bool get isDineIn => orderType.toLowerCase().contains('dine');
  bool get isTakeAway => orderType.toLowerCase().contains('take') || orderType.toLowerCase().contains('bungkus');

  String get formattedTotal => CurrencyFormatter.format(total);
  String get formattedSubtotal => CurrencyFormatter.format(subtotal);
  String get formattedDiscount => CurrencyFormatter.format(discountAmount);
  String get formattedTax => CurrencyFormatter.format(taxAmount);

  Color get statusColor {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'processing':
        return AppColors.info;
      case 'ready':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  Color get statusSoftColor {
    switch (status) {
      case 'pending':
        return AppColors.warningSoft;
      case 'processing':
        return AppColors.infoSoft;
      case 'ready':
        return AppColors.primarySoft;
      case 'completed':
        return AppColors.successSoft;
      case 'cancelled':
        return AppColors.dangerSoft;
      default:
        return AppColors.lightBackground;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return Icons.notifications_active_rounded;
      case 'processing':
        return Icons.soup_kitchen_rounded;
      case 'ready':
        return Icons.check_circle_outline_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded;
    }
  }

  OnlineOrderModel copyWith({
    String? status,
    String? statusLabel,
    String? cancelledReason,
  }) {
    return OnlineOrderModel(
      id: id,
      invoiceNumber: invoiceNumber,
      shortOrderNumber: shortOrderNumber,
      orderToken: orderToken,
      orderSource: orderSource,
      orderType: orderType,
      tableNumber: tableNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      discountPercent: discountPercent,
      discountAmount: discountAmount,
      taxPercent: taxPercent,
      taxAmount: taxAmount,
      total: total,
      paid: paid,
      change: change,
      itemsCount: itemsCount,
      totalQty: totalQty,
      items: items,
      createdAt: createdAt,
      timeAgo: timeAgo,
      cancelledReason: cancelledReason ?? this.cancelledReason,
      cancelledAt: cancelledAt,
    );
  }
}
