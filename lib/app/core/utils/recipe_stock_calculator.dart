import 'dart:math';
import '../../data/models/admin_ingredient_model.dart';
import '../../data/models/product_ingredient_model.dart';

class IngredientCapacityBreakdown {
  final int? ingredientId;
  final String name;
  final double recipeAmount;
  final String recipeUnit;
  final double currentStock;
  final String stockUnit;
  final int maxCups;
  final bool isBottleneck;

  const IngredientCapacityBreakdown({
    this.ingredientId,
    required this.name,
    required this.recipeAmount,
    required this.recipeUnit,
    required this.currentStock,
    required this.stockUnit,
    required this.maxCups,
    this.isBottleneck = false,
  });
}

class ProductStockCapacity {
  final bool hasRecipe;
  final int maxCups;
  final String? bottleneckName;
  final double? bottleneckStock;
  final String? bottleneckUnit;
  final String? bottleneckDetails;
  final List<IngredientCapacityBreakdown> breakdowns;

  const ProductStockCapacity({
    this.hasRecipe = false,
    this.maxCups = 0,
    this.bottleneckName,
    this.bottleneckStock,
    this.bottleneckUnit,
    this.bottleneckDetails,
    this.breakdowns = const [],
  });

  bool get isOutOfStock => hasRecipe && maxCups <= 0;
  bool get isCritical => hasRecipe && maxCups > 0 && maxCups <= 10;
  bool get isWarning => hasRecipe && maxCups > 10 && maxCups <= 30;
  bool get isSafe => hasRecipe && maxCups > 30;

  String get formattedCups => hasRecipe ? '~$maxCups cup' : 'Tanpa Resep';
}

class RecipeStockCalculator {
  /// Normalisasi variasi nama satuan
  static String normalizeUnit(String? unit) {
    if (unit == null || unit.trim().isEmpty) return 'pcs';
    final u = unit.toLowerCase().trim();

    if (u == 'g' || u == 'gr' || u == 'gram' || u == 'grams') return 'gram';
    if (u == 'kg' || u == 'kilo' || u == 'kilogram' || u == 'kilograms') return 'kg';
    if (u == 'ml' || u == 'mili' || u == 'mililiter' || u == 'milliliter' || u == 'cc') return 'ml';
    if (u == 'l' || u == 'lt' || u == 'ltr' || u == 'liter' || u == 'liters') return 'liter';
    if (u == 'pc' || u == 'pcs' || u == 'buah' || u == 'biji' || u == 'lembar' || u == 'cup' || u == 'pack') return 'pcs';
    if (u == 'sachet' || u == 'saset' || u == 'bungkus') return 'sachet';

    return u;
  }

  /// Konversi nilai stok gudang ke dalam satuan yang digunakan di resep
  static double convertStockToRecipeUnit({
    required double stock,
    required String stockUnit,
    required String recipeUnit,
  }) {
    final su = normalizeUnit(stockUnit);
    final ru = normalizeUnit(recipeUnit);

    if (su == ru) return stock;

    if (su == 'kg' && ru == 'gram') return stock * 1000.0;
    if (su == 'gram' && ru == 'kg') return stock / 1000.0;
    if (su == 'liter' && ru == 'ml') return stock * 1000.0;
    if (su == 'ml' && ru == 'liter') return stock / 1000.0;

    return stock;
  }

  /// Hitung kapasitas cup produk secara mandiri di client-side
  static ProductStockCapacity calculate({
    required List<ProductIngredientModel> recipeIngredients,
    List<AdminIngredientModel> stockIngredients = const [],
  }) {
    if (recipeIngredients.isEmpty) {
      return const ProductStockCapacity(hasRecipe: false);
    }

    final stockMap = {for (var item in stockIngredients) item.id: item};

    int minCups = 999999999;
    String? bottleneckName;
    double? bottleneckStock;
    String? bottleneckUnit;
    String? bottleneckDetails;
    final List<IngredientCapacityBreakdown> rawBreakdowns = [];

    for (final ing in recipeIngredients) {
      if (ing.amount <= 0) continue;

      // Cari stok fisik dari master ingredient atau dari model ingredient
      final stockIng = ing.ingredientId != null ? stockMap[ing.ingredientId] : null;
      final currentStock = ing.currentStock ?? stockIng?.stock ?? 0.0;
      final stockUnit = ing.stockUnit ?? stockIng?.unit ?? ing.unit;

      final availableInRecipeUnit = convertStockToRecipeUnit(
        stock: currentStock,
        stockUnit: stockUnit,
        recipeUnit: ing.unit,
      );

      final cups = (!availableInRecipeUnit.isFinite || !ing.amount.isFinite || availableInRecipeUnit <= 0 || ing.amount <= 0)
          ? 0
          : (availableInRecipeUnit / ing.amount).floor();

      final ingName = ing.name.isNotEmpty
          ? ing.name
          : (stockIng?.name ?? 'Bahan Baku');

      rawBreakdowns.add(IngredientCapacityBreakdown(
        ingredientId: ing.ingredientId,
        name: ingName,
        recipeAmount: ing.amount,
        recipeUnit: ing.unit,
        currentStock: currentStock,
        stockUnit: stockUnit,
        maxCups: cups,
      ));

      if (cups < minCups) {
        minCups = cups;
        bottleneckName = ingName;
        bottleneckStock = currentStock;
        bottleneckUnit = stockUnit;
        final formattedStock = currentStock % 1 == 0
            ? currentStock.toInt().toString()
            : currentStock.toStringAsFixed(1);
        bottleneckDetails = '$ingName (sisa $formattedStock $stockUnit)';
      }
    }

    if (minCups == 999999999) {
      return const ProductStockCapacity(hasRecipe: false);
    }

    final finalMinCups = max(0, minCups);

    // Tandai bahan mana saja yang menjadi bottleneck
    final breakdowns = rawBreakdowns.map((b) {
      return IngredientCapacityBreakdown(
        ingredientId: b.ingredientId,
        name: b.name,
        recipeAmount: b.recipeAmount,
        recipeUnit: b.recipeUnit,
        currentStock: b.currentStock,
        stockUnit: b.stockUnit,
        maxCups: b.maxCups,
        isBottleneck: b.maxCups == finalMinCups,
      );
    }).toList();

    return ProductStockCapacity(
      hasRecipe: true,
      maxCups: finalMinCups,
      bottleneckName: bottleneckName,
      bottleneckStock: bottleneckStock,
      bottleneckUnit: bottleneckUnit,
      bottleneckDetails: bottleneckDetails,
      breakdowns: breakdowns,
    );
  }
}
