import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/transactions_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/skeletons/list_item_skeleton.dart';
import '../../../data/models/transaction_model.dart';

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
          // Search & Filter Status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari no invoice, meja, nama pelanggan...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => controller.onSearchChanged(val),
                ),
                const SizedBox(height: 10),
                // Status Filter Chips
                Obx(() {
                  final curStatus = controller.selectedStatus.value;
                  return Row(
                    children: [
                      _buildStatusFilterChip('completed', 'Selesai', curStatus == 'completed'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('cancelled', 'Dibatalkan', curStatus == 'cancelled'),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('all', 'Semua Status', curStatus == 'all'),
                    ],
                  );
                }),
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

  Widget _buildStatusFilterChip(String status, String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primarySoft,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.lightBorder,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
      ),
      onSelected: (_) => controller.onStatusChanged(status),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel tx) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightBorder, width: 1.2),
      ),
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
                          color: tx.isCompleted ? AppColors.primarySoft : AppColors.dangerSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tx.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: tx.isCompleted ? AppColors.primaryDark : AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${tx.time} • ${tx.date}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
                      ? 'Dine In ${tx.tableNumber != null && tx.tableNumber!.isNotEmpty ? "(Meja ${tx.tableNumber})" : ""}'
                      : 'Take Away',
                  AppColors.primary,
                ),
                _buildSmallBadge(
                  Icons.payment_rounded,
                  tx.paymentMethod.toUpperCase(),
                  AppColors.secondary,
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
                      Text(
                        '${item.quantity}x ${item.name}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      ),
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
                    '+${tx.details.length - 3} item lainnya...',
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
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
