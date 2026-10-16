import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/data/models/transaction_model.dart';
import 'package:noli_apps/app/data/providers/api_provider.dart';
import 'package:noli_apps/app/data/services/esc_pos_printer_service.dart';
import 'package:noli_apps/app/data/services/storage_service.dart';
import 'package:noli_apps/app/modules/transactions/controllers/transactions_controller.dart';
import 'package:noli_apps/app/modules/transactions/views/transactions_view.dart';

class MockApiProvider extends GetxService implements ApiProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockStorageService extends GetxService implements StorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPrinterService extends GetxService implements EscPosPrinterService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestTransactionsController extends TransactionsController {
  @override
  Future<void> fetchTodayTransactions({bool silent = false, bool resetPage = true}) async {}
}

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Transaction card in grid mode renders without overflow with max badges and items', (tester) async {
    Get.put<ApiProvider>(MockApiProvider());
    Get.put<StorageService>(MockStorageService());
    Get.put<EscPosPrinterService>(MockPrinterService());
    Get.put<TransactionsController>(TestTransactionsController());

    final tx = TransactionModel(
      id: 101,
      invoiceNumber: 'INV-20261016-0099',
      status: 'completed',
      orderType: 'dine_in',
      tableNumber: 'Meja 12 VIP',
      customerName: 'Budi Santoso Herlambang',
      paymentMethod: 'qris',
      total: 125000,
      paid: 125000,
      change: 0,
      time: '14:35:00',
      date: '2026-10-16',
      details: [
        TransactionDetailModel(
          name: 'Es Kopi Susu Creamy Aren Double Espresso',
          quantity: 2,
          price: 25000,
          subtotal: 50000,
        ),
        TransactionDetailModel(
          name: 'Croissant Butter Warm Baked',
          quantity: 1,
          price: 35000,
          subtotal: 35000,
        ),
        TransactionDetailModel(
          name: 'French Fries Truffle Mayo',
          quantity: 1,
          price: 40000,
          subtotal: 40000,
        ),
        TransactionDetailModel(
          name: 'Mineral Water Cold 600ml',
          quantity: 2,
          price: 10000,
          subtotal: 20000,
        ),
      ],
    );

    final view = TransactionsView();

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 210, // cardExtent
              child: Builder(
                builder: (context) => view.buildTransactionCardForTest(
                  context,
                  tx,
                  isGrid: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify no RenderFlex overflow exception
    expect(tester.takeException(), isNull);
    expect(find.text('INV-20261016-0099'), findsOneWidget);
    expect(find.text('Cetak Struk'), findsOneWidget);
    expect(find.textContaining('item lainnya'), findsOneWidget);
  });
}
