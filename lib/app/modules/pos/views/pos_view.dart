import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/pos_controller.dart';
import '../controllers/cart_controller.dart';
import '../../shift/controllers/shift_controller.dart';
import '../../shift/views/shift_dialogs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/offline_sync_service.dart';
import '../../../routes/app_routes.dart';
import 'widgets/category_selector.dart';
import 'widgets/product_card.dart';
import 'widgets/cart_bottom_sheet.dart';
import 'widgets/tablet_cart_panel.dart';

class PosView extends GetView<PosController> {
  const PosView({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final shiftController = Get.find<ShiftController>();
    final offlineSyncService = Get.find<OfflineSyncService>();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        titleSpacing: 16,
        title: Obx(() {
          final cafeName = controller.cafeSettings.value.shopName;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cafeName.isNotEmpty ? cafeName : 'Noli POS Kasir',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Sistem Kasir & Inventory Toko',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          );
        }),
        actions: [
          // Shift Status Button
          Obx(() {
            final isOpen = shiftController.hasActiveShift.value;
            final bgColor = isOpen
                ? AppColors.primarySoft
                : AppColors.warningSoft;
            final borderColor = isOpen ? AppColors.primary : AppColors.warning;
            final textColor = isOpen
                ? AppColors.primaryDark
                : AppColors.warning;
            final iconColor = isOpen ? AppColors.primary : AppColors.warning;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
              child: Material(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    if (isOpen) {
                      await ShiftDialogs.showShiftSummaryDialog(context);
                    } else {
                      await ShiftDialogs.showStartShiftDialog(context);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOpen
                              ? Icons.lock_open_rounded
                              : Icons.lock_clock_rounded,
                          size: 16,
                          color: iconColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOpen ? 'Shift Aktif' : 'Buka Shift',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Offline Queue Indicator (jika ada data antrean offline)
          Obx(() {
            final count = offlineSyncService.pendingCount.value;
            if (count == 0) return const SizedBox.shrink();
            return IconButton(
              tooltip: '$count Transaksi Offline Menunggu Sync',
              icon: Badge(
                label: Text('$count'),
                backgroundColor: AppColors.warning,
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.warning,
                ),
              ),
              onPressed: () => offlineSyncService.syncPendingTransactions(),
            );
          }),

          // Open Bills Icon
          IconButton(
            tooltip: 'Daftar Bill Aktif (Meja)',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Get.toNamed(AppRoutes.openBills),
          ),

          // Riwayat Transaksi Hari Ini
          IconButton(
            tooltip: 'Riwayat Transaksi',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Get.toNamed(AppRoutes.transactions),
          ),

          // Pengaturan & Perangkat
          IconButton(
            tooltip: 'Pengaturan & Printer',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Get.toNamed(AppRoutes.settings),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth >= 768;

          if (isTablet) {
            // Tampilan Tablet Split-Screen (Kiri: Katalog & Search, Kanan: Cart Panel)
            return Row(
              children: [
                Expanded(child: _buildMenuContent(context, crossAxisCount: 3)),
                const TabletCartPanel(),
              ],
            );
          } else {
            // Tampilan Smartphone Portrait (Full Katalog + Floating Bottom Cart Bar)
            return Stack(
              children: [
                _buildMenuContent(
                  context,
                  crossAxisCount: 2,
                  bottomPadding: 80,
                ),
                // Floating Bottom Bar untuk HP
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildMobileBottomBar(context, cartController),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildMenuContent(
    BuildContext context, {
    required int crossAxisCount,
    double bottomPadding = 16,
  }) {
    return Column(
      children: [
        const SizedBox(height: 8),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              hintText: 'Cari menu berdasarkan nama atau barcode...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),
              suffixIcon: Obx(() {
                if (controller.searchQuery.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => controller.clearSearch(),
                );
              }),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
            ),
            onChanged: (val) => controller.onSearchChanged(val),
          ),
        ),
        const SizedBox(height: 12),

        // Category Pills Selector
        const CategorySelector(),
        const SizedBox(height: 10),

        // Product Grid
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final products = controller.filteredProducts;

            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.searchQuery.value.isNotEmpty
                          ? 'Tidak ditemukan menu "${controller.searchQuery.value}"'
                          : 'Belum ada menu pada kategori ini.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => controller.fetchBootstrap(),
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.76,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: products[index]);
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMobileBottomBar(
    BuildContext context,
    CartController cartController,
  ) {
    return Obx(() {
      if (cartController.isCartEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Badge & Item Count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${cartController.totalItemsCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Total Tagihan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Total Tagihan:',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  Text(
                    CurrencyFormatter.format(cartController.grandTotal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Tombol Buka Keranjang
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => CartBottomSheet.show(context),
              child: const Row(
                children: [
                  Text(
                    'Lihat Pesanan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
