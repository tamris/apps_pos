import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:get/get.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'storage_service.dart';
import '../../core/utils/currency_formatter.dart';

class EscPosPrinterService extends GetxService {
  final StorageService _storageService = Get.find<StorageService>();

  final RxBool isConnected = false.obs;
  final RxString connectedDeviceName = ''.obs;
  final RxString connectedMacAddress = ''.obs;
  final RxList<BluetoothInfo> availableDevices = <BluetoothInfo>[].obs;
  final RxBool isScanning = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    try {
      final bool status = await PrintBluetoothThermal.connectionStatus;
      isConnected.value = status;
      if (status) {
        connectedDeviceName.value = _storageService.printerName ?? 'Bluetooth Printer';
        connectedMacAddress.value = _storageService.printerMac ?? '';
      }
    } catch (_) {
      isConnected.value = false;
    }
  }

  /// Scan daftar printer Bluetooth yang telah ter-pairing
  Future<List<BluetoothInfo>> scanDevices() async {
    isScanning.value = true;
    try {
      final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      availableDevices.assignAll(devices);
      return devices;
    } catch (e) {
      Get.snackbar('Bluetooth Error', 'Gagal memindai perangkat bluetooth: $e');
      return [];
    } finally {
      isScanning.value = false;
    }
  }

  /// Hubungkan ke Printer Bluetooth berdasarkan MAC Address
  Future<bool> connect(String macAddress, String deviceName) async {
    try {
      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
      if (result) {
        isConnected.value = true;
        connectedDeviceName.value = deviceName;
        connectedMacAddress.value = macAddress;
        await _storageService.savePrinter(macAddress, deviceName);
        Get.snackbar('Printer Terhubung', '$deviceName siap digunakan untuk cetak struk.');
        return true;
      } else {
        isConnected.value = false;
        Get.snackbar('Koneksi Gagal', 'Tidak dapat terhubung ke $deviceName.');
        return false;
      }
    } catch (e) {
      isConnected.value = false;
      Get.snackbar('Koneksi Error', e.toString());
      return false;
    }
  }

  /// Putuskan koneksi printer
  Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
      isConnected.value = false;
      connectedDeviceName.value = '';
      connectedMacAddress.value = '';
      await _storageService.clearPrinter();
      Get.snackbar('Printer Terputus', 'Koneksi printer telah diputus.');
    } catch (_) {}
  }

  /// Generate ESC/POS byte data untuk Struk Transaksi Pelanggan (58mm / 32 kolom)
  Future<List<int>> generateCustomerReceiptBytes(Map<String, dynamic> payload) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // 1. Header Toko
    final header = payload['header'] ?? {};
    final shopName = header['shop_name'] ?? 'POS CAFE';
    final address = header['address'] ?? '';
    final phone = header['phone'] ?? '';

    bytes += generator.reset();
    bytes += generator.text(
      shopName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    if (address.toString().isNotEmpty) {
      bytes += generator.text(
        address,
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
      );
    }
    if (phone.toString().isNotEmpty) {
      bytes += generator.text(
        'Telp: $phone',
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
      );
    }

    bytes += generator.hr(ch: '-');

    // 2. Info Transaksi
    final invoice = payload['invoice_number'] ?? '-';
    final date = payload['date'] ?? '-';
    final cashier = payload['cashier_name'] ?? 'Kasir';
    final orderType = payload['order_type'] ?? 'DINE IN';
    final tableNumber = payload['table_number'];
    final customerName = payload['customer_name'];

    bytes += generator.text('No: $invoice', styles: const PosStyles(bold: true));
    bytes += generator.row([
      PosColumn(text: 'Tgl : $date', width: 7, styles: const PosStyles(fontType: PosFontType.fontB)),
      PosColumn(text: 'Ksr: $cashier', width: 5, styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontB)),
    ]);

    String orderDesc = 'Tipe: $orderType';
    if (tableNumber != null && tableNumber.toString().isNotEmpty) {
      orderDesc += ' | $tableNumber';
    }
    if (customerName != null && customerName.toString().isNotEmpty) {
      orderDesc += ' ($customerName)';
    }
    bytes += generator.text(orderDesc, styles: const PosStyles(fontType: PosFontType.fontB));

    bytes += generator.hr(ch: '=');

    // 3. Item List
    final List items = payload['items'] ?? [];
    for (var item in items) {
      final name = item['name'] ?? 'Item';
      final int qty = item['quantity'] is int ? item['quantity'] : int.tryParse(item['quantity'].toString()) ?? 1;
      final double price = (item['price'] != null) ? double.tryParse(item['price'].toString()) ?? 0 : 0;
      final double subtotal = (item['subtotal'] != null) ? double.tryParse(item['subtotal'].toString()) ?? (price * qty) : (price * qty);
      final notes = item['notes']?.toString();

      // Nama Item
      bytes += generator.text(name, styles: const PosStyles(bold: true));

      // Baris Qty x Harga = Subtotal
      bytes += generator.row([
        PosColumn(
          text: '  $qty x ${CurrencyFormatter.formatWithoutSymbol(price)}',
          width: 7,
          styles: const PosStyles(fontType: PosFontType.fontB),
        ),
        PosColumn(
          text: CurrencyFormatter.formatWithoutSymbol(subtotal),
          width: 5,
          styles: const PosStyles(align: PosAlign.right, fontType: PosFontType.fontB),
        ),
      ]);

      if (notes != null && notes.trim().isNotEmpty) {
        bytes += generator.text(
          '  * $notes',
          styles: const PosStyles(fontType: PosFontType.fontB),
        );
      }
    }

    bytes += generator.hr(ch: '-');

    // 4. Summary & Payment
    final summary = payload['summary'] ?? {};
    final double subtotal = (summary['subtotal'] != null) ? double.tryParse(summary['subtotal'].toString()) ?? 0 : 0;
    final double discount = (summary['discount'] != null) ? double.tryParse(summary['discount'].toString()) ?? 0 : 0;
    final double tax = (summary['tax'] != null) ? double.tryParse(summary['tax'].toString()) ?? 0 : 0;
    final double total = (summary['total'] != null) ? double.tryParse(summary['total'].toString()) ?? 0 : 0;
    final String paymentMethod = summary['payment_method'] ?? 'CASH';
    final double paid = (summary['paid'] != null) ? double.tryParse(summary['paid'].toString()) ?? 0 : 0;
    final double change = (summary['change'] != null) ? double.tryParse(summary['change'].toString()) ?? 0 : 0;

    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 6),
      PosColumn(text: CurrencyFormatter.format(subtotal), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    if (discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Diskon', width: 6),
        PosColumn(text: '-${CurrencyFormatter.format(discount)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    if (tax > 0) {
      bytes += generator.row([
        PosColumn(text: 'Pajak (PB1)', width: 6),
        PosColumn(text: CurrencyFormatter.format(tax), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 5, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(text: CurrencyFormatter.format(total), width: 7, styles: const PosStyles(bold: true, align: PosAlign.right, height: PosTextSize.size2)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Metode Bayar', width: 6),
      PosColumn(text: paymentMethod, width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Bayar', width: 6),
      PosColumn(text: CurrencyFormatter.format(paid), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    if (paymentMethod.toUpperCase() == 'CASH') {
      bytes += generator.row([
        PosColumn(text: 'Kembalian', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: CurrencyFormatter.format(change), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
    }

    bytes += generator.hr(ch: '-');

    // 5. Footer Toko
    final footer = payload['footer'] ?? {};
    final footerMsg = footer['message'] ?? 'Terima Kasih Atas Kunjungan Anda!';
    final wifiName = footer['wifi_name'];
    final wifiPass = footer['wifi_password'];

    bytes += generator.text(
      footerMsg,
      styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    );

    if (wifiName != null && wifiName.toString().isNotEmpty) {
      bytes += generator.text(
        'Wi-Fi: $wifiName | Pass: ${wifiPass ?? "-"}',
        styles: const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
      );
    }

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  /// Generate ESC/POS byte data untuk Laporan Tutup Shift Kasir (58mm)
  Future<List<int>> generateShiftReportBytes(Map<String, dynamic> payload) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    final header = payload['header'] ?? {};
    final shopName = header['shop_name'] ?? 'POS CAFE';
    final title = header['title'] ?? 'REKAP TUTUP SHIFT';

    bytes += generator.reset();
    bytes += generator.text(
      shopName,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    );
    bytes += generator.text(
      title,
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.hr(ch: '=');

    final cashier = payload['cashier_name'] ?? 'Kasir';
    final startTime = payload['start_time'] ?? '-';
    final endTime = payload['end_time'] ?? '-';

    bytes += generator.text('Kasir  : $cashier');
    bytes += generator.text('Mulai  : $startTime');
    bytes += generator.text('Selesai: $endTime');
    bytes += generator.hr(ch: '-');

    final summary = payload['summary'] ?? {};
    final startingCash = summary['starting_cash'] ?? 0;
    final cashSales = summary['cash_sales'] ?? 0;
    final qrisSales = summary['qris_sales'] ?? 0;
    final transferSales = summary['transfer_sales'] ?? 0;
    final totalSales = summary['total_sales'] ?? 0;
    final totalTx = summary['total_transactions'] ?? 0;
    final expectedCash = summary['expected_cash'] ?? 0;
    final actualCash = summary['actual_cash'] ?? 0;
    final difference = summary['difference'] ?? 0;

    bytes += generator.row([
      PosColumn(text: 'Modal Awal', width: 6),
      PosColumn(text: CurrencyFormatter.format(startingCash), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Penjualan Tunai', width: 6),
      PosColumn(text: CurrencyFormatter.format(cashSales), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Penjualan QRIS', width: 6),
      PosColumn(text: CurrencyFormatter.format(qrisSales), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Penjualan Transfer', width: 6),
      PosColumn(text: CurrencyFormatter.format(transferSales), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr(ch: '-');

    bytes += generator.row([
      PosColumn(text: 'TOTAL OMSET', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: CurrencyFormatter.format(totalSales), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Total Transaksi', width: 6),
      PosColumn(text: '$totalTx Trx', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr(ch: '-');

    bytes += generator.row([
      PosColumn(text: 'Kas Seharusnya', width: 6),
      PosColumn(text: CurrencyFormatter.format(expectedCash), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Kas Fisik Riil', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: CurrencyFormatter.format(actualCash), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Selisih Kas', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: CurrencyFormatter.format(difference), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    final notes = payload['notes']?.toString();
    if (notes != null && notes.isNotEmpty) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text('Catatan: $notes', styles: const PosStyles(fontType: PosFontType.fontB));
    }

    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  /// Generate ESC/POS byte data untuk Struk Dapur / Kitchen Order Ticket (58mm)
  Future<List<int>> generateKitchenReceiptBytes(Map<String, dynamic> payload) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.reset();
    bytes += generator.text(
      '*** STRUK DAPUR ***',
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    );
    bytes += generator.hr(ch: '=');

    final invoice = payload['invoice_number'] ?? '-';
    final date = payload['date'] ?? DateTime.now().toString().substring(0, 16);
    final orderType = payload['order_type'] ?? 'DINE IN';
    final tableNumber = payload['table_number'];
    final customer = payload['customer_name'];

    if (tableNumber != null && tableNumber.toString().isNotEmpty) {
      bytes += generator.text(
        'MEJA: $tableNumber',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
      );
    } else {
      bytes += generator.text(
        'TIPE: $orderType',
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
      );
    }

    if (customer != null && customer.toString().isNotEmpty) {
      bytes += generator.text('Pelanggan: $customer');
    }
    bytes += generator.text('No. Order: $invoice');
    bytes += generator.text('Waktu    : $date');
    bytes += generator.hr(ch: '-');

    // List item pesanan
    final List items = payload['items'] ?? [];
    for (var item in items) {
      final name = item['name'] ?? 'Item';
      final qty = item['quantity'] ?? 1;
      final notes = item['notes'];

      bytes += generator.text(
        '$qty x $name',
        styles: const PosStyles(bold: true, height: PosTextSize.size2),
      );
      if (notes != null && notes.toString().isNotEmpty) {
        bytes += generator.text(
          '  * $notes',
          styles: const PosStyles(fontType: PosFontType.fontB),
        );
      }
      bytes += generator.feed(1);
    }

    bytes += generator.hr(ch: '=');
    bytes += generator.text(
      'SEGERA DIPROSES',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }

  /// Eksekusi cetak struk dapur ke printer Bluetooth
  Future<bool> printKitchenReceipt(Map<String, dynamic> kitchenPayload) async {
    if (!isConnected.value) {
      Get.snackbar('Printer Belum Terhubung', 'Silakan hubungkan printer Bluetooth di Pengaturan.');
      return false;
    }

    try {
      final List<int> bytes = await generateKitchenReceiptBytes(kitchenPayload);
      final bool result = await PrintBluetoothThermal.writeBytes(Uint8List.fromList(bytes));
      return result;
    } catch (e) {
      Get.snackbar('Gagal Mencetak Dapur', e.toString());
      return false;
    }
  }

  /// Eksekusi cetak struk ke printer Bluetooth
  Future<bool> printReceipt(Map<String, dynamic> receiptPayload) async {
    if (!isConnected.value) {
      Get.snackbar('Printer Belum Terhubung', 'Silakan hubungkan printer Bluetooth 58mm di menu Pengaturan.');
      return false;
    }

    try {
      final List<int> bytes = await generateCustomerReceiptBytes(receiptPayload);
      final bool result = await PrintBluetoothThermal.writeBytes(Uint8List.fromList(bytes));
      return result;
    } catch (e) {
      Get.snackbar('Gagal Mencetak', e.toString());
      return false;
    }
  }

  /// Eksekusi cetak laporan shift
  Future<bool> printShiftReport(Map<String, dynamic> shiftPayload) async {
    if (!isConnected.value) {
      Get.snackbar('Printer Belum Terhubung', 'Silakan hubungkan printer Bluetooth di Pengaturan.');
      return false;
    }

    try {
      final List<int> bytes = await generateShiftReportBytes(shiftPayload);
      final bool result = await PrintBluetoothThermal.writeBytes(Uint8List.fromList(bytes));
      return result;
    } catch (e) {
      Get.snackbar('Gagal Mencetak', e.toString());
      return false;
    }
  }

  /// Cetak struk uji coba printer
  Future<bool> printTestReceipt() async {
    final testPayload = {
      'header': {
        'shop_name': 'POS TEST 58MM',
        'address': 'Printer Test Thermal Ready',
        'phone': '081234567890',
      },
      'invoice_number': 'TEST-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'date': DateTime.now().toString().substring(0, 16),
      'cashier_name': 'Admin/Kasir',
      'order_type': 'TEST PRINT',
      'items': [
        {'name': 'Kopi Susu Gula Aren', 'quantity': 2, 'price': 18000, 'subtotal': 36000, 'notes': 'Less Ice'},
        {'name': 'Croissant Butter', 'quantity': 1, 'price': 22000, 'subtotal': 22000, 'notes': 'Hangatkan'},
      ],
      'summary': {
        'subtotal': 58000,
        'discount': 0,
        'tax': 0,
        'total': 58000,
        'payment_method': 'TUNAI (CASH)',
        'paid': 60000,
        'change': 2000,
      },
      'footer': {
        'message': 'Printer 58mm Berfungsi Normal!',
        'wifi_name': 'Cafe Guest',
        'wifi_password': 'kopienakbanget',
      },
    };

    return await printReceipt(testPayload);
  }
}
