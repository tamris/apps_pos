import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_controller.dart';
import '../../../../data/models/admin_transaction_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/skeletons/list_item_skeleton.dart';
import '../widgets/admin_transaction_detail_dialog.dart';
import '../widgets/admin_void_dialog.dart';

class AdminTransactionsTab extends GetView<AdminController> {
  const AdminTransactionsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Search Bar & Status Filter Bar
        _buildSearchAndFilters(context),

        // 2. Responsive Transactions Grid/List
        Expanded(
          child: Obx(() {
            if (controller.isLoadingTransactions.value && controller.transactions.isEmpty) {
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
                          color: AppColors.secondarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.secondary),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tidak Ada Transaksi',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tidak ditemukan riwayat transaksi yang sesuai dengan kriteria pencarian dan filter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () {
                          controller.selectedTrxStatus.value = 'all';
                          controller.selectedTrxOrderSource.value = 'all';
                          controller.selectedTrxPaymentMethod.value = 'all';
                          controller.selectedTrxDate.value = null;
                          controller.trxSearchQuery.value = '';
                          controller.trxSearchController.clear();
                          controller.fetchTransactions();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Reset Semua Filter', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.secondary,
              onRefresh: () => controller.fetchTransactions(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 768;

                  if (isTablet) {
                    final crossAxisCount = constraints.maxWidth >= 1200 ? 3 : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 200,
                      ),
                      itemCount: controller.transactions.length,
                      itemBuilder: (context, index) {
                        final tx = controller.transactions[index];
                        return _buildTransactionCard(context, tx);
                      },
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: controller.transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final tx = controller.transactions[index];
                      return _buildTransactionCard(context, tx);
                    },
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Search Bar & Filter Tabs
  // ---------------------------------------------------------------------------
  Widget _buildSearchAndFilters(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.trxSearchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (val) => controller.trxSearchQuery.value = val,
                  onSubmitted: (_) => controller.fetchTransactions(),
                  decoration: InputDecoration(
                    hintText: 'Cari no invoice, kasir, meja, nama pelanggan...',
                    hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                    suffixIcon: Obx(() {
                      if (controller.trxSearchQuery.value.isNotEmpty) {
                        return IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            controller.trxSearchController.clear();
                            controller.trxSearchQuery.value = '';
                            controller.fetchTransactions();
                          },
                        );
                      }
                      return const SizedBox.shrink();
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: () => controller.fetchTransactions(),
                icon: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Obx(() => Row(
              children: [
                _buildStatusTab('Semua', 'all', controller.selectedTrxStatus, AppColors.secondary),
                _buildStatusTab('Selesai', 'completed', controller.selectedTrxStatus, AppColors.primary),
                _buildStatusTab('Open Bill', 'pending', controller.selectedTrxStatus, AppColors.warning),
                _buildStatusTab('Dibatalkan (Void)', 'cancelled', controller.selectedTrxStatus, AppColors.danger),
                const SizedBox(width: 8),
                Container(height: 20, width: 1, color: AppColors.lightBorder),
                const SizedBox(width: 8),
                _buildStatusTab('Semua Saluran', 'all', controller.selectedTrxOrderSource, AppColors.secondary),
                _buildStatusTab('Kasir POS', 'pos', controller.selectedTrxOrderSource, AppColors.secondary),
                _buildStatusTab('Online Order', 'self_order', controller.selectedTrxOrderSource, AppColors.info),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(String label, String value, RxString target, Color accentColor) {
    final isCurrent = target.value == value;

    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Material(
        color: isCurrent ? accentColor : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            target.value = value;
            controller.fetchTransactions();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCurrent ? accentColor : AppColors.lightBorder,
                width: 1.2,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                color: isCurrent ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Transaction Card (Consistent with POS style)
  // ---------------------------------------------------------------------------
  Widget _buildTransactionCard(BuildContext context, AdminTransactionModel tx) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: tx.isCancelled ? AppColors.danger.withValues(alpha: 0.35) : AppColors.lightBorder,
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final fullTrx = await controller.fetchTransactionDetail(tx.id) ?? tx;
          if (context.mounted) {
            AdminTransactionDetailDialog.show(
              context,
              transaction: fullTrx,
              onVoidPressed: () => _openVoidDialog(context, fullTrx),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Section: Invoice Number, Badges, Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                tx.invoiceNumber,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: tx.isCancelled ? AppColors.danger : AppColors.textPrimary,
                                  decoration: tx.isCancelled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildStatusBadge(tx),
                            if (tx.isSelfOrder) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondarySoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ONLINE',
                                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.secondary),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Time pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 12, color: AppColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(tx.createdAt),
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Order Attributes (Dine In / Meja, Payment Method, Customer)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildSmallBadge(
                        Icons.restaurant_rounded,
                        tx.orderType == 'dine_in'
                            ? (tx.tableNumber != null && tx.tableNumber!.isNotEmpty ? 'Meja ${tx.tableNumber}' : 'Dine In')
                            : 'Take Away',
                        AppColors.secondary,
                      ),
                      _buildSmallBadge(
                        Icons.payment_rounded,
                        tx.isPending ? 'BELUM BAYAR' : tx.paymentMethod.toUpperCase(),
                        tx.isPending ? AppColors.warning : AppColors.info,
                      ),
                      if (tx.customerName.isNotEmpty && tx.customerName != 'Pelanggan Umum')
                        _buildSmallBadge(
                          Icons.person_outline_rounded,
                          tx.customerName,
                          AppColors.primary,
                        ),
                    ],
                  ),
                ],
              ),

              // Bottom Section: Cashier & Total Nominal + Action Button
              Column(
                children: [
                  const Divider(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kasir: ${tx.cashierName}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            CurrencyFormatter.format(tx.total),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: tx.isCancelled ? AppColors.textMuted : AppColors.primaryDark,
                              decoration: tx.isCancelled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!tx.isCancelled)
                            Material(
                              color: AppColors.dangerSoft,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _openVoidDialog(context, tx),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.delete_sweep_rounded, size: 14, color: AppColors.danger),
                                      SizedBox(width: 4),
                                      Text('Void', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                        ],
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

  void _openVoidDialog(BuildContext context, AdminTransactionModel tx) {
    AdminVoidDialog.show(
      context,
      transaction: tx,
      onConfirmVoid: (reason) => controller.voidTransaction(tx.id, reason),
    );
  }

  Widget _buildSmallBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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

  Widget _buildStatusBadge(AdminTransactionModel tx) {
    if (tx.isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'DIBATALKAN',
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.danger),
        ),
      );
    }
    if (tx.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'OPEN BILL',
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.warning),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'SELESAI',
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.success),
      ),
    );
  }

  String _formatTime(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dtStr).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return dtStr;
    }
  }
}
