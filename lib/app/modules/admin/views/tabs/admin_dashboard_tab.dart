import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_controller.dart';
import '../../../../data/models/admin_transaction_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/skeletons/list_item_skeleton.dart';
import '../widgets/admin_transaction_detail_dialog.dart';
import '../widgets/admin_void_dialog.dart';

class AdminDashboardTab extends GetView<AdminController> {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingDashboard.value && controller.dashboardData.value.date.isEmpty) {
        return const ListItemSkeleton(itemCount: 4);
      }

      final data = controller.dashboardData.value;
      final summary = data.summary;

      return RefreshIndicator(
        color: AppColors.secondary,
        onRefresh: () => controller.fetchDashboard(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 768;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // 1. Mobile Only: Compact Date Selector (Tablet uses top header bar)
                if (!isTablet) ...[
                  _buildMobileDateFilterBar(context),
                  const SizedBox(height: 14),
                ],

                // 2. Uniform, Balanced Hero KPI Cards (3 across on tablet, stacked on mobile)
                _buildKpiSection(summary, isTablet),
                const SizedBox(height: 16),

                // 3. Balanced Grid on Tablet (Row-by-Row IntrinsicHeight for 100% equal card heights)
                if (isTablet) ...[
                  // Row 1: Shift Kasir Aktif & Rincian Pembayaran (100% Sama Rata)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildActiveShiftCard(data)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildPaymentBreakdownCard(data, summary.totalRevenue)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Row 2: Pengawasan Operasional & Distribusi Penjualan (100% Sama Rata)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildOperationalWatchlistCard(data)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDistributionCard(data, isTablet)),
                      ],
                    ),
                  ),
                ] else ...[
                  // Mobile view stacked (100% equal width each, no squished cards)
                  _buildActiveShiftCard(data),
                  const SizedBox(height: 14),
                  _buildPaymentBreakdownCard(data, summary.totalRevenue),
                  const SizedBox(height: 14),
                  _buildDistributionCard(data, isTablet),
                  const SizedBox(height: 14),
                  _buildOperationalWatchlistCard(data),
                ],
                const SizedBox(height: 16),

                // 4. Live Recent Transactions Feed (Fills the viewport and provides real-time monitoring)
                _buildRecentTransactionsSection(context, isTablet),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Mobile Only: Date Filter Bar
  // ---------------------------------------------------------------------------
  Widget _buildMobileDateFilterBar(BuildContext context) {
    final selected = controller.selectedDashboardDate.value;
    final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBorder, width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, color: AppColors.secondary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatDateLabel(selected),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildDateChip('Hari Ini', selected == nowStr, () => controller.changeDashboardDate(DateTime.now())),
          const SizedBox(width: 6),
          _buildDateChip('Kemarin', selected == yesterdayStr, () => controller.changeDashboardDate(DateTime.now().subtract(const Duration(days: 1)))),
        ],
      ),
    );
  }

  Widget _buildDateChip(String label, bool isSelected, VoidCallback onTap) {
    return Material(
      color: isSelected ? AppColors.secondary : AppColors.lightBackground,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.secondary : AppColors.lightBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Uniform, Cohesive Hero KPI Cards
  // ---------------------------------------------------------------------------
  Widget _buildKpiSection(dynamic summary, bool isTablet) {
    final cardRevenue = _buildKpiCard(
      title: 'Total Omset Bersih',
      value: CurrencyFormatter.format(summary.totalRevenue),
      valueColor: AppColors.secondary,
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.secondary,
      subtitle: '${summary.totalTransactions} transaksi terselesaikan',
      badgeText: 'NET REVENUE',
    );

    final cardTransactions = _buildKpiCard(
      title: 'Total Pesanan',
      value: '${summary.totalTransactions}',
      valueColor: AppColors.textPrimary,
      icon: Icons.receipt_long_rounded,
      color: AppColors.primary,
      subtitle: 'Pesanan berhasil diproses',
      badgeText: 'SELESAI',
    );

    final cardAverage = _buildKpiCard(
      title: 'Rata-rata / Struk',
      value: CurrencyFormatter.format(summary.averagePerTransaction),
      valueColor: AppColors.textPrimary,
      icon: Icons.analytics_rounded,
      color: AppColors.info,
      subtitle: 'Basket size per transaksi',
      badgeText: 'AVERAGE',
    );

    if (isTablet) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: cardRevenue),
            const SizedBox(width: 14),
            Expanded(child: cardTransactions),
            const SizedBox(width: 14),
            Expanded(child: cardAverage),
          ],
        ),
      );
    }

    return Column(
      children: [
        cardRevenue,
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cardTransactions),
              const SizedBox(width: 10),
              Expanded(child: cardAverage),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color color,
    required String subtitle,
    required String badgeText,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Active Shift Card (100% Sama Rata)
  // ---------------------------------------------------------------------------
  Widget _buildActiveShiftCard(dynamic data) {
    final shift = data.activeShift;

    if (shift == null) {
      return Container(
        constraints: const BoxConstraints(minHeight: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.storefront_outlined, color: AppColors.textSecondary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Shift Kasir Saat Ini',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: const Text('TUTUP', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: const Icon(Icons.point_of_sale_outlined, color: AppColors.textMuted, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Belum Ada Shift Kasir Aktif',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Kasir belum membuka sesi shift hari ini. Laci uang kasir belum dicatat.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.lightBorder),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 13, color: AppColors.textMuted),
                    SizedBox(width: 4),
                    Text(
                      'Buka kasir di POS untuk memulai shift',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Text(
                  'Standby',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.secondarySoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, color: AppColors.secondary, size: 9),
                    SizedBox(width: 5),
                    Text(
                      'SHIFT SEDANG BERJALAN',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.secondarySoft,
                child: Text(
                  shift.cashierName.isNotEmpty ? shift.cashierName[0].toUpperCase() : 'K',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                shift.cashierName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildShiftMiniStat('Modal Awal', CurrencyFormatter.format(shift.startingCash)),
                ),
                Container(height: 32, width: 1, color: AppColors.lightBorder),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildShiftMiniStat('Penjualan Tunai', CurrencyFormatter.format(shift.cashSales)),
                ),
                Container(height: 32, width: 1, color: AppColors.lightBorder),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildShiftMiniStat(
                    'Estimasi di Laci',
                    CurrencyFormatter.format(shift.expectedCash),
                    isHighlight: true,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.lightBorder),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Dibuka: ${_formatTime(shift.startTime)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Text(
                '${shift.totalTransactions} transaksi terselesaikan',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftMiniStat(String label, String value, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isHighlight ? AppColors.secondary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Payment Breakdown Card (100% Sama Rata)
  // ---------------------------------------------------------------------------
  Widget _buildPaymentBreakdownCard(dynamic data, double totalRevenue) {
    final p = data.paymentBreakdown;

    final cashPercent = totalRevenue > 0 ? (p.cash.total / totalRevenue) : 0.0;
    final qrisPercent = totalRevenue > 0 ? (p.qris.total / totalRevenue) : 0.0;
    final transferPercent = totalRevenue > 0 ? (p.transfer.total / totalRevenue) : 0.0;

    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_rounded, color: AppColors.secondary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Rincian Metode Pembayaran',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondarySoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('REAL-TIME', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPaymentProgressRow(
            label: 'Uang Tunai (Laci Kasir)',
            icon: Icons.payments_rounded,
            total: p.cash.total,
            count: p.cash.count,
            percentage: cashPercent,
            color: AppColors.primary,
          ),
          const SizedBox(height: 10),
          _buildPaymentProgressRow(
            label: 'QRIS Digital (GoPay, OVO, dll)',
            icon: Icons.qr_code_2_rounded,
            total: p.qris.total,
            count: p.qris.count,
            percentage: qrisPercent,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 10),
          _buildPaymentProgressRow(
            label: 'Transfer Bank Langsung',
            icon: Icons.credit_card_rounded,
            total: p.transfer.total,
            count: p.transfer.count,
            percentage: transferPercent,
            color: AppColors.info,
          ),
          const Spacer(),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.lightBorder),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Penerimaan: ${CurrencyFormatter.format(totalRevenue)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const Text(
                '3 Metode Aktif',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProgressRow({
    required String label,
    required IconData icon,
    required double total,
    required int count,
    required double percentage,
    required Color color,
  }) {
    final percentInt = (percentage * 100).clamp(0, 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text('$count transaksi • $percentInt% kontribusi', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(total),
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: AppColors.lightBackground,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Operational Watchlist Card (100% Sama Rata)
  // ---------------------------------------------------------------------------
  Widget _buildOperationalWatchlistCard(dynamic data) {
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.secondary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Pengawasan Operasional Toko',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('MONITORING', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.warning)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Open Bills Tile
          Material(
            color: AppColors.warningSoft.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => controller.switchTab(3),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.table_restaurant_rounded, color: AppColors.warning, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data.openBillsSummary.count} Meja Belum Lunas',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Potensi Omset: ${CurrencyFormatter.format(data.openBillsSummary.potentialRevenue)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Lihat Meja', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.secondary),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Cancellations (Void) Tile
          Material(
            color: AppColors.dangerSoft.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                controller.selectedTrxStatus.value = 'cancelled';
                controller.switchTab(1);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data.cancellationsSummary.count} Transaksi Dibatalkan (Void)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.danger),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total Nominal: ${CurrencyFormatter.format(data.cancellationsSummary.totalNominal)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Rincian', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger)),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.danger),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.lightBorder),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data.openBillsSummary.count + data.cancellationsSummary.count} isu pengawasan terdeteksi',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                data.cancellationsSummary.count > 0 ? 'Perlu Perhatian' : 'Kondisi Normal',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: data.cancellationsSummary.count > 0 ? AppColors.danger : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Distribution Card: Sales Channel & Order Type (100% Sama Rata)
  // ---------------------------------------------------------------------------
  Widget _buildDistributionCard(dynamic data, bool isTablet) {
    final posTotal = data.orderSourceBreakdown.pos.total;
    final onlineTotal = data.orderSourceBreakdown.onlineOrder.total;
    final channelSum = posTotal + onlineTotal;

    final dineInTotal = data.orderTypeBreakdown.dineIn.total;
    final takeawayTotal = data.orderTypeBreakdown.takeaway.total;
    final typeSum = dineInTotal + takeawayTotal;

    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, color: AppColors.secondary, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Distribusi Saluran & Tipe',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondarySoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('DISTRIBUSI', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isTablet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SALURAN PENJUALAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
                      const SizedBox(height: 10),
                      _buildDistributionRowItem(
                        label: 'Kasir POS',
                        icon: Icons.point_of_sale_rounded,
                        count: data.orderSourceBreakdown.pos.count,
                        total: posTotal,
                        totalSum: channelSum,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(height: 10),
                      _buildDistributionRowItem(
                        label: 'Pesanan Online',
                        icon: Icons.language_rounded,
                        count: data.orderSourceBreakdown.onlineOrder.count,
                        total: onlineTotal,
                        totalSum: channelSum,
                        color: AppColors.info,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 90,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  color: AppColors.lightBorder,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TIPE PESANAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
                      const SizedBox(height: 10),
                      _buildDistributionRowItem(
                        label: 'Dine-in',
                        icon: Icons.table_restaurant_rounded,
                        count: data.orderTypeBreakdown.dineIn.count,
                        total: dineInTotal,
                        totalSum: typeSum,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 10),
                      _buildDistributionRowItem(
                        label: 'Takeaway',
                        icon: Icons.shopping_bag_rounded,
                        count: data.orderTypeBreakdown.takeaway.count,
                        total: takeawayTotal,
                        totalSum: typeSum,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            const Text('SALURAN PENJUALAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            _buildDistributionRowItem(
              label: 'Kasir POS',
              icon: Icons.point_of_sale_rounded,
              count: data.orderSourceBreakdown.pos.count,
              total: posTotal,
              totalSum: channelSum,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 8),
            _buildDistributionRowItem(
              label: 'Pesanan Online',
              icon: Icons.language_rounded,
              count: data.orderSourceBreakdown.onlineOrder.count,
              total: onlineTotal,
              totalSum: channelSum,
              color: AppColors.info,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.lightBorder),
            const SizedBox(height: 12),
            const Text('TIPE PESANAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            _buildDistributionRowItem(
              label: 'Dine-in',
              icon: Icons.table_restaurant_rounded,
              count: data.orderTypeBreakdown.dineIn.count,
              total: dineInTotal,
              totalSum: typeSum,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            _buildDistributionRowItem(
              label: 'Takeaway',
              icon: Icons.shopping_bag_rounded,
              count: data.orderTypeBreakdown.takeaway.count,
              total: takeawayTotal,
              totalSum: typeSum,
              color: AppColors.warning,
            ),
          ],
          const Spacer(),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.lightBorder),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'POS: ${channelSum > 0 ? ((posTotal / channelSum) * 100).toInt() : 0}% • Online: ${channelSum > 0 ? ((onlineTotal / channelSum) * 100).toInt() : 0}%',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                'Dine-in: ${typeSum > 0 ? ((dineInTotal / typeSum) * 100).toInt() : 0}% • Takeaway: ${typeSum > 0 ? ((takeawayTotal / typeSum) * 100).toInt() : 0}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionRowItem({
    required String label,
    required IconData icon,
    required int count,
    required double total,
    required double totalSum,
    required Color color,
  }) {
    final percent = totalSum > 0 ? (total / totalSum) : 0.0;
    final percentInt = (percent * 100).clamp(0, 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$count pesanan • $percentInt%',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(total),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 4,
            backgroundColor: AppColors.lightBackground,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Live Recent Transactions Feed (Responsive & Structured)
  // ---------------------------------------------------------------------------
  Widget _buildRecentTransactionsSection(BuildContext context, bool isTablet) {
    return Obx(() {
      final list = controller.transactions;
      final displayList = list.take(6).toList();

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.secondary, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Transaksi Terkini Hari Ini',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fiber_manual_record, color: AppColors.success, size: 8),
                      SizedBox(width: 4),
                      Text(
                        'LIVE FEED',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.success),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => controller.switchTab(1),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.secondary),
                  label: Text(
                    'Lihat Semua (${list.length})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (controller.isLoadingTransactions.value && list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary)),
              )
            else if (displayList.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.receipt_outlined, size: 38, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text(
                      'Belum ada transaksi pada periode ini',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            else ...[
              // Tablet Column Header Bar
              if (isTablet) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.lightBorder.withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 44),
                      Expanded(
                        flex: 5,
                        child: Text(
                          'INVOICE & PELANGGAN',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.6),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'WAKTU & METODE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.6),
                        ),
                      ),
                      SizedBox(
                        width: 105,
                        child: Text(
                          'STATUS',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.6),
                        ),
                      ),
                      SizedBox(
                        width: 125,
                        child: Text(
                          'TOTAL OMSET',
                          textAlign: TextAlign.end,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.6),
                        ),
                      ),
                      SizedBox(width: 28),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                separatorBuilder: (context, i) => const Divider(height: 1, color: AppColors.lightBorder),
                itemBuilder: (context, i) {
                  final tx = displayList[i];
                  final isDineIn = tx.orderType == 'dine_in';

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final fullTrx = await controller.fetchTransactionDetail(tx.id) ?? tx;
                      if (context.mounted) {
                        AdminTransactionDetailDialog.show(
                          context,
                          transaction: fullTrx,
                          onVoidPressed: () => AdminVoidDialog.show(
                            context,
                            transaction: fullTrx,
                            onConfirmVoid: (reason) => controller.voidTransaction(fullTrx.id, reason),
                          ),
                        );
                      }
                    },
                    child: isTablet
                        ? _buildTabletTransactionRow(tx, isDineIn, i.isEven)
                        : _buildMobileTransactionTile(tx, isDineIn, i.isEven),
                  );
                },
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildTabletTransactionRow(AdminTransactionModel tx, bool isDineIn, bool isEven) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : AppColors.lightBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 1. Order Type Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDineIn ? AppColors.primary.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDineIn ? Icons.table_restaurant_rounded : Icons.shopping_bag_rounded,
              color: isDineIn ? AppColors.primary : AppColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),

          // 2. Invoice & Customer
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tx.invoiceNumber,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: tx.isCancelled ? AppColors.danger : AppColors.textPrimary,
                          decoration: tx.isCancelled ? TextDecoration.lineThrough : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isDineIn ? AppColors.primary.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isDineIn
                            ? (tx.tableNumber != null && tx.tableNumber!.isNotEmpty ? 'Meja ${tx.tableNumber}' : 'Dine-in')
                            : 'Takeaway',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isDineIn ? AppColors.primary : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${tx.customerName.isNotEmpty ? tx.customerName : "Pelanggan Umum"} • Kasir: ${tx.cashierName}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          // 3. Waktu & Metode
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(tx.createdAt),
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.secondaryLight.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    tx.paymentMethod.toUpperCase(),
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                ),
              ],
            ),
          ),

          // 4. Status Pill
          SizedBox(
            width: 105,
            child: Center(child: _buildStatusPill(tx)),
          ),

          // 5. Total Omset
          SizedBox(
            width: 125,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(tx.total),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: tx.isCancelled ? AppColors.textMuted : AppColors.textPrimary,
                    decoration: tx.isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tx.items.length} item',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),

          // 6. Action Icon
          const SizedBox(
            width: 28,
            child: Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTransactionTile(AdminTransactionModel tx, bool isDineIn, bool isEven) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isEven ? Colors.white : AppColors.lightBackground.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier 1: Avatar, Invoice & Customer, Total Omset
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDineIn ? AppColors.primary.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isDineIn ? Icons.table_restaurant_rounded : Icons.shopping_bag_rounded,
                  color: isDineIn ? AppColors.primary : AppColors.warning,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tx.invoiceNumber,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: tx.isCancelled ? AppColors.danger : AppColors.textPrimary,
                              decoration: tx.isCancelled ? TextDecoration.lineThrough : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDineIn ? AppColors.primary.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isDineIn
                                ? (tx.tableNumber != null && tx.tableNumber!.isNotEmpty ? 'Meja ${tx.tableNumber}' : 'Dine-in')
                                : 'Takeaway',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isDineIn ? AppColors.primary : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tx.customerName.isNotEmpty ? tx.customerName : "Pelanggan Umum"} • ${tx.cashierName}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(tx.total),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: tx.isCancelled ? AppColors.textMuted : AppColors.textPrimary,
                      decoration: tx.isCancelled ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tx.items.length} item',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Tier 2: Time, Payment Pill, Status Pill, Chevron
          Row(
            children: [
              const SizedBox(width: 44),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 11.5, color: AppColors.textMuted),
                  const SizedBox(width: 3.5),
                  Text(
                    _formatTime(tx.createdAt),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondarySoft,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppColors.secondaryLight.withValues(alpha: 0.3)),
                ),
                child: Text(
                  tx.paymentMethod.toUpperCase(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.secondary),
                ),
              ),
              const Spacer(),
              _buildStatusPill(tx),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(AdminTransactionModel tx) {
    if (tx.isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'DIBATALKAN',
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.danger),
        ),
      );
    }
    if (tx.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'OPEN BILL',
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.warning),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'SELESAI',
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.success),
      ),
    );
  }

  String _formatDateLabel(String dtStr) {
    if (dtStr.isEmpty) return 'Hari Ini';
    try {
      final dt = DateTime.parse(dtStr);
      return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return dtStr;
    }
  }

  String _formatTime(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dtStr).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return dtStr;
    }
  }
}
