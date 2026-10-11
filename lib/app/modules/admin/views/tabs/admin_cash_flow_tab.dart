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
import '../widgets/common/admin_load_more_footer.dart';

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

          // 3. Responsive Data Grid / List with Infinite Scroll
          Expanded(
            child: Obx(() {
              if (controller.isLoadingCashFlow.value && controller.cashFlowMovements.isEmpty) {
                return const ListItemSkeleton();
              }

              final movements = controller.filteredCashFlowMovements;

              return RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: () async {
                  await Future.wait([
                    controller.fetchCashFlow(),
                    controller.fetchCashFlowSummary(),
                    controller.fetchAdminExpenseCategories(),
                  ]);
                },
                child: movements.isEmpty
                    ? CashFlowEmptyState(
                        onReset: () => controller.clearCashFlowFilters(),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final isDesktop = width >= 1150;
                          final isTablet = width >= 750;
                          final crossAxisCount = isDesktop ? 3 : 2;

                          return CustomScrollView(
                            controller: controller.cashFlowScrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 20 : 16,
                                  vertical: isTablet ? 16 : 14,
                                ),
                                sliver: isTablet
                                    ? SliverGrid(
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: 14,
                                          mainAxisSpacing: 14,
                                          mainAxisExtent: 148,
                                        ),
                                        delegate:
                                            SliverChildBuilderDelegate(
                                          (context, i) {
                                            final m = movements[i];
                                            return CashFlowCard(
                                              movement: m,
                                              onTap: () =>
                                                  AdminCashFlowDetailDialog.show(
                                                      context,
                                                      movement: m),
                                            );
                                          },
                                          childCount: movements.length,
                                        ),
                                      )
                                    : SliverList.separated(
                                        itemCount: movements.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, i) {
                                          final m = movements[i];
                                          return CashFlowCard(
                                            movement: m,
                                            onTap: () =>
                                                AdminCashFlowDetailDialog.show(
                                                    context,
                                                    movement: m),
                                          );
                                        },
                                      ),
                              ),

                              // Bottom Loading Spinner or End-of-List Indicator
                              SliverToBoxAdapter(
                                child: Obx(() => AdminLoadMoreFooter(
                                      isLoadingMore:
                                          controller.isLoadingMoreCashFlow.value,
                                      hasMore: controller.hasMoreCashFlow.value,
                                      itemCount: movements.length,
                                      itemName: 'arus kas',
                                    )),
                              ),
                            ],
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
