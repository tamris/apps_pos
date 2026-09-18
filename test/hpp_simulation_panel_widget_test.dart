import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/data/models/hpp_calculation_model.dart';
import 'package:noli_apps/app/data/models/product_ingredient_model.dart';
import 'package:noli_apps/app/data/providers/api_provider.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/hpp/hpp_simulation_panel.dart';

class MockApiProvider extends GetxService implements ApiProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestAdminController extends AdminController {
  @override
  Future<void> fetchDashboard({String? date}) async {}

  @override
  Future<void> fetchTransactions() async {}

  @override
  Future<void> fetchOpenBills() async {}

  @override
  Future<void> fetchShifts({String? date, String? status}) async {}

  @override
  Future<void> fetchMenuSales({bool refresh = false}) async {}

  @override
  Future<void> fetchMenuCategories() async {}

  @override
  Future<HppCalculationModel?> calculateHppSimulation({
    List<ProductIngredientModel>? ingredients,
    double? sellingPrice,
    double? operationalCost,
    double? kenaikanPersen,
    int? targetMonthlyUnits,
    double? targetMonthlyProfit,
    int? operationalDays,
    String modeAlokasiOps = 'manual',
    List<Map<String, dynamic>>? biayaTetapItems,
  }) async {
    return null;
  }
}

void main() {
  setUp(() {
    Get.reset();
  });

  final testIngredients = [
    ProductIngredientModel(
      name: 'Biji Kopi (House Blend)',
      amount: 16,
      unit: 'gram',
      buyPrice: 150000,
      buyAmount: 1,
      buyUnit: 'kg',
      subtotal: 2400,
    ),
    ProductIngredientModel(
      name: 'Air Mineral',
      amount: 150,
      unit: 'ml',
      buyPrice: 20000,
      buyAmount: 19,
      buyUnit: 'liter',
      subtotal: 158,
    ),
    ProductIngredientModel(
      name: 'Plastic Cup 16 oz',
      amount: 1,
      unit: 'pcs',
      buyPrice: 35000,
      buyAmount: 50,
      buyUnit: 'pcs',
      subtotal: 700,
    ),
  ];

  final testCalcResult = HppCalculationModel(
    ingredients: testIngredients,
    summary: HppCalculationSummary(
      totalVariableCost: 3258,
      simulatedVariableCost: 3258,
      operationalCostPerUnit: 1000,
      baseHpp: 4258,
      simulatedHpp: 4258,
      effectiveHpp: 4258,
    ),
    pricingTiers: {
      'kompetitif': HppPricingTierItem(
        tier: 'kompetitif',
        label: 'Tier Kompetitif',
        harga: 10000,
        margin: 57.4,
        profit: 5742,
      ),
      'standar': HppPricingTierItem(
        tier: 'standar',
        label: 'Tier Standar Cafe',
        harga: 12000,
        margin: 64.5,
        profit: 7742,
      ),
      'premium': HppPricingTierItem(
        tier: 'premium',
        label: 'Tier Premium',
        harga: 15000,
        margin: 71.6,
        profit: 10742,
      ),
    },
  );

  testWidgets('Pumps HppSimulationPanel on desktop and verifies modern aesthetic elements', (tester) async {
    Get.put<ApiProvider>(MockApiProvider());
    final controller = Get.put<AdminController>(TestAdminController());

    controller.simulationProductName.value = 'Americano Ice';
    controller.simulationIngredients.value = testIngredients;
    controller.simulationCalculationResult.value = testCalcResult;

    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HppSimulationPanel(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Header and product name
    expect(find.textContaining('Hasil Estimasi Resep: Americano Ice'), findsOneWidget);
    expect(find.text('3 Bahan Baku'), findsOneWidget);
    expect(find.text('Kalkulasi Otomatis'), findsOneWidget);
    expect(find.text('Tambah Bahan Baku'), findsOneWidget);

    // 2. Verify Table Columns and ingredient rows
    expect(find.text('NAMA BAHAN BAKU'), findsOneWidget);
    expect(find.text('TAKARAN PORSI'), findsOneWidget);
    expect(find.text('HARGA BELI KEMASAN'), findsOneWidget);
    expect(find.text('SUBTOTAL / CUP'), findsOneWidget);

    // 3. Verify Ingredients and Category Labels
    expect(find.text('Biji Kopi (House Blend)'), findsOneWidget);
    expect(find.text('Kopi / Base').first, findsOneWidget);
    expect(find.text('Air Mineral'), findsOneWidget);
    expect(find.text('Cairan / Susu').first, findsOneWidget);
    expect(find.text('Plastic Cup 16 oz'), findsOneWidget);
    expect(find.text('Packaging').first, findsOneWidget);

    // 4. Verify Food Cost Summary
    expect(find.text('Total Biaya Bahan Murni (Food Cost)'), findsOneWidget);

    // 5. Verify 3-Tier Recommendation Cards
    expect(find.text('Tier Kompetitif'), findsOneWidget);
    expect(find.text('Tier Standar Cafe'), findsOneWidget);
    expect(find.text('Tier Premium'), findsOneWidget);
    expect(find.text('REKOMENDASI CAFE'), findsOneWidget);
    expect(find.text('Dipilih'), findsOneWidget);

    // 6. Verify Bottom CTA Button
    expect(find.textContaining('Terapkan ke Katalog'), findsOneWidget);

    // Tap Tier Kompetitif to test interaction
    await tester.tap(find.text('Tier Kompetitif'));
    await tester.pumpAndSettle();

    expect(find.text('Tier Kompetitif'), findsOneWidget);
  });
}
