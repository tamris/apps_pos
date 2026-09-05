import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';
import '../../../../data/models/admin_open_bill_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/skeletons/list_item_skeleton.dart';
import '../widgets/admin_transaction_detail_dialog.dart';

class AdminOpenBillsTab extends GetView<AdminController> {
  const AdminOpenBillsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // 1. KPI Metrics Header Strip (4 Modern Cards)
          _buildMetricsStrip(),

          // 2. Search & Status Filter Bar (Uniform 40px Height)
          _buildSearchAndFilters(context),

          // 3. Open Bills Grid / List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingOpenBills.value && controller.openBills.isEmpty) {
                return const ListItemSkeleton();
              }

              final displayBills = controller.filteredOpenBills;

              if (displayBills.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: () => controller.fetchOpenBills(),
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
                          mainAxisExtent: 154,
                        ),
                        itemCount: displayBills.length,
                        itemBuilder: (context, i) {
                          final b = displayBills[i];
                          return _buildModernOpenBillCard(context, b);
                        },
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      itemCount: displayBills.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final b = displayBills[i];
                        return _buildModernOpenBillCard(context, b);
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
  // 1. KPI Metrics Strip (4 Executive Metric Cards)
  // ---------------------------------------------------------------------------
  Widget _buildMetricsStrip() {
    return Obx(() {
      final list = controller.openBills;
      final totalActive = controller.openBillsTotalActive.value;
      final totalAmount = controller.openBillsTotalAmount.value;
      final criticalCount = list.where((b) => b.elapsedMinutes >= 60).length;
      final selfOrderCount = list.where((b) => b.isSelfOrder).length;
      final posCount = list.where((b) => !b.isSelfOrder).length;

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
                      label: 'Meja Aktif',
                      value: '$totalActive Meja',
                      subtext: 'Pesanan belum lunas',
                      icon: Icons.table_restaurant_rounded,
                      iconColor: AppColors.secondary,
                      iconBg: const Color(0xFFEEF2FF),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 185,
                      label: 'Tagihan Gantung',
                      value: CurrencyFormatter.format(totalAmount),
                      subtext: 'Potensi kas tertunda',
                      icon: Icons.hourglass_top_rounded,
                      iconColor: const Color(0xFFD97706),
                      iconBg: const Color(0xFFFEF3C7),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 175,
                      label: 'Perlu Perhatian',
                      value: criticalCount > 0 ? '$criticalCount Meja > 60m' : 'Semua < 1 Jam',
                      subtext: criticalCount > 0 ? 'Waktu tunggu lama' : 'Pelayanan prima',
                      icon: criticalCount > 0 ? Icons.alarm_on_rounded : Icons.check_circle_outline_rounded,
                      iconColor: criticalCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                      iconBg: criticalCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 180,
                      label: 'Kanal Pesanan',
                      value: '$selfOrderCount Online • $posCount POS',
                      subtext: 'Komparasi saluran',
                      icon: Icons.devices_rounded,
                      iconColor: const Color(0xFF0EA5E9),
                      iconBg: const Color(0xFFF0F9FF),
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'Meja Aktif',
                    value: '$totalActive Meja',
                    subtext: 'Pesanan belum lunas',
                    icon: Icons.table_restaurant_rounded,
                    iconColor: AppColors.secondary,
                    iconBg: const Color(0xFFEEF2FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Tagihan Gantung',
                    value: CurrencyFormatter.format(totalAmount),
                    subtext: 'Potensi kas tertunda',
                    icon: Icons.hourglass_top_rounded,
                    iconColor: const Color(0xFFD97706),
                    iconBg: const Color(0xFFFEF3C7),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Perlu Perhatian',
                    value: criticalCount > 0 ? '$criticalCount Meja > 60m' : 'Semua < 1 Jam',
                    subtext: criticalCount > 0 ? 'Waktu tunggu lama' : 'Pelayanan prima',
                    icon: criticalCount > 0 ? Icons.alarm_on_rounded : Icons.check_circle_outline_rounded,
                    iconColor: criticalCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                    iconBg: criticalCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Kanal Pesanan',
                    value: '$selfOrderCount Online • $posCount POS',
                    subtext: 'Komparasi saluran',
                    icon: Icons.devices_rounded,
                    iconColor: const Color(0xFF0EA5E9),
                    iconBg: const Color(0xFFF0F9FF),
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
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: _buildSearchTextField(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildRefreshActionBtn(),
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
              // Row 1: Search Field + Refresh Action Button
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: _buildSearchTextField(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildRefreshActionBtn(),
                ],
              ),
              const SizedBox(height: 10),
              // Row 2: Status Filter Chips + Reset Button
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
      controller: controller.openBillSearchController,
      textInputAction: TextInputAction.search,
      onChanged: (val) => controller.openBillSearchQuery.value = val,
      onSubmitted: (_) => controller.fetchOpenBills(),
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: 'Cari nomor meja, nama tamu, invoice, atau kasir...',
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
        suffixIcon: Obx(() {
          if (controller.openBillSearchQuery.value.isNotEmpty) {
            return IconButton(
              icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
              onPressed: () {
                controller.openBillSearchController.clear();
                controller.openBillSearchQuery.value = '';
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

  Widget _buildRefreshActionBtn() {
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
        onPressed: () => controller.fetchOpenBills(),
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Segarkan', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFilterChipsRow() {
    return Obx(() {
      final list = controller.openBills;
      final criticalCount = list.where((b) => b.elapsedMinutes >= 60).length;
      final freshCount = list.where((b) => b.elapsedMinutes < 30).length;
      final isFilterActive = controller.selectedOpenBillFilter.value != 'all' ||
          controller.openBillSearchQuery.value.isNotEmpty;

      return Row(
        children: [
          _buildFilterChip('Semua Meja', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Perlu Perhatian (> 60m)',
            'critical',
            dotColor: const Color(0xFFDC2626),
            badgeCount: criticalCount,
            badgeColor: const Color(0xFFDC2626),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Baru Dipesan (< 30m)',
            'fresh',
            dotColor: const Color(0xFF10B981),
            badgeCount: freshCount,
            badgeColor: const Color(0xFF059669),
          ),
          const SizedBox(width: 8),
          _buildFilterChip('Online (Self-Order)', 'self_order', dotColor: AppColors.secondary),
          const SizedBox(width: 8),
          _buildFilterChip('Kasir POS', 'pos', dotColor: const Color(0xFF64748B)),
          if (isFilterActive) ...[
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                controller.selectedOpenBillFilter.value = 'all';
                controller.openBillSearchQuery.value = '';
                controller.openBillSearchController.clear();
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
      final isSelected = controller.selectedOpenBillFilter.value == value;

      return Material(
        color: isSelected ? AppColors.secondarySoft : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            controller.selectedOpenBillFilter.value = value;
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

  // ---------------------------------------------------------------------------
  // 3. Modern Open Bill Card (Restaurant Table Format)
  // ---------------------------------------------------------------------------
  Widget _buildModernOpenBillCard(BuildContext context, AdminOpenBillModel b) {
    final bool isCritical = b.elapsedMinutes >= 60;
    final bool isFresh = b.elapsedMinutes < 30;

    Color timerBg = const Color(0xFFF0FDF4);
    Color timerBorder = const Color(0xFFBBF7D0);
    Color timerText = const Color(0xFF15803D);
    IconData timerIcon = Icons.access_time_rounded;

    if (isCritical) {
      timerBg = const Color(0xFFFEF2F2);
      timerBorder = const Color(0xFFFECACA);
      timerText = const Color(0xFFB91C1C);
      timerIcon = Icons.alarm_on_rounded;
    } else if (!isFresh) {
      timerBg = const Color(0xFFFFFBEB);
      timerBorder = const Color(0xFFFDE68A);
      timerText = const Color(0xFFB45309);
      timerIcon = Icons.hourglass_bottom_rounded;
    }

    final initials = b.customerName.isNotEmpty
        ? b.customerName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'TM';

    final bool hasTable = b.tableNumber.isNotEmpty && b.tableNumber != '-';
    final String tableLabel = hasTable
        ? 'MEJA ${b.tableNumber.toUpperCase()}'
        : (b.isSelfOrder ? 'ONLINE (TANPA MEJA)' : 'PESANAN LANGSUNG');

    final String timeDisplay = b.formattedTime != null && b.formattedTime!.isNotEmpty && b.formattedTime != '-'
        ? '${b.formattedTime} • ${b.elapsedMinutes > 0 ? '${b.elapsedMinutes}m' : 'Baru'}'
        : (b.elapsedMinutes > 0 ? '${b.elapsedMinutes} mnt' : 'Baru');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
          width: isCritical ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCritical
                ? const Color(0xFFDC2626).withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: isCritical ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final detail = await controller.fetchTransactionDetail(b.id);
            if (detail != null && context.mounted) {
              AdminTransactionDetailDialog.show(context, transaction: detail);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Table Capsule & Elapsed Timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Table Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasTable
                                ? Icons.table_restaurant_rounded
                                : (b.isSelfOrder ? Icons.phonelink_ring_rounded : Icons.takeout_dining_rounded),
                            size: 13,
                            color: const Color(0xFF334155),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            tableLabel,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Order Channel & Timer Badge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: b.isSelfOrder ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: b.isSelfOrder ? const Color(0xFFC7D2FE) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            b.isSelfOrder ? 'Online' : 'POS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: b.isSelfOrder ? AppColors.secondary : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: timerBg,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: timerBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(timerIcon, size: 10.5, color: timerText),
                              const SizedBox(width: 3),
                              Text(
                                timeDisplay,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: timerText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Middle Info: Customer & Cashier
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12.5,
                      backgroundColor: const Color(0xFFEEF2FF),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.customerName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            '${b.invoiceNumber} • Kasir: ${b.cashierName}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Item Preview Banner (Fills whitespace with valuable menu details)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 11.5,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          (b.itemsSummary != null && b.itemsSummary!.isNotEmpty)
                              ? b.itemsSummary!
                              : '${b.itemsCount} Menu dipesan',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Row: Items count, Status Pill & Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${b.itemsCount} Menu',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (b.isSelfOrder && b.isPaid) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Text(
                              b.status == 'ready'
                                  ? 'Siap'
                                  : (b.status == 'processing' ? 'Dimasak' : 'Lunas QRIS'),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyFormatter.format(b.total),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
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

  // ---------------------------------------------------------------------------
  // Empty State (Zero Open Bills / Search Not Found)
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    final hasSearchOrFilter = controller.openBillSearchQuery.value.isNotEmpty ||
        controller.selectedOpenBillFilter.value != 'all';

    if (hasSearchOrFilter) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 26,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Tidak Ada Meja Ditemukan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tidak ada tagihan meja yang cocok dengan filter atau kata kunci pencarian Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () {
                  controller.openBillSearchQuery.value = '';
                  controller.openBillSearchController.clear();
                  controller.selectedOpenBillFilter.value = 'all';
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                label: const Text('Reset Filter Meja', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 32,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Semua Meja Telah Lunas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tidak ada tagihan meja aktif (open bill) yang belum diselesaikan saat ini.\nSemua pesanan tamu telah selesai dibayar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () => controller.fetchOpenBills(),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Perbarui Data Meja', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
