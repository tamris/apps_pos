import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'storage_service.dart';
import '../../core/utils/app_snackbar.dart';

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
      AppSnackbar.danger('Bluetooth Error', 'Gagal memindai perangkat bluetooth: $e');
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
        AppSnackbar.success('Printer Terhubung', '$deviceName siap digunakan untuk cetak struk.');
        return true;
      } else {
        isConnected.value = false;
        AppSnackbar.danger('Koneksi Gagal', 'Tidak dapat terhubung ke $deviceName.');
        return false;
      }
    } catch (e) {
      isConnected.value = false;
      AppSnackbar.danger('Koneksi Error', e.toString());
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
      AppSnackbar.info('Printer Terputus', 'Koneksi printer telah diputus.');
    } catch (_) {}
  }

  /// Format baris 32 kolom presisi untuk thermal printer 58mm (Font A Standard)
  static String line32(String left, String right, {int width = 32}) {
    left = left.trim();
    right = right.trim();
    final int leftLen = left.length;
    final int rightLen = right.length;

    if (leftLen + rightLen >= width) {
      final int maxLeft = width - rightLen - 1;
      if (maxLeft > 0) {
        left = left.substring(0, maxLeft);
      }
      return '$left $right';
    } else {
      final int spaces = width - leftLen - rightLen;
      return '$left${' ' * spaces}$right';
    }
  }

  /// Format angka ribuan (e.g. 25000 -> 25.000)
  static String formatNumber(num value) {
    final parts = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }

  /// Konversi gambar menjadi ESC/POS Column Bit-Image (ESC * 33 - 24 Dot Double Density)
  /// Standar universal yang didukung oleh 100% printer thermal ESC/POS 58mm & 80mm
  static List<int> convertImageToEscPosBitImage(Uint8List imageBytes, {int maxWidth = 150, int maxHeight = 96}) {
    try {
      final img.Image? decoded = img.decodeImage(imageBytes);
      if (decoded == null) return [];

      int origWidth = decoded.width;
      int origHeight = decoded.height;
      if (origWidth <= 0 || origHeight <= 0) return [];

      // Skala proporsional pas di tengah (sweet spot ~150px / 19mm)
      double scaleW = maxWidth / origWidth;
      double scaleH = maxHeight / origHeight;
      double scale = scaleW < scaleH ? scaleW : scaleH;
      if (scale > 1.0) scale = 1.0;

      int targetWidth = (origWidth * scale).round();
      int targetHeight = (origHeight * scale).round();
      if (targetWidth <= 0 || targetHeight <= 0) return [];

      final img.Image resized = img.copyResize(
        decoded,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );

      final List<int> bytes = [];

      // Align center: \x1ba\x01
      bytes.addAll([0x1B, 0x61, 0x01]);

      // Set line spacing to 24 dots (0.33mm * 24 dots): \x1b3\x18 (24)
      bytes.addAll([0x1B, 0x33, 24]);

      final int width = resized.width;
      final int height = resized.height;

      final int nL = width % 256;
      final int nH = width ~/ 256;

      // Loop through 24-dot vertical bands
      for (int y = 0; y < height; y += 24) {
        // ESC * 33 (24-dot double-density) nL nH
        bytes.addAll([0x1B, 0x2A, 33, nL, nH]);

        for (int x = 0; x < width; x++) {
          for (int k = 0; k < 3; k++) {
            int byteVal = 0;
            for (int bit = 0; bit < 8; bit++) {
              int currentY = y + (k * 8) + bit;
              int isBlack = 0;

              if (currentY < height) {
                final pixel = resized.getPixel(x, currentY);
                if (pixel.a > 80) {
                  double luminance = (0.299 * pixel.r) + (0.587 * pixel.g) + (0.114 * pixel.b);
                  if (luminance < 180) {
                    isBlack = 1;
                  }
                }
              }
              byteVal = (byteVal << 1) | isBlack;
            }
            bytes.add(byteVal);
          }
        }
        // Rapatkan jarak baris di band terakhir agar teks nama cafe naik lebih dekat ke logo
        if (y + 24 >= height) {
          bytes.addAll([0x1B, 0x33, 4]);
        }
        // Line feed: \n
        bytes.add(0x0A);
      }

      // Reset line spacing to default (1/6 inch): \x1b2
      bytes.addAll([0x1B, 0x32]);
      // Reset alignment to center: \x1ba\x01
      bytes.addAll([0x1B, 0x61, 0x01]);

      return bytes;
    } catch (_) {
      return [];
    }
  }

  // ESC/POS Commands
  static const String esc = '\x1b';
  static const String init = '\x1b@';
  static const String alignCenter = '\x1ba\x01';
  static const String alignLeft = '\x1ba\x00';
  static const String fontNormal = '\x1b!\x00';
  static const String doubleHeight = '\x1b!\x10';
  static const String resetBold = '\x1bE\x00\x1bG\x00';
  static const String cutPaper = '\n\n\n\n\x1d\x56\x00';

  /// Generate ESC/POS byte data untuk Struk Transaksi Pelanggan (58mm / 32 kolom)
  /// Format identik 100% dengan ReceiptPrintService.php pada pos-inventory backend
  Future<List<int>> generateCustomerReceiptBytes(Map<String, dynamic> payload) async {
    // Jika backend sudah mengirimkan rawbt_base64 string secara langsung, langsung decode
    if (payload['rawbt_base64'] != null && payload['rawbt_base64'].toString().isNotEmpty) {
      try {
        final decoded = base64Decode(payload['rawbt_base64'].toString());
        if (decoded.isNotEmpty) return List<int>.from(decoded);
      } catch (_) {}
    }

    final header = payload['header'] ?? {};
    final shopName = (header['shop_name'] ?? 'POS CAFE').toString().toUpperCase();
    final address = header['address']?.toString() ?? '';
    final phone = header['phone']?.toString() ?? '';

    final invoice = payload['invoice_number']?.toString() ?? '-';
    final date = payload['date']?.toString() ?? '-';
    final cashier = payload['cashier_name']?.toString() ?? 'Staff';
    final orderType = payload['order_type']?.toString().toUpperCase() ?? 'DINE IN';
    final tableNumber = payload['table_number']?.toString();
    final customerName = payload['customer_name']?.toString();

    final List items = payload['items'] ?? [];
    final summary = payload['summary'] ?? {};
    final double subtotal = (summary['subtotal'] != null) ? double.tryParse(summary['subtotal'].toString()) ?? 0 : 0;
    final double discount = (summary['discount'] != null) ? double.tryParse(summary['discount'].toString()) ?? 0 : 0;
    final double tax = (summary['tax'] != null) ? double.tryParse(summary['tax'].toString()) ?? 0 : 0;
    final double total = (summary['total'] != null) ? double.tryParse(summary['total'].toString()) ?? 0 : 0;
    final String paymentMethod = summary['payment_method']?.toString().toUpperCase() ?? 'CASH';
    final double paid = (summary['paid'] != null) ? double.tryParse(summary['paid'].toString()) ?? 0 : 0;
    final double change = (summary['change'] != null) ? double.tryParse(summary['change'].toString()) ?? 0 : 0;
    final String status = payload['status']?.toString().toLowerCase() ?? 'completed';

    final footer = payload['footer'] ?? {};
    final footerMsg = footer['message']?.toString() ?? 'Terima kasih atas kunjungannya!';
    final wifiName = footer['wifi_name']?.toString();
    final wifiPass = footer['wifi_password']?.toString();

    final List<int> outBytes = [];

    // Inisialisasi awal & bersihkan sisa tebal dari print sebelumnya
    outBytes.addAll(latin1.encode(init + resetBold + fontNormal));

    // 0. LOGO CAFE ESC/POS (JIKA ADA)
    if (header['logo_raster'] != null && header['logo_raster'] is List<int>) {
      outBytes.addAll(header['logo_raster'] as List<int>);
      outBytes.addAll(latin1.encode(resetBold + fontNormal));
    } else {
      // Fallback otomatis muat logo lokal cafe jika tidak ada raster di payload
      try {
        final ByteData byteData = await rootBundle.load('assets/icons/cafe_logo.png');
        final logoBytes = convertImageToEscPosBitImage(byteData.buffer.asUint8List(), maxWidth: 200);
        if (logoBytes.isNotEmpty) {
          outBytes.addAll(logoBytes);
          outBytes.addAll(latin1.encode(resetBold + fontNormal));
        }
      } catch (_) {}
    }

    final buffer = StringBuffer();

    // 1. HEADER TOKO (CENTER & REGULAR CLEAN)
    buffer.write(alignCenter);
    buffer.write('$shopName\n');
    if (address.isNotEmpty) {
      buffer.write('$address\n');
    }
    if (phone.isNotEmpty) {
      buffer.write('Telp: $phone\n');
    }
    buffer.write('--------------------------------\n');

    // 2. METADATA TRANSAKSI (LEFT)
    buffer.write(alignLeft);
    buffer.write('${line32("No. Inv", invoice)}\n');
    buffer.write('${line32("Waktu", date)}\n');
    buffer.write('${line32("Kasir", cashier)}\n');

    if ((tableNumber != null && tableNumber.isNotEmpty) || (customerName != null && customerName.isNotEmpty)) {
      String orderTypeStr = orderType;
      if (orderType.contains('DINE')) {
        orderTypeStr = 'DINE IN${tableNumber != null && tableNumber.isNotEmpty ? " ($tableNumber)" : ""}';
      } else if (orderType.contains('TAKE')) {
        orderTypeStr = 'TAKE AWAY';
      } else if (orderType.contains('DELIVERY')) {
        orderTypeStr = 'DELIVERY';
      }
      buffer.write('${line32("Pesanan", orderTypeStr)}\n');

      if (customerName != null && customerName.isNotEmpty) {
        buffer.write('${line32("Pelanggan", customerName)}\n');
      }
    }
    buffer.write('--------------------------------\n');

    // 3. DAFTAR ITEM PESANAN (TIDAK BOLD, FORMAT PERSIS BACKEND)
    for (var item in items) {
      final name = item['name'] ?? 'Item';
      final int qty = item['quantity'] is int ? item['quantity'] : int.tryParse(item['quantity'].toString()) ?? 1;
      final double price = (item['price'] != null) ? double.tryParse(item['price'].toString()) ?? 0 : 0;
      final double itemSub = (item['subtotal'] != null) ? double.tryParse(item['subtotal'].toString()) ?? (price * qty) : (price * qty);
      final notes = item['notes']?.toString();

      buffer.write('$name\n');
      final qtyPrice = '$qty x ${formatNumber(price)}';
      final subStr = formatNumber(itemSub);
      buffer.write('${line32(qtyPrice, subStr)}\n');

      // Add-ons / Toppings (format persis receipt backend: '  + Extra Shot (4.000)')
      if (item['addons'] != null && item['addons'] is List) {
        for (var addon in (item['addons'] as List)) {
          final aName = addon['name']?.toString() ?? '';
          final aPrice = (addon['price'] != null) ? double.tryParse(addon['price'].toString()) ?? 0 : 0;
          if (aName.isNotEmpty) {
            final addonLine = (aPrice > 0) ? '  + $aName (${formatNumber(aPrice)})' : '  + $aName';
            buffer.write('$addonLine\n');
          }
        }
      }

      if (notes != null && notes.trim().isNotEmpty) {
        buffer.write(' * $notes\n');
      }
    }
    buffer.write('--------------------------------\n');

    // 4. SUB TOTAL & DISKON & PAJAK
    buffer.write('${line32("Subtotal", formatNumber(subtotal))}\n');

    if (discount > 0) {
      final double discNominal = (discount <= 100) ? (subtotal * discount / 100) : discount;
      final String discLabel = 'Diskon${discount <= 100 ? " (${discount.toInt()}%)" : ""}';
      buffer.write('${line32(discLabel, "-${formatNumber(discNominal)}")}\n');
    }

    if (tax > 0) {
      final double taxNominal = (tax <= 100) ? (subtotal * tax / 100) : tax;
      final String taxLabel = 'Pajak${tax <= 100 ? " (${tax.toInt()}%)" : ""}';
      buffer.write('${line32(taxLabel, "+${formatNumber(taxNominal)}")}\n');
    }

    // 5. GRAND TOTAL (DOUBLE HEIGHT, BUKAN BOLD)
    buffer.write('--------------------------------\n');
    buffer.write(doubleHeight);
    buffer.write('${line32("TOTAL", "Rp ${formatNumber(total)}")}\n');
    buffer.write(fontNormal);
    buffer.write('--------------------------------\n');

    // 6. PEMBAYARAN & KEMBALIAN
    if (status == 'pending') {
      buffer.write(alignCenter);
      buffer.write('*** TAGIHAN SEMENTARA ***\n');
      buffer.write('(BELUM LUNAS / OPEN BILL)\n');
      buffer.write(alignLeft);
    } else {
      String payMethod = paymentMethod;
      if (payMethod == 'CASH' || payMethod == 'TUNAI') {
        payMethod = 'TUNAI';
      } else if (payMethod == 'QRIS') {
        payMethod = 'QRIS';
      } else if (payMethod == 'TRANSFER') {
        payMethod = 'TRANSFER';
      }
      buffer.write('${line32("Bayar ($payMethod)", formatNumber(paid))}\n');
      buffer.write('${line32("Kembali", formatNumber(change))}\n');
    }

    // 7. WIFI CAFE (JIKA ADA)
    if ((wifiName != null && wifiName.isNotEmpty) || (wifiPass != null && wifiPass.isNotEmpty)) {
      buffer.write('--------------------------------\n');
      buffer.write(alignCenter);
      String wifiStr = 'WiFi: ${wifiName ?? "-"}';
      if (wifiPass != null && wifiPass.isNotEmpty) {
        wifiStr += ' | Pass: $wifiPass';
      }
      buffer.write('$wifiStr\n');
    }

    // 8. FOOTER
    buffer.write('--------------------------------\n');
    buffer.write(alignCenter);
    buffer.write('$footerMsg\n');
    buffer.write('-- Have a Good Coffee Day --\n');

    // FEED & CUT
    buffer.write(cutPaper);

    outBytes.addAll(latin1.encode(buffer.toString()));
    return List<int>.from(outBytes);
  }

  /// Generate ESC/POS byte data untuk Laporan Tutup Shift Kasir (58mm)
  Future<List<int>> generateShiftReportBytes(Map<String, dynamic> payload) async {
    final header = payload['header'] ?? {};
    final shopName = (header['shop_name'] ?? 'POS CAFE').toString().toUpperCase();
    final address = header['address']?.toString() ?? '';
    final phone = header['phone']?.toString() ?? '';

    final cashier = payload['cashier_name']?.toString() ?? 'Kasir';
    final shiftId = payload['shift_id']?.toString() ?? '#SFT-00001';
    final startTime = payload['start_time']?.toString() ?? '-';
    final endTime = payload['end_time']?.toString() ?? '(Belum Ditutup)';
    final duration = payload['duration']?.toString();
    final status = payload['status']?.toString().toLowerCase() ?? 'closed';

    final summary = payload['summary'] ?? {};
    final double startingCash = (summary['starting_cash'] != null) ? double.tryParse(summary['starting_cash'].toString()) ?? 0 : 0;
    final double cashSales = (summary['cash_sales'] != null) ? double.tryParse(summary['cash_sales'].toString()) ?? 0 : 0;
    final double qrisSales = (summary['qris_sales'] != null) ? double.tryParse(summary['qris_sales'].toString()) ?? 0 : 0;
    final double transferSales = (summary['transfer_sales'] != null) ? double.tryParse(summary['transfer_sales'].toString()) ?? 0 : 0;
    final double totalSales = (summary['total_sales'] != null) ? double.tryParse(summary['total_sales'].toString()) ?? 0 : 0;
    final int totalTx = (summary['total_transactions'] != null) ? int.tryParse(summary['total_transactions'].toString()) ?? 0 : 0;
    final double expectedCash = (summary['expected_cash'] != null) ? double.tryParse(summary['expected_cash'].toString()) ?? 0 : 0;
    final double actualCash = (summary['actual_cash'] != null) ? double.tryParse(summary['actual_cash'].toString()) ?? 0 : 0;
    final double difference = (summary['difference'] != null) ? double.tryParse(summary['difference'].toString()) ?? 0 : 0;
    final String? notes = payload['notes']?.toString();

    final buffer = StringBuffer();
    buffer.write(init);
    buffer.write(resetBold);
    buffer.write(fontNormal);

    // Header
    buffer.write(alignCenter);
    buffer.write('$shopName\n');
    if (address.isNotEmpty) buffer.write('$address\n');
    if (phone.isNotEmpty) buffer.write('Telp: $phone\n');
    buffer.write('--------------------------------\n');
    buffer.write('*** REKAP SHIFT ***\n');
    buffer.write(status == 'closed' ? 'STATUS: DITUTUP (FINAL)\n' : 'STATUS: SHIFT AKTIF\n');
    buffer.write('--------------------------------\n');

    // Meta
    buffer.write(alignLeft);
    buffer.write('${line32("Shift ID", shiftId)}\n');
    buffer.write('${line32("Kasir", cashier)}\n');
    buffer.write('${line32("Buka Shift", startTime)}\n');
    buffer.write('${line32("Tutup Shift", endTime)}\n');
    if (duration != null && duration.isNotEmpty) {
      buffer.write('${line32("Durasi Kerja", duration)}\n');
    }
    buffer.write('--------------------------------\n');

    // Penjualan
    buffer.write('RINCIAN PENJUALAN\n');
    buffer.write('${line32("Total Struk", "$totalTx Trx")}\n');
    buffer.write('${line32("Penjualan Tunai", "Rp ${formatNumber(cashSales)}")}\n');
    buffer.write('${line32("Penjualan QRIS", "Rp ${formatNumber(qrisSales)}")}\n');
    buffer.write('${line32("Penjualan Transfer", "Rp ${formatNumber(transferSales)}")}\n');
    buffer.write('--------------------------------\n');

    // Total Omset
    buffer.write(doubleHeight);
    buffer.write('${line32("TOTAL OMSET", "Rp ${formatNumber(totalSales)}")}\n');
    buffer.write(fontNormal);
    buffer.write('--------------------------------\n');

    // Kas Laci
    buffer.write('REKONSILIASI KAS LACI\n');
    buffer.write('${line32("Modal Kas Awal", "Rp ${formatNumber(startingCash)}")}\n');
    buffer.write('${line32("(+) Total Tunai", "Rp ${formatNumber(cashSales)}")}\n');
    buffer.write('${line32("(=) Kas Harapan", "Rp ${formatNumber(expectedCash)}")}\n');

    if (status == 'closed') {
      buffer.write('${line32("Uang Fisik Kas", "Rp ${formatNumber(actualCash)}")}\n');
      String diffStr = (difference == 0)
          ? 'Rp 0 (PAS)'
          : (difference > 0 ? '+Rp ${formatNumber(difference)} (LEBIH)' : '-Rp ${formatNumber(difference.abs())} (KURANG)');
      buffer.write('--------------------------------\n');
      buffer.write(doubleHeight);
      buffer.write('${line32("SELISIH KAS", diffStr)}\n');
      buffer.write(fontNormal);
    }

    if (notes != null && notes.isNotEmpty) {
      buffer.write('Catatan: $notes\n');
    }

    // Tanda Tangan
    buffer.write('\n');
    buffer.write('${line32("   Kasir", "Supervisor  ")}\n\n\n');
    final kasirName = cashier.length > 10 ? cashier.substring(0, 10) : cashier;
    buffer.write('${line32(" ( $kasirName )", "( .......... )")}\n');

    buffer.write('--------------------------------\n');
    buffer.write(alignCenter);
    final nowStr = DateTime.now().toString().substring(0, 19).replaceAll('-', '/');
    buffer.write('Dicetak: $nowStr\n');
    buffer.write(cutPaper);

    return List<int>.from(latin1.encode(buffer.toString()));
  }

  /// Generate ESC/POS byte data untuk Struk Dapur / Kitchen Order Ticket (58mm)
  Future<List<int>> generateKitchenReceiptBytes(Map<String, dynamic> payload) async {
    final header = payload['header'] ?? {};
    final shopName = (header['shop_name'] ?? 'POS CAFE').toString().toUpperCase();

    final invoice = payload['invoice_number']?.toString() ?? '-';
    final date = payload['date']?.toString() ?? DateTime.now().toString().substring(0, 16);
    final cashier = payload['cashier_name']?.toString() ?? 'Kasir';
    final orderType = payload['order_type']?.toString().toUpperCase() ?? 'DINE IN';
    final tableNumber = payload['table_number']?.toString();
    final customer = payload['customer_name']?.toString();
    final List items = payload['items'] ?? [];

    final buffer = StringBuffer();
    buffer.write(init);
    buffer.write(resetBold);
    buffer.write(fontNormal);

    // 1. HEADER DAPUR / KITCHEN
    buffer.write(alignCenter);
    buffer.write('*** TIKET DAPUR ***\n');
    buffer.write('$shopName\n');
    buffer.write('--------------------------------\n');

    // 2. METADATA ORDER
    buffer.write(alignLeft);
    buffer.write('${line32("No. Inv", invoice)}\n');
    buffer.write('${line32("Waktu", date)}\n');
    buffer.write('${line32("Kasir", cashier)}\n');

    // 3. TIPE PESANAN & MEJA
    buffer.write('--------------------------------\n');
    buffer.write(alignCenter);
    String orderTypeStr = orderType;
    if (orderType.contains('DINE')) {
      orderTypeStr = 'DINE IN${tableNumber != null && tableNumber.isNotEmpty ? " ($tableNumber)" : ""}';
    } else if (orderType.contains('TAKE')) {
      orderTypeStr = 'TAKE AWAY (BUNGKUS)';
    } else if (orderType.contains('DELIVERY')) {
      orderTypeStr = 'DELIVERY (KIRIM)';
    }
    buffer.write('$orderTypeStr\n');

    if (customer != null && customer.isNotEmpty) {
      buffer.write('Pelanggan: $customer\n');
    }
    buffer.write('--------------------------------\n');

    // 4. DAFTAR ITEM PESANAN
    buffer.write(alignLeft);
    int totalItems = 0;
    for (var item in items) {
      final name = item['name'] ?? 'Item';
      final int qty = item['quantity'] is int ? item['quantity'] : int.tryParse(item['quantity'].toString()) ?? 1;
      final notes = item['notes']?.toString();
      totalItems += qty;

      buffer.write('${qty}x  $name\n');

      // Format addon di tiket dapur: '   [+] Extra Shot' persis standar F&B pos-inventory
      if (item['addons'] != null && item['addons'] is List) {
        for (var addon in (item['addons'] as List)) {
          final aName = addon['name']?.toString() ?? '';
          if (aName.isNotEmpty) {
            buffer.write('   [+] $aName\n');
          }
        }
      }

      if (notes != null && notes.trim().isNotEmpty) {
        buffer.write(' >> CTTN: $notes\n');
      }
    }

    // 5. TOTAL ITEM
    buffer.write('--------------------------------\n');
    buffer.write('${line32("TOTAL ITEM", "$totalItems Menu")}\n');
    buffer.write('--------------------------------\n');

    // 6. FOOTER DAPUR
    buffer.write(alignCenter);
    buffer.write('-- SEGERA DISIAPKAN --\n');
    buffer.write(cutPaper);

    return List<int>.from(latin1.encode(buffer.toString()));
  }

  /// Eksekusi cetak struk dapur ke printer Bluetooth
  Future<bool> printKitchenReceipt(Map<String, dynamic> kitchenPayload) async {
    if (!isConnected.value) {
      AppSnackbar.warning('Printer Belum Terhubung', 'Silakan hubungkan printer Bluetooth di Pengaturan.');
      return false;
    }

    try {
      final List<int> rawBytes = await generateKitchenReceiptBytes(kitchenPayload);
      // Wajib konversi ke standard List<int> (bukan Uint8List) agar Android MethodChannel
      // menerimanya sebagai java.util.List dan tidak crash ClassCastException
      final List<int> intList = List<int>.from(rawBytes);
      final bool result = await PrintBluetoothThermal.writeBytes(intList);
      return result;
    } catch (e) {
      AppSnackbar.danger('Gagal Mencetak Dapur', e.toString());
      return false;
    }
  }

  /// Eksekusi cetak struk ke printer Bluetooth
  Future<bool> printReceipt(Map<String, dynamic> receiptPayload) async {
    if (!isConnected.value) {
      AppSnackbar.warning('Printer Belum Terhubung', 'Silakan hubungkan printer Bluetooth 58mm di menu Pengaturan.');
      return false;
    }

    try {
      final List<int> rawBytes = await generateCustomerReceiptBytes(receiptPayload);
      // Wajib konversi ke standard List<int> (bukan Uint8List) agar Android MethodChannel
      // menerimanya sebagai java.util.List dan tidak crash ClassCastException
      final List<int> intList = List<int>.from(rawBytes);
      final bool result = await PrintBluetoothThermal.writeBytes(intList);
      return result;
    } catch (e) {
      AppSnackbar.danger('Gagal Mencetak', e.toString());
      return false;
    }
  }

  /// Eksekusi cetak laporan shift
  Future<bool> printShiftReport(Map<String, dynamic> shiftPayload) async {
    if (!isConnected.value) {
      AppSnackbar.warning('Printer Belum Terhubung', 'Silakan hubungkan printer Bluetooth di Pengaturan.');
      return false;
    }

    try {
      final List<int> rawBytes = await generateShiftReportBytes(shiftPayload);
      // Wajib konversi ke standard List<int> (bukan Uint8List) agar Android MethodChannel
      // menerimanya sebagai java.util.List dan tidak crash ClassCastException
      final List<int> intList = List<int>.from(rawBytes);
      final bool result = await PrintBluetoothThermal.writeBytes(intList);
      return result;
    } catch (e) {
      AppSnackbar.danger('Gagal Mencetak', e.toString());
      return false;
    }
  }

  /// Cetak struk uji coba printer (Menggunakan data contoh realistis & Logo)
  Future<bool> printTestReceipt() async {
    List<int>? logoBytes;
    try {
      final ByteData byteData = await rootBundle.load('assets/icons/cafe_logo.png');
      logoBytes = convertImageToEscPosBitImage(byteData.buffer.asUint8List(), maxWidth: 150, maxHeight: 96);
    } catch (_) {
      try {
        final ByteData byteData = await rootBundle.load('assets/icons/app_icon.png');
        logoBytes = convertImageToEscPosBitImage(byteData.buffer.asUint8List(), maxWidth: 150, maxHeight: 96);
      } catch (_) {}
    }

    final testPayload = {
      'header': {
        'shop_name': 'NOLI COFFEE & SPACE',
        'address': 'Jl. Kh Wahid Hasyim, Slawi Kulon Kec. Slawi, Kab. Tegal Slawi',
        'phone': '081234567890',
        if (logoBytes != null && logoBytes.isNotEmpty) 'logo_raster': logoBytes,
      },
      'invoice_number': 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'date': DateTime.now().toString().substring(0, 16),
      'cashier_name': 'Admin Kasir',
      'order_type': 'DINE IN',
      'table_number': 'MEJA 05',
      'customer_name': 'Budi Santoso',
      'items': [
        {'name': 'Kopi Susu Gula Aren', 'quantity': 2, 'price': 18000, 'subtotal': 36000, 'notes': 'Less Ice'},
        {'name': 'Croissant Butter', 'quantity': 1, 'price': 22000, 'subtotal': 22000, 'notes': 'Hangatkan'},
      ],
      'summary': {
        'subtotal': 58000,
        'discount': 0,
        'tax': 0,
        'total': 58000,
        'payment_method': 'TUNAI',
        'paid': 60000,
        'change': 2000,
      },
      'footer': {
        'message': 'Terima kasih atas kunjungannya!',
        'wifi_name': 'Noli Cafe Guest',
        'wifi_password': 'kopienakbanget',
      },
    };

    return await printReceipt(testPayload);
  }
}
