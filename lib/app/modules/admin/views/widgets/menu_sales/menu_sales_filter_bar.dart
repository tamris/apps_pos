import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class MenuSalesFilterBar extends GetView<AdminController> {
  const MenuSalesFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
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
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 18,
          color: Color(0xFF94A3B8),
        ),
        suffixIcon: Obx(() {
          if (controller.menuSearchQuery.value.isNotEmpty) {
            return IconButton(
              icon: const Icon(
                Icons.clear_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: () => controller.fetchMenuSales(),
        icon: const Icon(Icons.search_rounded, size: 16),
        label: const Text(
          'Cari',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
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
            displayLabel =
                '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM').format(end)}';
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
            backgroundColor: isFiltered
                ? const Color(0xFFEEF2FF)
                : const Color(0xFFF8FAFC),
            side: BorderSide(
              color: isFiltered
                  ? const Color(0xFF818CF8)
                  : const Color(0xFFE2E8F0),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            foregroundColor:
                isFiltered ? AppColors.secondary : const Color(0xFF475569),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt_off_rounded,
                      size: 12,
                      color: Color(0xFFE11D48),
                    ),
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
                  const SizedBox(width: 4),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5.5,
                      vertical: 1,
                    ),
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
    final start = controller.menuCustomStartDate.value ??
        now.subtract(const Duration(days: 30));
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
      controller.changeMenuPeriod('custom',
          start: picked.start, end: picked.end);
    }
  }
}
