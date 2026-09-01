import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _compactRupiahFormat = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format angka ke Rupiah standar: `Rp 25.000`
  static String format(dynamic amount) {
    if (amount == null) return 'Rp 0';
    if (amount is String) {
      amount = double.tryParse(amount) ?? 0;
    }
    return _rupiahFormat.format(amount);
  }

  /// Format angka tanpa simbol "Rp ": `25.000`
  static String formatWithoutSymbol(dynamic amount) {
    if (amount == null) return '0';
    if (amount is String) {
      amount = double.tryParse(amount) ?? 0;
    }
    return NumberFormat('#,###', 'id_ID').format(amount);
  }

  /// Format ringkas untuk badge: `Rp 25K`
  static String formatCompact(dynamic amount) {
    if (amount == null) return 'Rp 0';
    if (amount is String) {
      amount = double.tryParse(amount) ?? 0;
    }
    return _compactRupiahFormat.format(amount);
  }
}
