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
  });

  bool get isOpen => status == 'open';

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
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
    };
  }
}
