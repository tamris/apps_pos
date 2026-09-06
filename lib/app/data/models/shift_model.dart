class ShiftModel {
  final int id;
  final int? userId;
  final String status;
  final String? startTime;
  final String? endTime;
  final double startingCash;
  final double cashSales;
  final double qrisSales;
  final double transferSales;
  final double totalSales;
  final int totalTransactions;
  final double expectedCash;
  final double? actualCash;
  final double difference;
  final String notes;
  final int offlineTransactionsCount;
  final bool isOffline;

  ShiftModel({
    required this.id,
    this.userId,
    required this.status,
    this.startTime,
    this.endTime,
    required this.startingCash,
    this.cashSales = 0.0,
    this.qrisSales = 0.0,
    this.transferSales = 0.0,
    this.totalSales = 0.0,
    this.totalTransactions = 0,
    required this.expectedCash,
    this.actualCash,
    this.difference = 0.0,
    this.notes = '',
    this.offlineTransactionsCount = 0,
    this.isOffline = false,
  });

  bool get isOpen => status == 'open';

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0;
    final bool offlineFlag = json['is_offline'] == true || rawId <= 0;
    final int offCount = json['offline_transactions_count'] is int
        ? json['offline_transactions_count']
        : int.tryParse(json['offline_transactions_count']?.toString() ?? '0') ?? 0;

    return ShiftModel(
      id: rawId,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0'),
      status: json['status'] ?? 'open',
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      startingCash: (json['starting_cash'] != null)
          ? double.tryParse(json['starting_cash'].toString()) ?? 0.0
          : 0.0,
      cashSales: (json['cash_sales'] != null)
          ? double.tryParse(json['cash_sales'].toString()) ?? 0.0
          : 0.0,
      qrisSales: (json['qris_sales'] != null)
          ? double.tryParse(json['qris_sales'].toString()) ?? 0.0
          : 0.0,
      transferSales: (json['transfer_sales'] != null)
          ? double.tryParse(json['transfer_sales'].toString()) ?? 0.0
          : 0.0,
      totalSales: (json['total_sales'] != null)
          ? double.tryParse(json['total_sales'].toString()) ?? 0.0
          : 0.0,
      totalTransactions: json['total_transactions'] is int
          ? json['total_transactions']
          : int.tryParse(json['total_transactions']?.toString() ?? '0') ?? 0,
      expectedCash: (json['expected_cash'] != null)
          ? double.tryParse(json['expected_cash'].toString()) ?? 0.0
          : 0.0,
      actualCash: (json['actual_cash'] != null)
          ? double.tryParse(json['actual_cash'].toString())
          : null,
      difference: (json['difference'] != null)
          ? double.tryParse(json['difference'].toString()) ?? 0.0
          : 0.0,
      notes: json['notes']?.toString() ?? '',
      offlineTransactionsCount: offCount,
      isOffline: offlineFlag,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'start_time': startTime,
      'end_time': endTime,
      'starting_cash': startingCash,
      'cash_sales': cashSales,
      'qris_sales': qrisSales,
      'transfer_sales': transferSales,
      'total_sales': totalSales,
      'total_transactions': totalTransactions,
      'expected_cash': expectedCash,
      'actual_cash': actualCash,
      'difference': difference,
      'notes': notes,
      'offline_transactions_count': offlineTransactionsCount,
      'is_offline': isOffline,
    };
  }

  ShiftModel copyWith({
    int? id,
    int? userId,
    String? status,
    String? startTime,
    String? endTime,
    double? startingCash,
    double? cashSales,
    double? qrisSales,
    double? transferSales,
    double? totalSales,
    int? totalTransactions,
    double? expectedCash,
    double? actualCash,
    double? difference,
    String? notes,
    int? offlineTransactionsCount,
    bool? isOffline,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startingCash: startingCash ?? this.startingCash,
      cashSales: cashSales ?? this.cashSales,
      qrisSales: qrisSales ?? this.qrisSales,
      transferSales: transferSales ?? this.transferSales,
      totalSales: totalSales ?? this.totalSales,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      expectedCash: expectedCash ?? this.expectedCash,
      actualCash: actualCash ?? this.actualCash,
      difference: difference ?? this.difference,
      notes: notes ?? this.notes,
      offlineTransactionsCount: offlineTransactionsCount ?? this.offlineTransactionsCount,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  /// Update omset dan kas di laci saat terjadi transaksi offline baru
  ShiftModel recordSale({
    required double amount,
    required String paymentMethod,
  }) {
    final cleanMethod = paymentMethod.trim().toLowerCase();
    final isCash = cleanMethod == 'cash' || cleanMethod == 'tunai';
    final isQris = cleanMethod == 'qris';
    final isTransfer = cleanMethod == 'transfer' || cleanMethod == 'bank' || cleanMethod == 'debit';

    final newCashSales = isCash ? cashSales + amount : cashSales;
    final newQrisSales = isQris ? qrisSales + amount : qrisSales;
    final newTransferSales = isTransfer ? transferSales + amount : transferSales;
    final newTotalSales = totalSales + amount;
    final newTotalTransactions = totalTransactions + 1;
    final newExpectedCash = isCash ? expectedCash + amount : expectedCash;

    return copyWith(
      cashSales: newCashSales,
      qrisSales: newQrisSales,
      transferSales: newTransferSales,
      totalSales: newTotalSales,
      totalTransactions: newTotalTransactions,
      expectedCash: newExpectedCash,
      offlineTransactionsCount: offlineTransactionsCount + 1,
      isOffline: true,
    );
  }
}
