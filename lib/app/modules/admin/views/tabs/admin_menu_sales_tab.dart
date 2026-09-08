import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_controller.dart';
import '../../../../data/models/admin_menu_sales_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../widgets/admin_menu_sales_detail_dialog.dart';

class AdminMenuSalesTab extends GetView<AdminController> {
  const AdminMenuSalesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // 1. KPI Metrics Summary Strip (Harmonized with AdminTransactionsTab)
          _buildMetricsStrip(),

          // 2. Search & Filter Bar (Harmonized with AdminTransactionsTab)
          _buildSearchAndFilters(context),

          // 3. Menu Sales Responsive Grid / List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingMenuSales.value && controller.menuSalesItems.isEmpty) {
                return _buildMenuSalesSkeleton();
              }

              final displayItems = controller.filteredMenuSalesItems;

              if (displayItems.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: () async {
                  await controller.fetchMenuSales(refresh: true);
                  await controller.fetchMenuCategories();
                },
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
                          mainAxisExtent: 148,
                        ),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          return _buildModernMenuCard(context, item);
                        },
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      itemCount: displayItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = displayItems[index];
                        return _buildModernMenuCard(context, item);
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
      final summary = controller.menuSalesSummary.value;
      final topCategory = controller.menuSalesCategories.isNotEmpty
          ? controller.menuSalesCategories.first
          : null;

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
                      width: 175,
                      label: 'Total Porsi Terjual',
                      value: '${summary.totalQuantitySold} Porsi',
                      subtext: 'Akumulasi porsi terjual',
                      icon: Icons.restaurant_menu_rounded,
                      iconColor: const Color(0xFF4F46E5),
                      iconBg: const Color(0xFFEEF2FF),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 195,
                      label: 'Menu Terlaris #1',
                      value: summary.topSellingProduct?.name ?? '-',
                      subtext: summary.topSellingProduct != null
                          ? '${summary.topSellingProduct!.quantitySold} porsi terjual'
                          : 'Belum ada data',
                      icon: Icons.emoji_events_rounded,
                      iconColor: const Color(0xFFD97706),
                      iconBg: const Color(0xFFFEF3C7),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 175,
                      label: 'Varian Menu Aktif',
                      value: '${summary.totalUniqueItemsSold} Menu',
                      subtext: 'Varian menu aktif terjual',
                      icon: Icons.fastfood_rounded,
                      iconColor: const Color(0xFF0284C7),
                      iconBg: const Color(0xFFF0F9FF),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 190,
                      label: 'Kategori Terfavorit',
                      value: topCategory != null ? topCategory.categoryName : '-',
                      subtext: topCategory != null
                          ? '${topCategory.revenueSharePercentage}% kontribusi'
                          : 'Belum ada data',
                      icon: Icons.category_rounded,
                      iconColor: const Color(0xFF059669),
                      iconBg: const Color(0xFFECFDF5),
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'Total Porsi Terjual',
                    value: '${summary.totalQuantitySold} Porsi',
                    subtext: 'Akumulasi porsi terjual',
                    icon: Icons.restaurant_menu_rounded,
                    iconColor: const Color(0xFF4F46E5),
                    iconBg: const Color(0xFFEEF2FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Menu Terlaris #1',
                    value: summary.topSellingProduct?.name ?? '-',
                    subtext: summary.topSellingProduct != null
                        ? '${summary.topSellingProduct!.quantitySold} porsi terjual'
                        : 'Belum ada data',
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFFD97706),
                    iconBg: const Color(0xFFFEF3C7),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Varian Menu Aktif',
                    value: '${summary.totalUniqueItemsSold} Menu',
                    subtext: 'Varian menu aktif terjual',
                    icon: Icons.fastfood_rounded,
                    iconColor: const Color(0xFF0284C7),
                    iconBg: const Color(0xFFF0F9FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Kategori Terfavorit',
                    value: topCategory != null ? topCategory.categoryName : '-',
                    subtext: topCategory != null
                        ? '${topCategory.revenueSharePercentage}% kontribusi'
                        : 'Belum ada data',
                    icon: Icons.category_rounded,
                    iconColor: const Color(0xFF059669),
                    iconBg: const Color(0xFFECFDF5),
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
  // 2. Search & Filters Bar (Matching AdminTransactionsTab & AdminShiftsTab)
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
              // Row 1: Search Field + Date Range Filter Button + Search Action Button
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
              // Row 2: Period Pills, Sort Dropdown & Category Filters
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
      controller: controller.menuSearchController,
      textInputAction: TextInputAction.search,
      onChanged: (val) => controller.menuSearchQuery.value = val,
      onSubmitted: (_) => controller.fetchMenuSales(),
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: 'Cari nama menu, SKU, atau kategori...',
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
        suffixIcon: Obx(() {
          if (controller.menuSearchQuery.value.isNotEmpty) {
            return IconButton(
              icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
              onPressed: () {
                controller.menuSearchController.clear();
                controller.menuSearchQuery.value = '';
                controller.fetchMenuSales();
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
        onPressed: () => controller.fetchMenuSales(),
        icon: const Icon(Icons.search_rounded, size: 16),
        label: const Text('Cari', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildDateSelectorBtn(BuildContext context) {
    return Obx(() {
      final period = controller.selectedMenuPeriod.value;
      final isFiltered = period != 'this_month';

      String displayLabel = 'Bulan Ini';
      if (period == 'today') {
        displayLabel = 'Hari Ini';
      } else if (period == 'yesterday') {
        displayLabel = 'Kemarin';
      } else if (period == 'this_week') {
        displayLabel = 'Minggu Ini';
      } else if (period == 'last_month') {
        displayLabel = 'Bulan Lalu';
      } else if (period == 'this_year') {
        displayLabel = 'Tahun Ini';
      } else if (period == 'custom') {
        final start = controller.menuCustomStartDate.value;
        final end = controller.menuCustomEndDate.value;
        if (start != null) {
          if (end != null && start != end) {
            displayLabel = '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM').format(end)}';
          } else {
            displayLabel = DateFormat('d MMM yyyy').format(start);
          }
        } else {
          displayLabel = 'Kustom';
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
          onPressed: () => _pickDateRange(context),
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
                    controller.changeMenuPeriod('this_month');
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
      final period = controller.selectedMenuPeriod.value;
      final selectedCat = controller.selectedMenuCategoryId.value;
      final isFilterActive = period != 'this_month' ||
          selectedCat != null ||
          controller.menuSearchQuery.value.isNotEmpty;

      final categories = controller.menuSalesCategories;

      const palette = [
        Color(0xFF4F46E5), // Indigo
        Color(0xFF059669), // Emerald
        Color(0xFFD97706), // Amber
        Color(0xFF0284C7), // Sky
        Color(0xFF7C3AED), // Purple
        Color(0xFFE11D48), // Rose
      ];

      return Row(
        children: [
          // 1. Period Filter Pills
          _buildFilterChip(
            label: 'Hari Ini',
            isSelected: period == 'today',
            onTap: () => controller.changeMenuPeriod('today'),
          ),
          _buildFilterChip(
            label: 'Kemarin',
            isSelected: period == 'yesterday',
            onTap: () => controller.changeMenuPeriod('yesterday'),
          ),
          _buildFilterChip(
            label: 'Minggu Ini',
            isSelected: period == 'this_week',
            onTap: () => controller.changeMenuPeriod('this_week'),
          ),
          _buildFilterChip(
            label: 'Bulan Ini',
            isSelected: period == 'this_month',
            onTap: () => controller.changeMenuPeriod('this_month'),
          ),
          _buildFilterChip(
            label: 'Bulan Lalu',
            isSelected: period == 'last_month',
            onTap: () => controller.changeMenuPeriod('last_month'),
          ),
          _buildFilterChip(
            label: 'Tahun Ini',
            isSelected: period == 'this_year',
            onTap: () => controller.changeMenuPeriod('this_year'),
          ),

          const SizedBox(width: 8),
          Container(height: 18, width: 1, color: const Color(0xFFCBD5E1)),
          const SizedBox(width: 8),

          // 2. Category Filter Chips
          _buildFilterChip(
            label: 'Semua Kategori',
            isSelected: selectedCat == null,
            onTap: () => controller.setMenuCategory(null),
          ),
          ...categories.asMap().entries.map((entry) {
            final idx = entry.key;
            final cat = entry.value;
            final color = palette[idx % palette.length];
            final isCatSelected = selectedCat == cat.categoryId;

            return _buildFilterChip(
              label: '${cat.categoryName} (${cat.revenueSharePercentage}%)',
              dotColor: color,
              isSelected: isCatSelected,
              activeBgColor: const Color(0xFFEEF2FF),
              activeBorderColor: const Color(0xFF818CF8),
              activeTextColor: const Color(0xFF4F46E5),
              onTap: () => controller.setMenuCategory(cat.categoryId),
            );
          }),

          // 3. Reset Filter Action
          if (isFilterActive) ...[
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => controller.clearMenuFilters(),
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
                    Icon(Icons.filter_alt_off_rounded, size: 12, color: Color(0xFFE11D48)),
                    SizedBox(width: 4),
                    Text(
                      'Reset Filter',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE11D48),
                      ),
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
    IconData? icon,
    Color? dotColor,
    int? badgeCount,
    Color? badgeColor,
    required bool isSelected,
    Color? activeBgColor,
    Color? activeBorderColor,
    Color? activeTextColor,
    Color? idleBgColor,
    Color? idleBorderColor,
    Color? idleTextColor,
    bool glow = false,
    required VoidCallback onTap,
  }) {
    Color bg = const Color(0xFFF8FAFC);
    Color border = const Color(0xFFE2E8F0);
    Color text = const Color(0xFF64748B);
    List<BoxShadow>? shadow;

    if (isSelected) {
      bg = activeBgColor ?? const Color(0xFFEEF2FF);
      border = activeBorderColor ?? const Color(0xFF818CF8);
      text = activeTextColor ?? const Color(0xFF4F46E5);
      if (glow) {
        final shadowColor = activeBorderColor ?? const Color(0xFF818CF8);
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

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final start = controller.menuCustomStartDate.value ?? now.subtract(const Duration(days: 30));
    final end = controller.menuCustomEndDate.value ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: start, end: end),
      helpText: 'PILIH RENTANG TANGGAL PENJUALAN',
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
      controller.changeMenuPeriod(
        'custom',
        start: picked.start,
        end: picked.end,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Modern Menu Item Card (Matching AdminTransactionsTab & AdminShiftsTab)
  // ---------------------------------------------------------------------------
  Widget _buildModernMenuCard(BuildContext context, AdminMenuSalesItemModel item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
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
          onTap: () => AdminMenuSalesDetailDialog.show(context, item.productId),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 11.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Rank Tag + Category + Sales Share Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildRankBadge(item.rank),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                item.categoryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildShareBadge(item.salesSharePercentage),
                  ],
                ),

                // Middle Row: Thumbnail + Product Name + Unit Price & SKU
                Row(
                  children: [
                    _buildProductThumbnail(item.imageUrl),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${CurrencyFormatter.format(item.unitPrice)} • SKU: ${item.sku.isNotEmpty ? item.sku : '-'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bottom Row: Sales Volume & Popularity Progress Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  item.rank <= 3
                                      ? Icons.local_fire_department_rounded
                                      : Icons.restaurant_menu_rounded,
                                  size: 13.5,
                                  color: item.rank == 1
                                      ? const Color(0xFFD97706)
                                      : item.rank <= 3
                                          ? const Color(0xFFEA580C)
                                          : const Color(0xFF4F46E5),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${item.quantitySold} Porsi Terjual',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${item.transactionsCount}x Pesanan',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: (item.salesSharePercentage / 100).clamp(0.02, 1.0),
                          minHeight: 3.5,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            item.rank == 1
                                ? const Color(0xFFD97706)
                                : item.rank <= 3
                                    ? const Color(0xFF6366F1)
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
        ),
      ),
    );
  }

  Widget _buildProductThumbnail(String? imageUrl) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: AppCachedImage(
        imageUrl: imageUrl,
        width: 42,
        height: 42,
        borderRadius: 7,
        placeholderIcon: Icons.restaurant_menu_rounded,
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bg;
    Color border;
    Color text;

    if (rank == 1) {
      bg = const Color(0xFFFEF3C7);
      border = const Color(0xFFFDE68A);
      text = const Color(0xFFB45309);
    } else if (rank == 2) {
      bg = const Color(0xFFF1F5F9);
      border = const Color(0xFFE2E8F0);
      text = const Color(0xFF475569);
    } else if (rank == 3) {
      bg = const Color(0xFFFFF7ED);
      border = const Color(0xFFFFEDD5);
      text = const Color(0xFFC2410C);
    } else {
      bg = const Color(0xFFF8FAFC);
      border = const Color(0xFFE2E8F0);
      text = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: text,
        ),
      ),
    );
  }

  Widget _buildShareBadge(num share) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Text(
        '$share% Pangsa',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4338CA),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Empty State (Matching other tabs)
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              size: 28,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tidak ada data penjualan menu',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Coba ubah filter rentang tanggal atau kata kunci pencarian.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () => controller.clearMenuFilters(),
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Reset Filter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Responsive Shimmer Skeleton (Matching Modern Menu Card Structure)
  // ---------------------------------------------------------------------------
  Widget _buildMenuSalesSkeleton() {
    return AppShimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= 1100;
          final isTablet = width >= 650;

          if (isTablet) {
            final crossAxisCount = isDesktop ? 3 : 2;
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 148,
              ),
              itemCount: 6,
              itemBuilder: (_, __) => _buildSkeletonCard(),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => _buildSkeletonCard(),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  ShimmerBox(width: 38, height: 18, borderRadius: 6),
                  SizedBox(width: 6),
                  ShimmerBox(width: 60, height: 18, borderRadius: 5),
                ],
              ),
              const ShimmerBox(width: 70, height: 18, borderRadius: 6),
            ],
          ),
          Row(
            children: [
              const ShimmerBox(width: 42, height: 42, borderRadius: 8),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 120, height: 13, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 160, height: 11, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    ShimmerBox(width: 90, height: 12, borderRadius: 4),
                    ShimmerBox(width: 60, height: 12, borderRadius: 4),
                  ],
                ),
                const SizedBox(height: 5),
                const ShimmerBox(width: double.infinity, height: 3.5, borderRadius: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
