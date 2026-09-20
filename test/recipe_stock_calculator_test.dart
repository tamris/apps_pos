import 'package:flutter_test/flutter_test.dart';
import 'package:noli_apps/app/core/utils/recipe_stock_calculator.dart';
import 'package:noli_apps/app/data/models/admin_ingredient_model.dart';
import 'package:noli_apps/app/data/models/product_ingredient_model.dart';

void main() {
  group('RecipeStockCalculator Tests', () {
    test('Empty recipe returns hasRecipe = false', () {
      final capacity = RecipeStockCalculator.calculate(recipeIngredients: []);
      expect(capacity.hasRecipe, isFalse);
      expect(capacity.formattedCups, 'Tanpa Resep');
    });

    test('Unit conversion: kg to gram and liter to ml', () {
      final recipe = <ProductIngredientModel>[
        ProductIngredientModel(
          ingredientId: 1,
          name: 'Biji Kopi',
          amount: 20,
          unit: 'gram',
          buyPrice: 100000,
          buyUnit: 'kg',
          subtotal: 2000,
        ),
        ProductIngredientModel(
          ingredientId: 2,
          name: 'Susu Fresh Milk',
          amount: 150,
          unit: 'ml',
          buyPrice: 20000,
          buyUnit: 'liter',
          subtotal: 3000,
        ),
      ];

      final stock = <AdminIngredientModel>[
        AdminIngredientModel(
          id: 1,
          name: 'Biji Kopi',
          stock: 1.0, // 1 kg = 1000 gram -> 1000 / 20 = 50 cups
          unit: 'kg',
          costPerUnit: 100000,
        ),
        AdminIngredientModel(
          id: 2,
          name: 'Susu Fresh Milk',
          stock: 3.0, // 3 liter = 3000 ml -> 3000 / 150 = 20 cups (BOTTLENECK)
          unit: 'liter',
          costPerUnit: 20000,
        ),
      ];

      final capacity = RecipeStockCalculator.calculate(
        recipeIngredients: recipe,
        stockIngredients: stock,
      );

      expect(capacity.hasRecipe, isTrue);
      expect(capacity.maxCups, 20); // 20 is the limiting reagent
      expect(capacity.bottleneckName, 'Susu Fresh Milk');
      expect(capacity.isWarning, isTrue); // 10 < 20 <= 30
      expect(capacity.isOutOfStock, isFalse);
    });

    test('Zero or negative stock results in out of stock', () {
      final recipe = <ProductIngredientModel>[
        ProductIngredientModel(
          ingredientId: 1,
          name: 'Sirup Karamel',
          amount: 15,
          unit: 'ml',
          buyPrice: 50000,
          buyUnit: 'liter',
          subtotal: 1000,
        ),
      ];

      final stock = <AdminIngredientModel>[
        AdminIngredientModel(
          id: 1,
          name: 'Sirup Karamel',
          stock: -10,
          unit: 'ml',
          costPerUnit: 50000,
        ),
      ];

      final capacity = RecipeStockCalculator.calculate(
        recipeIngredients: recipe,
        stockIngredients: stock,
      );

      expect(capacity.hasRecipe, isTrue);
      expect(capacity.maxCups, 0);
      expect(capacity.isOutOfStock, isTrue);
      expect(capacity.bottleneckName, 'Sirup Karamel');
    });

    test('Direct ingredient model properties fallback works without stockIngredients map', () {
      final recipe = <ProductIngredientModel>[
        ProductIngredientModel(
          ingredientId: 1,
          name: 'Matcha Powder',
          amount: 10,
          unit: 'gram',
          buyPrice: 400000,
          buyUnit: 'kg',
          currentStock: 100,
          stockUnit: 'gram',
          subtotal: 4000,
        ),
      ];

      final capacity = RecipeStockCalculator.calculate(
        recipeIngredients: recipe,
      );

      expect(capacity.hasRecipe, isTrue);
      expect(capacity.maxCups, 10);
      expect(capacity.isCritical, isTrue); // 10 cups is critical
    });
  });
}
