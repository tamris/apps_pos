import 'product_ingredient_model.dart';
import 'hpp_calculation_model.dart';

class AdminProductModel {
  final int id;
  final String name;
  final String sku;
  final String? barcode;
  final int categoryId;
  final String categoryName;
  final String? description;
  final double price;
  final double hargaBeli;
  final double operationalCost;
  final double profit;
  final double marginPercent;
  final double foodCostPercent;
  final bool isHealthyMargin;
  final bool isActive;
  final bool isArchived;
  final String? image;
  final String? imageUrl;
  final int ingredientsCount;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? pricingMetadata;
  final List<ProductIngredientModel> ingredients;
  final HppCalculationModel? hppAnalysis;
  final int? estimatedStock;
  final String? bottleneckIngredient;

  AdminProductModel({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    required this.categoryId,
    required this.categoryName,
    this.description,
    required this.price,
    this.hargaBeli = 0.0,
    this.operationalCost = 0.0,
    this.profit = 0.0,
    this.marginPercent = 0.0,
    this.foodCostPercent = 0.0,
    this.isHealthyMargin = true,
    this.isActive = true,
    this.isArchived = false,
    this.image,
    this.imageUrl,
    this.ingredientsCount = 0,
    this.createdAt,
    this.updatedAt,
    this.pricingMetadata,
    this.ingredients = const [],
    this.hppAnalysis,
    this.estimatedStock,
    this.bottleneckIngredient,
  });

  factory AdminProductModel.fromJson(Map<String, dynamic> json) {
    final priceVal = double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;
    final hppVal = double.tryParse(json['harga_beli']?.toString() ?? '0') ?? 0.0;
    final profitVal = (json['profit'] != null)
        ? (double.tryParse(json['profit'].toString()) ?? (priceVal - hppVal))
        : (priceVal - hppVal);
    final marginVal = (json['margin_percent'] != null)
        ? (double.tryParse(json['margin_percent'].toString()) ?? 0.0)
        : (priceVal > 0 ? ((profitVal / priceVal) * 100) : 0.0);
    final foodCostVal = (json['food_cost_percent'] != null)
        ? (double.tryParse(json['food_cost_percent'].toString()) ?? 0.0)
        : (priceVal > 0 ? ((hppVal / priceVal) * 100) : 0.0);

    final rawIngredients = json['ingredients'];
    List<ProductIngredientModel> parsedIngredients = [];
    if (rawIngredients is List) {
      parsedIngredients = rawIngredients
          .whereType<Map>()
          .map((item) => ProductIngredientModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    HppCalculationModel? parsedHppAnalysis;
    if (json['hpp_analysis'] is Map) {
      parsedHppAnalysis = HppCalculationModel.fromJson(Map<String, dynamic>.from(json['hpp_analysis']));
    }

    return AdminProductModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      barcode: json['barcode']?.toString(),
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      categoryName: json['category_name']?.toString() ??
          (json['category'] != null ? json['category']['name']?.toString() ?? 'Uncategorized' : 'Uncategorized'),
      description: json['description']?.toString(),
      price: priceVal,
      hargaBeli: hppVal,
      operationalCost: double.tryParse(json['operational_cost']?.toString() ?? '0') ?? 0.0,
      profit: profitVal < 0 ? 0 : profitVal,
      marginPercent: marginVal,
      foodCostPercent: foodCostVal,
      isHealthyMargin: json['is_healthy_margin'] == true || marginVal >= 45.0,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == null,
      isArchived: json['is_archived'] == true ||
          json['is_archived'] == 1 ||
          json['status'] == 'archived' ||
          json['deleted_at'] != null,
      image: json['image']?.toString(),
      imageUrl: json['image_url']?.toString(),
      ingredientsCount: json['ingredients_count'] is int
          ? json['ingredients_count']
          : parsedIngredients.length,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      pricingMetadata: json['pricing_metadata'] is Map ? Map<String, dynamic>.from(json['pricing_metadata']) : null,
      ingredients: parsedIngredients,
      hppAnalysis: parsedHppAnalysis,
      estimatedStock: json['estimated_stock'] != null
          ? (double.tryParse(json['estimated_stock'].toString())?.toInt())
          : null,
      bottleneckIngredient: json['bottleneck_ingredient']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'category_id': categoryId,
      'category_name': categoryName,
      'description': description,
      'price': price,
      'harga_beli': hargaBeli,
      'operational_cost': operationalCost,
      'profit': profit,
      'margin_percent': marginPercent,
      'food_cost_percent': foodCostPercent,
      'is_healthy_margin': isHealthyMargin,
      'is_active': isActive,
      'is_archived': isArchived,
      'image': image,
      'image_url': imageUrl,
      'ingredients_count': ingredientsCount,
      'estimated_stock': estimatedStock,
      'bottleneck_ingredient': bottleneckIngredient,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'pricing_metadata': pricingMetadata,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'hpp_analysis': hppAnalysis?.toJson(),
    };
  }

  AdminProductModel copyWith({
    int? id,
    String? name,
    String? sku,
    String? barcode,
    int? categoryId,
    String? categoryName,
    String? description,
    double? price,
    double? hargaBeli,
    double? operationalCost,
    double? profit,
    double? marginPercent,
    double? foodCostPercent,
    bool? isHealthyMargin,
    bool? isActive,
    bool? isArchived,
    String? image,
    String? imageUrl,
    int? ingredientsCount,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic>? pricingMetadata,
    List<ProductIngredientModel>? ingredients,
    HppCalculationModel? hppAnalysis,
    int? estimatedStock,
    String? bottleneckIngredient,
  }) {
    return AdminProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      description: description ?? this.description,
      price: price ?? this.price,
      hargaBeli: hargaBeli ?? this.hargaBeli,
      operationalCost: operationalCost ?? this.operationalCost,
      profit: profit ?? this.profit,
      marginPercent: marginPercent ?? this.marginPercent,
      foodCostPercent: foodCostPercent ?? this.foodCostPercent,
      isHealthyMargin: isHealthyMargin ?? this.isHealthyMargin,
      isActive: isActive ?? this.isActive,
      isArchived: isArchived ?? this.isArchived,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredientsCount: ingredientsCount ?? this.ingredientsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pricingMetadata: pricingMetadata ?? this.pricingMetadata,
      ingredients: ingredients ?? this.ingredients,
      hppAnalysis: hppAnalysis ?? this.hppAnalysis,
      estimatedStock: estimatedStock ?? this.estimatedStock,
      bottleneckIngredient: bottleneckIngredient ?? this.bottleneckIngredient,
    );
  }
}
