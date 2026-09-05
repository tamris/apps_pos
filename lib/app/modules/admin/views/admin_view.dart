import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/storage_service.dart';
import 'tabs/admin_dashboard_tab.dart';
import 'tabs/admin_transactions_tab.dart';
import 'tabs/admin_shifts_tab.dart';
import 'tabs/admin_open_bills_tab.dart';

class AdminView extends GetView<AdminController> {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = Get.find<StorageService>();
    final user = storageService.user;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 768;

          if (isTablet) {
            // Layout Tablet / Desktop: Full Height Modern Sidebar di Kiri + Right Content Area
            return Row(
              children: [
                // 1. Sleek Full-Height Left Sidebar
                _buildSidebar(context, user),

                // 2. Right Content Area dengan Integrated Header Bar
                Expanded(
                  child: Column(
                    children: [
                      _buildTopHeaderBar(context),
                      Expanded(
                        child: Obx(() => _buildActiveTab(controller.selectedTabIndex.value)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // Layout Mobile (< 768px): AppBar atas + Body + BottomNavigationBar
          return Scaffold(
            backgroundColor: AppColors.lightBackground,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 16,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.secondarySoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.secondaryLight.withValues(alpha: 0.3)),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: AppColors.secondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Panel Owner & Admin',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        user?.role.toUpperCase() == 'OWNER' ? 'Akses Pemilik (Full Access)' : 'Akses Administrator',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Segarkan',
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.secondary),
                  onPressed: () => controller.refreshCurrentTab(),
                ),
                IconButton(
                  tooltip: 'Keluar Akun',
                  icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  onPressed: () => _confirmLogout(context),
                ),
                const SizedBox(width: 6),
              ],
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: AppColors.lightBorder),
              ),
            ),
            body: Obx(() => _buildActiveTab(controller.selectedTabIndex.value)),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.lightBorder)),
              ),
              child: Obx(() => NavigationBar(
                selectedIndex: controller.selectedTabIndex.value,
                onDestinationSelected: controller.switchTab,
                backgroundColor: Colors.white,
                indicatorColor: AppColors.secondarySoft,
                elevation: 0,
                height: 64,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined, size: 20),
                    selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.secondary),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined, size: 20),
                    selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.secondary),
                    label: 'Transaksi',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.assignment_outlined, size: 20),
                    selectedIcon: Icon(Icons.assignment_rounded, color: AppColors.secondary),
                    label: 'Audit Shift',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.table_restaurant_outlined, size: 20),
                    selectedIcon: Icon(Icons.table_restaurant_rounded, color: AppColors.secondary),
                    label: 'Meja Aktif',
                  ),
                ],
              )),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tablet / Desktop Sleek Sidebar (Collapsible: 240px expanded <-> 72px compact)
  // Menggunakan Stack berlapis berdimensi pasti (240px & 72px) agar TIDAK ADA
  // elemen yang tertekan (overflow) sama sekali selama transisi buka/tutup!
  // ---------------------------------------------------------------------------
  Widget _buildSidebar(BuildContext context, dynamic user) {
    return Obx(() {
      final isCollapsed = controller.isSidebarCollapsed.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        width: isCollapsed ? 72 : 240,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: AppColors.lightBorder, width: 1.2)),
        ),
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              // 1. Layer Expanded Sidebar: Lebar pasti 240px, fade in saat terbuka
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 240,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: isCollapsed ? 120 : 220),
                  curve: Curves.easeInOut,
                  opacity: isCollapsed ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: isCollapsed,
                    child: _buildExpandedSidebar(context, user),
                  ),
                ),
              ),

              // 2. Layer Collapsed Rail: Lebar pasti 72px, fade in saat tertutup
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 72,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: isCollapsed ? 220 : 120),
                  curve: Curves.easeInOut,
                  opacity: isCollapsed ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !isCollapsed,
                    child: _buildCollapsedSidebar(context, user),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Full Expanded Sidebar (Width: 240px)
  // ---------------------------------------------------------------------------
  Widget _buildExpandedSidebar(BuildContext context, dynamic user) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 8, 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lightBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
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
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Noli POS',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              user?.role.toUpperCase() == 'OWNER' ? 'OWNER' : 'ADMIN',
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Portal Manajemen',
                        style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup Sidebar',
                  icon: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.textSecondary),
                  onPressed: controller.toggleSidebar,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.lightBorder),
          const SizedBox(height: 14),

          // Menu Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 8),
                  child: Text(
                    'NAVIGASI UTAMA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                _buildExpandedNavItem(
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard Bisnis',
                ),
                const SizedBox(height: 4),
                _buildExpandedNavItem(
                  index: 1,
                  icon: Icons.receipt_long_rounded,
                  label: 'Riwayat Transaksi',
                ),
                const SizedBox(height: 4),
                _buildExpandedNavItem(
                  index: 2,
                  icon: Icons.assignment_rounded,
                  label: 'Audit Shift Kasir',
                ),
                const SizedBox(height: 4),
                Obx(() => _buildExpandedNavItem(
                  index: 3,
                  icon: Icons.table_restaurant_rounded,
                  label: 'Tagihan Meja',
                  badgeCount: controller.openBillsTotalActive.value,
                )),
              ],
            ),
          ),

          const Spacer(),

          // Profile & Logout Footer
          _buildExpandedFooter(context, user),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Compact Collapsed Sidebar Rail (Width: 72px)
  // ---------------------------------------------------------------------------
  Widget _buildCollapsedSidebar(BuildContext context, dynamic user) {
    return SizedBox(
      width: 72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Tooltip(
                  message: 'Buka Sidebar (Noli POS)',
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: controller.toggleSidebar,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.lightBorder, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
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
                              color: AppColors.secondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                IconButton(
                  tooltip: 'Buka Sidebar',
                  icon: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
                  onPressed: controller.toggleSidebar,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.lightBorder),
          const SizedBox(height: 14),

          // Menu Items (Centered Icons)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                _buildCollapsedNavItem(
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard Bisnis',
                ),
                const SizedBox(height: 6),
                _buildCollapsedNavItem(
                  index: 1,
                  icon: Icons.receipt_long_rounded,
                  label: 'Riwayat Transaksi',
                ),
                const SizedBox(height: 6),
                _buildCollapsedNavItem(
                  index: 2,
                  icon: Icons.assignment_rounded,
                  label: 'Audit Shift Kasir',
                ),
                const SizedBox(height: 6),
                Obx(() => _buildCollapsedNavItem(
                  index: 3,
                  icon: Icons.table_restaurant_rounded,
                  label: 'Tagihan Meja',
                  badgeCount: controller.openBillsTotalActive.value,
                )),
              ],
            ),
          ),

          const Spacer(),

          // Profile & Logout Footer
          _buildCollapsedFooter(context, user),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Nav Item Helpers
  // ---------------------------------------------------------------------------
  Widget _buildExpandedNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    return Obx(() {
      final isSelected = controller.selectedTabIndex.value == index;
      return Material(
        color: isSelected ? AppColors.secondary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => controller.switchTab(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.warning,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.secondary : Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCollapsedNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    return Obx(() {
      final isSelected = controller.selectedTabIndex.value == index;
      return Tooltip(
        message: label,
        preferBelow: false,
        child: Material(
          color: isSelected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => controller.switchTab(index),
            child: Container(
              width: 48,
              height: 44,
              alignment: Alignment.center,
              child: Badge(
                isLabelVisible: badgeCount > 0,
                label: Text('$badgeCount', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                backgroundColor: isSelected ? Colors.white : AppColors.warning,
                textColor: isSelected ? AppColors.secondary : Colors.white,
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Footer Helpers
  // ---------------------------------------------------------------------------
  Widget _buildExpandedFooter(BuildContext context, dynamic user) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.secondary,
                  child: Text(
                    user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'A',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user?.name ?? 'Admin',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        user?.role.toUpperCase() == 'OWNER' ? 'Pemilik Toko' : 'Administrator',
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: AppColors.dangerSoft.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _confirmLogout(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, size: 16, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text(
                      'Keluar Akun',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedFooter(BuildContext context, dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Tooltip(
            message: '${user?.name ?? "Admin"} (${user?.role.toUpperCase() ?? "OWNER"})',
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.secondary,
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'A',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          IconButton(
            tooltip: 'Keluar Akun',
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Header Bar for Tablet Right Area
  // ---------------------------------------------------------------------------
  Widget _buildTopHeaderBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.lightBorder, width: 1.2)),
      ),
      child: Row(
        children: [
          // Sidebar Toggle Button
          Obx(() => IconButton(
            tooltip: controller.isSidebarCollapsed.value ? 'Buka Sidebar' : 'Tutup Sidebar',
            icon: Icon(
              controller.isSidebarCollapsed.value ? Icons.menu_rounded : Icons.menu_open_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
            onPressed: controller.toggleSidebar,
          )),
          const SizedBox(width: 8),
          // Dynamic Page Title & Subtitle (Wrapped in Expanded to prevent any overflow on resize)
          Expanded(
            child: Obx(() {
              final idx = controller.selectedTabIndex.value;
              String title;
              String subtitle;
              switch (idx) {
                case 0:
                  title = 'Dashboard Bisnis';
                  subtitle = '${_formatDateLabel(controller.selectedDashboardDate.value)} • Monitoring Real-Time';
                  break;
                case 1:
                  title = 'Riwayat Transaksi';
                  subtitle = 'Data seluruh transaksi kasir POS dan pemesanan online';
                  break;
                case 2:
                  title = 'Audit Shift Kasir';
                  subtitle = 'Rekapitulasi modal, fisik kasir, dan selisih laci per shift';
                  break;
                case 3:
                  title = 'Tagihan Meja Aktif';
                  subtitle = 'Daftar meja dengan transaksi yang belum diselesaikan kasir';
                  break;
                default:
                  title = 'Panel Manajemen';
                  subtitle = '';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            }),
          ),
          const SizedBox(width: 8),

          // Integrated Date Filter for Dashboard Tab
          Obx(() {
            if (controller.selectedTabIndex.value == 0) {
              final selected = controller.selectedDashboardDate.value;
              final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
              final yesterdayStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeaderDateChip('Hari Ini', selected == nowStr, () => controller.changeDashboardDate(DateTime.now())),
                  const SizedBox(width: 6),
                  _buildHeaderDateChip('Kemarin', selected == yesterdayStr, () => controller.changeDashboardDate(DateTime.now().subtract(const Duration(days: 1)))),
                  const SizedBox(width: 6),
                  Material(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(selected) ?? DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          controller.changeDashboardDate(picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: const Icon(Icons.edit_calendar_rounded, size: 16, color: AppColors.secondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(height: 24, width: 1, color: AppColors.lightBorder),
                  const SizedBox(width: 10),
                ],
              );
            }
            return const SizedBox.shrink();
          }),

          // Quick Refresh Action
          Material(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => controller.refreshCurrentTab(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 16, color: AppColors.secondary),
                    SizedBox(width: 6),
                    Text(
                      'Segarkan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderDateChip(String label, bool isSelected, VoidCallback onTap) {
    return Material(
      color: isSelected ? AppColors.secondary : AppColors.lightBackground,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.secondary : AppColors.lightBorder),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateLabel(String dtStr) {
    if (dtStr.isEmpty) return 'Hari Ini';
    try {
      final dt = DateTime.parse(dtStr);
      return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return dtStr;
    }
  }

  Widget _buildActiveTab(int index) {
    switch (index) {
      case 0:
        return const AdminDashboardTab();
      case 1:
        return const AdminTransactionsTab();
      case 2:
        return const AdminShiftsTab();
      case 3:
        return const AdminOpenBillsTab();
      default:
        return const AdminDashboardTab();
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.danger, size: 24),
            SizedBox(width: 10),
            Text('Keluar Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari Panel Owner/Admin dan kembali ke layar PIN Login?',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              controller.logout();
            },
            child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
