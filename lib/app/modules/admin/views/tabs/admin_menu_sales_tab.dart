import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import '../widgets/menu_sales/menu_sales_metrics_strip.dart';
import '../widgets/menu_sales/menu_sales_filter_bar.dart';
import '../widgets/menu_sales/menu_sales_card.dart';
import '../widgets/menu_sales/menu_sales_empty_state.dart';
import '../widgets/menu_sales/menu_sales_skeleton.dart';

class AdminMenuSalesTab extends GetView<AdminController> {
  const AdminMenuSalesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // 1. KPI Metrics Summary Strip
          const MenuSalesMetricsStrip(),

          // 2. Search & Filter Bar
          const MenuSalesFilterBar(),

          // 3. Menu Sales Responsive Grid / List
          Expanded(
            child: Obx(() {
              if (controller.isLoadingMenuSales.value &&
                  controller.menuSalesItems.isEmpty) {
                return const MenuSalesSkeleton();
              }

              final displayItems = controller.filteredMenuSalesItems;

              if (displayItems.isEmpty) {
                return MenuSalesEmptyState(
                  onResetFilter: () => controller.clearMenuFilters(),
                );
              }

              return RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: () async {
                  await controller.fetchMenuSales(refresh: true);
                  await controller.fetchMenuCategories();
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isDesktop = width >= 1100;
                    final isTablet = width >= 650;

                    if (isTablet) {
                      final crossAxisCount = isDesktop ? 3 : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 148,
                        ),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          return MenuSalesCard(item: item);
                        },
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      itemCount: displayItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = displayItems[index];
                        return MenuSalesCard(item: item);
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
}
