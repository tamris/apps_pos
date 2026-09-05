import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/admin_transaction_model.dart';
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
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 32,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header: Icon + Invoice + Status + Close
                _buildHeader(context, t),
                const SizedBox(height: 16),

                // 2. Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Void Info Banner if cancelled
                        if (t.isCancelled && t.cancelledInfo != null) ...[
                          _buildVoidBanner(t.cancelledInfo!),
                          const SizedBox(height: 14),
                        ],

                        // Order Metadata Grid
                        _buildOrderMetadataCard(t),
                        const SizedBox(height: 16),

                        // Section Items List
                        _buildItemsSection(t),
                        const SizedBox(height: 16),

                        // Pricing Calculation Box
                        _buildPricingSummaryCard(t),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Footer Action Buttons
                _buildFooterActions(context, t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, AdminTransactionModel t) {
    Color iconBg;
    Color iconColor;
    IconData headerIcon;

    if (t.isCancelled) {
      iconBg = const Color(0xFFFEF2F2);
      iconColor = const Color(0xFFDC2626);
      headerIcon = Icons.cancel_outlined;
    } else if (t.isPending) {
      iconBg = const Color(0xFFFFFBEB);
      iconColor = const Color(0xFFD97706);
      headerIcon = Icons.pending_actions_rounded;
    } else {
      iconBg = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF059669);
      headerIcon = Icons.receipt_long_rounded;
    }

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(headerIcon, color: iconColor, size: 22),
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
                      t.invoiceNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: t.isCancelled ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                        decoration: t.isCancelled ? TextDecoration.lineThrough : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(t),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(t.createdAt),
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 20,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Void Banner
  // ---------------------------------------------------------------------------
  Widget _buildVoidBanner(AdminTransactionCancelledInfo info) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFE11D48), size: 16),
              const SizedBox(width: 6),
              Text(
                'Dibatalkan oleh: ${info.cancelledByName}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE11D48)),
              ),
              const Spacer(),
              if (info.cancelledAt != null)
                Text(
                  _formatDateTime(info.cancelledAt),
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF9F1239)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Alasan: "${info.cancelledReason}"',
            style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF4C0519)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Order Metadata Card (2-column Clean Modern Grid)
  // ---------------------------------------------------------------------------
  Widget _buildOrderMetadataCard(AdminTransactionModel t) {
    final isDineIn = t.orderType == 'dine_in';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetaItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Pelanggan',
                  value: t.customerName.isNotEmpty ? t.customerName : 'Pelanggan Umum',
                ),
              ),
              Expanded(
                child: _buildMetaItem(
                  icon: Icons.badge_outlined,
                  label: 'Kasir',
                  value: t.cashierName.isNotEmpty ? t.cashierName : '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetaItem(
                  icon: isDineIn ? Icons.table_restaurant_outlined : Icons.takeout_dining_outlined,
                  label: 'Tipe Pemesanan',
                  value: isDineIn
                      ? (t.tableNumber != null && t.tableNumber!.isNotEmpty
                          ? 'Dine-in (Meja ${t.tableNumber})'
                          : 'Dine-in (Makan di Tempat)')
                      : 'Takeaway (Bungkus)',
                ),
              ),
              Expanded(
                child: _buildMetaItem(
                  icon: t.isSelfOrder ? Icons.phone_android_rounded : Icons.point_of_sale_rounded,
                  label: 'Saluran Order',
                  value: t.isSelfOrder ? 'Online (Self-Order)' : 'Kasir POS Langsung',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetaItem(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Metode Bayar',
                  value: t.paymentMethod.toUpperCase(),
                ),
              ),
              Expanded(
                child: _buildMetaItem(
                  icon: Icons.verified_outlined,
                  label: 'Status Bayar',
                  value: t.isPending ? 'Belum Lunas' : 'Lunas',
                  valueColor: t.isPending ? const Color(0xFFD97706) : const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 1.5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Items Section
  // ---------------------------------------------------------------------------
  Widget _buildItemsSection(AdminTransactionModel t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Rincian Menu Pesanan',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${t.items.length} item',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (t.items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                SizedBox(width: 8),
                Text(
                  'Rincian item tidak tersedia.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: t.items.length,
              separatorBuilder: (context, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, i) {
                final item = t.items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Qty badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${item.quantity}x',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Name & Addons & Notes
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@ ${CurrencyFormatter.format(item.price)}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '+ $aName (${CurrencyFormatter.format(aPrice)})',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF475569)),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            if (item.notes != null && item.notes!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.edit_note_rounded, size: 14, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      item.notes!,
                                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Line Total
                      Text(
                        CurrencyFormatter.format(item.subtotal),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Pricing Summary Card
  // ---------------------------------------------------------------------------
  Widget _buildPricingSummaryCard(AdminTransactionModel t) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', CurrencyFormatter.format(t.subtotal)),
          if (t.discount > 0) ...[
            const SizedBox(height: 6),
            _buildSummaryRow('Diskon', '- ${CurrencyFormatter.format(t.discount)}', valueColor: const Color(0xFFDC2626)),
          ],
          if (t.tax > 0) ...[
            const SizedBox(height: 6),
            _buildSummaryRow('Pajak PB1', '+ ${CurrencyFormatter.format(t.tax)}'),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFCBD5E1)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Tagihan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              Text(
                CurrencyFormatter.format(t.total),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF059669),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSummaryRow('Nominal Dibayar', CurrencyFormatter.format(t.paid), fontSize: 11.5),
          const SizedBox(height: 4),
          _buildSummaryRow('Kembalian', CurrencyFormatter.format(t.change), fontSize: 11.5),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {double fontSize = 12, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: fontSize, color: const Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Footer Action Buttons
  // ---------------------------------------------------------------------------
  Widget _buildFooterActions(BuildContext context, AdminTransactionModel t) {
    return Row(
      children: [
        // Tutup Button
        Expanded(
          flex: t.isCancelled ? 1 : 0,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),

        // Void Button if not cancelled
        if (!t.isCancelled) ...[
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onVoidPressed?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.delete_sweep_rounded, size: 18),
              label: const Text(
                'Batalkan / Void Transaksi Ini',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(AdminTransactionModel t) {
    if (t.isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: const Text(
          'Dibatalkan',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
        ),
      );
    }

    if (t.isPending) {
      if (t.isSelfOrder) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_top_rounded, size: 10, color: Color(0xFFEA580C)),
              SizedBox(width: 3.5),
              Text(
                'Menunggu Pembayaran',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFEA580C)),
              ),
            ],
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Text(
          'Open Bill',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: const Text(
        'Selesai',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
      ),
    );
  }

  String _formatDateTime(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dtStr).toLocal();
      return DateFormat('dd MMM yyyy • HH:mm').format(dt);
    } catch (_) {
      return dtStr;
    }
  }
}
