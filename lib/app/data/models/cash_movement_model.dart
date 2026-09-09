class CashMovementModel {
  final int id;
  final String movementNumber;
  final String type; // 'in' (Kas Masuk) or 'out' (Kas Keluar)
  final String typeLabel;
  final String source; // 'drawer', 'bank', 'petty_cash'
  final String sourceLabel;
  final double amount;
  final String? amountFormatted;
  final int? categoryId;
  final String categoryName;
  final String notes;
  final String? receiptImage;
  final String? receiptImageUrl;
  final String? movementDate;
  final String? movementDateFormatted;
  final int? userId;
  final String cashierName;
  final int? shiftId;
  final String? createdAt;

  CashMovementModel({
    required this.id,
    required this.movementNumber,
    required this.type,
    required this.typeLabel,
    required this.source,
    required this.sourceLabel,
    required this.amount,
    this.amountFormatted,
    this.categoryId,
    required this.categoryName,
    required this.notes,
    this.receiptImage,
    this.receiptImageUrl,
    this.movementDate,
    this.movementDateFormatted,
    this.userId,
    this.cashierName = 'Kasir',
    this.shiftId,
    this.createdAt,
  });

  bool get isOut => type == 'out';
  bool get isIn => type == 'in';
  bool get hasReceiptImage => receiptImageUrl != null && receiptImageUrl!.isNotEmpty;

  factory CashMovementModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] is Map ? json['user'] as Map<String, dynamic> : null;
    final String cName = userMap?['name']?.toString() ?? json['cashier_name']?.toString() ?? 'Kasir';
    final int? uId = userMap?['id'] is int ? userMap!['id'] : int.tryParse(userMap?['id']?.toString() ?? '');

    return CashMovementModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      movementNumber: json['movement_number']?.toString() ?? '',
      type: json['type']?.toString() ?? 'out',
      typeLabel: json['type_label']?.toString() ?? (json['type'] == 'in' ? 'Kas Masuk' : 'Kas Keluar'),
      source: json['source']?.toString() ?? 'drawer',
      sourceLabel: json['source_label']?.toString() ?? 'Laci Kasir',
      amount: (json['amount'] != null)
          ? double.tryParse(json['amount'].toString()) ?? 0.0
          : 0.0,
      amountFormatted: json['amount_formatted']?.toString(),
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id']?.toString() ?? ''),
      categoryName: json['category_name']?.toString() ?? 'Pengeluaran',
      notes: json['notes']?.toString() ?? '',
      receiptImage: json['receipt_image']?.toString(),
      receiptImageUrl: json['receipt_image_url']?.toString(),
      movementDate: json['movement_date']?.toString(),
      movementDateFormatted: json['movement_date_formatted']?.toString(),
      userId: uId,
      cashierName: cName,
      shiftId: json['shift_id'] is int
          ? json['shift_id']
          : int.tryParse(json['shift_id']?.toString() ?? ''),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movement_number': movementNumber,
      'type': type,
      'type_label': typeLabel,
      'source': source,
      'source_label': sourceLabel,
      'amount': amount,
      'amount_formatted': amountFormatted,
      'category_id': categoryId,
      'category_name': categoryName,
      'notes': notes,
      'receipt_image': receiptImage,
      'receipt_image_url': receiptImageUrl,
      'movement_date': movementDate,
      'movement_date_formatted': movementDateFormatted,
      'user': {
        'id': userId,
        'name': cashierName,
      },
      'shift_id': shiftId,
      'created_at': createdAt,
    };
  }
}
