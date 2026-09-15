import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/data/models/open_bill_model.dart';
import 'package:noli_apps/app/data/providers/api_provider.dart';
import 'package:noli_apps/app/data/services/esc_pos_printer_service.dart';
import 'package:noli_apps/app/data/services/storage_service.dart';
import 'package:noli_apps/app/modules/open_bills/controllers/open_bills_controller.dart';
import 'package:noli_apps/app/modules/open_bills/views/open_bills_view.dart';

class MockApiProvider extends GetxService implements ApiProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockStorageService extends GetxService implements StorageService {
  @override
  List<Map<String, dynamic>> getOfflineOpenBills() => [];

  @override
  List<Map<String, dynamic>> getCachedServerOpenBills() => [];

  @override
  List<int> getOfflineCompletedServerBillIds() => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPrinterService extends GetxService implements EscPosPrinterService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestOpenBillsController extends OpenBillsController {
  @override
  Future<void> fetchOpenBills() async {}
}

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  OpenBillModel createSampleBill({
    required int id,
    required String invoice,
    required String table,
    required int itemCount,
    required double total,
  }) {
    final details = List.generate(
      itemCount,
      (index) => OpenBillDetailItem(
        id: index + 1,
        productId: index + 1,
        name: 'Item ${index + 1}',
        quantity: 1,
        price: 15000,
        subtotal: 15000,
      ),
    );

    return OpenBillModel(
      id: id,
      invoiceNumber: invoice,
      orderType: 'dine_in',
      tableNumber: table,
      customerName: 'Customer $id',
      total: total,
      itemsCount: itemCount,
      createdAt: '2026-09-15 12:41:00',
      time: '12:41',
      date: '2026-09-15',
      details: details,
    );
  }

  testWidgets('Pumps OpenBillsView on desktop (1280x800) and verifies compact card grid', (tester) async {
    Get.put<ApiProvider>(MockApiProvider());
    Get.put<StorageService>(MockStorageService());
    Get.put<EscPosPrinterService>(MockPrinterService());

    final controller = Get.put<OpenBillsController>(TestOpenBillsController());

    // 2 bills matching user screenshot: 1 with 10 items (+7 menu lainnya), 1 with 2 items
    controller.openBills.assignAll([
      createSampleBill(id: 6, invoice: 'INV-20260915-0006', table: '02', itemCount: 10, total: 129000),
      createSampleBill(id: 5, invoice: 'INV-20260915-0005', table: '01', itemCount: 2, total: 21000),
    ]);

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: OpenBillsView(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and summary
    expect(find.text('Bill Aktif (2)'), findsOneWidget);
    expect(find.text('2 Bill Tersimpan'), findsOneWidget);

    // Verify Meja 02 card
    expect(find.text('Meja 02'), findsOneWidget);
    expect(find.text('INV-20260915-0006'), findsOneWidget);
    expect(find.text('+7 menu lainnya...'), findsOneWidget);
    expect(find.text('Total Tagihan (10 item)'), findsOneWidget);

    // Verify Meja 01 card
    expect(find.text('Meja 01'), findsOneWidget);
    expect(find.text('INV-20260915-0005'), findsOneWidget);
    expect(find.text('Total Tagihan (2 item)'), findsOneWidget);

    // Verify Cetak Struk buttons
    expect(find.text('Cetak Struk'), findsNWidgets(2));
  });

  testWidgets('Pumps OpenBillsView on mobile (390x844) without any overflow errors', (tester) async {
    Get.put<ApiProvider>(MockApiProvider());
    Get.put<StorageService>(MockStorageService());
    Get.put<EscPosPrinterService>(MockPrinterService());

    final controller = Get.put<OpenBillsController>(TestOpenBillsController());

    controller.openBills.assignAll([
      createSampleBill(id: 6, invoice: 'INV-20260915-0006', table: '02', itemCount: 10, total: 129000),
      createSampleBill(id: 5, invoice: 'INV-20260915-0005', table: '01', itemCount: 2, total: 21000),
    ]);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: OpenBillsView(),
      ),
    );
    expect(find.text('Bill Aktif (2)'), findsOneWidget);
    expect(find.text('Meja 02'), findsOneWidget);
    expect(find.text('Meja 01'), findsOneWidget);
  });

  testWidgets('Pumps OpenBillsView on tablet (800x1280) without overflow and verifies grid layout', (tester) async {
    Get.put<ApiProvider>(MockApiProvider());
    Get.put<StorageService>(MockStorageService());
    Get.put<EscPosPrinterService>(MockPrinterService());

    final controller = Get.put<OpenBillsController>(TestOpenBillsController());

    controller.openBills.assignAll([
      createSampleBill(id: 6, invoice: 'INV-20260915-0006', table: '02', itemCount: 10, total: 129000),
      createSampleBill(id: 5, invoice: 'INV-20260915-0005', table: '01', itemCount: 2, total: 21000),
    ]);

    tester.view.physicalSize = const Size(800, 1280);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: OpenBillsView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bill Aktif (2)'), findsOneWidget);
    expect(find.text('Meja 02'), findsOneWidget);
    expect(find.text('Meja 01'), findsOneWidget);
  });
}
