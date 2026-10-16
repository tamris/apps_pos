class CustomerModel {
  final int id;
  final String? name;
  final String phone;
  final int pointsBalance;
  final double pointsRupiahValue;
  final String pointsRupiahFormatted;
  final bool canRedeem;
  final int minRedeem;
  final int exchangeRate;
  final String? createdAt;

  CustomerModel({
    required this.id,
    this.name,
    required this.phone,
    this.pointsBalance = 0,
    this.pointsRupiahValue = 0.0,
    this.pointsRupiahFormatted = 'Rp 0',
    this.canRedeem = false,
    this.minRedeem = 5,
    this.exchangeRate = 1000,
    this.createdAt,
  });

  String get displayName => (name != null && name!.trim().isNotEmpty)
      ? name!.trim()
      : 'Member ($formattedPhone)';

  String get initials {
    if (name != null && name!.trim().isNotEmpty) {
      final parts = name!.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name!.trim().substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'MB';
  }

  String get formattedPhone {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('62') && clean.length > 9) {
      return '0${clean.substring(2, 5)}-${clean.substring(5, 9)}-${clean.substring(9)}';
    } else if (clean.startsWith('0') && clean.length > 8) {
      if (clean.length == 10) {
        return '${clean.substring(0, 4)}-${clean.substring(4, 7)}-${clean.substring(7)}';
      } else if (clean.length == 11) {
        return '${clean.substring(0, 4)}-${clean.substring(4, 8)}-${clean.substring(8)}';
      } else if (clean.length >= 12) {
        return '${clean.substring(0, 4)}-${clean.substring(4, 8)}-${clean.substring(8)}';
      }
    }
    return phone;
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString(),
      phone: json['phone']?.toString() ?? '',
      pointsBalance: json['points_balance'] is int
          ? json['points_balance']
          : int.tryParse(json['points_balance']?.toString() ?? '0') ?? 0,
      pointsRupiahValue: (json['points_rupiah_value'] != null)
          ? double.tryParse(json['points_rupiah_value'].toString()) ?? 0.0
          : 0.0,
      pointsRupiahFormatted: json['points_rupiah_formatted']?.toString() ?? 'Rp 0',
      canRedeem: json['can_redeem'] == true || json['can_redeem'] == 1,
      minRedeem: json['min_redeem'] is int
          ? json['min_redeem']
          : int.tryParse(json['min_redeem']?.toString() ?? '5') ?? 5,
      exchangeRate: json['exchange_rate'] is int
          ? json['exchange_rate']
          : int.tryParse(json['exchange_rate']?.toString() ?? '1000') ?? 1000,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'points_balance': pointsBalance,
      'points_rupiah_value': pointsRupiahValue,
      'points_rupiah_formatted': pointsRupiahFormatted,
      'can_redeem': canRedeem,
      'min_redeem': minRedeem,
      'exchange_rate': exchangeRate,
      'created_at': createdAt,
    };
  }

  CustomerModel copyWith({
    int? id,
    String? name,
    String? phone,
    int? pointsBalance,
    double? pointsRupiahValue,
    String? pointsRupiahFormatted,
    bool? canRedeem,
    int? minRedeem,
    int? exchangeRate,
    String? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      pointsBalance: pointsBalance ?? this.pointsBalance,
      pointsRupiahValue: pointsRupiahValue ?? this.pointsRupiahValue,
      pointsRupiahFormatted: pointsRupiahFormatted ?? this.pointsRupiahFormatted,
      canRedeem: canRedeem ?? this.canRedeem,
      minRedeem: minRedeem ?? this.minRedeem,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
