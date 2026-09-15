import 'package:flutter/material.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/data/models/admin_dashboard_model.dart';

class DashboardPaymentDistributionCard extends StatelessWidget {
  final AdminDashboardModel data;
  final double totalRevenue;
  final double? height;

  const DashboardPaymentDistributionCard({
    super.key,
    required this.data,
    required this.totalRevenue,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final p = data.paymentBreakdown;

    // Hitung total penerimaan efektif
    final calculatedTotal = p.cash.total + p.qris.total + p.transfer.total;
    final effectiveRevenue = totalRevenue > 0 ? totalRevenue : calculatedTotal;

    final qrisPercent = effectiveRevenue > 0
        ? (p.qris.total / effectiveRevenue)
        : 0.0;
    final cashPercent = effectiveRevenue > 0
        ? (p.cash.total / effectiveRevenue)
        : 0.0;
    final transferPercent = effectiveRevenue > 0
        ? (p.transfer.total / effectiveRevenue)
        : 0.0;

    final totalTransactions = p.cash.count + p.qris.count + p.transfer.count;

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: height != null
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row (Judul & Subjudul di Kiri, Total Rupiah & Jumlah Transaksi di Kanan)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Metode Pembayaran',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Total penerimaan kas & non-tunai',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      CurrencyFormatter.format(effectiveRevenue),
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalTransactions Transaksi',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (height == null) const SizedBox(height: 16),

          // 2. Bar Distribusi Multi-Segmen Pill Rounded
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 6.5,
              child: Row(
                children: [
                  if (cashPercent > 0)
                    Expanded(
                      flex: (cashPercent * 1000).toInt().clamp(1, 1000),
                      child: Container(color: const Color(0xFF10B981)),
                    ),
                  if (qrisPercent > 0)
                    Expanded(
                      flex: (qrisPercent * 1000).toInt().clamp(1, 1000),
                      child: Container(color: AppColors.secondary),
                    ),
                  if (transferPercent > 0)
                    Expanded(
                      flex: (transferPercent * 1000).toInt().clamp(1, 1000),
                      child: Container(color: const Color(0xFF0EA5E9)),
                    ),
                  if (qrisPercent == 0 &&
                      cashPercent == 0 &&
                      transferPercent == 0)
                    Expanded(child: Container(color: const Color(0xFFF1F5F9))),
                ],
              ),
            ),
          ),

          if (height == null) const SizedBox(height: 16),

          // 3. Item 1: Cash
          _buildPaymentItem(
            label: 'Cash',
            dotColor: const Color(0xFF10B981),
            total: p.cash.total,
            count: p.cash.count,
            percentage: cashPercent,
          ),

          if (height == null) const SizedBox(height: 14),

          // 4. Item 2: QRIS Digital
          _buildPaymentItem(
            label: 'QRIS Digital',
            dotColor: AppColors.secondary,
            total: p.qris.total,
            count: p.qris.count,
            percentage: qrisPercent,
          ),

          if (height == null) const SizedBox(height: 14),

          // 5. Item 3: Transfer Bank
          _buildPaymentItem(
            label: 'Transfer Bank',
            dotColor: const Color(0xFF0EA5E9),
            total: p.transfer.total,
            count: p.transfer.count,
            percentage: transferPercent,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem({
    required String label,
    required Color dotColor,
    required double total,
    required int count,
    required double percentage,
  }) {
    final percentInt = (percentage * 100).clamp(0, 100).toInt();

    return Row(
      children: [
        // Dot Indikator Warna
        Container(
          width: 7.5,
          height: 7.5,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),

        // Nama Metode Pembayaran & Tag Transaksi Persen dengan jarak lega
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: SizedBox(width: 7),
                ),
                TextSpan(
                  text: '($count trx • $percentInt%)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),

        // Nominal Rupiah di Sisi Kanan (Muted jika 0, Bold Slate jika ada nilai)
        Text(
          CurrencyFormatter.format(total),
          maxLines: 1,
          style: TextStyle(
            fontSize: 13,
            fontWeight: total > 0 ? FontWeight.w700 : FontWeight.w500,
            color: total > 0
                ? const Color(0xFF0F172A)
                : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
