import 'package:flutter_test/flutter_test.dart';
import 'package:noli_apps/app/data/models/shift_model.dart';

void main() {
  group('ShiftModel switchSalePaymentMethod Tests', () {
    test('Switches from Cash to QRIS correctly', () {
      final initialShift = ShiftModel(
        id: -1,
        status: 'open',
        startingCash: 100000,
        cashSales: 50000,
        qrisSales: 0,
        expectedCash: 150000,
        totalSales: 50000,
        totalTransactions: 1,
      );

      final updatedShift = initialShift.switchSalePaymentMethod(
        amount: 50000,
        oldPaymentMethod: 'cash',
        newPaymentMethod: 'qris',
      );

      expect(updatedShift.cashSales, equals(0.0));
      expect(updatedShift.qrisSales, equals(50000.0));
      expect(updatedShift.expectedCash, equals(100000.0));
      expect(updatedShift.totalSales, equals(50000.0));
    });

    test('Switches from QRIS to Cash correctly', () {
      final initialShift = ShiftModel(
        id: -1,
        status: 'open',
        startingCash: 100000,
        cashSales: 0,
        qrisSales: 50000,
        expectedCash: 100000,
        totalSales: 50000,
        totalTransactions: 1,
      );

      final updatedShift = initialShift.switchSalePaymentMethod(
        amount: 50000,
        oldPaymentMethod: 'qris',
        newPaymentMethod: 'cash',
      );

      expect(updatedShift.cashSales, equals(50000.0));
      expect(updatedShift.qrisSales, equals(0.0));
      expect(updatedShift.expectedCash, equals(150000.0));
      expect(updatedShift.totalSales, equals(50000.0));
    });
  });
}
