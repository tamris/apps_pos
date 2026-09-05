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
      if (controller.isLoadingDashboard.value &&
          controller.dashboardData.value.date.isEmpty) {
        return const ListItemSkeleton(itemCount: 4);
      }

      final data = controller.dashboardData.value;
      final summary = data.summary;

      return RefreshIndicator(
        color: AppColors.secondary,
        onRefresh: () => controller.fetchDashboard(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final isWide = availableWidth >= 760;
            final isScreenMobile = MediaQuery.of(context).size.width < 768;

            return ListView(
              padding: EdgeInsets.symmetric(
                horizontal: availableWidth >= 768 ? 20 : 16,
                vertical: 16,
              ),
              children: [
                // 1. Mobile Date Selector (Only when mobile AppBar is used)
                if (isScreenMobile) ...[
                  _buildMobileDateFilterBar(context),
                  const SizedBox(height: 14),
                ],

                // 2. Executive Metric Cards (Hero Strip)
                _buildKpiSection(summary, availableWidth),
                const SizedBox(height: 16),

                // 3. Operational Cards (2 columns on wide, stacked on narrow)
                if (isWide) ...[
                  // Row 1: Shift Kasir Aktif & Rincian Pembayaran
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildShiftLedgerCard(data, height: 215)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPaymentDistributionCard(
                          data,
                          summary.totalRevenue,
                          height: 215,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row 2: Pengawasan Operasional & Distribusi Saluran/Tipe
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildOperationsWatchlistCard(data, height: 215),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildChannelAndOrderTypeCard(
                          data,
                          true,
                          height: 215,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Stacked full-width cards (Clean, zero-cramp layout on mobile or narrow tablet)
                  _buildShiftLedgerCard(data),
                  const SizedBox(height: 14),
                  _buildPaymentDistributionCard(data, summary.totalRevenue),
                  const SizedBox(height: 14),
                  _buildOperationsWatchlistCard(data),
                  const SizedBox(height: 14),
                  _buildChannelAndOrderTypeCard(data, false),
                ],
                const SizedBox(height: 18),

                // 4. Live Recent Activity Stream (Table if >= 640, Card Stream if < 640)
                _buildRecentActivitySection(context, availableWidth),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Mobile Date Filter Bar
  // ---------------------------------------------------------------------------
  Widget _buildMobileDateFilterBar(BuildContext context) {
    final selected = controller.selectedDashboardDate.value;
    final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterdayStr = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 1)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(selected) ?? DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  initialEntryMode: DatePickerEntryMode.calendarOnly,
                  helpText: 'PILIH TANGGAL',
                  cancelText: 'Batal',
                  confirmText: 'Terapkan',
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.secondary,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Color(0xFF0F172A),
                        ),
                        datePickerTheme: DatePickerThemeData(
                          backgroundColor: Colors.white,
                          headerBackgroundColor: AppColors.secondary,
                          headerForegroundColor: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  controller.changeDashboardDate(picked);
                }
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.secondary,
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDateLabel(selected),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildDateChip(
            'Hari Ini',
            selected == nowStr,
            () => controller.changeDashboardDate(DateTime.now()),
          ),
          const SizedBox(width: 6),
          _buildDateChip(
            'Kemarin',
            selected == yesterdayStr,
            () => controller.changeDashboardDate(
              DateTime.now().subtract(const Duration(days: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(String label, bool isSelected, VoidCallback onTap) {
    return Material(
      color: isSelected ? AppColors.secondary : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Executive Metric Strip (Hero KPIs)
  // Clean, high signal-to-noise ratio without yelling uppercase badges
  // ---------------------------------------------------------------------------
  Widget _buildKpiSection(dynamic summary, double availableWidth) {
    final isCompact = availableWidth < 500;

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

    final cardTransactions = _buildKpiCard(
      label: 'Volume Pesanan',
      value: '${summary.totalTransactions}',
      valueColor: const Color(0xFF0F172A),
      icon: Icons.receipt_long_outlined,
      iconColor: const Color(0xFF0EA5E9),
      iconBg: const Color(0xFFF0F9FF),
      subtitle: 'Pesanan terbayar dan selesai',
      isCompact: isCompact,
    );

    final cardAverage = _buildKpiCard(
      label: 'Rata-rata / Struk',
      value: CurrencyFormatter.format(summary.averagePerTransaction),
      valueColor: const Color(0xFF0F172A),
      icon: Icons.analytics_outlined,
      iconColor: const Color(0xFF10B981),
      iconBg: const Color(0xFFECFDF5),
      subtitle: 'Nilai rata-rata belanja',
      isCompact: isCompact,
    );

    if (availableWidth >= 860) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: cardRevenue),
          const SizedBox(width: 14),
          Expanded(child: cardTransactions),
          const SizedBox(width: 14),
          Expanded(child: cardAverage),
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
              Expanded(child: cardTransactions),
              const SizedBox(width: 10),
              Expanded(child: cardAverage),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        cardRevenue,
        const SizedBox(height: 10),
        cardTransactions,
        const SizedBox(height: 10),
        cardAverage,
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

  // ---------------------------------------------------------------------------
  // 2. Shift Kasir Aktif (Financial Ledger Style)
  // Clean financial format instead of box-inside-box clutter
  // ---------------------------------------------------------------------------
  // 2. Operasional Shift Kasir (Cash Ledger Strip)
  // Structured cash-in-drawer reconciliation card with quick shift audit link
  // ---------------------------------------------------------------------------
  Widget _buildShiftLedgerCard(dynamic data, {double? height}) {
    final shift = data.activeShift;

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
          // 1. Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shift Kasir',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              if (shift != null)
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.fiber_manual_record,
                              size: 6.5,
                              color: Color(0xFF10B981),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Aktif',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: const Color(0xFFEEF2FF),
                        child: Text(
                          shift.cashierName.isNotEmpty
                              ? shift.cashierName[0].toUpperCase()
                              : 'K',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          shift.cashierName,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Belum Dibuka',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),

          if (shift == null) ...[
            if (height == null) const SizedBox(height: 18),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: Color(0xFF94A3B8),
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tidak ada shift aktif hari ini',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Buka kasir pada POS untuk mulai mencatat arus kas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            if (height == null) const SizedBox(height: 18),
            Column(
              children: [
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Status Laci Kas',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    InkWell(
                      onTap: () => controller.switchTab(2),
                      child: const Text(
                        'Riwayat Shift →',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            if (height == null) const SizedBox(height: 10),
            // 2. Cash In Drawer (Hero Box)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.point_of_sale_outlined,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Estimasi Kas di Laci',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            CurrencyFormatter.format(shift.expectedCash),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Modal: ${CurrencyFormatter.format(shift.startingCash)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '+ Penjualan: ${CurrencyFormatter.format(shift.cashSales)}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF047857),
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (height == null) const SizedBox(height: 8),
            // 3. Shift Performance Strip (Omzet shift & Transaksi)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insights_outlined,
                        size: 13,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Total Omzet: ${CurrencyFormatter.format(shift.totalSales > 0 ? shift.totalSales : shift.cashSales)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF334155),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${shift.totalTransactions} transaksi',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),

            if (height == null) const SizedBox(height: 8),
            // 4. Footer Row with Quick Action
            Column(
              children: [
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 12.5,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Dibuka pukul ${_formatTime(shift.startTime)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => controller.switchTab(2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Audit Shift',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Rincian Metode Pembayaran (FinTech Multi-Segment Distribution Bar)
  // Replaces disconnected progress bars with a unified, modern financial bar
  // ---------------------------------------------------------------------------
  Widget _buildPaymentDistributionCard(
    dynamic data,
    double totalRevenue, {
    double? height,
  }) {
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

          // Unified Multi-Segment Distribution Bar (FinTech style)
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  if (cashPercent > 0)
                    Expanded(
                      flex: (cashPercent * 100).toInt().clamp(1, 100),
                      child: Container(
                        color: const Color(0xFF10B981),
                      ), // Emerald
                    ),
                  if (qrisPercent > 0)
                    Expanded(
                      flex: (qrisPercent * 100).toInt().clamp(1, 100),
                      child: Container(color: AppColors.secondary), // Indigo
                    ),
                  if (transferPercent > 0)
                    Expanded(
                      flex: (transferPercent * 100).toInt().clamp(1, 100),
                      child: Container(color: const Color(0xFF0EA5E9)), // Sky
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
                      'Total Penerimaan Real-Time',
                      maxLines: 1,
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${p.cash.count + p.qris.count + p.transfer.count} Transaksi',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 11,
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
          ),
        ),
        Text(
          '$count trx • $percentInt%',
          maxLines: 1,
          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(width: 10),
        Text(
          CurrencyFormatter.format(total),
          maxLines: 1,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Pengawasan Operasional Toko
  // Clean alert links without screaming loud borders
  // ---------------------------------------------------------------------------
  Widget _buildOperationsWatchlistCard(dynamic data, {double? height}) {
    final int openBillsCount = data.openBillsSummary.count;
    final double openBillsPotential = data.openBillsSummary.potentialRevenue;
    final int cancellationsCount = data.cancellationsSummary.count;
    final double cancellationsNominal = data.cancellationsSummary.totalNominal;
    final int totalIssues = openBillsCount + cancellationsCount;

    final Widget openBillsTile = _buildOperationActionTile(
      icon: openBillsCount > 0
          ? Icons.table_restaurant_outlined
          : Icons.table_restaurant_outlined,
      iconBg: openBillsCount > 0
          ? const Color(0xFFFEF3C7)
          : const Color(0xFFF1F5F9),
      iconColor: openBillsCount > 0
          ? const Color(0xFFD97706)
          : const Color(0xFF64748B),
      title: openBillsCount > 0
          ? '$openBillsCount Meja Belum Lunas'
          : 'Semua Tagihan Meja Lunas',
      subtitle: openBillsCount > 0
          ? 'Potensi tertunda: ${CurrencyFormatter.format(openBillsPotential)}'
          : 'Tidak ada open bill / tagihan gantung',
      subtitleColor: openBillsCount > 0
          ? const Color(0xFFD97706)
          : const Color(0xFF94A3B8),
      actionText: openBillsCount > 0 ? 'Lihat Meja' : 'Denah',
      actionColor: openBillsCount > 0
          ? AppColors.secondary
          : const Color(0xFF64748B),
      actionBg: openBillsCount > 0
          ? const Color(0xFFEEF2FF)
          : const Color(0xFFF1F5F9),
      cardBg: openBillsCount > 0
          ? const Color(0xFFFFFDF5)
          : const Color(0xFFF8FAFC),
      borderColor: openBillsCount > 0
          ? const Color(0xFFFDE68A)
          : const Color(0xFFE2E8F0),
      onTap: () => controller.switchTab(3),
    );

    final Widget cancellationsTile = _buildOperationActionTile(
      icon: cancellationsCount > 0
          ? Icons.delete_sweep_outlined
          : Icons.verified_outlined,
      iconBg: cancellationsCount > 0
          ? const Color(0xFFFEE2E2)
          : const Color(0xFFF1F5F9),
      iconColor: cancellationsCount > 0
          ? const Color(0xFFDC2626)
          : const Color(0xFF64748B),
      title: cancellationsCount > 0
          ? '$cancellationsCount Pembatalan Nota (Void)'
          : 'Nol Pembatalan Nota (Void)',
      subtitle: cancellationsCount > 0
          ? 'Total nominal: ${CurrencyFormatter.format(cancellationsNominal)}'
          : 'Seluruh transaksi hari ini tercatat valid',
      subtitleColor: cancellationsCount > 0
          ? const Color(0xFFDC2626)
          : const Color(0xFF94A3B8),
      actionText: cancellationsCount > 0 ? 'Audit Void' : 'Riwayat',
      actionColor: cancellationsCount > 0
          ? const Color(0xFFDC2626)
          : const Color(0xFF64748B),
      actionBg: cancellationsCount > 0
          ? const Color(0xFFFEF2F2)
          : const Color(0xFFF1F5F9),
      cardBg: cancellationsCount > 0
          ? const Color(0xFFFFFBFB)
          : const Color(0xFFF8FAFC),
      borderColor: cancellationsCount > 0
          ? const Color(0xFFFECACA)
          : const Color(0xFFE2E8F0),
      onTap: () {
        controller.selectedTrxStatus.value = 'cancelled';
        controller.switchTab(1);
      },
    );

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Pengawasan Operasional',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: totalIssues > 0
                      ? const Color(0xFFFFFBEB)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: totalIssues > 0
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      size: 6,
                      color: totalIssues > 0
                          ? const Color(0xFFD97706)
                          : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      totalIssues > 0
                          ? '$totalIssues Isu Perlu Perhatian'
                          : 'Operasional Tertib',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: totalIssues > 0
                            ? const Color(0xFFB45309)
                            : const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Two Action Tiles filling available space
          if (height != null) ...[
            const SizedBox(height: 12),
            Expanded(child: openBillsTile),
            const SizedBox(height: 10),
            Expanded(child: cancellationsTile),
          ] else ...[
            const SizedBox(height: 12),
            openBillsTile,
            const SizedBox(height: 10),
            cancellationsTile,
          ],
        ],
      ),
    );
  }

  Widget _buildOperationActionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required String actionText,
    required Color actionColor,
    required Color actionBg,
    required Color cardBg,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: actionBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: actionColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: actionColor,
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

  // ---------------------------------------------------------------------------
  // 5. Distribusi Saluran & Tipe Pesanan
  // Balanced proportion bars for POS vs Online & Dine-in vs Takeaway
  // ---------------------------------------------------------------------------
  Widget _buildChannelAndOrderTypeCard(
    dynamic data,
    bool isTablet, {
    double? height,
  }) {
    final posTotal = data.orderSourceBreakdown.pos.total;
    final onlineTotal = data.orderSourceBreakdown.onlineOrder.total;
    final channelSum = posTotal + onlineTotal;

    final dineInTotal = data.orderTypeBreakdown.dineIn.total;
    final takeawayTotal = data.orderTypeBreakdown.takeaway.total;
    final typeSum = dineInTotal + takeawayTotal;

    final posPercent = channelSum > 0 ? (posTotal / channelSum) : 0.0;
    final dineInPercent = typeSum > 0 ? (dineInTotal / typeSum) : 0.0;
    final useSideBySide = isTablet || height != null;

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
          const Text(
            'Distribusi Pesanan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          if (height == null) const SizedBox(height: 10),

          // Side-by-side or stacked
          if (useSideBySide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Saluran Penjualan
                Expanded(
                  child: _buildProportionSection(
                    title: 'SALURAN',
                    labelA: 'Kasir POS',
                    countA: data.orderSourceBreakdown.pos.count,
                    totalA: posTotal,
                    colorA: AppColors.secondary,
                    labelB: 'Online',
                    countB: data.orderSourceBreakdown.onlineOrder.count,
                    totalB: onlineTotal,
                    colorB: const Color(0xFF0EA5E9),
                    ratioA: posPercent,
                  ),
                ),
                Container(
                  width: 1,
                  height: 65,
                  color: const Color(0xFFE2E8F0),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                // Tipe Pesanan
                Expanded(
                  child: _buildProportionSection(
                    title: 'TIPE',
                    labelA: 'Dine-in',
                    countA: data.orderTypeBreakdown.dineIn.count,
                    totalA: dineInTotal,
                    colorA: const Color(0xFF10B981),
                    labelB: 'Takeaway',
                    countB: data.orderTypeBreakdown.takeaway.count,
                    totalB: takeawayTotal,
                    colorB: const Color(0xFFF59E0B),
                    ratioA: dineInPercent,
                  ),
                ),
              ],
            )
          else ...[
            _buildProportionSection(
              title: 'SALURAN PENJUALAN',
              labelA: 'Kasir POS',
              countA: data.orderSourceBreakdown.pos.count,
              totalA: posTotal,
              colorA: AppColors.secondary,
              labelB: 'Online',
              countB: data.orderSourceBreakdown.onlineOrder.count,
              totalB: onlineTotal,
              colorB: const Color(0xFF0EA5E9),
              ratioA: posPercent,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            _buildProportionSection(
              title: 'TIPE PESANAN',
              labelA: 'Dine-in',
              countA: data.orderTypeBreakdown.dineIn.count,
              totalA: dineInTotal,
              colorA: const Color(0xFF10B981),
              labelB: 'Takeaway',
              countB: data.orderTypeBreakdown.takeaway.count,
              totalB: takeawayTotal,
              colorB: const Color(0xFFF59E0B),
              ratioA: dineInPercent,
            ),
          ],

          if (height == null) const SizedBox(height: 10),
          Column(
            children: [
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'POS: ${(posPercent * 100).toInt()}% • Online: ${((1 - posPercent) * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Dine-in: ${(dineInPercent * 100).toInt()}% • Takeaway: ${((1 - dineInPercent) * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
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

  Widget _buildProportionSection({
    required String title,
    required String labelA,
    required int countA,
    required double totalA,
    required Color colorA,
    required String labelB,
    required int countB,
    required double totalB,
    required Color colorB,
    required double ratioA,
  }) {
    final percentA = (ratioA * 100).clamp(0, 100).toInt();
    final percentB = (100 - percentA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                Expanded(
                  flex: percentA > 0 ? percentA : 1,
                  child: Container(
                    color: percentA > 0 ? colorA : const Color(0xFFE2E8F0),
                  ),
                ),
                Expanded(
                  flex: percentB > 0 ? percentB : 1,
                  child: Container(
                    color: percentB > 0 ? colorB : const Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorA,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      labelA,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$countA ($percentA%)',
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorB,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      labelB,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$countB ($percentB%)',
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Live Recent Activity Stream
  // Executive clean stream without clutter
  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // 6. Live Recent Activity Stream (Responsive Data Grid & Mobile Feed)
  // FinTech balanced table layout on tablet/desktop, sleek feed on mobile
  // ---------------------------------------------------------------------------
  Widget _buildRecentActivitySection(
    BuildContext context,
    double availableWidth,
  ) {
    final isDesktop = availableWidth >= 860;
    final isTablet = availableWidth >= 640;

    return Obx(() {
      final list = controller.transactions;
      final displayList = list.take(6).toList();

      return Container(
        padding: const EdgeInsets.all(18),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Aktivitas Transaksi Hari Ini',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fiber_manual_record,
                            size: 6.5,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${list.length} Tercatat',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => controller.switchTab(1),
                  iconAlignment: IconAlignment.end,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                  label: Text(
                    isTablet ? 'Riwayat Lengkap' : 'Semua',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (controller.isLoadingTransactions.value && list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.secondary,
                  ),
                ),
              )
            else if (displayList.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        size: 28,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Belum ada transaksi pada periode ini',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Transaksi yang masuk hari ini akan tampil secara real-time.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              )
            else ...[
              // Unified Table Container (Rounded + Bordered)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Tablet & Desktop Header
                    if (isTablet)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 58,
                              child: Text(
                                'WAKTU',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 3,
                              child: Text(
                                'INVOICE & PELANGGAN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'TIPE PESANAN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (isDesktop)
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'METODE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            const Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  'STATUS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'TOTAL',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),
                      ),

                    // Rows List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayList.length,
                      separatorBuilder: (context, i) =>
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, i) {
                        final tx = displayList[i];
                        final isDineIn = tx.orderType == 'dine_in';

                        return InkWell(
                          hoverColor: const Color(0xFFF8FAFC),
                          onTap: () async {
                            final fullTrx =
                                await controller.fetchTransactionDetail(
                                  tx.id,
                                ) ??
                                tx;
                            if (context.mounted) {
                              AdminTransactionDetailDialog.show(
                                context,
                                transaction: fullTrx,
                                onVoidPressed: () => AdminVoidDialog.show(
                                  context,
                                  transaction: fullTrx,
                                  onConfirmVoid: (reason) => controller
                                      .voidTransaction(fullTrx.id, reason),
                                ),
                              );
                            }
                          },
                          child: isTablet
                              ? _buildTabletRow(tx, isDineIn, isDesktop)
                              : _buildMobileRow(tx, isDineIn),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildTabletRow(
    AdminTransactionModel tx,
    bool isDineIn,
    bool isDesktop,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Row(
        children: [
          // 1. Waktu
          SizedBox(
            width: 58,
            child: Text(
              _formatTime(tx.createdAt),
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 2. Invoice & Pelanggan
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_outlined,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.invoiceNumber,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: tx.isCancelled
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0F172A),
                          decoration: tx.isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${tx.customerName.isNotEmpty ? tx.customerName : "Pelanggan Umum"} • Kasir: ${tx.cashierName}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Tipe Pesanan Pill
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildOrderTypeBadge(tx, isDineIn),
            ),
          ),

          // 4. Metode Pill (Only when isDesktop, otherwise shown under Total)
          if (isDesktop)
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildPaymentMethodBadge(tx.paymentMethod),
              ),
            ),

          // 5. Status Pill
          Expanded(flex: 2, child: Center(child: _buildCleanStatus(tx))),

          // 6. Total
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyFormatter.format(tx.total),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: tx.isCancelled
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0F172A),
                    decoration: tx.isCancelled
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (!isDesktop) ...[
                  const SizedBox(height: 2),
                  Text(
                    tx.paymentMethod.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 7. Chevron
          const SizedBox(
            width: 20,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeBadge(AdminTransactionModel tx, bool isDineIn) {
    final isTable =
        isDineIn && tx.tableNumber != null && tx.tableNumber!.isNotEmpty;
    final label = isTable
        ? 'Meja ${tx.tableNumber}'
        : (isDineIn ? 'Dine-in' : 'Takeaway');
    final icon = isDineIn
        ? Icons.table_restaurant_outlined
        : Icons.shopping_bag_outlined;
    final bg = isDineIn ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);
    final border = isDineIn ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A);
    final textCol = isDineIn
        ? const Color(0xFF047857)
        : const Color(0xFFB45309);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: textCol),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: textCol,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodBadge(String method) {
    final m = method.toLowerCase();
    Color bg = const Color(0xFFF1F5F9);
    Color border = const Color(0xFFE2E8F0);
    Color textCol = const Color(0xFF475569);
    IconData icon = Icons.payments_outlined;

    if (m.contains('cash') || m.contains('tunai')) {
      bg = const Color(0xFFF1F5F9);
      border = const Color(0xFFE2E8F0);
      textCol = const Color(0xFF334155);
      icon = Icons.payments_outlined;
    } else if (m.contains('qris')) {
      bg = const Color(0xFFEEF2FF);
      border = const Color(0xFFC7D2FE);
      textCol = AppColors.secondary;
      icon = Icons.qr_code_2_rounded;
    } else if (m.contains('transfer') || m.contains('bank')) {
      bg = const Color(0xFFF0F9FF);
      border = const Color(0xFFBAE6FD);
      textCol = const Color(0xFF0284C7);
      icon = Icons.account_balance_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: textCol),
          const SizedBox(width: 4),
          Text(
            method.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRow(AdminTransactionModel tx, bool isDineIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.invoiceNumber,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: tx.isCancelled
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF0F172A),
                        decoration: tx.isCancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatTime(tx.createdAt)} • ${tx.customerName.isNotEmpty ? tx.customerName : "Pelanggan Umum"}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
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
                      fontWeight: FontWeight.w700,
                      color: tx.isCancelled
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0F172A),
                      decoration: tx.isCancelled
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _buildCleanStatus(tx),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildOrderTypeBadge(tx, isDineIn),
              const SizedBox(width: 6),
              _buildPaymentMethodBadge(tx.paymentMethod),
              const Spacer(),
              Text(
                'Kasir: ${tx.cashierName}',
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: Color(0xFFCBD5E1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCleanStatus(AdminTransactionModel tx) {
    if (tx.isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.fiber_manual_record, size: 6, color: Color(0xFFDC2626)),
            SizedBox(width: 4),
            Text(
              'Batal',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      );
    }
    if (tx.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.fiber_manual_record, size: 6, color: Color(0xFFD97706)),
            SizedBox(width: 4),
            Text(
              'Open Bill',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD97706),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.fiber_manual_record, size: 6, color: Color(0xFF10B981)),
          SizedBox(width: 4),
          Text(
            'Selesai',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF047857),
            ),
          ),
        ],
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
