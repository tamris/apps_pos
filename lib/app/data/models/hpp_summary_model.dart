class HppLowMarginProduct {
  final int id;
  final String name;
  final String category;
  final double price;
  final double hargaBeli;
  final double marginPercent;
  final double foodCostPercent;

  HppLowMarginProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.hargaBeli,
    required this.marginPercent,
    required this.foodCostPercent,
  });

  factory HppLowMarginProduct.fromJson(Map<String, dynamic> json) {
    return HppLowMarginProduct(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? 'Uncategorized').toString(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      hargaBeli: double.tryParse(json['harga_beli']?.toString() ?? '0') ?? 0.0,
      marginPercent: double.tryParse(json['margin_percent']?.toString() ?? '0') ?? 0.0,
      foodCostPercent: double.tryParse(json['food_cost_percent']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'harga_beli': hargaBeli,
      'margin_percent': marginPercent,
      'food_cost_percent': foodCostPercent,
    };
  }
}

class HppSummaryModel {
  final int totalActiveProducts;
  final double averageMarginPercent;
  final double averageFoodCostPercent;
  final bool isMarginHealthy;
  final int lowMarginCount;
  final double lowMarginAlertThresholdPercent;
  final List<HppLowMarginProduct> lowMarginProducts;

  HppSummaryModel({
    this.totalActiveProducts = 0,
    this.averageMarginPercent = 0.0,
    this.averageFoodCostPercent = 0.0,
    this.isMarginHealthy = true,
    this.lowMarginCount = 0,
    this.lowMarginAlertThresholdPercent = 35.0,
    this.lowMarginProducts = const [],
  });

  factory HppSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['low_margin_products'];
    List<HppLowMarginProduct> parsedList = [];
    if (rawList is List) {
      parsedList = rawList
          .whereType<Map>()
          .map((i) => HppLowMarginProduct.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }

    return HppSummaryModel(
      totalActiveProducts: int.tryParse(json['total_active_products']?.toString() ?? '0') ?? 0,
      averageMarginPercent: double.tryParse(json['average_margin_percent']?.toString() ?? '0') ?? 0.0,
      averageFoodCostPercent: double.tryParse(json['average_food_cost_percent']?.toString() ?? '0') ?? 0.0,
      isMarginHealthy: json['is_margin_healthy'] == true,
      lowMarginCount: int.tryParse(json['low_margin_count']?.toString() ?? '0') ?? parsedList.length,
      lowMarginAlertThresholdPercent: double.tryParse(json['low_margin_alert_threshold_percent']?.toString() ?? '35') ?? 35.0,
      lowMarginProducts: parsedList,
    );
  }

  factory HppSummaryModel.empty() {
    return HppSummaryModel();
  }

  Map<String, dynamic> toJson() {
    return {
      'total_active_products': totalActiveProducts,
      'average_margin_percent': averageMarginPercent,
      'average_food_cost_percent': averageFoodCostPercent,
      'is_margin_healthy': isMarginHealthy,
      'low_margin_count': lowMarginCount,
      'low_margin_alert_threshold_percent': lowMarginAlertThresholdPercent,
      'low_margin_products': lowMarginProducts.map((i) => i.toJson()).toList(),
    };
  }
}
