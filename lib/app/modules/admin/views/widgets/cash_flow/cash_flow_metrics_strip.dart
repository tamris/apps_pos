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

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'today':
        return 'Hari Ini';
      case 'month':
        return 'Bulan Ini';
      default:
        return 'Periode';
    }
  }

  void _showBreakdownDialog(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String heroLabel,
    required String heroValue,
    String? heroPrefix,
    required List<_BreakdownRowData> items,
    String? infoNote,
  }) {
    final isTablet = MediaQuery.of(context).size.width >= 650;

    Widget content(BuildContext ctx) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isTablet
              ? BorderRadius.circular(16)
              : const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
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
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                  onPressed: () => Navigator.of(ctx).pop(),
                  visualDensity: VisualDensity.compact,
                  splashRadius: 18,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hero Total Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heroLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                        children: [
                          if (heroPrefix != null)
                            TextSpan(
                              text: heroPrefix,
                              style: TextStyle(
                                color: iconColor,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          TextSpan(text: heroValue),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Breakdown Items
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: items.map((item) => _buildBreakdownRow(item)).toList(),
                ),
              ),
            ),
            if (infoNote != null && infoNote.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        infoNote,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (isTablet) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: content(ctx),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => content(ctx),
      );
    }
  }

  Widget _buildBreakdownRow(_BreakdownRowData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: data.iconBg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (data.sublines != null && data.sublines!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  for (final line in data.sublines!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 4.5,
                            height: 4.5,
                            decoration: const BoxDecoration(
                              color: Color(0xFF94A3B8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              line,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ] else if (data.subtitle != null && data.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    data.subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data.amount,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: data.amountColor ?? const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = controller.cashFlowSummary.value;
      final totalInflow = summary.totalInflow > 0
          ? summary.totalInflow
          : (summary.totalSales + summary.cashInTotal);
      final totalOut = summary.cashOutTotal;
      final netFlow = summary.netCashFlow;
      final isSurplus = summary.isSurplus;
      final breakdown = summary.categoryBreakdown;
      final topCategory = breakdown.isNotEmpty ? breakdown.first : null;
      final periodLabel = _getPeriodLabel(controller.selectedCashFlowPeriod.value);

      return Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 860;

            final cardSaldo = _buildMetricCard(
              width: isNarrow ? 210 : null,
              label: 'Saldo Kas Toko Riil',
              value: CurrencyFormatter.format(summary.totalRealBalance),
              subtext: 'Rincian fisik & bank',
              icon: Icons.account_balance_wallet_rounded,
              iconColor: AppColors.secondary,
              iconBg: const Color(0xFFEEF2FF),
              onTap: () => _showBreakdownDialog(
                context,
                title: 'Rincian Saldo Kas Toko',
                subtitle: 'Posisi uang kas riil toko saat ini (All-Time)',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.secondary,
                iconBg: const Color(0xFFEEF2FF),
                heroLabel: 'Total Kas Riil Toko Saat Ini',
                heroValue: CurrencyFormatter.format(summary.totalRealBalance),
                items: [
                  _BreakdownRowData(
                    title: 'Kas Tunai Fisik (Laci + Toko)',
                    subtitle: 'Uang fisik di laci kasir dan kas operasional',
                    amount: CurrencyFormatter.format(summary.cashBalance),
                    icon: Icons.payments_rounded,
                    iconColor: const Color(0xFF16A34A),
                    iconBg: const Color(0xFFDCFCE7),
                  ),
                  _BreakdownRowData(
                    title: 'Saldo Rekening Bank (Non-Tunai)',
                    subtitle: 'Penerimaan QRIS & transfer bank',
                    amount: CurrencyFormatter.format(summary.bankBalance),
                    icon: Icons.account_balance_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFFDBEAFE),
                  ),
                ],
                infoNote:
                    'Saldo Kas Riil adalah akumulasi nyata uang kas toko saat ini (uang fisik di laci kasir dan saldo di rekening bank). Angka ini dihitung dari seluruh transaksi dan tidak ter-reset saat pergantian bulan.',
              ),
            );

            final cardPemasukan = _buildMetricCard(
              width: isNarrow ? 210 : null,
              label: 'Total Pemasukan Kas',
              value: CurrencyFormatter.format(totalInflow),
              subtext: 'Rincian omzet & pay-in',
              icon: Icons.arrow_downward_rounded,
              iconColor: const Color(0xFF059669),
              iconBg: const Color(0xFFECFDF5),
              onTap: () => _showBreakdownDialog(
                context,
                title: 'Rincian Pemasukan Kas',
                subtitle: 'Total penerimaan kas periode $periodLabel',
                icon: Icons.arrow_downward_rounded,
                iconColor: const Color(0xFF059669),
                iconBg: const Color(0xFFECFDF5),
                heroLabel: 'Total Pemasukan Kas ($periodLabel)',
                heroValue: CurrencyFormatter.format(totalInflow),
                items: [
                  _BreakdownRowData(
                    title: 'Penjualan Omzet Selesai',
                    sublines: [
                      'Tunai: ${CurrencyFormatter.format(summary.cashSales)}',
                      'Non-Tunai: ${CurrencyFormatter.format(summary.nonCashSales)}',
                    ],
                    amount: CurrencyFormatter.format(summary.totalSales),
                    icon: Icons.shopping_bag_rounded,
                    iconColor: const Color(0xFF059669),
                    iconBg: const Color(0xFFECFDF5),
                  ),
                  _BreakdownRowData(
                    title: 'Kas Masuk Non-Penjualan (Pay In)',
                    sublines: [
                      'Laci Kasir: ${CurrencyFormatter.format(summary.cashInDrawer)}',
                      'Rekening Bank: ${CurrencyFormatter.format(summary.cashInBank)}',
                    ],
                    amount: CurrencyFormatter.format(summary.cashInTotal),
                    icon: Icons.input_rounded,
                    iconColor: const Color(0xFF0D9488),
                    iconBg: const Color(0xFFCCFBF1),
                  ),
                ],
                infoNote:
                    'Total Pemasukan Kas mencatat seluruh uang masuk selama periode $periodLabel, bersumber dari omzet penjualan selesai (tunai & non-tunai) serta kas masuk tambahan (Pay-In).',
              ),
            );

            final cardPengeluaran = _buildMetricCard(
              width: isNarrow ? 210 : null,
              label: 'Total Pengeluaran Kas',
              value: CurrencyFormatter.format(totalOut),
              subtext: 'Rincian beban toko',
              icon: Icons.arrow_upward_rounded,
              iconColor: const Color(0xFFDC2626),
              iconBg: const Color(0xFFFEF2F2),
              onTap: () => _showBreakdownDialog(
                context,
                title: 'Rincian Pengeluaran Kas',
                subtitle: 'Total beban & kas keluar periode $periodLabel',
                icon: Icons.arrow_upward_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBg: const Color(0xFFFEF2F2),
                heroLabel: 'Total Pengeluaran Kas ($periodLabel)',
                heroValue: CurrencyFormatter.format(totalOut),
                items: [
                  _BreakdownRowData(
                    title: 'Pengeluaran via Transfer Bank',
                    subtitle: 'Beban yang dibayar via transfer rekening',
                    amount: CurrencyFormatter.format(summary.cashOutBank),
                    icon: Icons.account_balance_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFFDBEAFE),
                  ),
                  _BreakdownRowData(
                    title: 'Pengeluaran Tunai (Laci & Toko)',
                    sublines: [
                      'Kas Operasional Toko: ${CurrencyFormatter.format(summary.cashOutPettyCash)}',
                      'Laci Kasir: ${CurrencyFormatter.format(summary.cashOutDrawer)}',
                    ],
                    amount: CurrencyFormatter.format(
                        summary.cashOutDrawer + summary.cashOutPettyCash),
                    icon: Icons.payments_rounded,
                    iconColor: const Color(0xFFDC2626),
                    iconBg: const Color(0xFFFEE2E2),
                  ),
                  if (topCategory != null)
                    _BreakdownRowData(
                      title: 'Kategori Beban Terbesar',
                      subtitle: '${topCategory.category} (${topCategory.percentage}%)',
                      amount: CurrencyFormatter.format(topCategory.totalAmount),
                      icon: Icons.pie_chart_rounded,
                      iconColor: const Color(0xFFD97706),
                      iconBg: const Color(0xFFFEF3C7),
                    ),
                ],
                infoNote:
                    'Total Pengeluaran Kas mencatat seluruh beban operasional dan uang keluar toko selama periode $periodLabel, baik dibayar tunai melalui laci kasir/toko maupun transfer bank.',
              ),
            );

            final cardArusBersih = _buildMetricCard(
              width: isNarrow ? 210 : null,
              label: 'Arus Kas Bersih (Net)',
              value: CurrencyFormatter.format(netFlow.abs()),
              valuePrefix: isSurplus ? '+ ' : '- ',
              subtext: isSurplus ? 'Surplus kas operasional' : 'Defisit kas operasional',
              icon: isSurplus ? Icons.account_balance_wallet_rounded : Icons.money_off_rounded,
              iconColor: isSurplus ? AppColors.secondary : const Color(0xFFE11D48),
              iconBg: isSurplus ? const Color(0xFFEEF2FF) : const Color(0xFFFFF1F2),
              onTap: () => _showBreakdownDialog(
                context,
                title: 'Rincian Arus Kas Bersih',
                subtitle: 'Selisih pemasukan dan pengeluaran periode $periodLabel',
                icon: isSurplus ? Icons.account_balance_wallet_rounded : Icons.money_off_rounded,
                iconColor: isSurplus ? AppColors.secondary : const Color(0xFFE11D48),
                iconBg: isSurplus ? const Color(0xFFEEF2FF) : const Color(0xFFFFF1F2),
                heroLabel: 'Arus Kas Bersih ($periodLabel)',
                heroValue: CurrencyFormatter.format(netFlow.abs()),
                heroPrefix: isSurplus ? '+ ' : '- ',
                items: [
                  _BreakdownRowData(
                    title: 'Total Pemasukan Kas',
                    subtitle: 'Penjualan selesai + Pay In',
                    amount: '+ ${CurrencyFormatter.format(totalInflow)}',
                    amountColor: const Color(0xFF059669),
                    icon: Icons.arrow_downward_rounded,
                    iconColor: const Color(0xFF059669),
                    iconBg: const Color(0xFFECFDF5),
                  ),
                  _BreakdownRowData(
                    title: 'Total Pengeluaran Kas',
                    subtitle: 'Seluruh beban operasional & kas keluar',
                    amount: '- ${CurrencyFormatter.format(totalOut)}',
                    amountColor: const Color(0xFFDC2626),
                    icon: Icons.arrow_upward_rounded,
                    iconColor: const Color(0xFFDC2626),
                    iconBg: const Color(0xFFFEE2E2),
                  ),
                ],
                infoNote: isSurplus
                    ? 'Arus Kas Bersih periode $periodLabel surplus sebesar ${CurrencyFormatter.format(netFlow.abs())}, menandakan pemasukan kas toko lebih besar daripada total pengeluaran beban.'
                    : 'Arus Kas Bersih periode $periodLabel defisit sebesar ${CurrencyFormatter.format(netFlow.abs())}, menandakan total pengeluaran beban toko melebihi penerimaan kas.',
              ),
            );

            if (isNarrow) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    cardSaldo,
                    const SizedBox(width: 10),
                    cardPemasukan,
                    const SizedBox(width: 10),
                    cardPengeluaran,
                    const SizedBox(width: 10),
                    cardArusBersih,
                  ],
                ),
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cardSaldo),
                  const SizedBox(width: 10),
                  Expanded(child: cardPemasukan),
                  const SizedBox(width: 10),
                  Expanded(child: cardPengeluaran),
                  const SizedBox(width: 10),
                  Expanded(child: cardArusBersih),
                ],
              ),
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
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: iconColor.withValues(alpha: 0.08),
        highlightColor: iconColor.withValues(alpha: 0.04),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
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
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: RichText(
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
                      ),
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
        ),
      ),
    );
  }
}

class _BreakdownRowData {
  final String title;
  final String? subtitle;
  final List<String>? sublines;
  final String amount;
  final Color? amountColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  _BreakdownRowData({
    required this.title,
    this.subtitle,
    this.sublines,
    required this.amount,
    this.amountColor,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}
