import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/open_bills_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/open_bill_model.dart';

class OpenBillsView extends GetView<OpenBillsController> {
  const OpenBillsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Obx(() => Text(
              'Bill Aktif (${controller.openBills.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Data',
            onPressed: () => controller.fetchOpenBills(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan nomor meja atau nama...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: Obx(() {
                  if (controller.searchQuery.value.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => controller.onSearchChanged(''),
                  );
                }),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => controller.onSearchChanged(val),
            ),
          ),

          // Bill Cards List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (controller.openBills.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tidak Ada Bill Aktif',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Semua pesanan meja telah selesai dibayar.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => controller.fetchOpenBills(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: controller.openBills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final bill = controller.openBills[index];
                    return _buildBillCard(context, bill);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard(BuildContext context, OpenBillModel bill) {
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
            // Header Bar Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: Text(
                        bill.billTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      bill.invoiceNumber,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Text(
                  bill.createdAt,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item Details Preview
            if (bill.details.isNotEmpty) ...[
              ...bill.details.take(3).map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.quantity}x ${item.name}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      ),
                      Text(
                        CurrencyFormatter.format(item.subtotal),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }),
              if (bill.details.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '+${bill.details.length - 3} item lainnya...',
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                  ),
                ),
              const Divider(height: 16),
            ],

            // Total & Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Tagihan', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text(
                      CurrencyFormatter.format(bill.total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    // Tombol Void / Batalkan
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _confirmCancelBill(context, bill),
                      child: const Text('Batalkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),

                    // Tombol Lanjutkan Bill (Resume)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16),
                      label: const Text('Buka Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => controller.resumeBill(bill),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancelBill(BuildContext context, OpenBillModel bill) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Batalkan Bill Pesanan?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Pesanan ${bill.billTitle} (${bill.invoiceNumber}) akan dibatalkan secara permanen.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Kembali')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Get.back();
              controller.cancelBill(bill);
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}
