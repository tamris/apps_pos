import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/widgets/skeletons/list_item_skeleton.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import '../widgets/products/admin_product_form_dialog.dart';
import '../widgets/products/product_metrics_strip.dart';
import '../widgets/products/product_filter_bar.dart';
import '../widgets/products/product_card.dart';
import 'admin_hpp_tab.dart';

class AdminProductsTab extends GetView<AdminController> {
  const AdminProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // 1. Top Sub-Tab Navigation Bar (Katalog Menu vs Analisis Margin & AI Resep)
          _buildSubTabBar(context),

          // 2. Active Sub-View
          Expanded(
            child: Obx(() {
              if (controller.productManagementSubTab.value == 1) {
                return const AdminHppTab();
              }
              return _buildProductCatalogView(context);
            }),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Segmented Sub-Tab Bar
  // ---------------------------------------------------------------------------
  Widget _buildSubTabBar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 20, vertical: isNarrow ? 8 : 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
          ),
          child: Obx(() {
            final activeTab = controller.productManagementSubTab.value;
            final totalProducts = controller.products.length;
            final lowMarginCount = controller.hppSummary.value.lowMarginProducts.length;

            final btn1 = _buildSegmentedBtn(
              index: 0,
              isActive: activeTab == 0,
              title: isNarrow ? 'Katalog' : 'Katalog Produk',
              icon: Icons.inventory_2_outlined,
              badgeText: totalProducts > 0 ? '$totalProducts' : null,
              badgeColor: const Color(0xFF64748B),
              onTap: () => controller.setProductManagementSubTab(0),
              isExpanded: isNarrow,
            );

            final btn2 = _buildSegmentedBtn(
              index: 1,
              isActive: activeTab == 1,
              title: isNarrow ? 'Resep & HPP' : 'Kalkulator & Resep HPP',
              icon: Icons.calculate_outlined,
              badgeText: lowMarginCount > 0 ? (isNarrow ? '$lowMarginCount' : '$lowMarginCount Perhatian') : null,
              badgeColor: AppColors.danger,
              onTap: () => controller.setProductManagementSubTab(1),
              isExpanded: isNarrow,
            );

            if (isNarrow) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(child: btn1),
                    const SizedBox(width: 4),
                    Expanded(child: btn2),
                  ],
                ),
              );
            }

            final segmentedPill = Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  btn1,
                  const SizedBox(width: 4),
                  btn2,
                ],
              ),
            );

            return Row(
              children: [
                // Sisi Kiri: Segmented Sub-Tab
                segmentedPill,

                const Spacer(),

                // Sisi Kanan: Primary Action Button
                ElevatedButton.icon(
                  onPressed: () => AdminProductFormDialog.show(context),
                  icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  label: const Text(
                    'Tambah Menu Baru',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildSegmentedBtn({
    required int index,
    required bool isActive,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? badgeText,
    Color badgeColor = const Color(0xFF64748B),
    bool isExpanded = false,
  }) {
    return Material(
      color: isActive ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      elevation: isActive ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isExpanded ? 8 : 14, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isActive ? const Color(0xFFE2E8F0) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: isExpanded ? MainAxisAlignment.center : MainAxisAlignment.start,
            mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isActive ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (badgeColor == AppColors.danger
                            ? AppColors.dangerSoft
                            : const Color(0xFFF1F5F9))
                        : badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // View 1: Catalog View (Strip KPI + Filter + Grid)
  // ---------------------------------------------------------------------------
  Widget _buildProductCatalogView(BuildContext context) {
    return Column(
      children: [
        // 1. KPI Metrics Summary Strip
        ProductMetricsStrip(controller: controller),

        // 2. Search & Multi-Filter Bar + Actions
        ProductFilterBar(controller: controller),

        // 3. Responsive Data Grid / List
        Expanded(
          child: Obx(() {
            if (controller.isLoadingProducts.value && controller.products.isEmpty) {
              return const ListItemSkeleton();
            }

            final products = controller.filteredProducts;

            return RefreshIndicator(
              color: AppColors.secondary,
              onRefresh: () async {
                await Future.wait([
                  controller.fetchAdminProducts(),
                  controller.fetchAdminProductCategories(),
                  controller.fetchHppSummary(showLoader: false),
                ]);
              },
              child: products.isEmpty
                  ? _buildEmptyState(context)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final isWideScreen = width >= 1500;
                        final isDesktop = width >= 1100;
                        final isTablet = width >= 700;

                        if (isTablet) {
                          final crossAxisCount = isWideScreen ? 4 : (isDesktop ? 3 : 2);
                          return GridView.builder(
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              mainAxisExtent: 140,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, i) {
                              final p = products[i];
                              return ProductCard(
                                product: p,
                                controller: controller,
                              );
                            },
                          );
                        }

                        return ListView.separated(
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          itemCount: products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final p = products[i];
                            return SizedBox(
                              height: 140,
                              child: ProductCard(
                                product: p,
                                controller: controller,
                              ),
                            );
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

  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF94A3B8),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tidak Ada Menu Ditemukan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Coba ubah kata kunci pencarian, filter kategori, atau tambahkan menu baru.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => controller.clearProductFilters(),
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.secondary),
                  label: const Text(
                    'Reset Filter & Pencarian',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
