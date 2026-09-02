import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/transaction_model.dart';
import '../../controllers/transactions_controller.dart';

class TransactionDetailDialog {
  static void show(
    BuildContext context,
    TransactionModel tx,
    TransactionsController controller,
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
                      color: tx.isCompleted ? AppColors.primarySoft : AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      tx.isCompleted ? Icons.receipt_long_rounded : Icons.cancel_outlined,
                      color: tx.isCompleted ? AppColors.primary : AppColors.danger,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                tx.invoiceNumber,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: tx.isCompleted ? AppColors.primarySoft : AppColors.dangerSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tx.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: tx.isCompleted ? AppColors.primaryDark : AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tx.time} • ${tx.date}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Info Badges
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildBadge(
                    Icons.restaurant_rounded,
                    tx.orderType == 'dine_in'
                        ? (tx.tableNumber != null && tx.tableNumber!.isNotEmpty
                            ? 'Dine In (Meja ${tx.tableNumber})'
                            : 'Dine In')
                        : 'Take Away',
                    AppColors.primary,
                  ),
                  _buildBadge(
                    Icons.payment_rounded,
                    'Metode: ${tx.paymentMethod.toUpperCase()}',
                    AppColors.secondary,
                  ),
                  if (tx.customerName != null && tx.customerName!.isNotEmpty)
                    _buildBadge(
                      Icons.person_outline_rounded,
                      'Pelanggan: ${tx.customerName}',
                      AppColors.info,
                    ),
                ],
              ),
              const Divider(height: 24),

              // 3. Daftar Item Pesanan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rincian Menu',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    '${tx.itemsCount > 0 ? tx.itemsCount : tx.details.length} Item',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: tx.details.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'Tidak ada rincian item.',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: tx.details.length,
                          separatorBuilder: (_, __) => const Divider(height: 14),
                          itemBuilder: (context, i) {
                            final item = tx.details[i];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(6),
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
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (item.notes != null && item.notes!.trim().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            'Catatan: ${item.notes}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontStyle: FontStyle.italic,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      if (item.price > 0)
                                        Text(
                                          '@ ${CurrencyFormatter.format(item.price)}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(item.subtotal),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Ringkasan Pembayaran
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Transaksi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(
                          CurrencyFormatter.format(tx.total),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    if (tx.paid > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Nominal Dibayar', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(CurrencyFormatter.format(tx.paid), style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                    if (tx.change > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kembalian', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            CurrencyFormatter.format(tx.change),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Tombol Aksi Bawah
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.lightBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.receipt_outlined, size: 18),
                      label: const Text('Lihat Kertas Struk', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        controller.previewReceipt(tx.id);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('Cetak Struk', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        controller.printOrPreviewReceipt(tx.id);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
