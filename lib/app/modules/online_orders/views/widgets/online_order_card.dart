import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/online_order_model.dart';
import '../../controllers/online_orders_controller.dart';
import 'online_order_detail_dialog.dart';

class OnlineOrderCard extends StatelessWidget {
  final OnlineOrderModel order;
  final OnlineOrdersController controller;

  const OnlineOrderCard({
    super.key,
    required this.order,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final hasTable = order.tableNumber != null &&
        order.tableNumber!.trim().isNotEmpty &&
        order.tableNumber!.trim() != '-';
    final locationText = order.isDineIn
        ? (hasTable ? 'Meja ${order.tableNumber}' : 'Dine In')
        : 'Take Away';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.isPending ? AppColors.warning.withAlpha(120) : AppColors.lightBorder,
          width: order.isPending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(order.isPending ? 10 : 4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => OnlineOrderDetailDialog.show(context, order, controller),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Bar: Table/Type, Order Number & Status Chip
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Badge Meja / Take Away
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: order.isDineIn ? AppColors.primarySoft : AppColors.secondarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            order.isDineIn ? Icons.table_restaurant_rounded : Icons.shopping_bag_outlined,
                            size: 14,
                            color: order.isDineIn ? AppColors.primary : AppColors.secondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            locationText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: order.isDineIn ? AppColors.primaryDark : AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Nomor Pesanan
                    Text(
                      order.shortOrderNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: order.statusSoftColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: order.statusColor.withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(order.statusIcon, size: 13, color: order.statusColor),
                          const SizedBox(width: 5),
                          Text(
                            order.statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: order.statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. Info Pelanggan & Waktu
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.customerName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (order.timeAgo != null)
                      Text(
                        order.timeAgo!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const Divider(height: 16),

                // 3. Rincian Menu Pesanan (Items Preview)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...order.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBackground,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${item.quantity}x',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (item.notes.isNotEmpty)
                                        Text(
                                          'Catatan: ${item.notes}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.warning,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  item.formattedSubtotal,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 14),

                // 4. Footer: Total Tagihan & Status Bayar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Lunas (Online)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Total Pesanan',
                          style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                        ),
                        Text(
                          order.formattedTotal,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. Tombol Aksi Cepat Sesuai Status (Quick Actions)
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (order.isPending) {
      return Row(
        children: [
          // Tombol Tolak
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Tolak'),
            onPressed: () => _showCancelDialog(context),
          ),
          const SizedBox(width: 10),

          // Tombol Terima & Masak
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.soup_kitchen_rounded, size: 18),
              label: const Text(
                'Terima & Masak',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => controller.updateOrderStatus(
                order,
                'processing',
                autoPrintKitchen: true,
              ),
            ),
          ),
        ],
      );
    }

    if (order.isProcessing) {
      return Row(
        children: [
          // Cetak Dapur
          IconButton.outlined(
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            tooltip: 'Cetak Tiket Dapur',
            icon: const Icon(Icons.print_rounded, size: 18),
            onPressed: () => controller.printKitchenSlip(order),
          ),
          const SizedBox(width: 10),

          // Tombol Siap Diantar / Diambil
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.notifications_active_rounded, size: 18),
              label: const Text(
                'Siap Diambil / Diantar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => controller.updateOrderStatus(order, 'ready'),
            ),
          ),
        ],
      );
    }

    if (order.isReady) {
      return Row(
        children: [
          // Cetak Struk
          IconButton.outlined(
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            tooltip: 'Cetak Struk Pelanggan',
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
            onPressed: () => controller.printCustomerReceipt(order),
          ),
          const SizedBox(width: 10),

          // Tombol Selesaikan Pesanan
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text(
                'Selesaikan Pesanan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => controller.updateOrderStatus(order, 'completed'),
            ),
          ),
        ],
      );
    }

    // Untuk Completed / Cancelled
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (order.isCompleted)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Cetak Struk'),
            onPressed: () => controller.printCustomerReceipt(order),
          ),
        TextButton.icon(
          icon: const Icon(Icons.info_outline_rounded, size: 16),
          label: const Text('Lihat Detail Lengkap'),
          onPressed: () => OnlineOrderDetailDialog.show(context, order, controller),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Text('Tolak Pesanan ${order.shortOrderNumber}?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alasan penolakan/pembatalan pesanan online ini:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Contoh: Bahan menu habis / Toko sedang penuh',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              controller.updateOrderStatus(
                order,
                'cancelled',
                reason: reasonController.text.trim(),
              );
            },
            child: const Text('Tolak Pesanan'),
          ),
        ],
      ),
    );
  }
}
