class IngredientUsageModel {
  final int productId;
  final String productName;
  final String categoryName;
  final double amount;
  final String unit;
  final double subtotal;

  const IngredientUsageModel({
    required this.productId,
    required this.productName,
    required this.categoryName,
    required this.amount,
    required this.unit,
    required this.subtotal,
  });

  factory IngredientUsageModel.fromJson(Map<String, dynamic> json) {
    return IngredientUsageModel(
      productId: int.tryParse(json['product_id']?.toString() ?? '0') ?? 0,
      productName: (json['product_name'] ?? 'Menu').toString(),
      categoryName: (json['category_name'] ?? 'Umum').toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      unit: (json['unit'] ?? 'gram').toString(),
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'category_name': categoryName,
      'amount': amount,
      'unit': unit,
      'subtotal': subtotal,
    };
  }
}

class AdminIngredientModel {
  final int id;
  final String name;
  final String category;
  final String sku;
  final double stock;
  final String unit;
  final double minStock;
  final double costPerUnit;
  final double buyPrice;
  final double buyAmount;
  final String buyUnit;
  final bool isActive;
  final int productsCount;
  final List<IngredientUsageModel> usedInProducts;
  final String? createdAt;
  final String? updatedAt;

  const AdminIngredientModel({
    required this.id,
    required this.name,
    this.category = 'Umum',
    this.sku = '',
    required this.stock,
    required this.unit,
    this.minStock = 0.0,
    required this.costPerUnit,
    this.buyPrice = 0.0,
    this.buyAmount = 1.0,
    this.buyUnit = 'gram',
    this.isActive = true,
    this.productsCount = 0,
    this.usedInProducts = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isDebtStock => stock < 0;
  bool get isZeroStock => stock == 0;
  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= minStock;
  bool get isSafe => stock > minStock;
  double get debtAmount => stock < 0 ? stock.abs() : 0.0;

  bool get isPerishable {
    final cat = category.toLowerCase();
    final n = name.toLowerCase();

    if (cat.contains('kemasan') ||
        cat.contains('cup') ||
        cat.contains('packaging') ||
        cat.contains('alat') ||
        cat.contains('perlengkapan')) {
      return false;
    }

    if (n.contains('cup') ||
        n.contains('tutup') ||
        n.contains('sedotan') ||
        n.contains('straw') ||
        n.contains('plastik') ||
        n.contains('paper') ||
        n.contains('kantong') ||
        n.contains('kresek') ||
        n.contains('dus') ||
        n.contains('box') ||
        n.contains('sealer') ||
        n.contains('lid') ||
        n.contains('tisue') ||
        n.contains('tissue') ||
        n.contains('sendok') ||
        n.contains('garpu') ||
        n.contains('sarung tangan')) {
      return false;
    }

    return true;
  }

  double get totalInventoryValue => stock > 0 ? (stock * costPerUnit) : 0.0;

  String get formattedStock {
    if (stock % 1 == 0) {
      return stock.toInt().toString();
    }
    return stock.toStringAsFixed(1);
  }

  String get formattedMinStock {
    if (minStock % 1 == 0) {
      return minStock.toInt().toString();
    }
    return minStock.toStringAsFixed(1);
  }

  factory AdminIngredientModel.fromJson(Map<String, dynamic> json) {
    final rawStock = json['stock'] ?? json['stok'] ?? 0;
    final rawMinStock = json['min_stock'] ?? json['minimum_stock'] ?? 0;
    final rawCost = json['cost_per_unit'] ?? json['harga_satuan'] ?? 0;
    final rawBuyPrice = json['buy_price'] ?? json['harga_beli'] ?? 0;
    final rawBuyAmount = json['buy_amount'] ?? json['jumlah_beli'] ?? 1;

    final parsedStock = double.tryParse(rawStock.toString()) ?? 0.0;
    final parsedCost = double.tryParse(rawCost.toString()) ?? 0.0;
    final parsedBuyPrice = double.tryParse(rawBuyPrice.toString()) ?? 0.0;
    final parsedBuyAmount = double.tryParse(rawBuyAmount.toString()) ?? 1.0;

    // Fallback costPerUnit if zero but buyPrice and buyAmount exist
    final effectiveCostPerUnit = (parsedCost > 0)
        ? parsedCost
        : ((parsedBuyPrice > 0 && parsedBuyAmount > 0)
            ? (parsedBuyPrice / parsedBuyAmount)
            : 0.0);

    final rawUsed = json['used_in_products'];
    List<IngredientUsageModel> parsedUsedIn = [];
    if (rawUsed is List) {
      parsedUsedIn = rawUsed
          .map((m) {
            if (m is Map<String, dynamic>) {
              return IngredientUsageModel.fromJson(m);
            } else if (m is Map) {
              return IngredientUsageModel.fromJson(Map<String, dynamic>.from(m));
            }
            return null;
          })
          .whereType<IngredientUsageModel>()
          .toList();
    }

    final pCount = int.tryParse(json['products_count']?.toString() ?? '') ?? parsedUsedIn.length;

    return AdminIngredientModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? json['nama'] ?? '').toString(),
      category: (json['category'] ?? json['kategori'] ?? 'Umum').toString(),
      sku: (json['sku'] ?? '').toString(),
      stock: parsedStock,
      unit: (json['unit'] ?? json['satuan'] ?? 'gram').toString(),
      minStock: double.tryParse(rawMinStock.toString()) ?? 0.0,
      costPerUnit: effectiveCostPerUnit,
      buyPrice: parsedBuyPrice,
      buyAmount: parsedBuyAmount > 0 ? parsedBuyAmount : 1.0,
      buyUnit: (json['buy_unit'] ?? json['satuan_beli'] ?? json['unit'] ?? 'gram').toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['status'] == 'active' || json['is_active'] == null,
      productsCount: pCount,
      usedInProducts: parsedUsedIn,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'sku': sku,
      'stock': stock,
      'unit': unit,
      'min_stock': minStock,
      'cost_per_unit': costPerUnit,
      'buy_price': buyPrice,
      'buy_amount': buyAmount,
      'buy_unit': buyUnit,
      'is_active': isActive ? 1 : 0,
      'products_count': productsCount,
      'used_in_products': usedInProducts.map((u) => u.toJson()).toList(),
    };
  }

  AdminIngredientModel copyWith({
    int? id,
    String? name,
    String? category,
    String? sku,
    double? stock,
    String? unit,
    double? minStock,
    double? costPerUnit,
    double? buyPrice,
    double? buyAmount,
    String? buyUnit,
    bool? isActive,
    int? productsCount,
    List<IngredientUsageModel>? usedInProducts,
  }) {
    return AdminIngredientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      minStock: minStock ?? this.minStock,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      buyPrice: buyPrice ?? this.buyPrice,
      buyAmount: buyAmount ?? this.buyAmount,
      buyUnit: buyUnit ?? this.buyUnit,
      isActive: isActive ?? this.isActive,
      productsCount: productsCount ?? this.productsCount,
      usedInProducts: usedInProducts ?? this.usedInProducts,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class AdminIngredientSummaryModel {
  final int totalIngredients;
  final int lowStockCount;
  final int outOfStockCount;
  final double totalInventoryValue;

  const AdminIngredientSummaryModel({
    required this.totalIngredients,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.totalInventoryValue,
  });

  int get safeStockCount {
    final count = totalIngredients - lowStockCount - outOfStockCount;
    return count > 0 ? count : 0;
  }

  factory AdminIngredientSummaryModel.empty() {
    return const AdminIngredientSummaryModel(
      totalIngredients: 0,
      lowStockCount: 0,
      outOfStockCount: 0,
      totalInventoryValue: 0.0,
    );
  }

  factory AdminIngredientSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminIngredientSummaryModel(
      totalIngredients: int.tryParse(json['total_ingredients']?.toString() ?? '0') ?? 0,
      lowStockCount: int.tryParse(json['low_stock_count']?.toString() ?? '0') ?? 0,
      outOfStockCount: int.tryParse(json['out_of_stock_count']?.toString() ?? '0') ?? 0,
      totalInventoryValue: double.tryParse(json['total_inventory_value']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_ingredients': totalIngredients,
      'low_stock_count': lowStockCount,
      'out_of_stock_count': outOfStockCount,
      'total_inventory_value': totalInventoryValue,
    };
  }
}
