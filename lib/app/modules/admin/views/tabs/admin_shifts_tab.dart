import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_controller.dart';
import '../../../../data/models/admin_shift_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/skeletons/list_item_skeleton.dart';
import '../widgets/admin_shift_detail_dialog.dart';

class AdminShiftsTab extends GetView<AdminController> {
  const AdminShiftsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // 1. KPI Metrics Summary Strip
          _buildMetricsStrip(),

          // 2. Search & Filter Bar (Clean Modern)
          _buildSearchAndFilters(context),

          // 3. Shifts Responsive Grid / List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingShifts.value && controller.shifts.isEmpty) {
                return const ListItemSkeleton();
              }

              final displayShifts = controller.filteredShifts;

              if (displayShifts.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: () => controller.fetchShifts(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isDesktop = width >= 1150;
                    final isTablet = width >= 650;

                    if (isTablet) {
                      final crossAxisCount = isDesktop ? 3 : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 184,
                        ),
                        itemCount: displayShifts.length,
                        itemBuilder: (context, i) {
                          final s = displayShifts[i];
                          return _buildModernShiftCard(context, s);
                        },
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      itemCount: displayShifts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final s = displayShifts[i];
                        return _buildModernShiftCard(context, s);
                      },
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Quick KPI Metrics Strip
  // ---------------------------------------------------------------------------
  Widget _buildMetricsStrip() {
    return Obx(() {
      final list = controller.shifts;
      final totalShifts = list.length;
      final activeShifts = list.where((s) => s.isOpen).length;
      final totalCashierSales = list.fold<double>(0.0, (sum, s) => sum + s.totalSales);
      final discrepancyCount = list.where((s) => !s.isOpen && (s.isShortage || s.isOverage)).length;

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
                      label: 'Total Shift',
                      value: '$totalShifts Sesi',
                      subtext: 'Rekaman audit kasir',
                      icon: Icons.assignment_rounded,
                      iconColor: AppColors.secondary,
                      iconBg: const Color(0xFFEEF2FF),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 185,
                      label: 'Total Omzet Kasir',
                      value: CurrencyFormatter.format(totalCashierSales),
                      subtext: 'Akumulasi penjualan',
                      icon: Icons.payments_rounded,
                      iconColor: const Color(0xFF10B981),
                      iconBg: const Color(0xFFECFDF5),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 170,
                      label: 'Shift Aktif',
                      value: '$activeShifts Kasir',
                      subtext: activeShifts > 0 ? 'Laci kasir buka' : 'Tidak ada shift aktif',
                      icon: Icons.storefront_rounded,
                      iconColor: const Color(0xFF0EA5E9),
                      iconBg: const Color(0xFFF0F9FF),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 180,
                      label: 'Audit Arus Kas',
                      value: discrepancyCount > 0 ? '$discrepancyCount Ada Selisih' : 'Kas 100% Pas',
                      subtext: discrepancyCount > 0 ? 'Periksa selisih fisik' : 'Semua laci sesuai',
                      icon: discrepancyCount > 0 ? Icons.warning_amber_rounded : Icons.verified_rounded,
                      iconColor: discrepancyCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                      iconBg: discrepancyCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'Total Shift',
                    value: '$totalShifts Sesi',
                    subtext: 'Rekaman audit kasir',
                    icon: Icons.assignment_rounded,
                    iconColor: AppColors.secondary,
                    iconBg: const Color(0xFFEEF2FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Total Omzet Kasir',
                    value: CurrencyFormatter.format(totalCashierSales),
                    subtext: 'Akumulasi penjualan',
                    icon: Icons.payments_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFECFDF5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Shift Aktif',
                    value: '$activeShifts Kasir',
                    subtext: activeShifts > 0 ? 'Laci kasir buka' : 'Tidak ada shift aktif',
                    icon: Icons.storefront_rounded,
                    iconColor: const Color(0xFF0EA5E9),
                    iconBg: const Color(0xFFF0F9FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Audit Arus Kas',
                    value: discrepancyCount > 0 ? '$discrepancyCount Ada Selisih' : 'Kas 100% Pas',
                    subtext: discrepancyCount > 0 ? 'Periksa selisih fisik' : 'Semua laci sesuai',
                    icon: discrepancyCount > 0 ? Icons.warning_amber_rounded : Icons.verified_rounded,
                    iconColor: discrepancyCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                    iconBg: discrepancyCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
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
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtext,
                  style: const TextStyle(
                    fontSize: 9.5,
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

  // ---------------------------------------------------------------------------
  // 2. Search & Filter Bar
  // ---------------------------------------------------------------------------
  Widget _buildSearchAndFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 40,
                  child: _buildSearchTextField(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildDateFilterBtn(context)),
                    const SizedBox(width: 8),
                    _buildSearchActionBtn(),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildFilterChipsRow(),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Search Field + Date Filter Button + Search Action Button
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: _buildSearchTextField(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildDateFilterBtn(context),
                  const SizedBox(width: 8),
                  _buildSearchActionBtn(),
                ],
              ),
              const SizedBox(height: 10),
              // Row 2: Status Filter Chips + Reset
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildFilterChipsRow(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchTextField() {
    return TextField(
      controller: controller.shiftSearchController,
      textInputAction: TextInputAction.search,
      onChanged: (val) => controller.shiftSearchQuery.value = val,
      onSubmitted: (_) => controller.fetchShifts(),
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: 'Cari nama kasir, email, atau ID shift...',
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
        suffixIcon: Obx(() {
          if (controller.shiftSearchQuery.value.isNotEmpty) {
            return IconButton(
              icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
              onPressed: () {
                controller.shiftSearchController.clear();
                controller.shiftSearchQuery.value = '';
              },
            );
          }
          return const SizedBox.shrink();
        }),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        fillColor: const Color(0xFFF8FAFC),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.2),
        ),
      ),
    );
  }

  Widget _buildSearchActionBtn() {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: () => controller.fetchShifts(),
        icon: const Icon(Icons.search_rounded, size: 16),
        label: const Text('Cari', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFilterChipsRow() {
    return Obx(() {
      final list = controller.shifts;
      final discrepancyCount = list.where((s) => !s.isOpen && (s.isShortage || s.isOverage)).length;
      final isFilterActive = controller.selectedShiftStatus.value != 'all' ||
          controller.selectedShiftDate.value != null ||
          controller.shiftSearchQuery.value.isNotEmpty;

      return Row(
        children: [
          _buildFilterChip('Semua Shift', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Aktif Berjalan', 'open', dotColor: const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _buildFilterChip('Kas Pas', 'balanced', dotColor: const Color(0xFF059669)),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Ada Selisih',
            'discrepancy',
            badgeCount: discrepancyCount,
            badgeColor: const Color(0xFFDC2626),
          ),
          if (isFilterActive) ...[
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                controller.selectedShiftStatus.value = 'all';
                controller.selectedShiftDate.value = null;
                controller.shiftSearchQuery.value = '';
                controller.shiftSearchController.clear();
                controller.fetchShifts();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restart_alt_rounded, size: 13, color: Color(0xFFE11D48)),
                    SizedBox(width: 4),
                    Text(
                      'Reset Filter',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE11D48)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildFilterChip(
    String label,
    String value, {
    Color? dotColor,
    int? badgeCount,
    Color? badgeColor,
  }) {
    return Obx(() {
      final isSelected = controller.selectedShiftStatus.value == value;

      return Material(
        color: isSelected ? AppColors.secondarySoft : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            controller.selectedShiftStatus.value = value;
            controller.fetchShifts();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.secondaryLight.withValues(alpha: 0.5)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null && (badgeCount == null || badgeCount == 0)) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.secondary : const Color(0xFF475569),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: badgeColor ?? const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDateFilterBtn(BuildContext context) {
    return Obx(() {
      final date = controller.selectedShiftDate.value;
      final isDateActive = date != null && date.isNotEmpty;

      String displayLabel = 'Filter Tanggal';
      if (isDateActive) {
        try {
          final dt = DateTime.parse(date);
          final now = DateTime.now();
          if (DateFormat('yyyy-MM-dd').format(dt) == DateFormat('yyyy-MM-dd').format(now)) {
            displayLabel = 'Hari Ini';
          } else {
            displayLabel = DateFormat('dd MMM yyyy').format(dt);
          }
        } catch (_) {
          displayLabel = date;
        }
      }

      return SizedBox(
        height: 40,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: isDateActive ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
            side: BorderSide(
              color: isDateActive ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            foregroundColor: isDateActive ? AppColors.secondary : const Color(0xFF475569),
          ),
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2024),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              initialEntryMode: DatePickerEntryMode.calendarOnly,
              helpText: 'PILIH TANGGAL AUDIT SHIFT',
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
                      headerHeadlineStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      headerHelpStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: Color(0xFFC7D2FE),
                      ),
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      dayStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      todayBorder: const BorderSide(
                        color: AppColors.secondary,
                        width: 1.5,
                      ),
                      todayForegroundColor: WidgetStateProperty.all(
                        AppColors.secondary,
                      ),
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: const Size(360, 700),
                    ),
                    child: child!,
                  ),
                );
              },
            );
            if (picked != null) {
              controller.selectedShiftDate.value = DateFormat('yyyy-MM-dd').format(picked);
              controller.fetchShifts();
            }
          },
          icon: Icon(
            Icons.calendar_today_rounded,
            size: 15,
            color: isDateActive ? AppColors.secondary : const Color(0xFF64748B),
          ),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isDateActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (isDateActive) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    controller.selectedShiftDate.value = null;
                    controller.fetchShifts();
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // 3. Modern Shift Card (Ledger Format)
  // ---------------------------------------------------------------------------
  Widget _buildModernShiftCard(BuildContext context, AdminShiftModel s) {
    final startTimeStr = _formatTime(s.startTime);
    final endTimeStr = s.isOpen ? 'Sekarang' : _formatTime(s.endTime);
    final durationStr = _computeDuration(s.startTime, s.endTime, s.isOpen);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: s.isOpen
              ? AppColors.secondary.withValues(alpha: 0.35)
              : (s.isShortage ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: s.isOpen
                ? AppColors.secondary.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final detail = await controller.fetchShiftDetail(s.id);
            if (detail != null && context.mounted) {
              AdminShiftDetailDialog.show(context, shift: detail);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Cashier Profile & Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: s.isOpen ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        s.cashierName.isNotEmpty ? s.cashierName[0].toUpperCase() : 'K',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: s.isOpen ? AppColors.secondary : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  s.cashierName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${s.id}',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 11,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 3.5),
                              Flexible(
                                child: Text(
                                  '${_formatDate(s.startTime)} • $startTimeStr - $endTimeStr ${durationStr.isNotEmpty ? "($durationStr)" : ""}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildDiscrepancyBadge(s),
                  ],
                ),

                const SizedBox(height: 8),

                // Financial Ledger Box (3 Metrics: Modal Awal, Penjualan, Kas Fisik)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      // Modal Awal
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MODAL AWAL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(s.startingCash),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                      const SizedBox(width: 8),

                      // Total Penjualan
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL OMZET',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(s.totalSales),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                      const SizedBox(width: 8),

                      // Uang Fisik Laci
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KAS FISIK LACI',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                s.actualCash != null
                                    ? CurrencyFormatter.format(s.actualCash)
                                    : (s.isOpen ? 'Sedang Jalan' : '-'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: s.actualCash != null
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Bottom Row: Volume Struk & Z-Report Action Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_long_rounded,
                            size: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${s.totalTransactions} Transaksi',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Detail Z-Report',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscrepancyBadge(AdminShiftModel s) {
    if (s.isOpen) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.fiber_manual_record, size: 6, color: AppColors.secondary),
            SizedBox(width: 4),
            Text(
              'Aktif',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      );
    }

    if (s.isShortage) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_downward_rounded, size: 10, color: Color(0xFFDC2626)),
            const SizedBox(width: 2),
            Text(
              'Minus ${CurrencyFormatter.format(s.difference?.abs() ?? 0)}',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      );
    }

    if (s.isOverage) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_upward_rounded, size: 10, color: Color(0xFFD97706)),
            const SizedBox(width: 2),
            Text(
              'Lebih ${CurrencyFormatter.format(s.difference ?? 0)}',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD97706),
              ),
            ),
          ],
        ),
      );
    }

    // Balanced / Pas
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_rounded, size: 11, color: Color(0xFF047857)),
          SizedBox(width: 3),
          Text(
            'Kas Pas (Rp 0)',
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

  // ---------------------------------------------------------------------------
  // Empty State
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.assignment_late_outlined,
                size: 28,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Belum Ada Riwayat Shift',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tidak ada rekaman audit shift kasir yang cocok dengan filter yang dipilih.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.secondary,
                elevation: 0,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              ),
              onPressed: () {
                controller.selectedShiftStatus.value = 'all';
                controller.selectedShiftDate.value = null;
                controller.shiftSearchController.clear();
                controller.shiftSearchQuery.value = '';
                controller.fetchShifts();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Reset Filter',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  String _computeDuration(String? startStr, String? endStr, bool isOpen) {
    if (startStr == null || startStr.isEmpty) return '';
    try {
      final start = DateTime.parse(startStr).toLocal();
      final end = (endStr != null && endStr.isNotEmpty)
          ? DateTime.parse(endStr).toLocal()
          : (isOpen ? DateTime.now() : null);
      if (end == null) return '';
      final diff = end.difference(start);
      if (diff.isNegative) return '';
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (hours > 0) {
        return '${hours}j ${minutes}m';
      }
      return '${minutes}m';
    } catch (_) {
      return '';
    }
  }


  String _formatDate(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dtStr).toLocal();
      return DateFormat('d MMM').format(dt);
    } catch (_) {
      return dtStr;
    }
  }

  String _formatTime(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return 'Aktif';
    try {
      final dt = DateTime.parse(dtStr).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return dtStr;
    }
  }
}
