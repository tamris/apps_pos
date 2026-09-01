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
        titleSpacing: 0,
        title: Obx(() => Text(
              'Bill Aktif (${controller.openBills.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Data',
            onPressed: () => controller.fetchOpenBills(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan nomor meja, nama pelanggan, atau invoice...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                suffixIcon: Obx(() {
                  if (controller.searchQuery.value.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => controller.onSearchChanged(''),
                  );
                }),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (val) => controller.onSearchChanged(val),
            ),
          ),

          // Bill Cards List / Grid (Responsive)
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (controller.openBills.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak Ada Bill Aktif',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Semua pesanan meja telah selesai dibayar atau belum ada bill tersimpan.',
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
                onRefresh: () => controller.fetchOpenBills(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth >= 768;

                    if (isTablet) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 200,
                        ),
                        itemCount: controller.openBills.length,
                        itemBuilder: (context, index) {
                          final bill = controller.openBills[index];
                          return _buildBillCard(context, bill);
                        },
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.openBills.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final bill = controller.openBills[index];
                        return _buildBillCard(context, bill);
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

  Widget _buildBillCard(BuildContext context, OpenBillModel bill) {
    final itemsCount = bill.details.fold<int>(0, (sum, item) => sum + item.quantity);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => controller.resumeBill(bill),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(6),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Header (Meja / Pelanggan + Invoice + Jam)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              border: Border.all(color: AppColors.primaryLight.withAlpha(120)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  bill.tableNumber != null && bill.tableNumber!.isNotEmpty
                                      ? Icons.table_restaurant_rounded
                                      : Icons.person_rounded,
                                  size: 14,
                                  color: AppColors.primaryDark,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  bill.billTitle,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            bill.invoiceNumber,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            bill.createdAt,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 2. Daftar Preview Item Pesanan
                  if (bill.details.isNotEmpty) ...[
                    ...bill.details.take(2).map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.name}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(item.subtotal),
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (bill.details.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          '+${bill.details.length - 2} item lainnya...',
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ],
              ),

              // 3. Footer (Total Tagihan & Tombol Buka Bill)
              Column(
                children: [
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Tagihan ($itemsCount item)',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
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
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 16),
                        label: const Text(
                          'Buka Bill',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => controller.resumeBill(bill),
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
}
