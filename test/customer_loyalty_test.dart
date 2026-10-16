import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/data/models/customer_model.dart';
import 'package:noli_apps/app/data/models/product_model.dart';
import 'package:noli_apps/app/modules/pos/controllers/cart_controller.dart';
import 'package:noli_apps/app/data/providers/api_provider.dart';
import 'package:noli_apps/app/data/services/storage_service.dart';
import 'package:noli_apps/app/data/services/offline_sync_service.dart';
import 'package:noli_apps/app/data/services/esc_pos_printer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CustomerModel Tests', () {
    test('CustomerModel.fromJson parses fields correctly', () {
      final json = {
        'id': 12,
        'name': 'Rian Pratama',
        'phone': '081234567890',
        'points_balance': 150,
        'points_rupiah_value': 150000.0,
        'points_rupiah_formatted': 'Rp 150.000',
        'can_redeem': true,
        'min_redeem': 5,
        'exchange_rate': 1000,
        'created_at': '15/10/2026 14:00',
      };

      final customer = CustomerModel.fromJson(json);

      expect(customer.id, 12);
      expect(customer.name, 'Rian Pratama');
      expect(customer.phone, '081234567890');
      expect(customer.pointsBalance, 150);
      expect(customer.pointsRupiahValue, 150000.0);
      expect(customer.pointsRupiahFormatted, 'Rp 150.000');
      expect(customer.canRedeem, true);
      expect(customer.minRedeem, 5);
      expect(customer.exchangeRate, 1000);
      expect(customer.initials, 'RP');
      expect(customer.formattedPhone, '0812-3456-7890');
      expect(customer.displayName, 'Rian Pratama');
    });

    test('CustomerModel handles null name gracefully', () {
      final json = {
        'id': 5,
        'name': null,
        'phone': '085211223344',
        'points_balance': 0,
      };

      final customer = CustomerModel.fromJson(json);
      expect(customer.displayName, 'Member (0852-1122-3344)');
      expect(customer.initials, 'MB');
      expect(customer.pointsBalance, 0);
      expect(customer.canRedeem, false);
    });
  });

  group('CartController Loyalty & Points Calculation Tests', () {
    late CartController cartController;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      Get.reset();

      final storageService = StorageService();
      await storageService.init();
      Get.put<StorageService>(storageService);
      Get.put<ApiProvider>(ApiProvider());
      Get.put<OfflineSyncService>(OfflineSyncService());
      Get.put<EscPosPrinterService>(EscPosPrinterService());

      cartController = CartController();
      Get.put<CartController>(cartController);
    });

    tearDown(() {
      Get.reset();
    });

    test('Selecting customer sets customer info and resets redeem points', () {
      final customer = CustomerModel(
        id: 1,
        name: 'Rian',
        phone: '081234567890',
        pointsBalance: 50,
        canRedeem: true,
      );

      cartController.selectCustomer(customer);

      expect(cartController.hasCustomer, isTrue);
      expect(cartController.selectedCustomer.value?.id, 1);
      expect(cartController.customerName.value, 'Rian');
      expect(cartController.redeemPoints.value, 0);
      expect(cartController.pointsDiscountAmount, 0.0);
    });

    test('Removing customer cleans up customer and redeem points', () {
      final customer = CustomerModel(
        id: 1,
        name: 'Rian',
        phone: '081234567890',
        pointsBalance: 50,
      );

      cartController.selectCustomer(customer);
      cartController.removeCustomer();

      expect(cartController.hasCustomer, isFalse);
      expect(cartController.selectedCustomer.value, isNull);
      expect(cartController.redeemPoints.value, 0);
    });

    test('Points deduction applies correctly to grandTotal', () {
      // Tambah item ke keranjang seharga Rp 50.000
      final product = ProductModel(
        id: 101,
        name: 'Kopi Susu Gula Aren',
        price: 25000,
        categoryId: 1,
        categoryName: 'Coffee',
      );
      cartController.addItem(product, quantity: 2); // Subtotal: Rp 50.000

      expect(cartController.subtotal, 50000.0);
      expect(cartController.grandTotal, 50000.0);

      // Pasang member dengan saldo 30 poin (exchange rate 1000 = Rp 30.000)
      final customer = CustomerModel(
        id: 1,
        name: 'Rian',
        phone: '081234567890',
        pointsBalance: 30,
        exchangeRate: 1000,
        canRedeem: true,
      );
      cartController.selectCustomer(customer);

      // Tukar 20 poin
      cartController.setRedeemPoints(20);

      expect(cartController.redeemPoints.value, 20);
      expect(cartController.pointsDiscountAmount, 20000.0);
      // Grand Total = 50.000 - 20.000 = 30.000
      expect(cartController.grandTotal, 30000.0);

      // Toggle max redeem (akan redeem maksimal 30 poin = Rp 30.000)
      cartController.toggleMaxRedeem();
      // Saat toggle ketika > 0, akan reset ke 0
      expect(cartController.redeemPoints.value, 0);
      expect(cartController.grandTotal, 50000.0);

      // Toggle lagi -> akan set ke max (30 poin)
      cartController.toggleMaxRedeem();
      expect(cartController.redeemPoints.value, 30);
      expect(cartController.pointsDiscountAmount, 30000.0);
      expect(cartController.grandTotal, 20000.0);
    });

    test('Redeem points does not exceed total bill amount', () {
      final product = ProductModel(
        id: 102,
        name: 'Espresso',
        price: 15000,
        categoryId: 1,
        categoryName: 'Coffee',
      );
      cartController.addItem(product, quantity: 1); // Subtotal: 15.000

      final customer = CustomerModel(
        id: 1,
        name: 'Sultan',
        phone: '081299999999',
        pointsBalance: 100, // Rp 100.000 (jauh di atas tagihan Rp 15.000)
        exchangeRate: 1000,
        canRedeem: true,
      );
      cartController.selectCustomer(customer);

      // Maksimal poin yang bisa ditukar dibatasi oleh total belanja (15.000 / 1000 = 15 poin)
      expect(cartController.maxRedeemablePoints, 15);

      // Mencoba set 50 poin akan otomatis diclamp ke 15 poin
      cartController.setRedeemPoints(50);
      expect(cartController.redeemPoints.value, 15);
      expect(cartController.pointsDiscountAmount, 15000.0);
      expect(cartController.grandTotal, 0.0);
    });

    test('clearCart resets selected customer and redeemed points', () {
      final customer = CustomerModel(
        id: 1,
        name: 'Rian',
        phone: '081234567890',
        pointsBalance: 25,
      );
      cartController.selectCustomer(customer);
      cartController.setRedeemPoints(10);

      cartController.clearCart();

      expect(cartController.selectedCustomer.value, isNull);
      expect(cartController.redeemPoints.value, 0);
      expect(cartController.pointsDiscountAmount, 0.0);
    });
  });
}
