import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class TransactionsFilterBar extends GetView<AdminController> {
  const TransactionsFilterBar({super.key});

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
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 18,
          color: Color(0xFF94A3B8),
        ),
        suffixIcon: Obx(() {
          if (controller.trxSearchQuery.value.isNotEmpty) {
            return IconButton(
              icon: const Icon(
                Icons.clear_rounded,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: () => controller.fetchTransactions(),
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
      final dateStr = controller.selectedTrxDate.value;
      final isFiltered = dateStr != null && dateStr.isNotEmpty;

      String displayLabel = 'Filter Tanggal';
      if (isFiltered) {
        try {
          final dt = DateTime.parse(dateStr);
          final now = DateTime.now();
          if (DateFormat('yyyy-MM-dd').format(dt) ==
              DateFormat('yyyy-MM-dd').format(now)) {
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

      // Calculate totals for Open Bill (Khusus meja kasir POS) and Batal (Void)
      int openBillsCount =
          controller.openBills.where((b) => !b.isSelfOrder).length;
      if (openBillsCount == 0 &&
          controller.dashboardData.value.openBillsSummary.count > 0) {
        openBillsCount = controller.dashboardData.value.openBillsSummary.count;
      }
      final int trxOpenCount = controller.transactions
          .where((t) => t.isPending && !t.isSelfOrder)
          .length;
      if (trxOpenCount > openBillsCount) {
        openBillsCount = trxOpenCount;
      }

      int voidCount = controller.dashboardData.value.cancellationsSummary.count;
      final int trxVoidCount =
          controller.transactions.where((t) => t.isCancelled).length;
      if (trxVoidCount > voidCount) {
        voidCount = trxVoidCount;
      }

      final isPendingSelected = controller.selectedTrxStatus.value == 'pending';
      final isCancelledSelected =
          controller.selectedTrxStatus.value == 'cancelled';

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
            idleBorderColor:
                openBillsCount > 0 ? const Color(0xFFFDE68A) : null,
            idleTextColor: openBillsCount > 0 ? const Color(0xFF92400E) : null,
            glow: openBillsCount > 0 || isPendingSelected,
            onTap: () {
              controller.selectedTrxStatus.value = 'pending';
              if (controller.selectedTrxOrderSource.value == 'self_order') {
                controller.selectedTrxOrderSource.value = 'all';
              }
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
              if (controller.selectedTrxStatus.value == 'pending') {
                controller.selectedTrxStatus.value = 'all';
              }
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
                      Icons.restart_alt_rounded,
                      size: 13,
                      color: Color(0xFFE11D48),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Reset Filter',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
      border =
          activeBorderColor ?? AppColors.secondaryLight.withValues(alpha: 0.5);
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
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: text,
                  ),
                ),
                if (badgeCount != null && badgeCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: badgeColor ?? AppColors.secondary,
                      borderRadius: BorderRadius.circular(10),
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
          color:
              isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
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
              DropdownMenuItem(
                  value: 'transfer', child: Text('Metode: Transfer')),
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
      controller.selectedTrxDate.value =
          DateFormat('yyyy-MM-dd').format(picked);
      controller.fetchTransactions();
    }
  }
}
