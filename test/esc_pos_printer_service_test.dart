import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/data/services/esc_pos_printer_service.dart';
import 'package:noli_apps/app/data/services/storage_service.dart';

class MockStorageService extends GetxService implements StorageService {
  @override
  String? get printerName => 'Test Printer';
  @override
  String? get printerMac => '00:11:22:33:44:55';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.reset();
    Get.put<StorageService>(MockStorageService());
  });

  tearDown(() {
    Get.reset();
  });

  group('EscPosPrinterService Native QR Code & Barcode Tests', () {
    test('buildEscPosQrCode returns empty list for empty string', () {
      final bytes = EscPosPrinterService.buildEscPosQrCode('');
      expect(bytes, isEmpty);
    });

    test(
      'buildEscPosQrCode generates correct ESC/POS Model 2 QR byte stream',
      () {
        const url = 'https://noli.cafe/claim/ABC123XYZ';
        final bytes = EscPosPrinterService.buildEscPosQrCode(
          url,
          moduleSize: 5,
        );

        expect(bytes, isNotEmpty);

        // 0. Align center: ESC a 1 (\x1b\x61\x01)
        expect(bytes.sublist(0, 3), equals([0x1B, 0x61, 0x01]));

        // 1. Model 2 QR Code command: GS ( k \x04 \x00 \x31 \x41 \x32 \x00
        expect(
          bytes.sublist(3, 12),
          equals([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]),
        );

        // 2. Module Size command: GS ( k \x03 \x00 \x31 \x43 \x05
        expect(
          bytes.sublist(12, 20),
          equals([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, 0x05]),
        );

        // 3. Error Correction Level M: GS ( k \x03 \x00 \x31 \x45 \x31
        expect(
          bytes.sublist(20, 28),
          equals([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x31]),
        );

        // 4. Contains encoded URL
        final rawString = String.fromCharCodes(bytes);
        expect(rawString.contains(url), isTrue);

        // 5. Ends with print symbol command (Function 181: GS ( k \x03 \x00 \x31 \x51 \x30 \x0A)
        final endSub = bytes.sublist(bytes.length - 9);
        expect(
          endSub,
          equals([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30, 0x0A]),
        );
      },
    );

    test('buildEscPosBarcode128 generates valid Code 128 commands', () {
      const code = 'INV-20261016-001';
      final bytes = EscPosPrinterService.buildEscPosBarcode128(
        code,
        height: 60,
      );

      expect(bytes, isNotEmpty);
      // Align center
      expect(bytes.sublist(0, 3), equals([0x1B, 0x61, 0x01]));
      // GS h 60
      expect(bytes.sublist(3, 6), equals([0x1D, 0x68, 60]));
      // Contains code string
      final rawString = String.fromCharCodes(bytes);
      expect(rawString.contains(code), isTrue);
    });

    test('line32 formats 32 column receipt line with proper alignment', () {
      final line = EscPosPrinterService.line32('Subtotal', '25.000');
      expect(line.length, equals(32));
      expect(line.startsWith('Subtotal'), isTrue);
      expect(line.endsWith('25.000'), isTrue);
    });

    test('formatNumber formats numbers with dots as thousand separators', () {
      expect(EscPosPrinterService.formatNumber(50000), equals('50.000'));
      expect(EscPosPrinterService.formatNumber(1500000), equals('1.500.000'));
      expect(EscPosPrinterService.formatNumber(0), equals('0'));
    });

    test('generateCustomerReceiptBytes does not include member status and points for member transactions', () async {
      final service = EscPosPrinterService();
      final payload = {
        'header': {'shop_name': 'NOLI COFFEE'},
        'invoice_number': 'INV-001',
        'date': '2026-10-16 10:00',
        'cashier_name': 'Kasir',
        'order_type': 'DINE IN',
        'customer_name': 'Rian Pratama',
        'customer_phone': '081234567890',
        'items': [
          {'name': 'Kopi', 'quantity': 1, 'price': 15000, 'subtotal': 15000}
        ],
        'summary': {'subtotal': 15000, 'total': 15000, 'payment_method': 'TUNAI', 'paid': 15000, 'change': 0},
        'loyalty': {
          'customer_phone': '081234567890',
          'points_earned': 10,
          'points_balance': 100,
        },
      };

      final bytes = await service.generateCustomerReceiptBytes(payload);
      final text = String.fromCharCodes(bytes);

      expect(text.contains('Status Member'), isFalse);
      expect(text.contains('Poin Diperoleh'), isFalse);
      expect(text.contains('Sisa Saldo Poin'), isFalse);
    });
  });
}
