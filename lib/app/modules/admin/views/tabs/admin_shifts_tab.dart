import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/widgets/skeletons/list_item_skeleton.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/admin_shift_detail_dialog.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/shifts/shift_card.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/shifts/shifts_empty_state.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/shifts/shifts_filter_bar.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/shifts/shifts_metrics_strip.dart';

class AdminShiftsTab extends GetView<AdminController> {
  const AdminShiftsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // 1. KPI Metrics Summary Strip
          ShiftsMetricsStrip(controller: controller),

          // 2. Search & Filter Bar
          ShiftsFilterBar(controller: controller),

          // 3. Shifts Responsive Grid / List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingShifts.value && controller.shifts.isEmpty) {
                return const ListItemSkeleton();
              }

              final displayShifts = controller.filteredShifts;

              return RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: () => controller.fetchShifts(),
                child: displayShifts.isEmpty
                    ? ShiftsEmptyState(
                        onReset: () {
                          controller.selectedShiftStatus.value = 'all';
                          controller.clearShiftDateFilter();
                          controller.shiftSearchController.clear();
                          controller.shiftSearchQuery.value = '';
                        },
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final isDesktop = width >= 1150;
                          final isTablet = width >= 650;

                          if (isTablet) {
                      final crossAxisCount = isDesktop ? 3 : 2;
                      return GridView.builder(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                          return ShiftCard(
                            shift: s,
                            onTap: () => _openShiftDetail(context, s.id),
                          );
                        },
                      );
                    }

                    return ListView.separated(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      itemCount: displayShifts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final s = displayShifts[i];
                        return ShiftCard(
                          shift: s,
                          onTap: () => _openShiftDetail(context, s.id),
                        );
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

  Future<void> _openShiftDetail(BuildContext context, int shiftId) async {
    final detail = await controller.fetchShiftDetail(shiftId);
    if (detail != null && context.mounted) {
      AdminShiftDetailDialog.show(context, shift: detail);
    }
  }
}
