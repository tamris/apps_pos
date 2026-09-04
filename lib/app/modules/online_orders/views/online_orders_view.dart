import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeletons/online_order_skeleton.dart';
import '../controllers/online_orders_controller.dart';
import 'widgets/online_order_card.dart';

class OnlineOrdersView extends GetView<OnlineOrdersController> {
  const OnlineOrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        titleSpacing: 0,
        title: Obx(() {
          final isActive = controller.isStoreOnlineActive.value;
          return Row(
            children: [
              Icon(
                isActive ? Icons.delivery_dining_rounded : Icons.pause_circle_outline_rounded,
                color: isActive ? AppColors.primary : AppColors.danger,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pesanan Online',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          );
        }),
        actions: [
          // Toggle Toko Online Buka / Jeda
          Obx(() {
            final isActive = controller.isStoreOnlineActive.value;
            return Tooltip(
              message: isActive ? 'Pesanan Online Buka (Ketuk untuk Jeda)' : 'Pesanan Online Dijeda (Ketuk untuk Buka)',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => controller.toggleOnlineOrderStoreActive(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primarySoft : AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.danger,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? AppColors.primary : AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Toko Buka' : 'Dijeda',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isActive ? AppColors.primaryDark : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // Refresh Button
          IconButton(
            tooltip: 'Segarkan Data',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.fetchOrders(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Banner Status Toko Dijeda
          _buildPausedBanner(),

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
                    hintText: 'Cari nomor meja, nama pelanggan, atau invoice...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: Obx(() {
                      if (controller.searchQuery.value.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: controller.clearSearch,
                      );
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
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusTabs(),
              ],
            ),
          ),

          // 2. Orders Grid / List (Responsive Layout)
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const OnlineOrderSkeleton();
              }

              if (controller.orders.isEmpty) {
                return _buildEmptyState();
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 1100
                      ? 3
                      : (constraints.maxWidth >= 650 ? 2 : 1);

                  // Mobile Layout (Single Column)
                  if (crossAxisCount == 1) {
                    return RefreshIndicator(
                      onRefresh: () => controller.fetchOrders(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                        itemCount: controller.orders.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14.0),
                            child: SizedBox(
                              height: 330,
                              child: OnlineOrderCard(
                                order: controller.orders[index],
                                controller: controller,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }

                  // Tablet / Desktop Grid Layout (Multi Column KDS Style)
                  return RefreshIndicator(
                    onRefresh: () => controller.fetchOrders(),
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 330,
                      ),
                      itemCount: controller.orders.length,
                      itemBuilder: (context, index) {
                        return OnlineOrderCard(
                          order: controller.orders[index],
                          controller: controller,
                        );
                      },
                    ),
                  );
                },
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
        {'id': 'active', 'label': 'Semua Aktif', 'count': stats.active, 'color': AppColors.primary},
        {'id': 'pending', 'label': 'Menunggu', 'count': stats.pending, 'color': AppColors.warning},
        {'id': 'processing', 'label': 'Dimasak', 'count': stats.processing, 'color': AppColors.info},
        {'id': 'ready', 'label': 'Siap Diambil', 'count': stats.ready, 'color': AppColors.primary},
        {'id': 'completed', 'label': 'Selesai', 'count': stats.completedToday, 'color': AppColors.success},
        {'id': 'cancelled', 'label': 'Dibatalkan', 'count': stats.cancelledToday, 'color': AppColors.danger},
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                            color: isCurrent ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: isCurrent ? Colors.white.withAlpha(50) : color.withAlpha(30),
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

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
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
                Icons.delivery_dining_outlined,
                size: 54,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Pesanan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pesanan online baru dari pelanggan akan otomatis muncul di halaman ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Segarkan'),
              onPressed: () => controller.fetchOrders(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPausedBanner() {
    return Obx(() {
      if (controller.isStoreOnlineActive.value) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.dangerSoft,
        child: Row(
          children: [
            const Icon(Icons.pause_circle_filled_rounded, color: AppColors.danger, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Penerimaan Pesanan Online sedang DIJEDA. Pelanggan tidak dapat membuat pesanan baru.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ),
            TextButton(
              onPressed: () => controller.toggleOnlineOrderStoreActive(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Buka Toko',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
