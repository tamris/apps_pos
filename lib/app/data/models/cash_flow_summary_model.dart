class CashFlowCategoryBreakdown {
  final String category;
  final double totalAmount;
  final int count;
  final double percentage;

  CashFlowCategoryBreakdown({
    required this.category,
    required this.totalAmount,
    required this.count,
    required this.percentage,
  });

  factory CashFlowCategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return CashFlowCategoryBreakdown(
      category: json['category']?.toString() ?? 'Lainnya',
      totalAmount: (json['total_amount'] != null)
          ? double.tryParse(json['total_amount'].toString()) ?? 0.0
          : 0.0,
      count: (json['count'] != null)
          ? int.tryParse(json['count'].toString()) ?? 0
          : 0,
      percentage: (json['percentage'] != null)
          ? double.tryParse(json['percentage'].toString()) ?? 0.0
          : 0.0,
    );
  }
}

class CashFlowSummaryModel {
  final String startDate;
  final String endDate;

  // Sales
  final double totalSales;
  final double cashSales;
  final double nonCashSales;

  // Cash In
  final double cashInTotal;
  final double cashInDrawer;
  final double cashInBank;

  // Cash Out
  final double cashOutTotal;
  final double cashOutDrawer;
  final double cashOutBank;
  final double cashOutPettyCash;

  // Net Cash Flow
  final double netCashFlow;

  // Real-Time Total Cash Balance (All-Time / Saldo Kas Nyata Toko - Tidak terpengaruh filter)
  final double totalRealBalance;
  final double cashBalance; // Saldo Tunai (Laci + Kas Toko)
  final double bankBalance; // Saldo Non-Tunai (Rekening Bank)
  final double totalInflow; // Total Pemasukan (Penjualan + Kas Masuk)

  // Breakdown
  final List<CashFlowCategoryBreakdown> categoryBreakdown;

  CashFlowSummaryModel({
    required this.startDate,
    required this.endDate,
    required this.totalSales,
    required this.cashSales,
    required this.nonCashSales,
    required this.cashInTotal,
    required this.cashInDrawer,
    required this.cashInBank,
    required this.cashOutTotal,
    required this.cashOutDrawer,
    required this.cashOutBank,
    required this.cashOutPettyCash,
    required this.netCashFlow,
    this.totalRealBalance = 0.0,
    this.cashBalance = 0.0,
    this.bankBalance = 0.0,
    this.totalInflow = 0.0,
    required this.categoryBreakdown,
  });

  bool get isSurplus => netCashFlow >= 0;

  factory CashFlowSummaryModel.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>? ?? {};
    final sales = json['sales'] as Map<String, dynamic>? ?? {};
    final cashIn = json['cash_in'] as Map<String, dynamic>? ?? {};
    final cashOut = json['cash_out'] as Map<String, dynamic>? ?? {};
    final totalBalance = json['total_balance'] as Map<String, dynamic>? ?? {};

    final breakdownList = <CashFlowCategoryBreakdown>[];
    if (json['category_breakdown'] is List) {
      for (final item in json['category_breakdown']) {
        if (item is Map<String, dynamic>) {
          breakdownList.add(CashFlowCategoryBreakdown.fromJson(item));
        }
      }
    }

    final double tSales = (sales['total_sales'] != null)
        ? double.tryParse(sales['total_sales'].toString()) ?? 0.0
        : 0.0;
    final double cInTotal = (cashIn['total'] != null)
        ? double.tryParse(cashIn['total'].toString()) ?? 0.0
        : 0.0;
    final double tInflow = (cashIn['total_inflow'] != null)
        ? double.tryParse(cashIn['total_inflow'].toString()) ?? (tSales + cInTotal)
        : (tSales + cInTotal);

    final double realBal = (totalBalance['real_balance'] != null)
        ? double.tryParse(totalBalance['real_balance'].toString()) ?? 0.0
        : 0.0;
    final double cashBal = (totalBalance['cash_balance'] != null)
        ? double.tryParse(totalBalance['cash_balance'].toString()) ?? 0.0
        : 0.0;
    final double bankBal = (totalBalance['bank_balance'] != null)
        ? double.tryParse(totalBalance['bank_balance'].toString()) ?? 0.0
        : 0.0;

    return CashFlowSummaryModel(
      startDate: period['start_date']?.toString() ?? '',
      endDate: period['end_date']?.toString() ?? '',
      totalSales: tSales,
      cashSales: (sales['cash_sales'] != null)
          ? double.tryParse(sales['cash_sales'].toString()) ?? 0.0
          : 0.0,
      nonCashSales: (sales['non_cash_sales'] != null)
          ? double.tryParse(sales['non_cash_sales'].toString()) ?? 0.0
          : 0.0,
      cashInTotal: cInTotal,
      cashInDrawer: (cashIn['drawer'] != null)
          ? double.tryParse(cashIn['drawer'].toString()) ?? 0.0
          : 0.0,
      cashInBank: (cashIn['bank'] != null)
          ? double.tryParse(cashIn['bank'].toString()) ?? 0.0
          : 0.0,
      cashOutTotal: (cashOut['total'] != null)
          ? double.tryParse(cashOut['total'].toString()) ?? 0.0
          : 0.0,
      cashOutDrawer: (cashOut['drawer'] != null)
          ? double.tryParse(cashOut['drawer'].toString()) ?? 0.0
          : 0.0,
      cashOutBank: (cashOut['bank'] != null)
          ? double.tryParse(cashOut['bank'].toString()) ?? 0.0
          : 0.0,
      cashOutPettyCash: (cashOut['petty_cash'] != null)
          ? double.tryParse(cashOut['petty_cash'].toString()) ?? 0.0
          : 0.0,
      netCashFlow: (json['net_cash_flow'] != null)
          ? double.tryParse(json['net_cash_flow'].toString()) ?? 0.0
          : 0.0,
      totalRealBalance: realBal,
      cashBalance: cashBal,
      bankBalance: bankBal,
      totalInflow: tInflow,
      categoryBreakdown: breakdownList,
    );
  }

  factory CashFlowSummaryModel.empty() {
    return CashFlowSummaryModel(
      startDate: '',
      endDate: '',
      totalSales: 0.0,
      cashSales: 0.0,
      nonCashSales: 0.0,
      cashInTotal: 0.0,
      cashInDrawer: 0.0,
      cashInBank: 0.0,
      cashOutTotal: 0.0,
      cashOutDrawer: 0.0,
      cashOutBank: 0.0,
      cashOutPettyCash: 0.0,
      netCashFlow: 0.0,
      totalRealBalance: 0.0,
      cashBalance: 0.0,
      bankBalance: 0.0,
      totalInflow: 0.0,
      categoryBreakdown: const [],
    );
  }
}
