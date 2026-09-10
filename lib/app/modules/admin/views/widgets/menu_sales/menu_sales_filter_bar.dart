import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import '../common/admin_date_range_dialog.dart';

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
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCategoryDropdown(),
                    _buildResetButton(),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              // 1. Search Field
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: _buildSearchTextField(),
                ),
              ),
              const SizedBox(width: 10),
              // 2. Date Range Filter
              _buildDateSelectorBtn(context),
              const SizedBox(width: 8),
              // 3. Category Dropdown
              _buildCategoryDropdown(),
              // 4. Reset Action
              _buildResetButton(),
              const SizedBox(width: 8),
              // 5. Search Button
              _buildSearchActionBtn(),
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
      onChanged: controller.onMenuSearchChanged,
      onSubmitted: (_) => controller.submitMenuSearch(),
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
          if (controller.hasMenuSearch.value) {
            return IconButton(
              icon: const Icon(
                Icons.clear_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
              onPressed: controller.clearMenuSearch,
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
        onPressed: controller.submitMenuSearch,
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

  Widget _buildResetButton() {
    return Obx(() {
      final period = controller.selectedMenuPeriod.value;
      final selectedCat = controller.selectedMenuCategoryId.value;
      final isFilterActive = period != 'this_month' ||
          selectedCat != null ||
          controller.menuSearchQuery.value.isNotEmpty;

      if (!isFilterActive) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: SizedBox(
          height: 40,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => controller.clearMenuFilters(),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restart_alt_rounded,
                    size: 14,
                    color: Color(0xFFE11D48),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Reset Filter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE11D48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCategoryDropdown() {
    return Obx(() {
      final selectedCatId = controller.selectedMenuCategoryId.value;
      final categories = controller.menuSalesCategories;
      final isSelected = selectedCatId != null;

      String getLabel() {
        if (selectedCatId == null) return 'Kategori: Semua';
        final match = categories.firstWhereOrNull((c) => c.categoryId == selectedCatId);
        return match != null ? 'Kategori: ${match.categoryName}' : 'Kategori: Semua';
      }

      return SizedBox(
        height: 40,
        child: PopupMenuButton<int>(
          tooltip: 'Pilih Kategori Menu',
          offset: const Offset(0, 44),
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          onSelected: (val) {
            controller.setMenuCategory(val == -1 ? null : val);
          },
          itemBuilder: (context) => [
            _buildCategoryMenuItem(-1, 'Semua Kategori', isSelected: selectedCatId == null),
            ...categories.map((cat) => _buildCategoryMenuItem(
                  cat.categoryId ?? 0,
                  cat.categoryName,
                  isSelected: selectedCatId == cat.categoryId,
                )),
          ],
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF818CF8)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.secondary : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isSelected ? AppColors.secondary : const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  PopupMenuItem<int> _buildCategoryMenuItem(
    int value,
    String label, {
    required bool isSelected,
  }) {
    return PopupMenuItem<int>(
      value: value,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.secondary : const Color(0xFF1E293B),
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_rounded,
              size: 15,
              color: AppColors.secondary,
            ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final start = controller.menuCustomStartDate.value ??
        now.subtract(const Duration(days: 30));
    final end = controller.menuCustomEndDate.value ?? now;

    final picked = await AdminDateRangeDialog.show(
      context,
      initialStartDate: start,
      initialEndDate: end,
    );

    if (picked != null) {
      controller.changeMenuPeriod(
        'custom',
        start: picked.start,
        end: picked.end,
      );
    }
  }
}
