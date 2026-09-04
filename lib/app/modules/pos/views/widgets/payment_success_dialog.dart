import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/services/esc_pos_printer_service.dart';
import '../../../transactions/views/widgets/receipt_view_dialog.dart';
import '../../controllers/cart_controller.dart';

class PaymentSuccessDialog {
  static void show({
    required String invoiceNumber,
    required double total,
    required double paid,
    required double change,
    required String paymentMethod,
    bool isOffline = false,
    Map<String, dynamic>? receiptPayload,
    Map<String, dynamic>? kitchenPayload,
  }) {
    final printerService = Get.find<EscPosPrinterService>();

    // Tactile confirmation upon successful transaction
    HapticFeedback.mediumImpact();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Success Animated Circle Icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryLight, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(25),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.primary,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 14),

                // 2. Title
                const Text(
                  'Pembayaran Berhasil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),

                // 3. Invoice & Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOffline ? Colors.amber.shade50 : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOffline ? Colors.amber.shade300 : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOffline ? Icons.cloud_off_rounded : Icons.receipt_long_rounded,
                        size: 13,
                        color: isOffline ? Colors.amber.shade800 : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        invoiceNumber,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isOffline ? Colors.amber.shade900 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Hero Kembalian Banner (Jika Tunai)
                if (paymentMethod.toUpperCase().contains('CASH') || paymentMethod.toUpperCase().contains('TUNAI')) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: change > 0 ? AppColors.primary : AppColors.primaryLight,
                        width: change > 0 ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              change > 0 ? Icons.payments_rounded : Icons.check_circle_rounded,
                              size: 15,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              change > 0 ? 'KEMBALIAN KASIR' : 'STATUS PEMBAYARAN',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          change > 0 ? CurrencyFormatter.format(change) : 'UANG PAS (LUNAS)',
                          style: TextStyle(
                            fontSize: change > 0 ? 26 : 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // 5. Transaction Details Summary
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Column(
                    children: [
                      _buildRow('Total Tagihan', CurrencyFormatter.format(total)),
                      _buildRow('Metode Bayar', paymentMethod),
                      _buildRow('Uang Diterima', CurrencyFormatter.format(paid)),
                      if (!paymentMethod.toUpperCase().contains('CASH') && !paymentMethod.toUpperCase().contains('TUNAI')) ...[
                        const Divider(height: 14),
                        _buildRow('Status', 'LUNAS', isBold: true, valueColor: AppColors.primaryDark),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 6. Print Actions (Struk Kasir & Struk Dapur)
                Row(
                  children: [
                    // Tombol Struk Kasir
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          if (receiptPayload != null) {
                            if (printerService.isConnected.value) {
                              await printerService.printReceipt(receiptPayload);
                            } else {
                              ReceiptViewDialog.show(receiptPayload);
                            }
                          } else {
                            final fallbackReceipt = {
                              'header': {'shop_name': 'NOLI COFFE & SPACE', 'address': 'POS Kasir'},
                              'invoice_number': invoiceNumber,
                              'date': DateTime.now().toString().substring(0, 16),
                              'cashier_name': 'Kasir',
                              'order_type': 'TRANSAKSI',
                              'items': [],
                              'summary': {
                                'total': total,
                                'paid': paid,
                                'change': change,
                                'payment_method': paymentMethod,
                              },
                            };
                            ReceiptViewDialog.show(fallbackReceipt);
                          }
                        },
                        icon: const Icon(Icons.print_rounded, size: 16, color: AppColors.primaryDark),
                        label: const Text(
                          'Struk Kasir',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.primarySoft,
                          side: const BorderSide(color: AppColors.primaryLight),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Tombol Struk Dapur
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          if (kitchenPayload != null) {
                            if (printerService.isConnected.value) {
                              await printerService.printKitchenReceipt(kitchenPayload);
                            } else {
                              ReceiptViewDialog.showKitchen(kitchenPayload);
                            }
                          } else {
                            final fallbackKitchen = {
                              'invoice_number': invoiceNumber,
                              'date': DateTime.now().toString().substring(0, 16),
                              'order_type': 'DINE IN / TAKE AWAY',
                              'items': [],
                            };
                            ReceiptViewDialog.showKitchen(fallbackKitchen);
                          }
                        },
                        icon: const Icon(Icons.soup_kitchen_rounded, size: 16, color: AppColors.primaryDark),
                        label: const Text(
                          'Struk Dapur',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.primarySoft,
                          side: const BorderSide(color: AppColors.primaryLight),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 7. Full-Width Primary Selesai / Transaksi Baru Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Get.back();
                      if (Get.isBottomSheetOpen ?? false) {
                        Get.back();
                      }
                      if (Get.isRegistered<CartController>()) {
                        Get.find<CartController>().clearCart();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Transaksi Baru',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static Widget _buildRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              color: valueColor ?? (isBold ? AppColors.textPrimary : AppColors.textPrimary),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
