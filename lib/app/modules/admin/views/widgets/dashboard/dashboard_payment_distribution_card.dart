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

    final cashPercent = totalRevenue > 0 ? (p.cash.total / totalRevenue) : 0.0;
    final qrisPercent = totalRevenue > 0 ? (p.qris.total / totalRevenue) : 0.0;
    final transferPercent = totalRevenue > 0
        ? (p.transfer.total / totalRevenue)
        : 0.0;

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Metode Pembayaran',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormatter.format(totalRevenue),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (height == null) const SizedBox(height: 10),

          // Multi-Segment Distribution Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  if (cashPercent > 0)
                    Expanded(
                      flex: (cashPercent * 100).toInt().clamp(1, 100),
                      child: Container(color: const Color(0xFF10B981)),
                    ),
                  if (qrisPercent > 0)
                    Expanded(
                      flex: (qrisPercent * 100).toInt().clamp(1, 100),
                      child: Container(color: AppColors.secondary),
                    ),
                  if (transferPercent > 0)
                    Expanded(
                      flex: (transferPercent * 100).toInt().clamp(1, 100),
                      child: Container(color: const Color(0xFF0EA5E9)),
                    ),
                  if (totalRevenue == 0)
                    Expanded(child: Container(color: const Color(0xFFE2E8F0))),
                ],
              ),
            ),
          ),
          if (height == null) const SizedBox(height: 10),

          // Breakdown Items
          Column(
            children: [
              _buildPaymentRow(
                label: 'Uang Tunai',
                dotColor: const Color(0xFF10B981),
                total: p.cash.total,
                count: p.cash.count,
                percentage: cashPercent,
              ),
              const SizedBox(height: 5),
              _buildPaymentRow(
                label: 'QRIS Digital',
                dotColor: AppColors.secondary,
                total: p.qris.total,
                count: p.qris.count,
                percentage: qrisPercent,
              ),
              const SizedBox(height: 5),
              _buildPaymentRow(
                label: 'Transfer Bank',
                dotColor: const Color(0xFF0EA5E9),
                total: p.transfer.total,
                count: p.transfer.count,
                percentage: transferPercent,
              ),
            ],
          ),

          if (height == null) const SizedBox(height: 10),
          Column(
            children: [
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Total Pembayaran',
                      maxLines: 1,
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${p.cash.count + p.qris.count + p.transfer.count} Transaksi',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow({
    required String label,
    required Color dotColor,
    required double total,
    required int count,
    required double percentage,
  }) {
    final percentInt = (percentage * 100).clamp(0, 100).toInt();

    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
          ),
        ),
        Text(
          '$count trx • $percentInt%',
          maxLines: 1,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 10),
        Text(
          CurrencyFormatter.format(total),
          maxLines: 1,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
