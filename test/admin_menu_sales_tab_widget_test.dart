import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/data/models/admin_menu_sales_model.dart';
import 'package:noli_apps/app/data/providers/api_provider.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'package:noli_apps/app/modules/admin/views/tabs/admin_menu_sales_tab.dart';

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
}

void main() {
  setUp(() {
    Get.reset();
  });

  final sampleSummaryJson = {
    'total_quantity_sold': 350,
    'total_revenue': 8750000.0,
    'total_cost': 4500000.0,
    'total_profit': 4250000.0,
    'profit_margin': 48.6,
    'total_unique_items_sold': 18,
    'top_selling_product': {
      'id': 1,
      'name': 'Kopi Susu Gula Aren',
      'quantity_sold': 120,
      'total_revenue': 2400000.0,
    },
  };

  final sampleCategoriesJson = [
    {
      'id': 1,
      'category_name': 'Coffee & Beverage',
      'items_count': 10,
      'total_quantity': 250,
      'total_revenue': 5500000.0,
      'revenue_share_percentage': 62.8,
    },
    {
      'id': 2,
      'category_name': 'Makanan Berat',
      'items_count': 5,
      'total_quantity': 100,
      'total_revenue': 3250000.0,
      'revenue_share_percentage': 37.2,
    },
  ];

  final sampleItemsJson = [
    {
      'rank': 1,
      'product_id': 1,
      'product_name': 'Kopi Susu Gula Aren',
      'sku': 'KOP-01',
      'category': {'id': 1, 'name': 'Coffee & Beverage'},
      'image_url': null,
      'is_active': true,
      'is_deleted': false,
      'unit_price': 20000.0,
      'cost_price': 10000.0,
      'quantity_sold': 120,
      'total_revenue': 2400000.0,
      'total_cost': 1200000.0,
      'total_profit': 1200000.0,
      'profit_margin': 50.0,
      'sales_share_percentage': 34.3,
      'revenue_share_percentage': 27.4,
      'transactions_count': 95,
    },
    {
      'rank': 2,
      'product_id': 2,
      'product_name': 'Nasi Goreng Spesial',
      'sku': 'NG-01',
      'category': {'id': 2, 'name': 'Makanan Berat'},
      'image_url': null,
      'is_active': true,
      'is_deleted': false,
      'unit_price': 30000.0,
      'cost_price': 15000.0,
      'quantity_sold': 75,
      'total_revenue': 2250000.0,
      'total_cost': 1125000.0,
      'total_profit': 1125000.0,
      'profit_margin': 50.0,
      'sales_share_percentage': 21.4,
      'revenue_share_percentage': 25.7,
      'transactions_count': 60,
    },
  ];

  testWidgets('Pumps AdminMenuSalesTab on desktop and verifies popularity KPI cards & menu items', (tester) async {
    Get.put<ApiProvider>(MockApiProvider());
    final controller = Get.put<AdminController>(TestAdminController());

    controller.menuSalesSummary.value = AdminMenuSalesSummaryModel.fromJson(sampleSummaryJson);
    controller.menuSalesCategories.assignAll(
      sampleCategoriesJson.map((e) => AdminMenuSalesCategoryModel.fromJson(e)).toList(),
    );
    controller.menuSalesItems.assignAll(
      sampleItemsJson.map((e) => AdminMenuSalesItemModel.fromJson(e)).toList(),
    );

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminMenuSalesTab(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Top KPI Strip Focus on Menu Popularity (No Omset / Profit cards!)
    expect(find.text('Total Porsi Terjual'), findsOneWidget);
    expect(find.text('350 Porsi'), findsOneWidget);

    expect(find.text('Menu Terlaris #1'), findsOneWidget);
    expect(find.text('Kopi Susu Gula Aren'), findsWidgets);
    expect(find.text('120 porsi terjual'), findsOneWidget);

    expect(find.text('Varian Menu Aktif'), findsOneWidget);
    expect(find.text('18 Menu'), findsOneWidget);

    expect(find.text('Kategori Terfavorit'), findsOneWidget);
    expect(find.text('Coffee & Beverage'), findsWidgets);
    expect(find.text('62.8% kontribusi'), findsOneWidget);

    // 2. Verify Filter Controls (Date Button and Category Dropdown)
    expect(find.text('Bulan Ini'), findsWidgets);
    expect(find.text('Kategori: Semua'), findsOneWidget);
    expect(find.text('Urutkan: Terlaris'), findsNothing);
    expect(find.text('Urutkan: Omset'), findsNothing);

    // 3. Verify Menu Item Card popular metrics
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('34.3% Pangsa'), findsOneWidget);
    expect(find.text('21.4% Pangsa'), findsOneWidget);
    expect(find.text('120 Porsi Terjual'), findsOneWidget);
    expect(find.text('75 Porsi Terjual'), findsOneWidget);
    expect(find.text('95x Pesanan'), findsOneWidget);
    expect(find.text('60x Pesanan'), findsOneWidget);
  });

  testWidgets('Pumps AdminMenuSalesTab on mobile screen without overflow', (tester) async {
    Get.put<ApiProvider>(MockApiProvider());
    final controller = Get.put<AdminController>(TestAdminController());

    controller.menuSalesSummary.value = AdminMenuSalesSummaryModel.fromJson(sampleSummaryJson);
    controller.menuSalesCategories.assignAll(
      sampleCategoriesJson.map((e) => AdminMenuSalesCategoryModel.fromJson(e)).toList(),
    );
    controller.menuSalesItems.assignAll(
      sampleItemsJson.map((e) => AdminMenuSalesItemModel.fromJson(e)).toList(),
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminMenuSalesTab(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Total Porsi Terjual'), findsOneWidget);
    expect(find.text('120 Porsi Terjual'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
