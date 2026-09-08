import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class TransactionsMetricsStrip extends GetView<AdminController> {
  const TransactionsMetricsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = controller.transactions;
      final totalTrx = list.length;
      final completedTrx = list.where((t) => t.isCompleted).toList();
      double totalRevenue = 0.0;
      double totalProfit = 0.0;
      for (final t in completedTrx) {
        totalRevenue += t.total;
        totalProfit += (t.profit ?? 0.0);
      }
      final aov =
          completedTrx.isNotEmpty ? totalRevenue / completedTrx.length : 0.0;
      final profitMargin =
          totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;

      return Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;
            if (isNarrow) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMetricCard(
                      width: 170,
                      label: 'Total Transaksi',
                      value: '$totalTrx Trx',
                      subtext: 'Semua record',
                      icon: Icons.receipt_long_rounded,
                      iconColor: const Color(0xFF4F46E5),
                      iconBg: const Color(0xFFEEF2FF),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 195,
                      label: 'Total Omzet (Selesai)',
                      value: CurrencyFormatter.format(totalRevenue),
                      subtext: '${completedTrx.length} berhasil',
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: const Color(0xFF059669),
                      iconBg: const Color(0xFFECFDF5),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 190,
                      label: 'Rata-rata Belanja (AOV)',
                      value: CurrencyFormatter.format(aov),
                      subtext: 'Rata-rata per struk',
                      icon: Icons.query_stats_rounded,
                      iconColor: const Color(0xFF0284C7),
                      iconBg: const Color(0xFFF0F9FF),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 195,
                      label: 'Estimasi Laba Bersih',
                      value: CurrencyFormatter.format(totalProfit),
                      subtext: '${profitMargin.toStringAsFixed(1)}% margin',
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      iconBg: const Color(0xFFF5F3FF),
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'Total Transaksi',
                    value: '$totalTrx Trx',
                    subtext: 'Semua record',
                    icon: Icons.receipt_long_rounded,
                    iconColor: const Color(0xFF4F46E5),
                    iconBg: const Color(0xFFEEF2FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Total Omzet (Selesai)',
                    value: CurrencyFormatter.format(totalRevenue),
                    subtext: '${completedTrx.length} berhasil',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFF059669),
                    iconBg: const Color(0xFFECFDF5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Rata-rata Belanja (AOV)',
                    value: CurrencyFormatter.format(aov),
                    subtext: 'Rata-rata per struk',
                    icon: Icons.query_stats_rounded,
                    iconColor: const Color(0xFF0284C7),
                    iconBg: const Color(0xFFF0F9FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Estimasi Laba Bersih',
                    value: CurrencyFormatter.format(totalProfit),
                    subtext: '${profitMargin.toStringAsFixed(1)}% margin',
                    icon: Icons.trending_up_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    iconBg: const Color(0xFFF5F3FF),
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _buildMetricCard({
    double? width,
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Text(
                  subtext,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
