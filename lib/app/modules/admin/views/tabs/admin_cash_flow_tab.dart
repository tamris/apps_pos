import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/widgets/skeletons/list_item_skeleton.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import '../widgets/cash_flow/cash_flow_metrics_strip.dart';
import '../widgets/cash_flow/cash_flow_filter_bar.dart';
import '../widgets/cash_flow/cash_flow_card.dart';
import '../widgets/cash_flow/cash_flow_empty_state.dart';
import '../widgets/cash_flow/admin_add_expense_dialog.dart';
import '../widgets/cash_flow/admin_manage_categories_dialog.dart';
import '../widgets/cash_flow/admin_cash_flow_detail_dialog.dart';

class AdminCashFlowTab extends GetView<AdminController> {
  const AdminCashFlowTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // 1. KPI Metrics Summary Strip
          CashFlowMetricsStrip(controller: controller),

          // 2. Search & Multi-Filter Bar + Actions
          CashFlowFilterBar(
            controller: controller,
            onAddExpensePressed: () => AdminAddExpenseDialog.show(context),
            onManageCategoriesPressed: () => AdminManageCategoriesDialog.show(context),
          ),

          // 3. Responsive Data Grid / List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingCashFlow.value && controller.cashFlowMovements.isEmpty) {
                return const ListItemSkeleton();
              }

              final movements = controller.filteredCashFlowMovements;

              if (movements.isEmpty) {
                return CashFlowEmptyState(
                  onReset: () => controller.clearCashFlowFilters(),
                );
              }

              return RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: () async {
                  await Future.wait([
                    controller.fetchCashFlow(),
                    controller.fetchCashFlowSummary(),
                    controller.fetchAdminExpenseCategories(),
                  ]);
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isDesktop = width >= 1150;
                    final isTablet = width >= 750;

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
                        itemCount: movements.length,
                        itemBuilder: (context, i) {
                          final m = movements[i];
                          return CashFlowCard(
                            movement: m,
                            onTap: () => AdminCashFlowDetailDialog.show(context, movement: m),
                          );
                        },
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      itemCount: movements.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final m = movements[i];
                        return CashFlowCard(
                          movement: m,
                          onTap: () => AdminCashFlowDetailDialog.show(context, movement: m),
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
}
