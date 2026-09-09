import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class CashFlowMetricsStrip extends StatelessWidget {
  final AdminController controller;

  const CashFlowMetricsStrip({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = controller.cashFlowSummary.value;
      final totalIn = summary.cashInTotal;
      final totalOut = summary.cashOutTotal;
      final netFlow = summary.netCashFlow;
      final isSurplus = summary.isSurplus;
      final breakdown = summary.categoryBreakdown;
      final topCategory = breakdown.isNotEmpty ? breakdown.first : null;

      return Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 820;
            if (isNarrow) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildMetricCard(
                      width: 200,
                      label: 'Total Kas Masuk',
                      value: CurrencyFormatter.format(totalIn),
                      subtext: 'Laci: ${CurrencyFormatter.format(summary.cashInDrawer)} • Bank: ${CurrencyFormatter.format(summary.cashInBank)}',
                      icon: Icons.arrow_downward_rounded,
                      iconColor: const Color(0xFF059669),
                      iconBg: const Color(0xFFECFDF5),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 205,
                      label: 'Total Kas Keluar / Beban',
                      value: CurrencyFormatter.format(totalOut),
                      subtext: 'Bank: ${CurrencyFormatter.format(summary.cashOutBank)} • Laci: ${CurrencyFormatter.format(summary.cashOutDrawer)}',
                      icon: Icons.arrow_upward_rounded,
                      iconColor: const Color(0xFFDC2626),
                      iconBg: const Color(0xFFFEF2F2),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 195,
                      label: 'Arus Kas Bersih (Net)',
                      value: CurrencyFormatter.format(netFlow.abs()),
                      valuePrefix: isSurplus ? '+ ' : '- ',
                      subtext: isSurplus ? 'Surplus kas operasional' : 'Defisit kas operasional',
                      icon: isSurplus ? Icons.account_balance_wallet_rounded : Icons.money_off_rounded,
                      iconColor: isSurplus ? AppColors.secondary : const Color(0xFFE11D48),
                      iconBg: isSurplus ? AppColors.secondarySoft : const Color(0xFFFFF1F2),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 210,
                      label: 'Beban Terbesar',
                      value: topCategory != null ? CurrencyFormatter.format(topCategory.totalAmount) : 'Rp 0',
                      subtext: topCategory != null ? '${topCategory.category} (${topCategory.percentage}%)' : 'Belum ada beban',
                      icon: Icons.pie_chart_rounded,
                      iconColor: const Color(0xFFD97706),
                      iconBg: const Color(0xFFFFFBEB),
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'Total Kas Masuk',
                    value: CurrencyFormatter.format(totalIn),
                    subtext: 'Laci: ${CurrencyFormatter.format(summary.cashInDrawer)} • Bank: ${CurrencyFormatter.format(summary.cashInBank)}',
                    icon: Icons.arrow_downward_rounded,
                    iconColor: const Color(0xFF059669),
                    iconBg: const Color(0xFFECFDF5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Total Kas Keluar / Beban',
                    value: CurrencyFormatter.format(totalOut),
                    subtext: 'Bank: ${CurrencyFormatter.format(summary.cashOutBank)} • Laci: ${CurrencyFormatter.format(summary.cashOutDrawer)}',
                    icon: Icons.arrow_upward_rounded,
                    iconColor: const Color(0xFFDC2626),
                    iconBg: const Color(0xFFFEF2F2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Arus Kas Bersih (Net)',
                    value: CurrencyFormatter.format(netFlow.abs()),
                    valuePrefix: isSurplus ? '+ ' : '- ',
                    subtext: isSurplus ? 'Surplus kas operasional' : 'Defisit kas operasional',
                    icon: isSurplus ? Icons.account_balance_wallet_rounded : Icons.money_off_rounded,
                    iconColor: isSurplus ? AppColors.secondary : const Color(0xFFE11D48),
                    iconBg: isSurplus ? AppColors.secondarySoft : const Color(0xFFFFF1F2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Beban Terbesar',
                    value: topCategory != null ? CurrencyFormatter.format(topCategory.totalAmount) : 'Rp 0',
                    subtext: topCategory != null ? '${topCategory.category} (${topCategory.percentage}%)' : 'Belum ada beban',
                    icon: Icons.pie_chart_rounded,
                    iconColor: const Color(0xFFD97706),
                    iconBg: const Color(0xFFFFFBEB),
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
    String? valuePrefix,
    required String subtext,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                    children: [
                      if (valuePrefix != null)
                        TextSpan(
                          text: valuePrefix,
                          style: TextStyle(
                            color: iconColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      TextSpan(text: value),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
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
