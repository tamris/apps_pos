class AdminDashboardModel {
  final String date;
  final AdminSummaryModel summary;
  final AdminPaymentBreakdownModel paymentBreakdown;
  final AdminChannelBreakdownModel orderSourceBreakdown;
  final AdminOrderTypeBreakdownModel orderTypeBreakdown;
  final AdminActiveShiftModel? activeShift;
  final AdminOpenBillsSummaryModel openBillsSummary;
  final AdminCancellationsSummaryModel cancellationsSummary;

  AdminDashboardModel({
    required this.date,
    required this.summary,
    required this.paymentBreakdown,
    required this.orderSourceBreakdown,
    required this.orderTypeBreakdown,
    this.activeShift,
    required this.openBillsSummary,
    required this.cancellationsSummary,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      date: json['date']?.toString() ?? '',
      summary: AdminSummaryModel.fromJson(json['summary'] ?? {}),
      paymentBreakdown: AdminPaymentBreakdownModel.fromJson(json['payment_breakdown'] ?? {}),
      orderSourceBreakdown: AdminChannelBreakdownModel.fromJson(json['order_source_breakdown'] ?? {}),
      orderTypeBreakdown: AdminOrderTypeBreakdownModel.fromJson(json['order_type_breakdown'] ?? {}),
      activeShift: json['active_shift'] != null ? AdminActiveShiftModel.fromJson(json['active_shift']) : null,
      openBillsSummary: AdminOpenBillsSummaryModel.fromJson(json['open_bills_summary'] ?? {}),
      cancellationsSummary: AdminCancellationsSummaryModel.fromJson(json['cancellations_summary'] ?? {}),
    );
  }

  factory AdminDashboardModel.empty() {
    return AdminDashboardModel(
      date: '',
      summary: AdminSummaryModel.empty(),
      paymentBreakdown: AdminPaymentBreakdownModel.empty(),
      orderSourceBreakdown: AdminChannelBreakdownModel.empty(),
      orderTypeBreakdown: AdminOrderTypeBreakdownModel.empty(),
      activeShift: null,
      openBillsSummary: AdminOpenBillsSummaryModel.empty(),
      cancellationsSummary: AdminCancellationsSummaryModel.empty(),
    );
  }
}

class AdminSummaryModel {
  final double totalRevenue;
  final int totalTransactions;
  final double averagePerTransaction;

  AdminSummaryModel({
    required this.totalRevenue,
    required this.totalTransactions,
    required this.averagePerTransaction,
  });

  factory AdminSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminSummaryModel(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: (json['total_transactions'] as num?)?.toInt() ?? 0,
      averagePerTransaction: (json['average_per_transaction'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory AdminSummaryModel.empty() => AdminSummaryModel(
    totalRevenue: 0.0,
    totalTransactions: 0,
    averagePerTransaction: 0.0,
  );
}

class BreakdownItemModel {
  final String label;
  final double total;
  final int count;

  BreakdownItemModel({
    required this.label,
    required this.total,
    required this.count,
  });

  factory BreakdownItemModel.fromJson(Map<String, dynamic> json) {
    String rawLabel = json['label']?.toString() ?? '';
    if (rawLabel.toLowerCase().contains('dine')) {
      rawLabel = 'Dine-in';
    } else if (rawLabel.toLowerCase().contains('takeaway') ||
        rawLabel.toLowerCase().contains('take away') ||
        rawLabel.toLowerCase().contains('bungkus')) {
      rawLabel = 'Takeaway';
    }

    return BreakdownItemModel(
      label: rawLabel,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  factory BreakdownItemModel.empty(String defaultLabel) => BreakdownItemModel(
    label: defaultLabel,
    total: 0.0,
    count: 0,
  );
}

class AdminPaymentBreakdownModel {
  final BreakdownItemModel cash;
  final BreakdownItemModel qris;
  final BreakdownItemModel transfer;

  AdminPaymentBreakdownModel({
    required this.cash,
    required this.qris,
    required this.transfer,
  });

  factory AdminPaymentBreakdownModel.fromJson(Map<String, dynamic> json) {
    return AdminPaymentBreakdownModel(
      cash: BreakdownItemModel.fromJson(json['cash'] ?? {}),
      qris: BreakdownItemModel.fromJson(json['qris'] ?? {}),
      transfer: BreakdownItemModel.fromJson(json['transfer'] ?? {}),
    );
  }

  factory AdminPaymentBreakdownModel.empty() => AdminPaymentBreakdownModel(
    cash: BreakdownItemModel.empty('Uang Tunai (Laci Kasir)'),
    qris: BreakdownItemModel.empty('QRIS Digital'),
    transfer: BreakdownItemModel.empty('Transfer Bank'),
  );
}

class AdminChannelBreakdownModel {
  final BreakdownItemModel pos;
  final BreakdownItemModel onlineOrder;

  AdminChannelBreakdownModel({
    required this.pos,
    required this.onlineOrder,
  });

  factory AdminChannelBreakdownModel.fromJson(Map<String, dynamic> json) {
    return AdminChannelBreakdownModel(
      pos: BreakdownItemModel.fromJson(json['pos'] ?? {}),
      onlineOrder: BreakdownItemModel.fromJson(json['online_order'] ?? {}),
    );
  }

  factory AdminChannelBreakdownModel.empty() => AdminChannelBreakdownModel(
    pos: BreakdownItemModel.empty('Kasir POS'),
    onlineOrder: BreakdownItemModel.empty('Pesanan Online'),
  );
}

class AdminOrderTypeBreakdownModel {
  final BreakdownItemModel dineIn;
  final BreakdownItemModel takeaway;

  AdminOrderTypeBreakdownModel({
    required this.dineIn,
    required this.takeaway,
  });

  factory AdminOrderTypeBreakdownModel.fromJson(Map<String, dynamic> json) {
    return AdminOrderTypeBreakdownModel(
      dineIn: BreakdownItemModel.fromJson(json['dine_in'] ?? {}),
      takeaway: BreakdownItemModel.fromJson(json['takeaway'] ?? {}),
    );
  }

  factory AdminOrderTypeBreakdownModel.empty() => AdminOrderTypeBreakdownModel(
    dineIn: BreakdownItemModel.empty('Dine-in'),
    takeaway: BreakdownItemModel.empty('Takeaway'),
  );
}

class AdminActiveShiftModel {
  final int shiftId;
  final String cashierName;
  final int cashierId;
  final String? startTime;
  final double startingCash;
  final double cashSales;
  final double expectedCash;
  final double totalSales;
  final int totalTransactions;

  AdminActiveShiftModel({
    required this.shiftId,
    required this.cashierName,
    required this.cashierId,
    this.startTime,
    required this.startingCash,
    required this.cashSales,
    required this.expectedCash,
    required this.totalSales,
    required this.totalTransactions,
  });

  factory AdminActiveShiftModel.fromJson(Map<String, dynamic> json) {
    final cashier = json['cashier'] is Map ? json['cashier'] : {};
    return AdminActiveShiftModel(
      shiftId: (json['shift_id'] as num?)?.toInt() ?? 0,
      cashierName: json['cashier_name']?.toString() ?? cashier['name']?.toString() ?? 'Kasir',
      cashierId: (json['cashier_id'] as num?)?.toInt() ?? (cashier['id'] as num?)?.toInt() ?? 0,
      startTime: json['start_time']?.toString(),
      startingCash: (json['starting_cash'] as num?)?.toDouble() ?? 0.0,
      cashSales: (json['cash_sales'] as num?)?.toDouble() ?? 0.0,
      expectedCash: (json['expected_cash'] as num?)?.toDouble() ?? 0.0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: (json['total_transactions'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminOpenBillsSummaryModel {
  final int count;
  final double potentialRevenue;

  AdminOpenBillsSummaryModel({
    required this.count,
    required this.potentialRevenue,
  });

  factory AdminOpenBillsSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminOpenBillsSummaryModel(
      count: (json['count'] as num?)?.toInt() ?? 0,
      potentialRevenue: (json['potential_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory AdminOpenBillsSummaryModel.empty() => AdminOpenBillsSummaryModel(count: 0, potentialRevenue: 0.0);
}

class AdminCancellationsSummaryModel {
  final int count;
  final double totalNominal;

  AdminCancellationsSummaryModel({
    required this.count,
    required this.totalNominal,
  });

  factory AdminCancellationsSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminCancellationsSummaryModel(
      count: (json['count'] as num?)?.toInt() ?? 0,
      totalNominal: (json['total_nominal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory AdminCancellationsSummaryModel.empty() => AdminCancellationsSummaryModel(count: 0, totalNominal: 0.0);
}
