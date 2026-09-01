import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/services/esc_pos_printer_service.dart';

class ReceiptViewDialog {
  static void show(Map<String, dynamic> payload) {
    final printerService = Get.find<EscPosPrinterService>();

    final header = payload['header'] ?? {};
    final shopName = header['shop_name'] ?? 'POS CAFE';
    final address = header['address'] ?? '';
    final phone = header['phone'] ?? '';

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
    final footerMsg = footer['message'] ?? 'Terima Kasih Atas Kunjungan Anda!';
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
                  // Shop Header
                  Text(
                    shopName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  if (address.toString().isNotEmpty)
                    Text(address, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  if (phone.toString().isNotEmpty)
                    Text('Telp: $phone', style: const TextStyle(fontSize: 10, color: Colors.black54)),
                  const SizedBox(height: 8),
                  const Text('----------------------------------------', style: TextStyle(fontSize: 10, color: Colors.black45)),

                  // Transaction Meta
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No: $invoice', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tgl: $date', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                            Text('Ksr: $cashier', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                          ],
                        ),
                        Text(
                          'Tipe: $orderType ${tableNumber != null ? '| $tableNumber' : ''} ${customerName != null ? '($customerName)' : ''}',
                          style: const TextStyle(fontSize: 10, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const Text('========================================', style: TextStyle(fontSize: 10, color: Colors.black45)),

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
                          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('  $qty x ${CurrencyFormatter.formatWithoutSymbol(price)}', style: const TextStyle(fontSize: 10, color: Colors.black87)),
                              Text(CurrencyFormatter.formatWithoutSymbol(itemSub), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (notes != null && notes.trim().isNotEmpty)
                            Text('  * $notes', style: const TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Colors.black54)),
                        ],
                      ),
                    );
                  }),

                  const Text('----------------------------------------', style: TextStyle(fontSize: 10, color: Colors.black45)),

                  // Summary
                  _buildReceiptRow('Subtotal', CurrencyFormatter.format(subtotal)),
                  if (discount > 0) _buildReceiptRow('Diskon', '-${CurrencyFormatter.format(discount)}'),
                  if (tax > 0) _buildReceiptRow('Pajak (PB1)', CurrencyFormatter.format(tax)),
                  const SizedBox(height: 2),
                  _buildReceiptRow('TOTAL', CurrencyFormatter.format(total), isBold: true, fontSize: 13),
                  _buildReceiptRow('Bayar ($paymentMethod)', CurrencyFormatter.format(paid)),
                  if (paymentMethod.toUpperCase() == 'CASH')
                    _buildReceiptRow('Kembalian', CurrencyFormatter.format(change), isBold: true),

                  const Text('----------------------------------------', style: TextStyle(fontSize: 10, color: Colors.black45)),
                  const SizedBox(height: 4),

                  // Footer
                  Text(footerMsg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                  if (wifiName != null && wifiName.toString().isNotEmpty)
                    Text('Wi-Fi: $wifiName | Pass: ${wifiPass ?? "-"}', style: const TextStyle(fontSize: 9, color: Colors.black54)),
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
            label: const Text('Cetak'),
            onPressed: () async {
              if (printerService.isConnected.value) {
                await printerService.printReceipt(payload);
                Get.back();
              } else {
                Get.snackbar(
                  'Printer Belum Terhubung',
                  'Silakan sambungkan printer bluetooth di Pengaturan terlebih dahulu.',
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
