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

class AdminTransactionsTab extends GetView<AdminController> {
  const AdminTransactionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // 1. KPI Metrics Summary Strip
          _buildMetricsStrip(),

          // 2. Search & Filter Bar (Clean Modern Elevated)
          _buildSearchAndFilters(context),

          // 3. Transactions Responsive Grid / List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingTransactions.value && controller.transactions.isEmpty) {
                return const ListItemSkeleton();
              }

              if (controller.transactions.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: () => controller.fetchTransactions(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isDesktop = width >= 1100;
                    final isTablet = width >= 650;

                    if (isTablet) {
                      final crossAxisCount = isDesktop ? 3 : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 152,
                        ),
                        itemCount: controller.transactions.length,
                        itemBuilder: (context, index) {
                          final tx = controller.transactions[index];
                          return _buildModernCard(context, tx);
                        },
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      itemCount: controller.transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tx = controller.transactions[index];
                        return _buildModernCard(context, tx);
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
      final list = controller.transactions;
      final totalTrx = list.length;
      final completedTrx = list.where((t) => t.isCompleted).toList();
      double totalRevenue = 0.0;
      double totalProfit = 0.0;
      for (final t in completedTrx) {
        totalRevenue += t.total;
        totalProfit += (t.profit ?? 0.0);
      }
      final aov = completedTrx.isNotEmpty ? totalRevenue / completedTrx.length : 0.0;
      final profitMargin = totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;

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
                      subtext: '${profitMargin.toStringAsFixed(1)}% margin profit',
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
                    subtext: 'Record termuat',
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
                    subtext: '${completedTrx.length} transaksi valid',
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
                    subtext: '${profitMargin.toStringAsFixed(1)}% margin profit',
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
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
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
  // 2. Search & Filters Bar
  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // 2. Search & Filters Bar (Matching AdminShiftsTab style with Glowing Badges)
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
                    Expanded(child: _buildDateSelectorBtn(context)),
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
                  _buildDateSelectorBtn(context),
                  const SizedBox(width: 8),
                  _buildSearchActionBtn(),
                ],
              ),
              const SizedBox(height: 10),
              // Row 2: Status, Channel & Payment Filter Chips
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
      controller: controller.trxSearchController,
      textInputAction: TextInputAction.search,
      onChanged: (val) => controller.trxSearchQuery.value = val,
      onSubmitted: (_) => controller.fetchTransactions(),
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: 'Cari no. invoice, kasir, meja, pelanggan...',
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
        suffixIcon: Obx(() {
          if (controller.trxSearchQuery.value.isNotEmpty) {
            return IconButton(
              icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
              onPressed: () {
                controller.trxSearchController.clear();
                controller.trxSearchQuery.value = '';
                controller.fetchTransactions();
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
        onPressed: () => controller.fetchTransactions(),
        icon: const Icon(Icons.search_rounded, size: 16),
        label: const Text('Cari', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildDateSelectorBtn(BuildContext context) {
    return Obx(() {
      final dateStr = controller.selectedTrxDate.value;
      final isFiltered = dateStr != null && dateStr.isNotEmpty;

      String displayLabel = 'Filter Tanggal';
      if (isFiltered) {
        try {
          final dt = DateTime.parse(dateStr);
          final now = DateTime.now();
          if (DateFormat('yyyy-MM-dd').format(dt) == DateFormat('yyyy-MM-dd').format(now)) {
            displayLabel = 'Hari Ini';
          } else {
            displayLabel = DateFormat('dd MMM yyyy').format(dt);
          }
        } catch (_) {
          displayLabel = dateStr;
        }
      }

      return SizedBox(
        height: 40,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: isFiltered ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
            side: BorderSide(color: isFiltered ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            foregroundColor: isFiltered ? AppColors.secondary : const Color(0xFF475569),
          ),
          onPressed: () => _pickDate(context),
          icon: Icon(
            Icons.calendar_today_rounded,
            size: 15,
            color: isFiltered ? AppColors.secondary : const Color(0xFF64748B),
          ),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isFiltered ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (isFiltered) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () {
                    controller.selectedTrxDate.value = null;
                    controller.fetchTransactions();
                  },
                  borderRadius: BorderRadius.circular(10),
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

  Widget _buildFilterChipsRow() {
    return Obx(() {
      final isFilterActive = controller.selectedTrxStatus.value != 'all' ||
          controller.selectedTrxOrderSource.value != 'all' ||
          controller.selectedTrxPaymentMethod.value != 'all' ||
          controller.selectedTrxDate.value != null ||
          controller.trxSearchQuery.value.isNotEmpty;

      // Calculate totals for Open Bill and Batal (Void)
      int openBillsCount = controller.openBills.length;
      if (openBillsCount == 0 && controller.dashboardData.value.openBillsSummary.count > 0) {
        openBillsCount = controller.dashboardData.value.openBillsSummary.count;
      }
      final int trxOpenCount = controller.transactions.where((t) => t.isPending).length;
      if (trxOpenCount > openBillsCount) {
        openBillsCount = trxOpenCount;
      }

      int voidCount = controller.dashboardData.value.cancellationsSummary.count;
      final int trxVoidCount = controller.transactions.where((t) => t.isCancelled).length;
      if (trxVoidCount > voidCount) {
        voidCount = trxVoidCount;
      }

      final isPendingSelected = controller.selectedTrxStatus.value == 'pending';
      final isCancelledSelected = controller.selectedTrxStatus.value == 'cancelled';

      return Row(
        children: [
          // 1. Status Filter Pills
          _buildFilterChip(
            label: 'Semua Status',
            isSelected: controller.selectedTrxStatus.value == 'all',
            onTap: () {
              controller.selectedTrxStatus.value = 'all';
              controller.fetchTransactions();
            },
          ),
          _buildFilterChip(
            label: 'Selesai',
            dotColor: const Color(0xFF10B981),
            isSelected: controller.selectedTrxStatus.value == 'completed',
            activeBgColor: const Color(0xFFECFDF5),
            activeBorderColor: const Color(0xFF10B981),
            activeTextColor: const Color(0xFF047857),
            onTap: () {
              controller.selectedTrxStatus.value = 'completed';
              controller.fetchTransactions();
            },
          ),

          // Open Bill (Vibrant Glowing Amber with Total)
          _buildFilterChip(
            label: 'Open Bill',
            dotColor: const Color(0xFFF59E0B),
            badgeCount: openBillsCount,
            badgeColor: const Color(0xFFD97706),
            isSelected: isPendingSelected,
            activeBgColor: const Color(0xFFFEF3C7),
            activeBorderColor: const Color(0xFFF59E0B),
            activeTextColor: const Color(0xFFB45309),
            idleBgColor: openBillsCount > 0 ? const Color(0xFFFFFBEB) : null,
            idleBorderColor: openBillsCount > 0 ? const Color(0xFFFDE68A) : null,
            idleTextColor: openBillsCount > 0 ? const Color(0xFF92400E) : null,
            glow: openBillsCount > 0 || isPendingSelected,
            onTap: () {
              controller.selectedTrxStatus.value = 'pending';
              controller.fetchTransactions();
            },
          ),

          // Batal (Void) (Vibrant Glowing Rose/Red with Total)
          _buildFilterChip(
            label: 'Batal (Void)',
            dotColor: const Color(0xFFEF4444),
            badgeCount: voidCount,
            badgeColor: const Color(0xFFE11D48),
            isSelected: isCancelledSelected,
            activeBgColor: const Color(0xFFFFE4E6),
            activeBorderColor: const Color(0xFFF43F5E),
            activeTextColor: const Color(0xFF9F1239),
            idleBgColor: voidCount > 0 ? const Color(0xFFFFF1F2) : null,
            idleBorderColor: voidCount > 0 ? const Color(0xFFFECDD3) : null,
            idleTextColor: voidCount > 0 ? const Color(0xFFBE123C) : null,
            glow: voidCount > 0 || isCancelledSelected,
            onTap: () {
              controller.selectedTrxStatus.value = 'cancelled';
              controller.fetchTransactions();
            },
          ),

          const SizedBox(width: 8),
          Container(height: 18, width: 1, color: const Color(0xFFCBD5E1)),
          const SizedBox(width: 8),

          // 2. Channel Filters
          _buildFilterChip(
            label: 'Semua Saluran',
            isSelected: controller.selectedTrxOrderSource.value == 'all',
            onTap: () {
              controller.selectedTrxOrderSource.value = 'all';
              controller.fetchTransactions();
            },
          ),
          _buildFilterChip(
            label: 'Kasir POS',
            icon: Icons.point_of_sale_rounded,
            isSelected: controller.selectedTrxOrderSource.value == 'pos',
            onTap: () {
              controller.selectedTrxOrderSource.value = 'pos';
              controller.fetchTransactions();
            },
          ),
          _buildFilterChip(
            label: 'Online (Self-Order)',
            icon: Icons.phone_android_rounded,
            isSelected: controller.selectedTrxOrderSource.value == 'self_order',
            onTap: () {
              controller.selectedTrxOrderSource.value = 'self_order';
              controller.fetchTransactions();
            },
          ),

          const SizedBox(width: 8),
          Container(height: 18, width: 1, color: const Color(0xFFCBD5E1)),
          const SizedBox(width: 8),

          // 3. Payment Method Filter
          _buildPaymentDropdown(),

          // 4. Reset Filter Action
          if (isFilterActive) ...[
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                controller.selectedTrxStatus.value = 'all';
                controller.selectedTrxOrderSource.value = 'all';
                controller.selectedTrxPaymentMethod.value = 'all';
                controller.selectedTrxDate.value = null;
                controller.trxSearchQuery.value = '';
                controller.trxSearchController.clear();
                controller.fetchTransactions();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(8),
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? dotColor,
    IconData? icon,
    int? badgeCount,
    Color? badgeColor,
    Color? activeBgColor,
    Color? activeBorderColor,
    Color? activeTextColor,
    Color? idleBgColor,
    Color? idleBorderColor,
    Color? idleTextColor,
    bool glow = false,
  }) {
    Color bg = const Color(0xFFF1F5F9);
    Color border = const Color(0xFFE2E8F0);
    Color text = const Color(0xFF475569);
    List<BoxShadow>? shadow;

    if (isSelected) {
      bg = activeBgColor ?? AppColors.secondarySoft;
      border = activeBorderColor ?? AppColors.secondaryLight.withValues(alpha: 0.5);
      text = activeTextColor ?? AppColors.secondary;
      if (glow) {
        final shadowColor = activeBorderColor ?? AppColors.secondary;
        shadow = [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      }
    } else if (idleBgColor != null) {
      bg = idleBgColor;
      border = idleBorderColor ?? border;
      text = idleTextColor ?? text;
      if (glow && idleBorderColor != null) {
        shadow = [
          BoxShadow(
            color: idleBorderColor.withValues(alpha: 0.2),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ];
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border, width: isSelected ? 1.2 : 1.0),
              boxShadow: shadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                if (icon != null) ...[
                  Icon(icon, size: 13, color: text),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: text,
                  ),
                ),
                if (badgeCount != null && badgeCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1),
                    decoration: BoxDecoration(
                      color: badgeColor ?? const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDropdown() {
    return Obx(() {
      final method = controller.selectedTrxPaymentMethod.value;
      final isSelected = method != 'all';

      return Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.secondaryLight.withValues(alpha: 0.5)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: method,
            icon: Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: isSelected ? AppColors.secondary : const Color(0xFF64748B),
            ),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.secondary : const Color(0xFF475569),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Metode: Semua')),
              DropdownMenuItem(value: 'cash', child: Text('Metode: Tunai')),
              DropdownMenuItem(value: 'qris', child: Text('Metode: QRIS')),
              DropdownMenuItem(value: 'transfer', child: Text('Metode: Transfer')),
            ],
            onChanged: (val) {
              if (val != null) {
                controller.selectedTrxPaymentMethod.value = val;
                controller.fetchTransactions();
              }
            },
          ),
        ),
      );
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    DateTime initial = now;
    if (controller.selectedTrxDate.value != null) {
      try {
        initial = DateTime.parse(controller.selectedTrxDate.value!);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'PILIH TANGGAL TRANSAKSI',
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
      controller.selectedTrxDate.value = DateFormat('yyyy-MM-dd').format(picked);
      controller.fetchTransactions();
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Modern Transaction Card
  // ---------------------------------------------------------------------------
  Widget _buildModernCard(BuildContext context, AdminTransactionModel tx) {
    final isDineIn = tx.orderType == 'dine_in';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tx.isCancelled ? const Color(0xFFFEE2E2) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final fullTrx = await controller.fetchTransactionDetail(tx.id) ?? tx;
            if (context.mounted) {
              AdminTransactionDetailDialog.show(
                context,
                transaction: fullTrx,
                onVoidPressed: () => _openVoidDialog(context, fullTrx),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top: Invoice + Status Badge + Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Invoice Number
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Icon(Icons.receipt_outlined, size: 12, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  tx.invoiceNumber,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: tx.isCancelled ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                    decoration: tx.isCancelled ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Badge
                        _buildStatusBadge(tx),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Customer Name & Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 13, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  tx.customerName.isNotEmpty ? tx.customerName : 'Pelanggan Umum',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 3),
                            Text(
                              _formatTime(tx.createdAt),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Order Tags Row (Dine-in / Meja, Channel, Payment)
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        // Dine-in vs Takeaway
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDineIn ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            isDineIn
                                ? (tx.tableNumber != null && tx.tableNumber!.isNotEmpty ? 'Meja ${tx.tableNumber}' : 'Dine-in')
                                : 'Takeaway',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDineIn ? const Color(0xFF047857) : const Color(0xFFB45309),
                            ),
                          ),
                        ),

                        // Channel (POS vs Online)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tx.isSelfOrder ? const Color(0xFFF0F9FF) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            tx.isSelfOrder ? 'Online Order' : 'Kasir POS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: tx.isSelfOrder ? const Color(0xFF0284C7) : const Color(0xFF475569),
                            ),
                          ),
                        ),

                        // Payment Method
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            tx.paymentMethod.toUpperCase(),
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Bottom Row: Kasir & Total Amount & Action
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 8, thickness: 0.8, color: Color(0xFFF1F5F9)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Kasir Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.isSelfOrder ? 'Online (Self-Order)' : 'Kasir: ${tx.cashierName}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                CurrencyFormatter.format(tx.total),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: tx.isCancelled ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                  decoration: tx.isCancelled ? TextDecoration.lineThrough : null,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Action Buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!tx.isCancelled)
                              Material(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(6),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => _openVoidDialog(context, tx),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                    child: const Text(
                                      'Void',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFE11D48)),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Detail',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF64748B)),
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildStatusBadge(AdminTransactionModel tx) {
    if (tx.isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel, size: 10, color: Color(0xFFDC2626)),
            SizedBox(width: 3.5),
            Text(
              'Batal (Void)',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
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
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pending, size: 10, color: Color(0xFFD97706)),
            SizedBox(width: 3.5),
            Text(
              'Open Bill',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF059669)),
          SizedBox(width: 3.5),
          Text(
            'Selesai',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
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
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 44, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tidak Ada Transaksi',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tidak ditemukan transaksi yang cocok dengan kriteria pencarian dan filter.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () {
                controller.selectedTrxStatus.value = 'all';
                controller.selectedTrxOrderSource.value = 'all';
                controller.selectedTrxPaymentMethod.value = 'all';
                controller.selectedTrxDate.value = null;
                controller.trxSearchQuery.value = '';
                controller.trxSearchController.clear();
                controller.fetchTransactions();
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset Filter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _openVoidDialog(BuildContext context, AdminTransactionModel tx) {
    AdminVoidDialog.show(
      context,
      transaction: tx,
      onConfirmVoid: (reason) => controller.voidTransaction(tx.id, reason),
    );
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
