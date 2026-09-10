import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/widgets/skeletons/list_item_skeleton.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/admin_transaction_detail_dialog.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/open_bills/online_order_card.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/open_bills/open_bills_empty_state.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/open_bills/open_bills_filter_bar.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/open_bills/open_bills_metrics_strip.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/open_bills/table_bill_card.dart';

class AdminOpenBillsTab extends GetView<AdminController> {
  const AdminOpenBillsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // 1. KPI Metrics Header Strip (Adapting to active mode)
          OpenBillsMetricsStrip(controller: controller),

          // 2. Mode Switcher & Search & Status Filter Bar
          OpenBillsFilterBar(controller: controller),

          // 3. Open Bills Responsive Grid / List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingOpenBills.value && controller.openBills.isEmpty) {
                return const ListItemSkeleton();
              }

              final displayBills = controller.filteredOpenBills;

              return RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: () => controller.fetchOpenBills(),
                child: displayBills.isEmpty
                    ? OpenBillsEmptyState(controller: controller)
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
                          mainAxisExtent: 162,
                        ),
                        itemCount: displayBills.length,
                        itemBuilder: (context, i) {
                          final b = displayBills[i];
                          return b.isSelfOrder
                              ? OnlineOrderCard(
                                  bill: b,
                                  onTap: () => _openTransactionDetail(context, b.id),
                                )
                              : TableBillCard(
                                  bill: b,
                                  onTap: () => _openTransactionDetail(context, b.id),
                                );
                        },
                      );
                    }

                    return ListView.separated(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      itemCount: displayBills.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final b = displayBills[i];
                        return b.isSelfOrder
                            ? OnlineOrderCard(
                                bill: b,
                                onTap: () => _openTransactionDetail(context, b.id),
                              )
                            : TableBillCard(
                                bill: b,
                                onTap: () => _openTransactionDetail(context, b.id),
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

  Future<void> _openTransactionDetail(BuildContext context, int transactionId) async {
    final detail = await controller.fetchTransactionDetail(transactionId);
    if (detail != null && context.mounted) {
      AdminTransactionDetailDialog.show(context, transaction: detail);
    }
  }
}
