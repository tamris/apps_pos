import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/skeletons/list_item_skeleton.dart';
import '../widgets/dashboard/dashboard_kpi_section.dart';
import '../widgets/dashboard/dashboard_shift_ledger_card.dart';
import '../widgets/dashboard/dashboard_payment_distribution_card.dart';
import '../widgets/dashboard/dashboard_operations_watchlist_card.dart';
import '../widgets/dashboard/dashboard_channel_distribution_card.dart';
import '../widgets/dashboard/dashboard_menu_sales_shortcut_card.dart';
import '../widgets/dashboard/dashboard_recent_activity_section.dart';

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
                DashboardKpiSection(
                  summary: summary,
                  availableWidth: availableWidth,
                ),
                const SizedBox(height: 16),

                // 3. Operational Cards (2 columns on wide, stacked on narrow)
                if (isWide) ...[
                  // Row 1: Shift Kasir Aktif & Rincian Pembayaran
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DashboardShiftLedgerCard(
                          data: data,
                          height: 215,
                          onAuditShift: () => controller.switchTab(3),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardPaymentDistributionCard(
                          data: data,
                          totalRevenue: summary.totalRevenue,
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
                        child: DashboardOperationsWatchlistCard(
                          data: data,
                          height: 215,
                          onOpenBillsTap: () {
                            controller.selectedActiveOrderMode.value = 'tables';
                            controller.switchTab(4);
                          },
                          onCancellationsTap: () {
                            controller.selectedTrxStatus.value = 'cancelled';
                            controller.switchTab(1);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardChannelDistributionCard(
                          data: data,
                          isTablet: true,
                          height: 215,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Stacked full-width cards on mobile / narrow view
                  DashboardShiftLedgerCard(
                    data: data,
                    onAuditShift: () => controller.switchTab(3),
                  ),
                  const SizedBox(height: 14),
                  DashboardPaymentDistributionCard(
                    data: data,
                    totalRevenue: summary.totalRevenue,
                  ),
                  const SizedBox(height: 14),
                  DashboardOperationsWatchlistCard(
                    data: data,
                    onOpenBillsTap: () {
                      controller.selectedActiveOrderMode.value = 'tables';
                      controller.switchTab(4);
                    },
                    onCancellationsTap: () {
                      controller.selectedTrxStatus.value = 'cancelled';
                      controller.switchTab(1);
                    },
                  ),
                  const SizedBox(height: 14),
                  DashboardChannelDistributionCard(
                    data: data,
                    isTablet: false,
                  ),
                ],
                const SizedBox(height: 16),

                // 4. Menu Sales Spotlight Card
                Obx(
                  () => DashboardMenuSalesShortcutCard(
                    summary: controller.menuSalesSummary.value,
                    onViewMenu: () => controller.switchTab(2),
                  ),
                ),
                const SizedBox(height: 18),

                // 5. Live Recent Activity Stream
                DashboardRecentActivitySection(availableWidth: availableWidth),
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

  String _formatDateLabel(String dtStr) {
    if (dtStr.isEmpty) return 'Hari Ini';
    try {
      final dt = DateTime.parse(dtStr);
      return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return dtStr;
    }
  }
}
