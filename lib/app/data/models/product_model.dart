import 'addon_model.dart';

class ProductModel {
  final int id;
  final int categoryId;
  final String categoryName;
  final String name;
  final String? sku;
  final String? barcode;
  final double price;
  final double hargaBeli;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final int totalSold;
  final List<AddonModel> availableAddons;

  ProductModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    this.sku,
    this.barcode,
    required this.price,
    this.hargaBeli = 0.0,
    this.description,
    this.imageUrl,
    this.isActive = true,
    this.totalSold = 0,
    this.availableAddons = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      categoryName:
          json['category_name'] ??
          (json['category'] != null ? json['category']['name'] : 'Menu'),
      name: json['name'] ?? '',
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
      price: (json['price'] != null)
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
      hargaBeli: (json['harga_beli'] != null)
          ? double.tryParse(json['harga_beli'].toString()) ?? 0.0
          : 0.0,
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['image']?.toString(),
      isActive:
          json['is_active'] == 1 ||
          json['is_active'] == true ||
          json['is_active'] == null,
      totalSold: json['total_sold'] is int
          ? json['total_sold']
          : int.tryParse(json['total_sold']?.toString() ?? '0') ?? 0,
      availableAddons: (json['available_addons'] != null && json['available_addons'] is List)
          ? (json['available_addons'] as List)
              .map((i) => AddonModel.fromJson(Map<String, dynamic>.from(i)))
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'category_name': categoryName,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'price': price,
      'harga_beli': hargaBeli,
      'description': description,
      'image_url': imageUrl,
      'is_active': isActive,
      'total_sold': totalSold,
      'available_addons': availableAddons.map((a) => a.toJson()).toList(),
    };
  }

  ProductModel copyWith({
    int? id,
    int? categoryId,
    String? categoryName,
    String? name,
    String? sku,
    String? barcode,
    double? price,
    double? hargaBeli,
    String? description,
    String? imageUrl,
    bool? isActive,
    int? totalSold,
    List<AddonModel>? availableAddons,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      totalSold: totalSold ?? this.totalSold,
      availableAddons: availableAddons ?? this.availableAddons,
    );
  }
}
