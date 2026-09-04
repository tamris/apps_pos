import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/pos_controller.dart';
import '../controllers/cart_controller.dart';
import '../../shift/controllers/shift_controller.dart';
import '../../shift/views/shift_dialogs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/offline_sync_service.dart';
import '../../../data/services/online_order_polling_service.dart';
import '../../../routes/app_routes.dart';
import 'widgets/category_selector.dart';
import 'widgets/product_card.dart';
import 'widgets/cart_bottom_sheet.dart';
import 'widgets/tablet_cart_panel.dart';
import 'widgets/menu_availability_dialog.dart';
import '../../../core/widgets/skeletons/product_grid_skeleton.dart';

class PosView extends GetView<PosController> {
  const PosView({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final shiftController = Get.find<ShiftController>();
    final offlineSyncService = Get.find<OfflineSyncService>();
    final onlineOrderPollingService = Get.find<OnlineOrderPollingService>();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        titleSpacing: 16,
        title: Obx(() {
          final cafeName = controller.cafeSettings.value.shopName;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.lightBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.point_of_sale_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  cafeName.isNotEmpty ? cafeName : 'Noli POS Kasir',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          );
        }),
        actions: [
          // 1. Shift Status Compact Icon Button
          Obx(() {
            final isOpen = shiftController.hasActiveShift.value;
            final bgColor = isOpen ? AppColors.primarySoft : AppColors.warningSoft;
            final borderColor = isOpen ? AppColors.primary : AppColors.warning;
            final iconColor = isOpen ? AppColors.primary : AppColors.warning;

            return Tooltip(
              message: isOpen ? 'Shift Aktif (Ketuk untuk Ringkasan)' : 'Shift Tutup (Ketuk untuk Buka)',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Material(
                  color: bgColor,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () async {
                      if (isOpen) {
                        await ShiftDialogs.showShiftSummaryDialog(context);
                      } else {
                        await ShiftDialogs.showStartShiftDialog(context);
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor.withAlpha(120), width: 1.2),
                      ),
                      child: Icon(
                        isOpen ? Icons.lock_open_rounded : Icons.lock_clock_rounded,
                        size: 18,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

          // 2. Pesanan Online Status & Badge Icon Button
          Obx(() {
            final isActive = onlineOrderPollingService.isOnlineOrderActive.value;
            final count = onlineOrderPollingService.activeOrdersCount.value;
            final bgColor = isActive ? AppColors.primarySoft : AppColors.dangerSoft;
            final borderColor = isActive ? AppColors.primary : AppColors.danger;
            final iconColor = isActive ? AppColors.primary : AppColors.danger;

            return Tooltip(
              message: isActive
                  ? (count > 0 ? '$count Pesanan Online Aktif' : 'Toko Online Buka')
                  : 'Toko Online Dijeda',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Badge(
                  isLabelVisible: count > 0,
                  label: Text(
                    '$count',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                  backgroundColor: AppColors.primaryDark,
                  offset: const Offset(-2, 2),
                  child: Material(
                    color: bgColor,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Get.toNamed(AppRoutes.onlineOrders),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor.withAlpha(120), width: 1.2),
                        ),
                        child: Icon(
                          isActive ? Icons.delivery_dining_rounded : Icons.delivery_dining_outlined,
                          size: 20,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),

          // 3. Open Bills Icon (dengan badge jumlah bill aktif)
          Obx(() {
            final count = controller.activeOpenBillsCount.value;
            return IconButton(
              tooltip: count > 0 ? '$count Bill Aktif (Meja/Pesanan)' : 'Daftar Bill Aktif (Meja)',
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text(
                  '$count',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
                ),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.receipt_long_rounded),
              ),
              onPressed: () async {
                await Get.toNamed(AppRoutes.openBills);
                controller.fetchOpenBillsCount();
              },
            );
          }),

          // 4. Menu Lainnya (⋮ Dropdown: Riwayat Transaksi, Ketersediaan Menu, Sync Offline, Pengaturan)
          PopupMenuButton<String>(
            icon: Obx(() {
              final offlineCount = offlineSyncService.pendingCount.value;
              if (offlineCount > 0) {
                return Badge(
                  label: Text('$offlineCount'),
                  backgroundColor: AppColors.warning,
                  child: const Icon(Icons.more_vert_rounded),
                );
              }
              return const Icon(Icons.more_vert_rounded);
            }),
            tooltip: 'Menu Lainnya',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) async {
              switch (val) {
                case 'transactions':
                  Get.toNamed(AppRoutes.transactions);
                  break;
                case 'availability':
                  MenuAvailabilityDialog.show(context);
                  break;
                case 'sync':
                  offlineSyncService.showSyncDialog(context);
                  break;
                case 'settings':
                  Get.toNamed(AppRoutes.settings);
                  break;
              }
            },
            itemBuilder: (context) {
              final offlineCount = offlineSyncService.pendingCount.value;
              return [
                const PopupMenuItem(
                  value: 'transactions',
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 12),
                      Text('Riwayat Transaksi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'availability',
                  child: Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, color: AppColors.textPrimary, size: 20),
                      SizedBox(width: 12),
                      Text('Ketersediaan Menu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'sync',
                  child: Row(
                    children: [
                      Icon(
                        offlineCount > 0 ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                        color: offlineCount > 0 ? AppColors.warning : AppColors.info,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          offlineCount > 0 ? 'Sinkronisasi ($offlineCount antrean)' : 'Sinkronisasi Offline',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 20),
                      SizedBox(width: 12),
                      Text('Pengaturan & Printer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ];
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isTablet = constraints.maxWidth >= 768;

          if (isTablet) {
            // Tampilan Tablet Split-Screen (4 kolom kartu produk agar compact & minim scroll)
            return Row(
              children: [
                Expanded(
                  child: _buildMenuContent(
                    context,
                    crossAxisCount: 4,
                    childAspectRatio: 0.90,
                  ),
                ),
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
    double childAspectRatio = 0.90,
    double bottomPadding = 16,
  }) {
    return Column(
      children: [
        const SizedBox(height: 8),

        // Search Bar (Gaya asli dengan border nyala/fokus AppColors.primary)
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
              return const ProductGridSkeleton();
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
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: childAspectRatio,
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
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                CartBottomSheet.show(context);
              },
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
