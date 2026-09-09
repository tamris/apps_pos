import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import '../common/admin_date_range_dialog.dart';

class CashFlowFilterBar extends StatelessWidget {
  final AdminController controller;
  final VoidCallback onAddExpensePressed;
  final VoidCallback onManageCategoriesPressed;

  const CashFlowFilterBar({
    super.key,
    required this.controller,
    required this.onAddExpensePressed,
    required this.onManageCategoriesPressed,
  });

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
          final width = constraints.maxWidth;
          final isMobile = width < 680;

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Search Bar
                SizedBox(
                  height: 40,
                  child: _buildSearchTextField(),
                ),
                const SizedBox(height: 8),

                // 2. Date + Search Action Button Row
                Row(
                  children: [
                    Expanded(child: _buildDateSelectorBtn(context)),
                    const SizedBox(width: 8),
                    _buildSearchActionBtn(),
                  ],
                ),
                const SizedBox(height: 8),

                // 3. Add Expense Action Button (Full Width on mobile)
                SizedBox(
                  width: double.infinity,
                  child: _buildAddExpenseBtn(),
                ),
                const SizedBox(height: 10),

                // 4. Row 2 Filters: Type Chips + Category Dropdown + Source Dropdown + Reset Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: _buildFilterRowSejajar(),
                ),
              ],
            );
          }

          // Tablet & Desktop Layout (width >= 680)
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Search Field + Date Filter + Search Button + Catat Beban Toko
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: _buildSearchTextField(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildDateSelectorBtn(context),
                  const SizedBox(width: 8),
                  _buildSearchActionBtn(),
                  const SizedBox(width: 8),
                  _buildAddExpenseBtn(),
                ],
              ),
              const SizedBox(height: 10),

              // Row 2: Type Chips sejajar dengan Dropdown Kategori & Dropdown Sumber Dana + Reset Filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: _buildFilterRowSejajar(),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // ROW 1: SEARCH TEXT FIELD
  // ==========================================
  Widget _buildSearchTextField() {
    return TextField(
      controller: controller.cashFlowSearchController,
      textInputAction: TextInputAction.search,
      onChanged: (val) => controller.cashFlowSearchQuery.value = val,
      onSubmitted: (_) {
        controller.fetchCashFlow();
        controller.fetchCashFlowSummary();
      },
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: 'Cari no. arus kas, catatan pengeluaran, kategori...',
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
        suffixIcon: Obx(() {
          if (controller.cashFlowSearchQuery.value.isNotEmpty) {
            return IconButton(
              icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
              onPressed: () {
                controller.cashFlowSearchController.clear();
                controller.cashFlowSearchQuery.value = '';
                controller.fetchCashFlow();
                controller.fetchCashFlowSummary();
              },
            );
          }
          return const SizedBox.shrink();
        }),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
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

  // ==========================================
  // ROW 1: SEARCH ACTION BUTTON
  // ==========================================
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
        onPressed: () {
          controller.fetchCashFlow();
          controller.fetchCashFlowSummary();
        },
        icon: const Icon(Icons.search_rounded, size: 16),
        label: const Text(
          'Cari',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ==========================================
  // ROW 1: DATE RANGE SELECTOR BUTTON
  // ==========================================
  Widget _buildDateSelectorBtn(BuildContext context) {
    return Obx(() {
      final period = controller.selectedCashFlowPeriod.value;
      final start = controller.cashFlowCustomStartDate.value;
      final end = controller.cashFlowCustomEndDate.value;
      final now = DateTime.now();
      final isDateChanged = period != 'month';

      String displayLabel = 'Bulan Ini';
      if (period == 'today') {
        displayLabel = 'Hari Ini';
      } else if (period == 'custom' && start != null) {
        final isToday = start.year == now.year && start.month == now.month && start.day == now.day;
        final yesterday = now.subtract(const Duration(days: 1));
        final isYesterday = start.year == yesterday.year &&
            start.month == yesterday.month &&
            start.day == yesterday.day;

        if (end == null ||
            (start.year == end.year && start.month == end.month && start.day == end.day)) {
          if (isToday) {
            displayLabel = 'Hari Ini';
          } else if (isYesterday) {
            displayLabel = 'Kemarin';
          } else {
            displayLabel = DateFormat('dd MMM yyyy').format(start);
          }
        } else {
          displayLabel =
              '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
        }
      }

      return SizedBox(
        height: 40,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: isDateChanged ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
            side: BorderSide(
              color: isDateChanged ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            foregroundColor: isDateChanged ? AppColors.secondary : const Color(0xFF475569),
          ),
          onPressed: () => _pickDateRange(context),
          icon: Icon(
            Icons.calendar_today_rounded,
            size: 15,
            color: isDateChanged ? AppColors.secondary : const Color(0xFF64748B),
          ),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isDateChanged ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (isDateChanged) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => controller.resetCashFlowDateToDefault(),
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

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    DateTime initialStart = controller.cashFlowCustomStartDate.value ??
        DateTime(now.year, now.month, 1);
    DateTime initialEnd = controller.cashFlowCustomEndDate.value ?? now;
    if (controller.selectedCashFlowPeriod.value == 'today') {
      initialStart = now;
      initialEnd = now;
    } else if (controller.selectedCashFlowPeriod.value == 'month') {
      initialStart = DateTime(now.year, now.month, 1);
      initialEnd = now;
    }

    final picked = await AdminDateRangeDialog.show(
      context,
      initialStartDate: initialStart,
      initialEndDate: initialEnd,
      title: 'Rentang Tanggal Arus Kas',
      subtitle: 'Pilih rentang tanggal untuk audit arus kas & beban toko',
    );

    if (picked != null) {
      controller.changeCashFlowPeriod(
        'custom',
        customStart: picked.start,
        customEnd: picked.end,
      );
    }
  }

  // ==========================================
  // ROW 1: ADD EXPENSE ACTION BUTTON
  // ==========================================
  Widget _buildAddExpenseBtn() {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        icon: const Icon(Icons.add_circle_outline_rounded, size: 17),
        label: const Text(
          'Catat Beban Toko',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
        onPressed: onAddExpensePressed,
      ),
    );
  }

  // ==========================================
  // ROW 2: SEJAJAR (TIPE CHIPS + KATEGORI + SUMBER + RESET)
  // ==========================================
  Widget _buildFilterRowSejajar() {
    return Obx(() {
      final selectedType = controller.selectedCashFlowType.value;
      final selectedSource = controller.selectedCashFlowSource.value;
      final selectedCategory = controller.selectedCashFlowCategoryId.value;
      final period = controller.selectedCashFlowPeriod.value;
      final query = controller.cashFlowSearchQuery.value;

      final isFilterActive = selectedType != 'all' ||
          selectedSource != 'all' ||
          selectedCategory != null ||
          period != 'month' ||
          query.isNotEmpty;

      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Tipe Transaksi Chips
          _buildFilterSectionLabel('TIPE:'),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: 'Semua',
            isSelected: selectedType == 'all',
            onTap: () {
              controller.selectedCashFlowType.value = 'all';
              controller.fetchCashFlow();
            },
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: 'Kas Masuk',
            isSelected: selectedType == 'in',
            dotColor: const Color(0xFF10B981),
            activeBgColor: const Color(0xFFECFDF5),
            activeBorderColor: const Color(0xFF10B981),
            activeTextColor: const Color(0xFF047857),
            onTap: () {
              controller.selectedCashFlowType.value = 'in';
              controller.fetchCashFlow();
            },
          ),
          const SizedBox(width: 6),
          _buildFilterChip(
            label: 'Kas Keluar',
            isSelected: selectedType == 'out',
            dotColor: const Color(0xFFEF4444),
            activeBgColor: const Color(0xFFFEF2F2),
            activeBorderColor: const Color(0xFFEF4444),
            activeTextColor: const Color(0xFFB91C1C),
            onTap: () {
              controller.selectedCashFlowType.value = 'out';
              controller.fetchCashFlow();
            },
          ),

          // Divider Pemisah
          const SizedBox(width: 10),
          const SizedBox(
            height: 18,
            child: VerticalDivider(color: Color(0xFFCBD5E1), width: 1),
          ),
          const SizedBox(width: 10),

          // 2. Dropdown Kategori (Sejajar tinggi 32px)
          _buildCategoryDropdown(),

          const SizedBox(width: 8),

          // 3. Dropdown Sumber Dana (Sejajar tinggi 32px)
          _buildSourceDropdown(),

          // 4. Tombol Reset Filter
          if (isFilterActive) ...[
            const SizedBox(width: 10),
            _buildResetFilterBtn(),
          ],
        ],
      );
    });
  }

  // ==========================================
  // ROW 2: CATEGORY DROPDOWN (HEIGHT: 32PX)
  // ==========================================
  Widget _buildCategoryDropdown() {
    return Obx(() {
      final selectedCatId = controller.selectedCashFlowCategoryId.value;
      final categories = controller.adminExpenseCategories;
      final isSelected = selectedCatId != null;

      String getLabel() {
        if (selectedCatId == null) return 'Kategori: Semua';
        final match = categories.firstWhereOrNull((c) => c.id == selectedCatId);
        return match != null ? 'Kategori: ${match.name}' : 'Kategori: Semua';
      }

      return SizedBox(
        height: 32,
        child: PopupMenuButton<int>(
          tooltip: 'Pilih Kategori Beban / Arus Kas',
          offset: const Offset(0, 36),
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          onSelected: (val) {
            if (val == -999) {
              onManageCategoriesPressed();
            } else if (val == -1) {
              controller.setCashFlowCategory(null);
            } else {
              controller.setCashFlowCategory(val);
            }
          },
          itemBuilder: (context) => [
            _buildCategoryMenuItem(-1, 'Semua Kategori', isSelected: selectedCatId == null),
            ...categories.map((cat) => _buildCategoryMenuItem(
                  cat.id,
                  cat.name,
                  isSelected: selectedCatId == cat.id,
                )),
            const PopupMenuDivider(height: 1),
            PopupMenuItem<int>(
              value: -999,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Row(
                children: [
                  Icon(Icons.tune_rounded, size: 15, color: AppColors.secondary),
                  SizedBox(width: 8),
                  Text(
                    'Kelola Master Kategori...',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0),
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
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => controller.setCashFlowCategory(null),
                    borderRadius: BorderRadius.circular(8),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
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

  // ==========================================
  // ROW 2: SOURCE DROPDOWN (HEIGHT: 32PX)
  // ==========================================
  Widget _buildSourceDropdown() {
    return Obx(() {
      final selectedSource = controller.selectedCashFlowSource.value;
      final isSelected = selectedSource != 'all';

      String getLabel() {
        switch (selectedSource) {
          case 'bank':
            return 'Sumber: Non-Tunai';
          case 'cash':
            return 'Sumber: Tunai';
          default:
            return 'Sumber: Semua';
        }
      }

      IconData getIcon() {
        switch (selectedSource) {
          case 'bank':
            return Icons.account_balance_rounded;
          case 'cash':
            return Icons.payments_rounded;
          default:
            return Icons.account_balance_wallet_outlined;
        }
      }

      return SizedBox(
        height: 32,
        child: PopupMenuButton<String>(
          tooltip: 'Pilih Sumber Dana',
          offset: const Offset(0, 36),
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          onSelected: (val) {
            controller.selectedCashFlowSource.value = val;
            controller.fetchCashFlow();
          },
          itemBuilder: (context) => [
            _buildSourceMenuItem('all', 'Semua Sumber', isSelected: selectedSource == 'all'),
            _buildSourceMenuItem(
              'cash',
              'Tunai (Cash)',
              icon: Icons.payments_rounded,
              isSelected: selectedSource == 'cash',
            ),
            _buildSourceMenuItem(
              'bank',
              'Non-Tunai (Bank)',
              icon: Icons.account_balance_rounded,
              isSelected: selectedSource == 'bank',
            ),
          ],
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  getIcon(),
                  size: 13,
                  color: isSelected ? AppColors.secondary : const Color(0xFF64748B),
                ),
                const SizedBox(width: 5),
                Text(
                  getLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.secondary : const Color(0xFF475569),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      controller.selectedCashFlowSource.value = 'all';
                      controller.fetchCashFlow();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 13,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: isSelected ? AppColors.secondary : const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  PopupMenuItem<String> _buildSourceMenuItem(
    String value,
    String label, {
    IconData? icon,
    required bool isSelected,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.secondary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.secondary : const Color(0xFF1E293B),
              ),
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

  // ==========================================
  // ROW 2: FILTER CHIPS & RESET
  // ==========================================
  Widget _buildFilterSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? dotColor,
    Color? activeBgColor,
    Color? activeBorderColor,
    Color? activeTextColor,
  }) {
    Color bg = const Color(0xFFF1F5F9);
    Color border = const Color(0xFFE2E8F0);
    Color text = const Color(0xFF475569);

    if (isSelected) {
      bg = activeBgColor ?? AppColors.secondarySoft;
      border = activeBorderColor ?? AppColors.secondaryLight.withValues(alpha: 0.5);
      text = activeTextColor ?? AppColors.secondary;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
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
                  color: text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetFilterBtn() {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => controller.clearCashFlowFilters(),
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
            Icon(
              Icons.restart_alt_rounded,
              size: 13,
              color: Color(0xFFE11D48),
            ),
            SizedBox(width: 4),
            Text(
              'Reset Filter',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE11D48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
