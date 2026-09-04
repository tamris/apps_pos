import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/open_bills_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/skeletons/list_item_skeleton.dart';
import '../../../data/models/open_bill_model.dart';

class OpenBillsView extends GetView<OpenBillsController> {
  const OpenBillsView({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isLoading.value) {
        controller.fetchOpenBills();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        titleSpacing: 0,
        title: Obx(
          () => Text(
            'Bill Aktif (${controller.openBills.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
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
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari meja, nama pelanggan, atau invoice...',
                hintStyle: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: Obx(() {
                  if (controller.searchQuery.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () => controller.onSearchChanged(''),
                  );
                }),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (val) => controller.onSearchChanged(val),
            ),
          ),

          // 2. Summary Info Bar (Jika ada data bill tersimpan)
          Obx(() {
            if (controller.openBills.isEmpty) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft.withAlpha(120),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryLight.withAlpha(80),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          size: 16,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${controller.openBills.length} Bill Tersimpan',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Total: ${CurrencyFormatter.format(controller.totalPendingAmount)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // 3. Bill Cards List / Grid (Responsive)
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const ListItemSkeleton();
              }

              // State jika tidak ada data
              if (controller.openBills.isEmpty) {
                final isSearching = controller.searchQuery.value.trim().isNotEmpty;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: isSearching
                                ? AppColors.warningSoft
                                : AppColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSearching
                                ? Icons.search_off_rounded
                                : Icons.receipt_long_rounded,
                            size: 48,
                            color: isSearching
                                ? AppColors.warning
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isSearching
                              ? 'Tidak Ditemukan Bill'
                              : 'Tidak Ada Bill Aktif',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isSearching
                              ? 'Tidak ditemukan bill dengan kata kunci "${controller.searchQuery.value}".'
                              : 'Semua pesanan meja telah selesai dibayar atau belum ada bill tersimpan.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        if (isSearching) ...[
                          const SizedBox(height: 14),
                          TextButton.icon(
                            onPressed: () => controller.onSearchChanged(''),
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            label: const Text('Hapus Pencarian'),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              final displayedList = controller.openBills;

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => controller.fetchOpenBills(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTablet = constraints.maxWidth >= 768;

                    if (isTablet) {
                      final crossAxisCount = constraints.maxWidth >= 1200 ? 3 : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 195,
                        ),
                        itemCount: displayedList.length,
                        itemBuilder: (context, index) {
                          final bill = displayedList[index];
                          return _buildBillCard(context, bill);
                        },
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayedList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final bill = displayedList[index];
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
    final itemsCount = bill.details.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    final int totalDetails = bill.details.length;
    final int maxItemsToShow = (totalDetails <= 3) ? totalDetails : 3;
    final displayedItems = bill.details.take(maxItemsToShow).toList();
    final int remainingItems = totalDetails - maxItemsToShow;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => controller.resumeBill(bill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Bagian Kiri: Badge Meja/Take Away & Subtitle
                      Expanded(
                        child: Row(
                          children: [
                            // Badge Meja atau Take Away
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: bill.isTakeAway
                                    ? AppColors.warningSoft
                                    : AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: bill.isTakeAway
                                      ? AppColors.warning.withAlpha(120)
                                      : AppColors.primaryLight.withAlpha(120),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    bill.isTakeAway
                                        ? Icons.takeout_dining_rounded
                                        : (bill.tableNumber != null &&
                                                bill.tableNumber!.isNotEmpty
                                            ? Icons.table_restaurant_rounded
                                            : Icons.person_rounded),
                                    size: 13,
                                    color: bill.isTakeAway
                                        ? AppColors.warning
                                        : AppColors.primaryDark,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    bill.billTitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: bill.isTakeAway
                                          ? AppColors.warning
                                          : AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (bill.customerSubtitle != null) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '• ${bill.customerSubtitle}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                bill.invoiceNumber,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (bill.isOffline || bill.id < 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
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

                      const SizedBox(width: 8),

                      // Bagian Kanan: Format Jam saja (tanpa relatif & tanpa titik tiga)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
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
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              bill.formattedTime,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // 2. Daftar Preview Item Pesanan
                  if (bill.details.isNotEmpty) ...[
                    ...displayedItems.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(item.subtotal),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (remainingItems > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          '+$remainingItems menu lainnya...',
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'Belum ada rincian menu tersimpan',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // 3. Footer (Total Tagihan & Tombol Cetak Struk)
              Column(
                children: [
                  const Divider(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Tagihan ($itemsCount item)',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(
                          Icons.print_rounded,
                          size: 16,
                        ),
                        label: const Text(
                          'Cetak Struk',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => controller.printBill(bill),
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
