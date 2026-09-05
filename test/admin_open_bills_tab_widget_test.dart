import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/data/models/admin_open_bill_model.dart';
import 'package:noli_apps/app/data/models/admin_transaction_model.dart';
import 'package:noli_apps/app/data/providers/api_provider.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'package:noli_apps/app/modules/admin/views/tabs/admin_open_bills_tab.dart';

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
  Future<AdminTransactionModel?> fetchTransactionDetail(int id) async => null;
}

void main() {
  setUp(() {
    Get.reset();
  });

  final openBillsJsonList = [
    {
      'id': 101,
      'invoice_number': 'INV-20260905-001',
      'table_number': '5',
      'customer_name': 'Pak Joko Widodo',
      'order_type': 'dine_in',
      'order_source': 'pos',
      'total': 185000,
      'items_count': 4,
      'created_at': '2026-09-05T10:00:00.000Z',
      'elapsed_minutes': 75,
      'cashier_name': 'Kasir Budi',
    },
    {
      'id': 102,
      'invoice_number': 'INV-20260905-002',
      'table_number': '12',
      'customer_name': 'Ibu Siti',
      'order_type': 'dine_in',
      'order_source': 'self_order',
      'total': 95000,
      'items_count': 2,
      'created_at': '2026-09-05T11:00:00.000Z',
      'elapsed_minutes': 20,
      'cashier_name': 'Self-Order System',
    },
  ];

  testWidgets('Pumps AdminOpenBillsTab on desktop, verifies KPI cards and search', (tester) async {
    final mockApi = MockApiProvider();
    Get.put<ApiProvider>(mockApi);

    final controller = TestAdminController();
    Get.put<AdminController>(controller);

    controller.openBills.value = openBillsJsonList.map((e) => AdminOpenBillModel.fromJson(e)).toList();
    controller.openBillsTotalActive.value = 2;
    controller.openBillsTotalAmount.value = 280000;

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminOpenBillsTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 4 KPI cards
    expect(find.text('Meja Aktif'), findsWidgets);
    expect(find.text('Tagihan Gantung'), findsWidgets);
    expect(find.text('Perlu Perhatian'), findsWidgets);
    expect(find.text('Kanal Pesanan'), findsWidgets);

    // Verify Table Cards rendered
    expect(find.text('MEJA 5'), findsWidgets);
    expect(find.text('MEJA 12'), findsWidgets);
    expect(find.text('Pak Joko Widodo'), findsWidgets);
    expect(find.text('Ibu Siti'), findsWidgets);

    // Test Search query by table
    controller.openBillSearchQuery.value = '12';
    await tester.pumpAndSettle();

    expect(find.text('MEJA 12'), findsWidgets);
    expect(find.text('MEJA 5'), findsNothing);

    // Test Search query by customer name
    controller.openBillSearchQuery.value = 'Joko';
    await tester.pumpAndSettle();

    expect(find.text('Pak Joko Widodo'), findsWidgets);
    expect(find.text('Ibu Siti'), findsNothing);

    // Reset search
    controller.openBillSearchQuery.value = '';
    await tester.pumpAndSettle();

    expect(find.text('MEJA 5'), findsWidgets);
    expect(find.text('MEJA 12'), findsWidgets);

    // Test Status Filter: critical (> 60 mins)
    controller.selectedOpenBillFilter.value = 'critical';
    await tester.pumpAndSettle();

    expect(find.text('MEJA 5'), findsWidgets); // 75 mins -> critical
    expect(find.text('MEJA 12'), findsNothing); // 20 mins -> not critical

    // Test Status Filter: fresh (< 30 mins)
    controller.selectedOpenBillFilter.value = 'fresh';
    await tester.pumpAndSettle();

    expect(find.text('MEJA 12'), findsWidgets); // 20 mins -> fresh
    expect(find.text('MEJA 5'), findsNothing);
  });

  testWidgets('Pumps AdminOpenBillsTab on mobile screen without overflow', (tester) async {
    final mockApi = MockApiProvider();
    Get.put<ApiProvider>(mockApi);

    final controller = TestAdminController();
    Get.put<AdminController>(controller);

    controller.openBills.value = openBillsJsonList.map((e) => AdminOpenBillModel.fromJson(e)).toList();
    controller.openBillsTotalActive.value = 2;
    controller.openBillsTotalAmount.value = 280000;

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminOpenBillsTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('MEJA 5'), findsWidgets);
    expect(find.text('MEJA 12'), findsWidgets);
    expect(find.text('Pak Joko Widodo'), findsWidgets);
    expect(find.text('Ibu Siti'), findsWidgets);
  });

  testWidgets('Pumps AdminOpenBillsTab empty state when all tables settled', (tester) async {
    final mockApi = MockApiProvider();
    Get.put<ApiProvider>(mockApi);

    final controller = TestAdminController();
    Get.put<AdminController>(controller);

    controller.openBills.value = [];
    controller.openBillsTotalActive.value = 0;
    controller.openBillsTotalAmount.value = 0;

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminOpenBillsTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Semua Meja Telah Lunas'), findsWidgets);
    expect(find.text('Perbarui Data Meja'), findsWidgets);
  });
}
