import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

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
}
