import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/data/models/admin_dashboard_model.dart';
import 'package:noli_apps/app/data/providers/api_provider.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'package:noli_apps/app/modules/admin/views/tabs/admin_dashboard_tab.dart';

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
}

void main() {
  setUp(() {
    Get.reset();
  });

  testWidgets('Pumps AdminDashboardTab without error', (tester) async {
    final mockApi = MockApiProvider();
    Get.put<ApiProvider>(mockApi);

    final controller = TestAdminController();
    Get.put<AdminController>(controller);

    final json = {
      'date': '2026-09-05',
      'summary': {
        'total_revenue': 1500000,
        'total_transactions': 25,
        'average_per_transaction': 60000,
      },
      'payment_breakdown': {
        'cash': {'count': 10, 'total': 500000},
        'qris': {'count': 10, 'total': 700000},
        'transfer': {'count': 5, 'total': 300000},
      },
      'order_source_breakdown': {
        'pos': {'count': 20, 'total': 1200000, 'label': 'Kasir POS'},
        'self_order': {'count': 5, 'total': 300000, 'label': 'Self-Order (Online)'},
      },
      'order_type_breakdown': {
        'dine_in': {'count': 18, 'total': 1000000, 'label': 'Dine In'},
        'takeaway': {'count': 7, 'total': 500000, 'label': 'Take Away'},
      },
      'active_shift': {
        'shift_id': 12,
        'cashier_id': 3,
        'cashier_name': 'Kasir Budi',
        'starting_cash': 200000,
        'cash_sales': 500000,
        'expected_cash': 700000,
      },
      'open_bills_summary': {
        'count': 3,
        'potential_revenue': 250000,
      },
      'cancellations_summary': {
        'count': 1,
        'total_nominal': 50000,
      },
    };

    controller.dashboardData.value = AdminDashboardModel.fromJson(json);

    // Set size to tablet/desktop
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminDashboardTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Rp 1.500.000'), findsWidgets);
    expect(find.text('Shift Kasir'), findsWidgets);
    expect(find.text('Kasir Budi'), findsWidgets);
  });

  testWidgets('Pumps AdminDashboardTab on mobile screen without error', (tester) async {
    final mockApi = MockApiProvider();
    Get.put<ApiProvider>(mockApi);

    final controller = TestAdminController();
    Get.put<AdminController>(controller);

    final json = {
      'date': '2026-09-05',
      'summary': {
        'total_revenue': 1500000,
        'total_transactions': 25,
        'average_per_transaction': 60000,
      },
      'payment_breakdown': {
        'cash': {'count': 10, 'total': 500000},
        'qris': {'count': 10, 'total': 700000},
        'transfer': {'count': 5, 'total': 300000},
      },
      'order_source_breakdown': {
        'pos': {'count': 20, 'total': 1200000, 'label': 'Kasir POS'},
        'online_order': {'count': 5, 'total': 300000, 'label': 'Self-Order (Online)'},
      },
      'order_type_breakdown': {
        'dine_in': {'count': 18, 'total': 1000000, 'label': 'Dine In'},
        'takeaway': {'count': 7, 'total': 500000, 'label': 'Take Away'},
      },
      'active_shift': {
        'shift_id': 12,
        'cashier_id': 3,
        'cashier_name': 'Kasir Budi',
        'starting_cash': 200000,
        'cash_sales': 500000,
        'expected_cash': 700000,
        'total_sales': 1200000,
        'total_transactions': 20,
      },
      'open_bills_summary': {
        'count': 3,
        'potential_revenue': 250000,
      },
      'cancellations_summary': {
        'count': 1,
        'total_nominal': 50000,
      },
    };

    controller.dashboardData.value = AdminDashboardModel.fromJson(json);

    // Set size to mobile phone (390 x 844)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminDashboardTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Rp 1.500.000'), findsWidgets);
    expect(find.text('Shift Kasir'), findsWidgets);
  });

  testWidgets('Pumps AdminDashboardTab on narrow desktop/tablet (800x700) without overflow', (tester) async {
    final mockApi = MockApiProvider();
    Get.put<ApiProvider>(mockApi);

    final controller = TestAdminController();
    Get.put<AdminController>(controller);

    final json = {
      'date': '2026-09-05',
      'summary': {
        'total_revenue': 1098000,
        'total_transactions': 18,
        'average_per_transaction': 61000,
      },
      'payment_breakdown': {
        'cash': {'count': 11, 'total': 435000},
        'qris': {'count': 7, 'total': 663000},
        'transfer': {'count': 0, 'total': 0},
      },
      'order_source_breakdown': {
        'pos': {'count': 17, 'total': 1000000, 'label': 'Kasir POS'},
        'online_order': {'count': 1, 'total': 98000, 'label': 'Online'},
      },
      'order_type_breakdown': {
        'dine_in': {'count': 16, 'total': 950000, 'label': 'Dine-in'},
        'takeaway': {'count': 2, 'total': 148000, 'label': 'Takeaway'},
      },
      'active_shift': null,
      'open_bills_summary': {
        'count': 0,
        'potential_revenue': 0,
      },
      'cancellations_summary': {
        'count': 2,
        'total_nominal': 273000,
      },
    };

    controller.dashboardData.value = AdminDashboardModel.fromJson(json);

    // Screen size 800x700 triggers isWide (>= 760) but < 880
    tester.view.physicalSize = const Size(800, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminDashboardTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Distribusi Pesanan'), findsOneWidget);
    expect(find.text('SALURAN'), findsOneWidget);
    expect(find.text('TIPE'), findsOneWidget);
    expect(find.text('Rp 1.098.000'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

