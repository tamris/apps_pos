import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/services/esc_pos_printer_service.dart';
import '../../../transactions/views/widgets/receipt_view_dialog.dart';

class PaymentSuccessDialog {
  static void show({
    required String invoiceNumber,
    required double total,
    required double paid,
    required double change,
    required String paymentMethod,
    Map<String, dynamic>? receiptPayload,
  }) {
    final printerService = Get.find<EscPosPrinterService>();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Animated Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryLight, width: 2),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Pembayaran Berhasil!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              invoiceNumber,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Column(
                children: [
                  _buildRow('Total Tagihan', CurrencyFormatter.format(total)),
                  _buildRow('Metode Bayar', paymentMethod),
                  _buildRow('Uang Diterima', CurrencyFormatter.format(paid)),
                  const Divider(height: 16),
                  _buildRow(
                    'Kembalian',
                    CurrencyFormatter.format(change),
                    isBold: true,
                    valueColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Cetak Struk & Transaksi Baru
            Row(
              children: [
                // Cetak Struk
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (receiptPayload != null) {
                        if (printerService.isConnected.value) {
                          await printerService.printReceipt(receiptPayload);
                        } else {
                          // Buka modal preview struk digital
                          ReceiptViewDialog.show(receiptPayload);
                        }
                      } else {
                        Get.snackbar('Informasi', 'Data struk tidak tersedia.');
                      }
                    },
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('Cetak Struk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  ),
                ),
                const SizedBox(width: 8),

                // Transaksi Baru
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Transaksi Baru', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  static Widget _buildRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? (isBold ? AppColors.textPrimary : AppColors.textSecondary),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
