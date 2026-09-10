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

          // 3. Transactions Responsive Grid / List
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

                          if (isTablet) {
                      final crossAxisCount = isDesktop ? 3 : 2;
                      return GridView.builder(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 152,
                        ),
                        itemCount: displayList.length,
                        itemBuilder: (context, index) {
                          final tx = displayList[index];
                          return TransactionCard(
                            tx: tx,
                            onTap: () => _openDetailDialog(context, tx),
                            onVoidPressed: () => _openVoidDialog(context, tx),
                          );
                        },
                      );
                    }

                    return ListView.separated(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      itemCount: displayList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final tx = displayList[index];
                        return TransactionCard(
                          tx: tx,
                          onTap: () => _openDetailDialog(context, tx),
                          onVoidPressed: () => _openVoidDialog(context, tx),
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
