import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/transactions_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/skeletons/list_item_skeleton.dart';
import '../../../data/models/transaction_model.dart';
import 'widgets/transaction_detail_dialog.dart';

class TransactionsView extends GetView<TransactionsController> {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi Hari Ini', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: () => controller.fetchTodayTransactions(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar & Status Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller.searchController,
                  onChanged: controller.onSearch,
                  decoration: InputDecoration(
                    hintText: 'Cari no invoice, meja, nama pelanggan...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: Obx(() {
                      if (controller.searchQuery.value.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: controller.clearSearch,
                      );
                    }),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    fillColor: AppColors.lightBackground,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.lightBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.lightBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusTabs(),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const ListItemSkeleton();
              }

              if (controller.transactions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_outlined, size: 48, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum Ada Transaksi',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Riwayat transaksi hari ini akan muncul di sini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => controller.fetchTodayTransactions(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: controller.transactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tx = controller.transactions[index];
                    return _buildTransactionCard(context, tx);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Obx(() {
      final selected = controller.selectedTab.value;
      final stats = controller.stats.value;

      final tabs = [
        {'id': 'completed', 'label': 'Selesai', 'count': stats.completed, 'color': AppColors.primary},
        {'id': 'pending', 'label': 'Open Bill', 'count': stats.pending, 'color': AppColors.warning},
        {'id': 'cancelled', 'label': 'Dibatalkan', 'count': stats.cancelled, 'color': AppColors.danger},
        {'id': 'all', 'label': 'Semua', 'count': stats.all, 'color': AppColors.secondary},
      ];

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isCurrent = selected == tab['id'];
            final color = tab['color'] as Color;
            final count = tab['count'] as int;

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Material(
                color: isCurrent ? color : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => controller.changeTab(tab['id'] as String),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCurrent ? color : AppColors.lightBorder,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tab['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                            color: isCurrent ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isCurrent ? Colors.white.withAlpha(50) : color.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? Colors.white : color,
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
          }).toList(),
        ),
      );
    });
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel tx) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightBorder, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => TransactionDetailDialog.show(context, tx, controller),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Meta
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            tx.invoiceNumber,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: tx.isCompleted
                                ? AppColors.primarySoft
                                : (tx.isPending ? AppColors.warningSoft : AppColors.dangerSoft),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tx.isPending ? 'OPEN BILL' : tx.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: tx.isCompleted
                                  ? AppColors.primaryDark
                                  : (tx.isPending ? AppColors.warning : AppColors.danger),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${tx.time} • ${tx.date}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Order Type & Payment Method Badges (Wrap to prevent overflow)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildSmallBadge(
                    Icons.restaurant_rounded,
                    tx.orderType == 'dine_in'
                        ? (tx.tableNumber != null && tx.tableNumber!.isNotEmpty ? 'Dine In (Meja ${tx.tableNumber})' : 'Dine In')
                        : 'Take Away',
                    AppColors.primary,
                  ),
                  _buildSmallBadge(
                    Icons.payment_rounded,
                    tx.isPending ? 'BELUM BAYAR' : tx.paymentMethod.toUpperCase(),
                    tx.isPending ? AppColors.warning : AppColors.secondary,
                  ),
                  if (tx.customerName != null && tx.customerName!.isNotEmpty)
                    _buildSmallBadge(
                      Icons.person_outline,
                      tx.customerName!,
                      AppColors.info,
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Details summary
              if (tx.details.isNotEmpty) ...[
                ...tx.details.take(3).map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity}x ${item.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          CurrencyFormatter.format(item.subtotal),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }),
                if (tx.details.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      '+${tx.details.length - 3} item lainnya... (Ketuk untuk rincian)',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.primary),
                    ),
                  ),
                const Divider(height: 16),
              ],

              // Total & Cetak Ulang Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      Text(
                        CurrencyFormatter.format(tx.total),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightBackground,
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.lightBorder),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text('Cetak Struk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => controller.printOrPreviewReceipt(tx.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
