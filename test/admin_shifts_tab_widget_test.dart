import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/data/models/admin_shift_model.dart';
import 'package:noli_apps/app/data/providers/api_provider.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'package:noli_apps/app/modules/admin/views/tabs/admin_shifts_tab.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/admin_shift_detail_dialog.dart';

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

  final shiftJsonList = [
    {
      'id': 1,
      'cashier': {
        'id': 3,
        'name': 'Kasir Budi',
        'email': 'budi@example.com',
      },
      'start_time': '2026-09-05T08:00:00.000Z',
      'end_time': null,
      'status': 'open',
      'starting_cash': 200000,
      'cash_sales': 500000,
      'qris_sales': 300000,
      'transfer_sales': 100000,
      'total_sales': 900000,
      'total_transactions': 15,
      'expected_cash': 700000,
      'actual_cash': null,
      'difference': null,
      'discrepancy_status': 'balanced',
      'notes': '',
    },
    {
      'id': 2,
      'cashier': {
        'id': 4,
        'name': 'Kasir Siti',
        'email': 'siti@example.com',
      },
      'start_time': '2026-09-05T08:00:00.000Z',
      'end_time': '2026-09-05T16:00:00.000Z',
      'status': 'closed',
      'starting_cash': 200000,
      'cash_sales': 450000,
      'qris_sales': 250000,
      'transfer_sales': 0,
      'total_sales': 700000,
      'total_transactions': 12,
      'expected_cash': 650000,
      'actual_cash': 635000,
      'difference': -15000,
      'discrepancy_status': 'shortage',
      'notes': 'Ada pengembalian uang receh',
    },
  ];

  testWidgets('Pumps AdminShiftsTab on desktop and verifies UI elements', (tester) async {
    final mockApi = MockApiProvider();
    Get.put<ApiProvider>(mockApi);

    final controller = TestAdminController();
    Get.put<AdminController>(controller);

    controller.shifts.value = shiftJsonList.map((e) => AdminShiftModel.fromJson(e)).toList();

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminShiftsTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify KPI cards
    expect(find.text('Total Shift'), findsWidgets);
    expect(find.text('Total Omzet Kasir'), findsWidgets);
    expect(find.text('Shift Aktif'), findsWidgets);
    expect(find.text('Audit Arus Kas'), findsWidgets);

    // Verify Cashiers rendered
    expect(find.text('Kasir Budi'), findsWidgets);
    expect(find.text('Kasir Siti'), findsWidgets);

    // Filter by search query
    controller.shiftSearchQuery.value = 'Siti';
    await tester.pumpAndSettle();

    expect(find.text('Kasir Siti'), findsWidgets);
    expect(find.text('Kasir Budi'), findsNothing);

    // Reset search
    controller.shiftSearchQuery.value = '';
    await tester.pumpAndSettle();
    expect(find.text('Kasir Budi'), findsWidgets);
    expect(find.text('Kasir Siti'), findsWidgets);
  });

  testWidgets('Pumps AdminShiftsTab on mobile screen without overflow', (tester) async {
    final mockApi = MockApiProvider();
    Get.put<ApiProvider>(mockApi);

    final controller = TestAdminController();
    Get.put<AdminController>(controller);

    controller.shifts.value = shiftJsonList.map((e) => AdminShiftModel.fromJson(e)).toList();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminShiftsTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Kasir Budi'), findsWidgets);
    expect(find.text('Kasir Siti'), findsWidgets);
  });

  testWidgets('Pumps AdminShiftDetailDialog with mathematical reconciliation', (tester) async {
    final detailJson = {
      'id': 2,
      'cashier': {
        'id': 4,
        'name': 'Kasir Siti',
        'email': 'siti@example.com',
      },
      'start_time': '2026-09-05T08:00:00.000Z',
      'end_time': '2026-09-05T16:00:00.000Z',
      'status': 'closed',
      'starting_cash': 200000,
      'cash_sales': 450000,
      'qris_sales': 250000,
      'transfer_sales': 0,
      'total_sales': 700000,
      'total_transactions': 2,
      'expected_cash': 650000,
      'actual_cash': 635000,
      'difference': -15000,
      'discrepancy_status': 'shortage',
      'notes': 'Ada pengembalian uang receh',
      'transactions': [
        {
          'id': 101,
          'invoice_number': 'INV-20260905-001',
          'total': 450000,
          'payment_method': 'cash',
          'order_type': 'dine_in',
          'status': 'completed',
          'created_at': '2026-09-05T09:00:00.000Z',
        },
        {
          'id': 102,
          'invoice_number': 'INV-20260905-002',
          'total': 250000,
          'payment_method': 'qris',
          'order_type': 'take_away',
          'status': 'completed',
          'created_at': '2026-09-05T11:00:00.000Z',
        },
      ],
    };

    final detailModel = AdminShiftDetailModel.fromJson(detailJson);

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: AdminShiftDetailDialog(shift: detailModel),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Dialog content
    expect(find.text('Kasir Siti'), findsWidgets);
    expect(find.text('Audit & Rekonsiliasi Laci Kasir'), findsWidgets);
    expect(find.text('Ekspektasi Uang Laci (Sistem)'), findsWidgets);
    expect(find.text('Hitungan Fisik Aktual (Kasir)'), findsWidgets);
    expect(find.text('Hasil Audit: Selisih Kurang (Defisit)'), findsWidgets);
    expect(find.text('Rincian Pembayaran Shift'), findsWidgets);
    expect(find.text('Uang Tunai'), findsWidgets);
    expect(find.text('QRIS Digital'), findsWidgets);
    expect(find.text('Ada pengembalian uang receh'), findsWidgets);
  });

  testWidgets('Pumps AdminShiftDetailDialog on mobile screen without overflow', (tester) async {
    final detailJson = {
      'id': 12,
      'cashier_name': 'Kasir Siti Nurhaliza Sangat Panjang Sekali Namanya',
      'cashier_email': 'siti.nurhaliza.panjang.sekali.emailnya@gmail.com',
      'start_time': '2026-09-05T08:00:00.000Z',
      'end_time': '2026-09-05T16:30:00.000Z',
      'status': 'closed',
      'starting_cash': 200000,
      'cash_sales': 450000,
      'qris_sales': 250000,
      'transfer_sales': 0,
      'total_sales': 700000,
      'total_transactions': 2,
      'expected_cash': 650000,
      'actual_cash': 635000,
      'difference': -15000,
      'discrepancy_status': 'shortage',
      'notes': 'Catatan penutupan kasir shift pagi',
      'transactions': [],
    };

    final detailModel = AdminShiftDetailModel.fromJson(detailJson);

    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: AdminShiftDetailDialog(shift: detailModel),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Audit & Rekonsiliasi Laci Kasir'), findsWidgets);
    expect(find.text('Uang Tunai'), findsWidgets);
    expect(find.text('QRIS Digital'), findsWidgets);
    expect(find.text('Transfer Bank'), findsWidgets);
    expect(find.text('Tutup'), findsWidgets);
  });
}
