import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/admin_transaction_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

class AdminTransactionDetailDialog extends StatelessWidget {
  final AdminTransactionModel transaction;
  final VoidCallback? onVoidPressed;

  const AdminTransactionDetailDialog({
    super.key,
    required this.transaction,
    this.onVoidPressed,
  });

  static void show(
    BuildContext context, {
    required AdminTransactionModel transaction,
    VoidCallback? onVoidPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AdminTransactionDetailDialog(
        transaction: transaction,
        onVoidPressed: onVoidPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = transaction;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: t.isCancelled ? AppColors.dangerSoft : AppColors.secondarySoft,
                      child: Icon(
                        t.isCancelled ? Icons.cancel_outlined : Icons.receipt_long_rounded,
                        color: t.isCancelled ? AppColors.danger : AppColors.secondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                t.invoiceNumber,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(t),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDateTime(t.createdAt),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Content scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Box Info Pembatalan jika void
                        if (t.isCancelled && t.cancelledInfo != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.dangerSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Dibatalkan oleh: ${t.cancelledInfo!.cancelledByName}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDateTime(t.cancelledInfo!.cancelledAt),
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Alasan: "${t.cancelledInfo!.cancelledReason}"',
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Order Attributes Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.lightBorder),
                          ),
                          child: Column(
                            children: [
                              _buildMetaRow('Pelanggan', t.customerName),
                              if (t.tableNumber != null && t.tableNumber!.isNotEmpty)
                                _buildMetaRow('Nomor Meja', 'Meja ${t.tableNumber}'),
                              _buildMetaRow('Kasir yang Melayani', t.cashierName),
                              _buildMetaRow('Tipe Pemesanan', t.orderType == 'dine_in' ? 'Dine-in (Makan di Tempat)' : 'Takeaway (Bungkus)'),
                              _buildMetaRow('Sumber Pesanan', t.isSelfOrder ? 'Online Order (Self-Order)' : 'Kasir POS Langsung'),
                              _buildMetaRow('Metode Pembayaran', t.paymentMethod.toUpperCase()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section Items List
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Detail Item Pesanan',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              '${t.items.length} item',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (t.items.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Rincian item tidak tersedia.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: t.items.length,
                            separatorBuilder: (context, i) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final item = t.items[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item.quantity}x',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                '@ ${CurrencyFormatter.format(item.price)}',
                                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.format(item.subtotal),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    if (item.addons.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: item.addons.map((a) {
                                          final aName = a['name']?.toString() ?? 'Addon';
                                          final aPrice = (a['price'] as num?)?.toDouble() ?? 0.0;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '+ $aName (${CurrencyFormatter.format(aPrice)})',
                                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                    if (item.notes != null && item.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        'Catatan: ${item.notes}',
                                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 16),

                        // Pricing Calculation Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.lightBorder),
                          ),
                          child: Column(
                            children: [
                              _buildPriceRow('Subtotal', CurrencyFormatter.format(t.subtotal)),
                              if (t.discount > 0)
                                _buildPriceRow('Diskon', '- ${CurrencyFormatter.format(t.discount)}', valueColor: AppColors.danger),
                              if (t.tax > 0)
                                _buildPriceRow('Pajak PB1', '+ ${CurrencyFormatter.format(t.tax)}'),
                              const Divider(height: 14),
                              _buildPriceRow('Total Tagihan', CurrencyFormatter.format(t.total), isBold: true, fontSize: 15),
                              _buildPriceRow('Nominal Dibayar', CurrencyFormatter.format(t.paid)),
                              _buildPriceRow('Kembalian', CurrencyFormatter.format(t.change)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Bottom Action: Void Button if not cancelled
                if (!t.isCancelled) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onVoidPressed?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded, size: 20),
                    label: const Text(
                      'Batalkan / Void Transaksi Ini',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ] else ...[
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tutup'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false, double fontSize = 12, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
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
              color: valueColor ?? (isBold ? AppColors.primaryDark : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AdminTransactionModel t) {
    if (t.isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Dibatalkan (Void)',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.danger),
        ),
      );
    }

    if (t.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Menunggu (Open Bill)',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Selesai',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
      ),
    );
  }

  String _formatDateTime(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dtStr).toLocal();
      return DateFormat('dd MMM yyyy HH:mm').format(dt);
    } catch (_) {
      return dtStr;
    }
  }
}
