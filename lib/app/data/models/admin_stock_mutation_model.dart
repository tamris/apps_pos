import 'package:intl/intl.dart';

class AdminStockMutationModel {
  final int id;
  final int ingredientId;
  final String ingredientName;
  final String type;
  final double amount;
  final double stockBefore;
  final double stockAfter;
  final String notes;
  final String userName;
  final String createdAt;

  const AdminStockMutationModel({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.type,
    required this.amount,
    required this.stockBefore,
    required this.stockAfter,
    this.notes = '',
    this.userName = 'Sistem',
    required this.createdAt,
  });

  bool get isIncrease =>
      amount > 0 ||
      type.toLowerCase() == 'restock' ||
      type.toLowerCase() == 'in_purchase' ||
      type.toLowerCase() == 'initial';

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'restock':
      case 'in_purchase':
        return 'Restock / Pembelian';
      case 'opname':
      case 'opname_adjustment':
        return isIncrease ? 'Opname (Fisik Lebih)' : 'Opname (Selisih Kurang)';
      case 'pos_usage':
      case 'sale':
      case 'out_sale':
      case 'usage':
        return 'Penjualan Menu POS';
      case 'waste':
      case 'damaged':
        final isPackaging = ingredientName.toLowerCase().contains('cup') ||
            ingredientName.toLowerCase().contains('plastik') ||
            ingredientName.toLowerCase().contains('sedotan') ||
            ingredientName.toLowerCase().contains('kemasan') ||
            ingredientName.toLowerCase().contains('dus') ||
            ingredientName.toLowerCase().contains('box');
        return isIncrease
            ? 'Opname (Koreksi Tambah)'
            : (isPackaging ? 'Barang Rusak / Cacat' : 'Bahan Rusak / Basi');
      case 'missing':
        return 'Selisih Hitung / Hilang';
      case 'expired':
        return 'Bahan Kadaluarsa';
      case 'initial':
        return 'Saldo Awal';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  String get formattedDateTime {
    if (createdAt.isEmpty) return '-';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return createdAt;
    }
  }

  factory AdminStockMutationModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'] ?? json['jumlah'] ?? 0;
    final rawBefore = json['stock_before'] ?? json['stok_sebelum'] ?? 0;
    final rawAfter = json['stock_after'] ?? json['stok_sesudah'] ?? 0;

    String parsedUserName = 'Admin';
    if (json['user'] != null && json['user'] is Map) {
      parsedUserName = (json['user']['name'] ?? 'Admin').toString();
    } else if (json['user_name'] != null) {
      parsedUserName = json['user_name'].toString();
    }

    String ingName = '';
    if (json['ingredient'] != null && json['ingredient'] is Map) {
      ingName = (json['ingredient']['name'] ?? '').toString();
    } else if (json['ingredient_name'] != null) {
      ingName = json['ingredient_name'].toString();
    }

    return AdminStockMutationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      ingredientId: json['ingredient_id'] is int
          ? json['ingredient_id']
          : int.tryParse(json['ingredient_id']?.toString() ?? '0') ?? 0,
      ingredientName: ingName,
      type: (json['type'] ?? json['tipe'] ?? 'mutasi').toString(),
      amount: double.tryParse(rawAmount.toString()) ?? 0.0,
      stockBefore: double.tryParse(rawBefore.toString()) ?? 0.0,
      stockAfter: double.tryParse(rawAfter.toString()) ?? 0.0,
      notes: (json['notes'] ?? json['catatan'] ?? '').toString(),
      userName: parsedUserName,
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}
