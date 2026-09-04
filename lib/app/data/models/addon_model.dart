import '../../core/utils/currency_formatter.dart';

class AddonModel {
  final int id;
  final String name;
  final double price;
  final double hargaBeli;
  final List<int> categoryIds;
  final List<String> categoryNames;
  final bool isActive;

  const AddonModel({
    required this.id,
    required this.name,
    required this.price,
    this.hargaBeli = 0.0,
    this.categoryIds = const [],
    this.categoryNames = const [],
    this.isActive = true,
  });

  factory AddonModel.fromJson(Map<String, dynamic> json) {
    List<int> catIds = [];
    if (json['category_ids'] != null && json['category_ids'] is List) {
      catIds = (json['category_ids'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e > 0)
          .toList();
    }

    List<String> catNames = [];
    if (json['category_names'] != null && json['category_names'] is List) {
      catNames = (json['category_names'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (json['categories'] != null && json['categories'] is List) {
      catNames = (json['categories'] as List)
          .map((e) => e is Map ? (e['name']?.toString() ?? '') : e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
      if (catIds.isEmpty) {
        catIds = (json['categories'] as List)
            .map((e) => e is Map ? (int.tryParse(e['id']?.toString() ?? '0') ?? 0) : 0)
            .where((e) => e > 0)
            .toList();
      }
    }

    return AddonModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? 'Add-on',
      price: (json['price'] != null)
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
      hargaBeli: (json['harga_beli'] != null)
          ? double.tryParse(json['harga_beli'].toString()) ?? 0.0
          : 0.0,
      categoryIds: catIds,
      categoryNames: catNames,
      isActive: json['is_active'] == 1 ||
          json['is_active'] == true ||
          json['is_active'] == null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'harga_beli': hargaBeli,
      'category_ids': categoryIds,
      'category_names': categoryNames,
      'is_active': isActive,
    };
  }

  /// Minimal payload sent to backend on checkout / save open bill
  Map<String, dynamic> toApiJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
    };
  }

  String get formattedPrice => CurrencyFormatter.format(price);

  String get formattedPriceWithPlus => '+ ${CurrencyFormatter.format(price)}';

  AddonModel copyWith({
    int? id,
    String? name,
    double? price,
    double? hargaBeli,
    List<int>? categoryIds,
    List<String>? categoryNames,
    bool? isActive,
  }) {
    return AddonModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      categoryIds: categoryIds ?? this.categoryIds,
      categoryNames: categoryNames ?? this.categoryNames,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddonModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
