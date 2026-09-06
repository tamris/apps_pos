import 'package:flutter_test/flutter_test.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/core/utils/date_formatter.dart';
import 'package:noli_apps/app/data/models/cart_item_model.dart';
import 'package:noli_apps/app/data/models/product_model.dart';

void main() {
  group('Unit Tests POS Utilities & Models', () {
    test('CurrencyFormatter formats IDR correctly', () {
      expect(CurrencyFormatter.format(15000), 'Rp 15.000');
      expect(CurrencyFormatter.format(0), 'Rp 0');
      expect(CurrencyFormatter.formatWithoutSymbol(250000), '250.000');
    });

    test('DateFormatter handles null and string dates', () {
      expect(DateFormatter.formatDateTime(null), '-');
      final formatted = DateFormatter.formatReceiptDate('2026-09-01 14:30:00');
      expect(formatted, '01/09/2026 14:30');
    });

    test('CartItemModel computes subtotal and customization key', () {
      final product = ProductModel(
        id: 1,
        categoryId: 1,
        categoryName: 'Minuman',
        name: 'Kopi Susu Gula Aren',
        price: 18000,
      );

      final item = CartItemModel(
        product: product,
        quantity: 2,
        sugarLevel: 'Less Sugar (50%)',
        iceLevel: 'Less Ice',
        notes: 'Gelas besar',
      );

      expect(item.subtotal, 36000);
      expect(item.customizationSummary, 'Less Sugar (50%) • Less Ice • Gelas besar');
      expect(item.itemKey, '1_Less Sugar (50%)_Less Ice__Gelas besar');
    });
  });
}
