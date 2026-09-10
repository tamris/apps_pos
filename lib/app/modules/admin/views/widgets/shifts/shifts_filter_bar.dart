import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import '../common/admin_date_range_dialog.dart';

class ShiftsFilterBar extends StatelessWidget {
  final AdminController controller;

  const ShiftsFilterBar({
    super.key,
    required this.controller,
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
      onChanged: controller.onShiftSearchChanged,
      onSubmitted: (_) => controller.submitShiftSearch(),
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: 'Cari nama kasir, email, atau ID shift...',
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
        suffixIcon: Obx(() {
          if (controller.hasShiftSearch.value) {
            return IconButton(
              icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
              onPressed: controller.clearShiftSearch,
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
        onPressed: controller.submitShiftSearch,
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
          controller.selectedShiftStartDate.value != null ||
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
                controller.clearShiftDateFilter();
                controller.shiftSearchQuery.value = '';
                controller.shiftSearchController.clear();
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
      final start = controller.selectedShiftStartDate.value;
      final end = controller.selectedShiftEndDate.value;
      final isDateActive = (start != null && end != null) || (date != null && date.isNotEmpty);

      String displayLabel = 'Filter Tanggal';
      if (start != null && end != null) {
        final now = DateTime.now();
        final isToday = start.year == now.year && start.month == now.month && start.day == now.day;
        final yesterday = now.subtract(const Duration(days: 1));
        final isYesterday = start.year == yesterday.year && start.month == yesterday.month && start.day == yesterday.day;

        if (start.year == end.year && start.month == end.month && start.day == end.day) {
          if (isToday) {
            displayLabel = 'Hari Ini';
          } else if (isYesterday) {
            displayLabel = 'Kemarin';
          } else {
            displayLabel = DateFormat('dd MMM yyyy').format(start);
          }
        } else {
          displayLabel = '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
        }
      } else if (date != null && date.isNotEmpty) {
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
            final now = DateTime.now();
            DateTime initialStart = controller.selectedShiftStartDate.value ?? now;
            DateTime initialEnd = controller.selectedShiftEndDate.value ?? initialStart;
            if (controller.selectedShiftStartDate.value == null && controller.selectedShiftDate.value != null) {
              final parsed = DateTime.tryParse(controller.selectedShiftDate.value!) ?? now;
              initialStart = parsed;
              initialEnd = parsed;
            }

            final picked = await AdminDateRangeDialog.show(
              context,
              initialStartDate: initialStart,
              initialEndDate: initialEnd,
              title: 'Pilih Tanggal Audit Shift',
              subtitle: 'Pilih rentang tanggal untuk audit shift kasir & Z-Report',
            );
            if (picked != null) {
              controller.setShiftDateRange(picked.start, picked.end);
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
                    controller.clearShiftDateFilter();
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
}
