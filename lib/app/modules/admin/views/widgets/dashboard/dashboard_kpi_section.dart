import 'package:flutter/material.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/data/models/admin_dashboard_model.dart';

class DashboardKpiSection extends StatelessWidget {
  final AdminSummaryModel summary;
  final double availableWidth;

  const DashboardKpiSection({
    super.key,
    required this.summary,
    required this.availableWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = availableWidth < 500;
    final profitVal = summary.profitValue;
    final marginVal = summary.marginValue;
    final itemsSoldVal = summary.itemsSoldValue;

    final cardRevenue = _buildKpiCard(
      label: 'Total Pendapatan',
      value: CurrencyFormatter.format(summary.totalRevenue),
      valueColor: const Color(0xFF0F172A),
      icon: Icons.account_balance_wallet_outlined,
      iconColor: AppColors.secondary,
      iconBg: const Color(0xFFEEF2FF),
      subtitle: '${summary.totalTransactions} pesanan berhasil diproses',
      isCompact: isCompact,
    );

    final cardProfit = _buildKpiCard(
      label: 'Estimasi Laba Bersih',
      value: CurrencyFormatter.format(profitVal),
      valueColor: const Color(0xFF0F172A),
      icon: Icons.trending_up_rounded,
      iconColor: const Color(0xFF7C3AED),
      iconBg: const Color(0xFFF5F3FF),
      subtitle: '${marginVal.toStringAsFixed(1)}% margin keuntungan',
      isCompact: isCompact,
    );

    final cardItemsSold = _buildKpiCard(
      label: 'Total Menu / Cup Terjual',
      value: '$itemsSoldVal Item Terjual',
      valueColor: const Color(0xFF0F172A),
      icon: Icons.local_cafe_rounded,
      iconColor: const Color(0xFFD97706),
      iconBg: const Color(0xFFFEF3C7),
      subtitle: 'Total item diproduksi bar & dapur',
      isCompact: isCompact,
    );

    if (availableWidth >= 860) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cardRevenue),
          const SizedBox(width: 14),
          Expanded(child: cardProfit),
          const SizedBox(width: 14),
          Expanded(child: cardItemsSold),
        ],
      );
    }

    if (availableWidth >= 480) {
      return Column(
        children: [
          cardRevenue,
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cardProfit),
              const SizedBox(width: 10),
              Expanded(child: cardItemsSold),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        cardRevenue,
        const SizedBox(height: 10),
        cardProfit,
        const SizedBox(height: 10),
        cardItemsSold,
      ],
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String subtitle,
    bool isCompact = false,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: isCompact ? 95 : 105),
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: -0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isCompact ? 20 : 22,
                fontWeight: FontWeight.w700,
                color: valueColor,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
