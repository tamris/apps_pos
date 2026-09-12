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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchTodayTransactions(silent: true);
    });

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi Hari Ini',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                      if (controller.searchQuery.value.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: controller.clearSearch,
                      );
                    }),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    fillColor: AppColors.lightBackground,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.lightBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.lightBorder,
                      ),
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
                          child: const Icon(
                            Icons.receipt_outlined,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum Ada Transaksi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Riwayat transaksi hari ini akan muncul di sini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => controller.fetchTodayTransactions(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isTabletOrDesktop = width >= 600;
                    final int crossAxisCount = width >= 1050 ? 3 : 2;
                    final double mainAxisExtent = width >= 1050 ? 228 : 232;

                    return CustomScrollView(
                      controller: controller.scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (isTabletOrDesktop)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: mainAxisExtent,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final tx = controller.transactions[index];
                                  return _buildTransactionCard(context, tx, isGrid: true);
                                },
                                childCount: controller.transactions.length,
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final tx = controller.transactions[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index == controller.transactions.length - 1 ? 0 : 10,
                                    ),
                                    child: _buildTransactionCard(context, tx, isGrid: false),
                                  );
                                },
                                childCount: controller.transactions.length,
                              ),
                            ),
                          ),

                        // Bottom Loading Spinner or End-of-List Indicator
                        SliverToBoxAdapter(
                          child: Obx(() {
                            if (controller.isLoadingMore.value) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Memuat transaksi berikutnya...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (!controller.hasMore.value && controller.transactions.length >= 21) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'Semua transaksi hari ini telah ditampilkan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            }

                            return const SizedBox(height: 16);
                          }),
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

  Widget _buildStatusTabs() {
    return Obx(() {
      final selected = controller.selectedTab.value;
      final stats = controller.stats.value;

      final tabs = [
        {
          'id': 'completed',
          'label': 'Selesai',
          'count': stats.completed,
          'color': AppColors.primary,
        },
        {
          'id': 'pending',
          'label': 'Open Bill',
          'count': stats.pending,
          'color': AppColors.warning,
        },
        {
          'id': 'cancelled',
          'label': 'Dibatalkan',
          'count': stats.cancelled,
          'color': AppColors.danger,
        },
        {
          'id': 'all',
          'label': 'Semua',
          'count': stats.all,
          'color': AppColors.secondary,
        },
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
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
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isCurrent
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? Colors.white.withAlpha(50)
                                  : color.withAlpha(30),
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

  Widget _buildTransactionCard(
    BuildContext context,
    TransactionModel tx, {
    bool isGrid = false,
  }) {
    final int totalDetails = tx.details.length;
    final int maxItemsToShow = (totalDetails <= 3) ? totalDetails : 3;
    final displayedItems = tx.details.take(maxItemsToShow).toList();
    final int remainingItems = totalDetails - maxItemsToShow;

    final Widget detailsSummaryWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayedItems.isNotEmpty) ...[
          ...displayedItems.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.format(item.subtotal),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (remainingItems > 0)
            Padding(
              padding: const EdgeInsets.only(top: 1.5),
              child: Text(
                '+$remainingItems item lainnya... (Ketuk untuk rincian)',
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ],
    );

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
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: isGrid
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.start,
            mainAxisSize: isGrid ? MainAxisSize.max : MainAxisSize.min,
            children: [
              // Bagian Atas: Header dan Badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tx.isCompleted
                                    ? AppColors.primarySoft
                                    : (tx.isPending
                                          ? AppColors.warningSoft
                                          : AppColors.dangerSoft),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tx.isPending
                                    ? 'OPEN BILL'
                                    : tx.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: tx.isCompleted
                                      ? AppColors.primaryDark
                                      : (tx.isPending
                                            ? AppColors.warning
                                            : AppColors.danger),
                                ),
                              ),
                            ),
                            if (tx.id < 0) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warningSoft,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.warning.withAlpha(120),
                                  ),
                                ),
                                child: const Text(
                                  'OFFLINE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.lightBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 11,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 3.5),
                                Text(
                                  tx.formattedTime,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 17,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Order Type & Payment Method Badges (Wrap to prevent overflow)
                  Wrap(
                    spacing: 5,
                    runSpacing: 3,
                    children: [
                      _buildSmallBadge(
                        Icons.restaurant_rounded,
                        tx.orderType == 'dine_in'
                            ? (tx.tableNumber != null &&
                                      tx.tableNumber!.isNotEmpty
                                  ? 'Dine In (Meja ${tx.tableNumber})'
                                  : 'Dine In')
                            : 'Take Away',
                        AppColors.primary,
                      ),
                      _buildSmallBadge(
                        Icons.payment_rounded,
                        tx.isPending
                            ? 'BELUM BAYAR'
                            : tx.paymentMethod.toUpperCase(),
                        tx.isPending ? AppColors.warning : AppColors.secondary,
                      ),
                      if (tx.customerName != null &&
                          tx.customerName!.isNotEmpty)
                        _buildSmallBadge(
                          Icons.person_outline,
                          tx.customerName!,
                          AppColors.info,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Details summary for List mode
                  if (!isGrid) detailsSummaryWidget,
                ],
              ),

              // Details summary for Grid mode (guaranteed no vertical overflow)
              if (isGrid)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: detailsSummaryWidget,
                    ),
                  ),
                ),

              // Bagian Bawah: Divider, Total & Cetak Struk Button
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 12, thickness: 0.8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(tx.total),
                            style: const TextStyle(
                              fontSize: 15,
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                        ),
                        icon: const Icon(Icons.print_outlined, size: 15),
                        label: const Text(
                          'Cetak Struk',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () =>
                            controller.printOrPreviewReceipt(tx.id),
                      ),
                    ],
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: color),
          const SizedBox(width: 3.5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
