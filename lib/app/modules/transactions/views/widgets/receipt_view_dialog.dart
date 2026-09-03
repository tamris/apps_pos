import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/services/esc_pos_printer_service.dart';
import '../../../../core/utils/app_snackbar.dart';

class ReceiptViewDialog {
  static void show(Map<String, dynamic> payload) {
    final printerService = Get.find<EscPosPrinterService>();

    final header = payload['header'] ?? {};
    final shopName = header['shop_name'] ?? 'POS CAFE';
    final address = header['address'] ?? '';
    final phone = header['phone'] ?? '';
    final String? logoUrl = header['logo_url']?.toString();
    final bool showLogo = (header['show_logo'] is bool) ? header['show_logo'] as bool : true;

    final invoice = payload['invoice_number'] ?? '-';
    final date = payload['date'] ?? '-';
    final cashier = payload['cashier_name'] ?? 'Kasir';
    final orderType = payload['order_type'] ?? 'DINE IN';
    final tableNumber = payload['table_number'];
    final customerName = payload['customer_name'];

    final List items = payload['items'] ?? [];
    final summary = payload['summary'] ?? {};
    final double subtotal = (summary['subtotal'] != null) ? double.tryParse(summary['subtotal'].toString()) ?? 0 : 0;
    final double discount = (summary['discount'] != null) ? double.tryParse(summary['discount'].toString()) ?? 0 : 0;
    final double tax = (summary['tax'] != null) ? double.tryParse(summary['tax'].toString()) ?? 0 : 0;
    final double total = (summary['total'] != null) ? double.tryParse(summary['total'].toString()) ?? 0 : 0;
    final String paymentMethod = summary['payment_method'] ?? 'CASH';
    final double paid = (summary['paid'] != null) ? double.tryParse(summary['paid'].toString()) ?? 0 : 0;
    final double change = (summary['change'] != null) ? double.tryParse(summary['change'].toString()) ?? 0 : 0;

    final footer = payload['footer'] ?? {};
    final footerMsg = footer['message'] ?? 'Terima Kasih Atas Kunjungannya!';
    final wifiName = footer['wifi_name'];
    final wifiPass = footer['wifi_password'];

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFBF7), // Warm receipt paper color
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo Cafe (Dinamis dari Backend URL / Fallback Asset)
                  if (showLogo)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: (logoUrl != null && logoUrl.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: logoUrl,
                              height: 52,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const SizedBox(height: 52),
                              errorWidget: (_, __, ___) => Image.asset(
                                'assets/icons/cafe_logo.png',
                                height: 52,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            )
                          : Image.asset(
                              'assets/icons/cafe_logo.png',
                              height: 52,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                    ),

                  // Shop Header
                  Text(
                    shopName.toUpperCase(),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  if (address.toString().isNotEmpty)
                    Text(address, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  if (phone.toString().isNotEmpty)
                    Text('Telp: $phone', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  const SizedBox(height: 6),
                  const Text('----------------------------------------', style: TextStyle(fontSize: 10, color: Colors.black38)),

                  // Transaction Meta
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReceiptRow('No. Inv', invoice, isBold: true),
                        _buildReceiptRow('Waktu', date),
                        _buildReceiptRow('Kasir', cashier),
                        if ((tableNumber != null && tableNumber.toString().isNotEmpty) || (customerName != null && customerName.toString().isNotEmpty)) ...[
                          _buildReceiptRow(
                            'Pesanan',
                            orderType.contains('DINE')
                                ? 'DINE IN ${tableNumber != null ? "(MEJA $tableNumber)" : ""}'
                                : orderType,
                            isBold: true,
                          ),
                          if (customerName != null && customerName.toString().isNotEmpty)
                            _buildReceiptRow('Pelanggan', customerName.toString(), isBold: true),
                        ],
                      ],
                    ),
                  ),
                  const Text('----------------------------------------', style: TextStyle(fontSize: 10, color: Colors.black38)),

                  // Item Rows
                  ...items.map((item) {
                    final name = item['name'] ?? 'Item';
                    final int qty = item['quantity'] is int ? item['quantity'] : int.tryParse(item['quantity'].toString()) ?? 1;
                    final double price = (item['price'] != null) ? double.tryParse(item['price'].toString()) ?? 0 : 0;
                    final double itemSub = (item['subtotal'] != null) ? double.tryParse(item['subtotal'].toString()) ?? (price * qty) : (price * qty);
                    final notes = item['notes']?.toString();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 11)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('$qty x ${CurrencyFormatter.formatWithoutSymbol(price)}', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                              Text(CurrencyFormatter.formatWithoutSymbol(itemSub), style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                          if (notes != null && notes.trim().isNotEmpty)
                            Text(' * $notes', style: const TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Colors.black54)),
                        ],
                      ),
                    );
                  }),

                  const Text('----------------------------------------', style: TextStyle(fontSize: 10, color: Colors.black38)),

                  // Totals
                  _buildReceiptRow('Subtotal', CurrencyFormatter.formatWithoutSymbol(subtotal)),
                  if (discount > 0) _buildReceiptRow('Diskon', '-${CurrencyFormatter.formatWithoutSymbol(discount)}'),
                  if (tax > 0) _buildReceiptRow('Pajak', '+${CurrencyFormatter.formatWithoutSymbol(tax)}'),
                  const Text('----------------------------------------', style: TextStyle(fontSize: 10, color: Colors.black38)),
                  _buildReceiptRow('TOTAL', 'Rp ${CurrencyFormatter.formatWithoutSymbol(total)}', isBold: true, fontSize: 13),
                  const Text('----------------------------------------', style: TextStyle(fontSize: 10, color: Colors.black38)),
                  _buildReceiptRow('Bayar (${paymentMethod == "CASH" ? "TUNAI" : paymentMethod})', CurrencyFormatter.formatWithoutSymbol(paid)),
                  _buildReceiptRow('Kembali', CurrencyFormatter.formatWithoutSymbol(change)),

                  // WiFi
                  if (wifiName != null && wifiName.toString().isNotEmpty) ...[
                    const Text('----------------------------------------', style: TextStyle(fontSize: 10, color: Colors.black38)),
                    Text(
                      'WiFi: $wifiName ${wifiPass != null && wifiPass.toString().isNotEmpty ? "| Pass: $wifiPass" : ""}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9, color: Colors.black54),
                    ),
                  ],

                  const Text('----------------------------------------', style: TextStyle(fontSize: 10, color: Colors.black38)),

                  // Footer
                  Text(footerMsg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  const SizedBox(height: 2),
                  const Text('-- Have a Good Coffee Day --', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Colors.black45)),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Cetak Struk'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (printerService.isConnected.value) {
                await printerService.printReceipt(payload);
                Get.back();
              } else {
                AppSnackbar.warning(
                  'Printer Belum Terhubung',
                  'Silakan sambungkan printer Bluetooth 58mm di menu Pengaturan.',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// Digital preview untuk Struk Dapur (Kitchen Ticket)
  static void showKitchen(Map<String, dynamic> payload) {
    final printerService = Get.find<EscPosPrinterService>();

    final invoice = payload['invoice_number'] ?? '-';
    final date = payload['date'] ?? '-';
    final orderType = payload['order_type'] ?? 'DINE IN';
    final tableNumber = payload['table_number'];
    final customerName = payload['customer_name'];
    final List items = payload['items'] ?? [];

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '*** STRUK DAPUR ***',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tableNumber != null && tableNumber.toString().isNotEmpty ? 'MEJA: $tableNumber' : 'TIPE: $orderType',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.brown),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('========================================', style: TextStyle(fontSize: 10, color: Colors.black45)),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No. Order : $invoice', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('Waktu     : $date', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                        if (customerName != null && customerName.toString().isNotEmpty)
                          Text('Pelanggan : $customerName', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                      ],
                    ),
                  ),
                  const Text('----------------------------------------', style: TextStyle(fontSize: 10, color: Colors.black45)),

                  // Items
                  ...items.map((item) {
                    final name = item['name'] ?? 'Item';
                    final int qty = item['quantity'] is int ? item['quantity'] : int.tryParse(item['quantity'].toString()) ?? 1;
                    final notes = item['notes']?.toString();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$qty x $name', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            if (notes != null && notes.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 12.0, top: 2.0),
                                child: Text('-> $notes', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red.shade700)),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const Text('========================================', style: TextStyle(fontSize: 10, color: Colors.black45)),
                  const Text('SEGERA DIPROSES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Cetak Dapur'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
            onPressed: () async {
              if (printerService.isConnected.value) {
                await printerService.printKitchenReceipt(payload);
                Get.back();
              } else {
                AppSnackbar.warning(
                  'Printer Belum Terhubung',
                  'Silakan sambungkan printer Bluetooth 58mm di menu Pengaturan.',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  static Widget _buildReceiptRow(String label, String value, {bool isBold = false, double fontSize = 11}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
