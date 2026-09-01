import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/online_order_model.dart';
import '../../controllers/online_orders_controller.dart';

class OnlineOrderDetailDialog {
  static void show(
    BuildContext context,
    OnlineOrderModel order,
    OnlineOrdersController controller,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: 480,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Dialog
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: order.statusSoftColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(order.statusIcon, color: order.statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              order.shortOrderNumber,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: order.isDineIn ? AppColors.primarySoft : AppColors.secondarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                order.isDineIn ? 'Meja ${order.tableNumber ?? "-"}' : 'Take Away',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: order.isDineIn ? AppColors.primaryDark : AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.invoiceNumber,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Scrollable Body Content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status & Customer Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Pelanggan', order.customerName),
                            if (order.customerPhone.isNotEmpty) ...[
                              const Divider(height: 10),
                              _buildInfoRow('No. Telepon', order.customerPhone),
                            ],
                            const Divider(height: 10),
                            _buildInfoRow('Waktu Pesan', order.createdAt),
                            const Divider(height: 10),
                            _buildInfoRow('Status Pesanan', order.statusLabel, valueColor: order.statusColor, isBold: true),
                            const Divider(height: 10),
                            _buildInfoRow('Pembayaran', 'QRIS (Lunas)', valueColor: AppColors.success, isBold: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Alasan Pembatalan (jika ada)
                      if (order.cancelledReason != null && order.cancelledReason!.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.dangerSoft,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.danger.withAlpha(60)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.danger),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Alasan Dibatalkan: ${order.cancelledReason}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Rincian Menu Pesanan
                      const Text(
                        'Daftar Menu yang Dipesan:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      ...order.items.map((item) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.lightBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${item.quantity}x',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.formattedPrice,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    if (item.notes.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.warningSoft,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Catatan: ${item.notes}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.warning,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                item.formattedSubtotal,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),

                      // Rincian Biaya
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            _buildPriceRow('Subtotal (${order.totalQty} item)', order.formattedSubtotal),
                            if (order.discountAmount > 0) ...[
                              const SizedBox(height: 4),
                              _buildPriceRow('Diskon', '-${order.formattedDiscount}', color: AppColors.danger),
                            ],
                            if (order.taxAmount > 0) ...[
                              const SizedBox(height: 4),
                              _buildPriceRow('Pajak (PB1)', order.formattedTax),
                            ],
                            const Divider(height: 14),
                            _buildPriceRow('Total Tagihan', order.formattedTotal, isBold: true, fontSize: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Tombol Cetak & Aksi Status
              Row(
                children: [
                  // Tombol Cetak Tiket Dapur
                  IconButton.outlined(
                    tooltip: 'Cetak Tiket Dapur',
                    icon: const Icon(Icons.soup_kitchen_rounded, color: AppColors.primary, size: 20),
                    onPressed: () => controller.printKitchenSlip(order),
                  ),
                  const SizedBox(width: 8),

                  // Tombol Cetak Struk Kasir
                  IconButton.outlined(
                    tooltip: 'Cetak Struk',
                    icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                    onPressed: () => controller.printCustomerReceipt(order),
                  ),
                  const SizedBox(width: 8),

                  // Tombol Aksi Utama
                  Expanded(
                    child: _buildModalActionButton(dialogContext, order, controller),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildModalActionButton(
    BuildContext dialogContext,
    OnlineOrderModel order,
    OnlineOrdersController controller,
  ) {
    if (order.isPending) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.soup_kitchen_rounded, size: 18),
        label: const Text('Terima & Masak', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          Navigator.of(dialogContext).pop();
          await controller.updateOrderStatus(order, 'processing', autoPrintKitchen: true);
        },
      );
    }

    if (order.isProcessing) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.notifications_active_rounded, size: 18),
        label: const Text('Siap Diambil/Diantar', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          Navigator.of(dialogContext).pop();
          await controller.updateOrderStatus(order, 'ready');
        },
      );
    }

    if (order.isReady) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.check_circle_rounded, size: 18),
        label: const Text('Selesaikan Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          Navigator.of(dialogContext).pop();
          await controller.updateOrderStatus(order, 'completed');
        },
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () => Navigator.of(dialogContext).pop(),
      child: const Text('Tutup'),
    );
  }

  static Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  static Widget _buildPriceRow(String label, String value, {bool isBold = false, double fontSize = 13, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? (isBold ? AppColors.primaryDark : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
