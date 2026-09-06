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

    // 1. Verify Tables Mode (Default Left Tab)
    expect(find.text('Meja Belum Lunas'), findsWidgets);
    expect(find.text('Tagihan Tertunda'), findsWidgets);
    expect(find.text('Durasi Tamu'), findsWidgets);
    expect(find.text('Menu Dinikmati'), findsWidgets);

    // Verify Dine-In Table Card rendered (Pak Joko Widodo, Meja 5)
    expect(find.text('MEJA 5'), findsWidgets);
    expect(find.text('Pak Joko Widodo'), findsWidgets);
    expect(find.text('Ibu Siti'), findsNothing);

    // Test Search query in Tables Mode
    controller.openBillSearchQuery.value = '5';
    await tester.pumpAndSettle();
    expect(find.text('MEJA 5'), findsWidgets);

    controller.openBillSearchQuery.value = 'NonExistent';
    await tester.pumpAndSettle();
    expect(find.text('MEJA 5'), findsNothing);

    // Reset search
    controller.openBillSearchQuery.value = '';
    await tester.pumpAndSettle();
    expect(find.text('MEJA 5'), findsWidgets);

    // Test Status Filter in Tables Mode: critical (> 60 mins)
    controller.selectedOpenBillFilter.value = 'critical';
    await tester.pumpAndSettle();
    expect(find.text('MEJA 5'), findsWidgets); // 75 mins -> critical

    // Test Status Filter: fresh (< 30 mins)
    controller.selectedOpenBillFilter.value = 'fresh';
    await tester.pumpAndSettle();
    expect(find.text('MEJA 5'), findsNothing); // 75 mins is not fresh

    // 2. Switch to 'Pesanan Online' (Right Tab)
    await tester.tap(find.text('Pesanan Online'));
    await tester.pumpAndSettle();

    // Verify Online Mode KPI cards
    expect(find.text('Pesanan Online'), findsWidgets);
    expect(find.text('Menunggu Bayar'), findsWidgets);
    expect(find.text('Antrean Dapur'), findsWidgets);
    expect(find.text('Total Nilai Online'), findsWidgets);

    // Verify Online Card rendered (Ibu Siti, Meja 12)
    expect(find.text('MEJA 12'), findsWidgets);
    expect(find.text('Ibu Siti'), findsWidgets);
    expect(find.text('Pak Joko Widodo'), findsNothing);
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

    // Tables card on mobile (default)
    expect(find.text('MEJA 5'), findsWidgets);
    expect(find.text('Pak Joko Widodo'), findsWidgets);

    // Switch to Online on mobile
    await tester.tap(find.text('Pesanan Online'));
    await tester.pumpAndSettle();

    expect(find.text('MEJA 12'), findsWidgets);
    expect(find.text('Ibu Siti'), findsWidgets);
  });

  testWidgets('Pumps AdminOpenBillsTab empty state when settled', (tester) async {
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

    // In Tables mode empty state (default)
    expect(find.text('Semua Meja Telah Lunas'), findsWidgets);
    expect(find.text('Perbarui Data Meja'), findsWidgets);

    // In Online mode empty state
    await tester.tap(find.text('Pesanan Online'));
    await tester.pumpAndSettle();

    expect(find.text('Tidak Ada Pesanan Online Aktif'), findsWidgets);
    expect(find.text('Perbarui Data Meja'), findsWidgets);
  });

  testWidgets('Switches smoothly between Meja Belum Lunas and Pesanan Online', (tester) async {
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

    // Default: Tables Mode
    expect(find.text('Pak Joko Widodo'), findsWidgets);
    expect(find.text('Ibu Siti'), findsNothing);

    // Switch to 'Pesanan Online'
    await tester.tap(find.text('Pesanan Online'));
    await tester.pumpAndSettle();

    expect(find.text('Ibu Siti'), findsWidgets);
    expect(find.text('Pak Joko Widodo'), findsNothing);

    // Switch back to 'Meja Belum Lunas'
    await tester.tap(find.text('Meja Belum Lunas'));
    await tester.pumpAndSettle();

    expect(find.text('Pak Joko Widodo'), findsWidgets);
    expect(find.text('Ibu Siti'), findsNothing);
  });
}
