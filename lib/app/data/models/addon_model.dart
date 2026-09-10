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
    // Periksa jika data bersarang di dalam relasi 'addon' (misal pivot / eager load Laravel)
    final Map<String, dynamic> source = (json['addon'] != null && json['addon'] is Map)
        ? Map<String, dynamic>.from(json['addon'])
        : json;

    List<int> catIds = [];
    final rawCatIds = source['category_ids'] ?? json['category_ids'];
    if (rawCatIds != null && rawCatIds is List) {
      catIds = rawCatIds
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((e) => e > 0)
          .toList();
    }

    List<String> catNames = [];
    final rawCatNames = source['category_names'] ?? json['category_names'];
    final rawCategories = source['categories'] ?? json['categories'];
    if (rawCatNames != null && rawCatNames is List) {
      catNames = rawCatNames
          .map((e) => e.toString())
          .toList();
    } else if (rawCategories != null && rawCategories is List) {
      catNames = rawCategories
          .map((e) => e is Map ? (e['name']?.toString() ?? '') : e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
      if (catIds.isEmpty) {
        catIds = rawCategories
            .map((e) => e is Map ? (int.tryParse(e['id']?.toString() ?? '0') ?? 0) : 0)
            .where((e) => e > 0)
            .toList();
      }
    }

    final idVal = source['id'] ?? json['addon_id'] ?? json['id'];
    final nameVal = source['name'] ?? json['addon_name'] ?? json['name'] ?? 'Add-on';
    final priceVal = source['price'] ?? json['addon_price'] ?? json['unit_price'] ?? json['subtotal'] ?? json['price'] ?? 0.0;
    final hgBeliVal = source['harga_beli'] ?? json['harga_beli'] ?? 0.0;
    final isActiveVal = source['is_active'] ?? json['is_active'];

    return AddonModel(
      id: idVal is int ? idVal : int.tryParse(idVal?.toString() ?? '0') ?? 0,
      name: nameVal.toString(),
      price: double.tryParse(priceVal.toString()) ?? 0.0,
      hargaBeli: double.tryParse(hgBeliVal.toString()) ?? 0.0,
      categoryIds: catIds,
      categoryNames: catNames,
      isActive: isActiveVal == 1 ||
          isActiveVal == true ||
          isActiveVal == null ||
          isActiveVal == '1',
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
