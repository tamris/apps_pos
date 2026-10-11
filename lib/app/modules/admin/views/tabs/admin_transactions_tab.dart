import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/widgets/skeletons/list_item_skeleton.dart';
import 'package:noli_apps/app/data/models/admin_transaction_model.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import '../widgets/admin_transaction_detail_dialog.dart';
import '../widgets/admin_void_dialog.dart';
import '../widgets/transactions/transactions_metrics_strip.dart';
import '../widgets/transactions/transactions_filter_bar.dart';
import '../widgets/transactions/transaction_card.dart';
import '../widgets/transactions/transactions_empty_state.dart';
import '../widgets/common/admin_load_more_footer.dart';

class AdminTransactionsTab extends GetView<AdminController> {
  const AdminTransactionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // 1. KPI Metrics Summary Strip
          const TransactionsMetricsStrip(),

          // 2. Search & Filter Bar
          const TransactionsFilterBar(),

          // 3. Transactions Responsive Grid / List with Infinite Scroll
          Expanded(
            child: Obx(() {
              if (controller.isLoadingTransactions.value &&
                  controller.transactions.isEmpty) {
                return const ListItemSkeleton();
              }

              // Filter transactions: If Open Bill status is selected, strictly display POS table bills
              final displayList =
                  controller.selectedTrxStatus.value == 'pending'
                      ? controller.transactions
                          .where((t) => !t.isSelfOrder)
                          .toList()
                      : controller.transactions;

              return RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: () => controller.fetchTransactions(),
                child: displayList.isEmpty
                    ? TransactionsEmptyState(
                        onResetFilter: () => controller.clearTrxFilters(),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final isDesktop = width >= 1100;
                          final isTablet = width >= 650;

                          return CustomScrollView(
                            controller: controller.trxScrollController,
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
                                          crossAxisCount: isDesktop ? 3 : 2,
                                          crossAxisSpacing: 14,
                                          mainAxisSpacing: 14,
                                          mainAxisExtent: 152,
                                        ),
                                        delegate:
                                            SliverChildBuilderDelegate(
                                          (context, index) {
                                            final tx = displayList[index];
                                            return TransactionCard(
                                              tx: tx,
                                              onTap: () =>
                                                  _openDetailDialog(context, tx),
                                              onVoidPressed: () =>
                                                  _openVoidDialog(context, tx),
                                            );
                                          },
                                          childCount: displayList.length,
                                        ),
                                      )
                                    : SliverList.separated(
                                        itemCount: displayList.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final tx = displayList[index];
                                          return TransactionCard(
                                            tx: tx,
                                            onTap: () =>
                                                _openDetailDialog(context, tx),
                                            onVoidPressed: () =>
                                                _openVoidDialog(context, tx),
                                          );
                                        },
                                      ),
                              ),

                              // Bottom Loading Spinner or End-of-List Indicator
                              SliverToBoxAdapter(
                                child: Obx(() => AdminLoadMoreFooter(
                                      isLoadingMore:
                                          controller.isLoadingMoreTrx.value,
                                      hasMore: controller.hasMoreTrx.value,
                                      itemCount: displayList.length,
                                      itemName: 'transaksi',
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

  Future<void> _openDetailDialog(
    BuildContext context,
    AdminTransactionModel tx,
  ) async {
    final fullTrx = await controller.fetchTransactionDetail(tx.id) ?? tx;
    if (context.mounted) {
      AdminTransactionDetailDialog.show(
        context,
        transaction: fullTrx,
        onVoidPressed: () => _openVoidDialog(context, fullTrx),
      );
    }
  }

  void _openVoidDialog(BuildContext context, AdminTransactionModel tx) {
    AdminVoidDialog.show(
      context,
      transaction: tx,
      onConfirmVoid: (reason) => controller.voidTransaction(tx.id, reason),
    );
  }
}
