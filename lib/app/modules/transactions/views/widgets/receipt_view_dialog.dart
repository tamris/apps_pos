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
                      padding: const EdgeInsets.only(top: 2.0, bottom: 6.0),
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
  /// Digital preview untuk Tiket Dapur (Kitchen Ticket) - Style Web pos-inventory
  static void showKitchen(Map<String, dynamic> payload) {
    final printerService = Get.find<EscPosPrinterService>();

    final header = payload['header'] ?? {};
    final shopName = (header['shop_name'] ?? 'NOLI COFFEE & SPACE').toString().toUpperCase();

    final invoice = payload['invoice_number']?.toString() ?? '-';
    final date = payload['date']?.toString() ?? DateTime.now().toString().substring(0, 16);
    final cashier = payload['cashier_name']?.toString() ?? 'Kasir';
    final orderType = payload['order_type']?.toString().toUpperCase() ?? 'DINE IN';
    final tableNumber = payload['table_number']?.toString();
    final customerName = payload['customer_name']?.toString();
    final List items = payload['items'] ?? [];

    String orderTypeBanner = orderType;
    if (orderType.contains('DINE')) {
      if (tableNumber != null && tableNumber.isNotEmpty) {
        final cleanTable = tableNumber.toUpperCase().replaceAll('MEJA', '').trim();
        orderTypeBanner = 'DINE IN (MEJA $cleanTable)';
      } else {
        orderTypeBanner = 'DINE IN';
      }
    } else if (orderType.contains('TAKE')) {
      orderTypeBanner = 'TAKE AWAY';
    } else if (orderType.contains('DELIVERY')) {
      orderTypeBanner = 'DELIVERY';
    }

    int totalItems = 0;
    for (var it in items) {
      final q = it['quantity'] is int ? it['quantity'] : int.tryParse(it['quantity']?.toString() ?? '1') ?? 1;
      totalItems += q as int;
    }

    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header (Center)
                  const Text(
                    '*** TIKET DAPUR ***',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shopName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Divider
                  _buildDashedLine(),
                  const SizedBox(height: 8),

                  // 2. Metadata (Left)
                  _buildMetaRow('No. Inv', invoice),
                  _buildMetaRow('Waktu  ', date),
                  _buildMetaRow('Kasir  ', cashier),
                  const SizedBox(height: 8),

                  // 3. Order Banner (Box abu-abu dengan border halus persis web)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          orderTypeBanner,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (customerName != null && customerName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Pelanggan: $customerName',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Divider
                  _buildDashedLine(),
                  const SizedBox(height: 8),

                  // 4. Daftar Item Pesanan
                  ...items.map((item) {
                    final name = item['name'] ?? 'Item';
                    final int qty = item['quantity'] is int
                        ? item['quantity']
                        : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                    final notes = item['notes']?.toString();
                    final addons = item['addons'] is List ? item['addons'] as List : [];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${qty}x  $name',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (addons.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 14.0, top: 2.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: addons.map((addon) {
                                  final aName = (addon is Map ? (addon['name']?.toString() ?? '') : addon.toString()).trim();
                                  return Text(
                                    '[+] $aName',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          if (notes != null && notes.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0, top: 2.0),
                              child: Text(
                                '>> CATATAN: $notes',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                  // Divider
                  _buildDashedLine(),
                  const SizedBox(height: 8),

                  // 5. Total Item
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL ITEM:',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '$totalItems Menu',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Divider
                  _buildDashedLine(),
                  const SizedBox(height: 12),

                  // 6. Footer
                  const Text(
                    '-- SEGERA DISIAPKAN --',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Cetak Dapur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669), // Emerald Green persis .btn-direct web
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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

  static Widget _buildDashedLine() {
    return const Text(
      '--------------------------------',
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.0,
      ),
    );
  }

  static Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Color(0xFF0F172A),
              ),
            ),
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
