import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/data/models/admin_product_model.dart';
import 'package:noli_apps/app/data/providers/api_provider.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'package:noli_apps/app/modules/admin/views/admin_view.dart';

import 'package:noli_apps/app/data/models/user_model.dart';
import 'package:noli_apps/app/data/services/storage_service.dart';

class MockApiProvider extends GetxService implements ApiProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockStorageService extends GetxService implements StorageService {
  @override
  UserModel? get user => UserModel(id: 1, name: 'Admin Test', email: 'admin@test.com', role: 'admin');

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
  Future<void> fetchAdminProducts({bool showLoader = true}) async {}

  @override
  Future<void> fetchAdminProductCategories() async {}

  @override
  Future<void> fetchHppSummary({bool showLoader = true}) async {}
}

void main() {
  setUp(() {
    Get.reset();
  });

  testWidgets('Pumps AdminView on mobile and switches to Tab 6', (tester) async {
    Get.put<StorageService>(MockStorageService());
    Get.put<ApiProvider>(MockApiProvider());
    final controller = Get.put<AdminController>(TestAdminController());

    controller.products.value = [
      AdminProductModel(
        id: 1,
        name: 'Americano Ice',
        sku: 'SKU-001',
        categoryId: 1,
        categoryName: 'Coffee',
        price: 15000,
        hargaBeli: 4000,
        isActive: true,
      ),
    ];

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const GetMaterialApp(
        home: AdminView(),
      ),
    );
    await tester.pumpAndSettle();

    // Now switch to Tab 6
    controller.switchTab(6);
    await tester.pumpAndSettle();

    expect(find.text('Americano Ice'), findsOneWidget);
    expect(find.text('Katalog'), findsOneWidget);

    // Switch to SubTab 1 (Kalkulator & Resep HPP)
    controller.setProductManagementSubTab(1);
    await tester.pumpAndSettle();

    // Switch back to SubTab 0
    controller.setProductManagementSubTab(0);
    await tester.pumpAndSettle();

    // Now switch back to Tab 0 (Dashboard) as the user did in screenshot 2!
    controller.switchTab(0);
    await tester.pumpAndSettle();

    expect(find.text('Noli Coffee'), findsOneWidget);
  });

  testWidgets('Pumps AdminView on small mobile (360x640) and switches tabs', (tester) async {
    Get.put<StorageService>(MockStorageService());
    Get.put<ApiProvider>(MockApiProvider());
    final controller = Get.put<AdminController>(TestAdminController());

    controller.products.value = [
      AdminProductModel(
        id: 1,
        name: 'Americano Ice',
        sku: 'SKU-001',
        categoryId: 1,
        categoryName: 'Coffee',
        price: 15000,
        hargaBeli: 4000,
        isActive: true,
      ),
    ];

    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const GetMaterialApp(
        home: AdminView(),
      ),
    );
    await tester.pumpAndSettle();

    // Switch to Tab 6
    controller.switchTab(6);
    await tester.pumpAndSettle();

    expect(find.text('Americano Ice'), findsOneWidget);

    // Switch to SubTab 1
    controller.setProductManagementSubTab(1);
    await tester.pumpAndSettle();

    // Switch back to SubTab 0
    controller.setProductManagementSubTab(0);
    await tester.pumpAndSettle();

    // Switch to Tab 0
    controller.switchTab(0);
    await tester.pumpAndSettle();

    expect(find.text('Noli Coffee'), findsOneWidget);
  });
}
