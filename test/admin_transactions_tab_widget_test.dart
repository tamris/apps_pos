import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/data/models/admin_transaction_model.dart';
import 'package:noli_apps/app/data/providers/api_provider.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'package:noli_apps/app/modules/admin/views/tabs/admin_transactions_tab.dart';

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
}

void main() {
  setUp(() {
    Get.reset();
  });

  final trxJsonList = [
    {
      'id': 101,
      'invoice_number': 'INV-20260905-001',
      'customer_name': 'Pelanggan Alice',
      'table_number': '02',
      'order_type': 'dine_in',
      'order_source': 'pos',
      'payment_method': 'cash',
      'payment_status': 'paid',
      'subtotal': 50000,
      'discount': 0,
      'tax': 0,
      'total': 50000,
      'profit': 25000,
      'paid': 50000,
      'change': 0,
      'status': 'completed',
      'cashier': {'id': 1, 'name': 'Kasir Budi'},
      'items': [],
    },
    {
      'id': 102,
      'invoice_number': 'INV-20260905-002',
      'customer_name': 'Pelanggan Bob',
      'table_number': '05',
      'order_type': 'dine_in',
      'order_source': 'self_order',
      'payment_method': 'qris',
      'payment_status': 'unpaid',
      'subtotal': 75000,
      'discount': 0,
      'tax': 0,
      'total': 75000,
      'paid': 0,
      'change': 0,
      'status': 'pending',
      'cashier': {'id': 1, 'name': 'Kasir Budi'},
      'items': [],
    },
    {
      'id': 103,
      'invoice_number': 'INV-20260905-003',
      'customer_name': 'Pelanggan Charlie',
      'table_number': '07',
      'order_type': 'take_away',
      'order_source': 'pos',
      'payment_method': 'cash',
      'payment_status': 'unpaid',
      'subtotal': 30000,
      'discount': 0,
      'tax': 0,
      'total': 30000,
      'paid': 0,
      'change': 0,
      'status': 'pending',
      'cashier': {'id': 1, 'name': 'Kasir Budi'},
      'items': [],
    },
    {
      'id': 104,
      'invoice_number': 'INV-20260905-004',
      'customer_name': 'Pelanggan Dave',
      'table_number': '01',
      'order_type': 'dine_in',
      'order_source': 'pos',
      'payment_method': 'cash',
      'payment_status': 'refunded',
      'subtotal': 40000,
      'discount': 0,
      'tax': 0,
      'total': 40000,
      'paid': 40000,
      'change': 0,
      'status': 'cancelled',
      'cashier': {'id': 1, 'name': 'Kasir Budi'},
      'cancelled_info': {
        'cancelled_reason': 'Pelanggan salah pesan',
        'cancelled_by_name': 'Admin Budi',
      },
      'items': [],
    },
  ];

  testWidgets('Pumps AdminTransactionsTab on desktop and verifies search & filter chips with badges', (tester) async {
    final mockApi = MockApiProvider();
    Get.put<ApiProvider>(mockApi);

    final controller = TestAdminController();
    Get.put<AdminController>(controller);

    controller.transactions.value = trxJsonList.map((e) => AdminTransactionModel.fromJson(e)).toList();

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminTransactionsTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Metric strip
    expect(find.text('Total Transaksi'), findsWidgets);
    expect(find.text('Total Omzet (Selesai)'), findsWidgets);
    expect(find.text('Rata-rata Belanja (AOV)'), findsWidgets);
    expect(find.text('Estimasi Laba Bersih'), findsWidgets);

    // Verify Searchbar
    expect(find.text('Cari no. invoice, kasir, meja, pelanggan...'), findsOneWidget);
    expect(find.text('Filter Tanggal'), findsOneWidget);
    expect(find.text('Cari'), findsOneWidget);

    // Verify Status Filters
    expect(find.text('Semua Status'), findsOneWidget);
    expect(find.text('Selesai'), findsWidgets);
    expect(find.text('Open Bill'), findsWidgets);
    expect(find.text('Batal (Void)'), findsWidgets);

    // Verify Badges for Open Bill (count: 2) and Batal (count: 1)
    expect(find.text('2'), findsWidgets); // Open Bill count
    expect(find.text('1'), findsWidgets); // Batal count

    // Verify Channel Filters
    expect(find.text('Semua Saluran'), findsOneWidget);
    expect(find.text('Kasir POS'), findsWidgets);
    expect(find.text('Online (Self-Order)'), findsWidgets);

    // Tap Open Bill filter
    await tester.tap(find.widgetWithText(InkWell, 'Open Bill').first);
    await tester.pumpAndSettle();
    expect(controller.selectedTrxStatus.value, 'pending');

    // Tap Batal (Void) filter
    await tester.tap(find.widgetWithText(InkWell, 'Batal (Void)').first);
    await tester.pumpAndSettle();
    expect(controller.selectedTrxStatus.value, 'cancelled');
  });

  testWidgets('Pumps AdminTransactionsTab on mobile screen without overflow', (tester) async {
    final mockApi = MockApiProvider();
    Get.put<ApiProvider>(mockApi);

    final controller = TestAdminController();
    Get.put<AdminController>(controller);

    controller.transactions.value = trxJsonList.map((e) => AdminTransactionModel.fromJson(e)).toList();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminTransactionsTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verification on mobile view
    expect(find.text('Pelanggan Alice'), findsWidgets);
    expect(find.text('Pelanggan Bob'), findsWidgets);
    expect(find.text('Cari'), findsOneWidget);
    expect(find.text('Filter Tanggal'), findsOneWidget);
  });
}
