import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/admin_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/storage_service.dart';
import 'tabs/admin_dashboard_tab.dart';
import 'tabs/admin_menu_sales_tab.dart';
import 'tabs/admin_transactions_tab.dart';
import 'tabs/admin_shifts_tab.dart';
import 'tabs/admin_open_bills_tab.dart';
import 'tabs/admin_cash_flow_tab.dart';
import 'widgets/common/admin_date_range_dialog.dart';
import 'widgets/navigation/admin_mobile_bottom_nav_bar.dart';

class AdminView extends GetView<AdminController> {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = Get.find<StorageService>();
    final user = storageService.user;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: const Color(0xFFF8FAFC), // Modern Slate-50 Canvas
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= 768;

              if (isTablet) {
                return SafeArea(
                  top: true,
                  bottom: false,
                  child: Row(
                    children: [
                      // 1. Sleek Full-Height Modern Sidebar
                      _buildSidebar(context, user),

                      // 2. Right Content Area with Executive Header Bar
                      Expanded(
                        child: Column(
                          children: [
                            _buildTopHeaderBar(context, user),
                            Expanded(
                              child: Obx(
                                () => _buildActiveTab(
                                  controller.selectedTabIndex.value,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Mobile View (< 768px): Clean Top AppBar + Active Tab Body + Modern 4-Tab "Menu Hub" Bottom Bar
              return PopScope(
                canPop: controller.selectedTabIndex.value == 0,
                onPopInvokedWithResult: (didPop, result) {
                  if (!didPop && controller.selectedTabIndex.value != 0) {
                    controller.switchTab(0);
                  }
                },
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  backgroundColor: const Color(0xFFF8FAFC),
                  appBar: AppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    automaticallyImplyLeading: false,
                    toolbarHeight: 52,
                    titleSpacing: 16,
                    shape: const Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    ),
                    title: Obx(() {
                      final tabIndex = controller.selectedTabIndex.value;
                      final isSubTab = tabIndex == 2 ||
                          tabIndex == 3 ||
                          tabIndex == 5 ||
                          tabIndex == 6;

                      if (tabIndex == 0) {
                        return Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.secondarySoft,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.secondaryLight.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/icons/app_icon.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.point_of_sale_rounded,
                                    color: AppColors.secondary,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Noli Coffee',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondarySoft,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                user?.role.toUpperCase() == 'OWNER'
                                    ? 'Owner'
                                    : 'Admin',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      final String tabTitle;
                      switch (tabIndex) {
                        case 1:
                          tabTitle = 'Riwayat Transaksi';
                          break;
                        case 2:
                          tabTitle = 'Laporan Menu';
                          break;
                        case 3:
                          tabTitle = 'Audit Shift Kasir';
                          break;
                        case 4:
                          tabTitle = 'Pesanan & Meja';
                          break;
                        case 5:
                          tabTitle = 'Arus Kas & Beban';
                          break;
                        case 6:
                          tabTitle = 'Pengaturan Toko';
                          break;
                        default:
                          tabTitle = 'Portal Admin';
                      }

                      return Row(
                        children: [
                          if (isSubTab) ...[
                            InkWell(
                              onTap: () => controller.switchTab(0),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 17,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tabTitle,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isSubTab)
                                  const Text(
                                    'Menu Hub • Ketuk panah untuk ke Dashboard',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                    actions: [
                      IconButton(
                        tooltip: 'Segarkan Data',
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF64748B),
                          size: 19,
                        ),
                        onPressed: () => controller.refreshCurrentTab(),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        tooltip: 'Keluar Akun',
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.danger,
                          size: 19,
                        ),
                        onPressed: () => _confirmLogout(context),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                  body: Obx(
                    () => _buildActiveTab(controller.selectedTabIndex.value),
                  ),
                  bottomNavigationBar: AdminMobileBottomNavBar(
                    controller: controller,
                  ),
                ),
              );
          },
        ),
      ),
    ),
  );
}

  // ---------------------------------------------------------------------------
  // Tablet / Desktop Sleek Sidebar (Collapsible: 200px expanded <-> 68px rail)
  // Stack berlapis berdimensi pasti (200px & 68px) untuk transisi 100% bebas overflow
  // ---------------------------------------------------------------------------
  static const double _sidebarExpandedWidth = 200.0;
  static const double _sidebarCollapsedWidth = 68.0;

  Widget _buildSidebar(BuildContext context, dynamic user) {
    return Obx(() {
      final isCollapsed = controller.isSidebarCollapsed.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOutCubic,
        width: isCollapsed ? _sidebarCollapsedWidth : _sidebarExpandedWidth,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              // 1. Layer Expanded Sidebar (Lebar 200px)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _sidebarExpandedWidth,
                child: ExcludeSemantics(
                  excluding: isCollapsed,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: isCollapsed ? 100 : 200),
                    curve: Curves.easeInOut,
                    opacity: isCollapsed ? 0.0 : 1.0,
                    child: IgnorePointer(
                      ignoring: isCollapsed,
                      child: _buildExpandedSidebar(context, user),
                    ),
                  ),
                ),
              ),

              // 2. Layer Collapsed Rail (Lebar 68px)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _sidebarCollapsedWidth,
                child: ExcludeSemantics(
                  excluding: !isCollapsed,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: isCollapsed ? 200 : 100),
                    curve: Curves.easeInOut,
                    opacity: isCollapsed ? 1.0 : 0.0,
                    child: IgnorePointer(
                      ignoring: !isCollapsed,
                      child: _buildCollapsedSidebar(context, user),
                    ),
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
  // Full Expanded Sidebar (Width: 200px)
  // ---------------------------------------------------------------------------
  Widget _buildExpandedSidebar(BuildContext context, dynamic user) {
    return SizedBox(
      width: _sidebarExpandedWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Brand (52px height - matches top bar)
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
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
                        size: 17,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Noli Coffee',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              user?.role.toUpperCase() == 'OWNER'
                                  ? 'OWNER'
                                  : 'ADMIN',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Portal Manajemen',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup Sidebar',
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    size: 19,
                    color: Color(0xFF64748B),
                  ),
                  onPressed: controller.toggleSidebar,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 26,
                    minHeight: 26,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Menu Items
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 6, bottom: 6),
                      child: Text(
                        'NAVIGASI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    _buildExpandedNavItem(
                      index: 0,
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard Bisnis',
                    ),
                    const SizedBox(height: 3),
                    _buildExpandedNavItem(
                      index: 1,
                      icon: Icons.receipt_long_rounded,
                      label: 'Riwayat Transaksi',
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => _buildExpandedNavItem(
                        index: 4,
                        icon: Icons.table_restaurant_rounded,
                        label: 'Pesanan & Meja',
                        badgeCount: controller.openBillsTotalActive.value,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _buildExpandedNavItem(
                      index: 3,
                      icon: Icons.assignment_rounded,
                      label: 'Shift Kasir',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ),
                    _buildExpandedNavItem(
                      index: 2,
                      icon: Icons.restaurant_menu_rounded,
                      label: 'Penjualan Menu',
                    ),
                    const SizedBox(height: 3),
                    _buildExpandedNavItem(
                      index: 5,
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Arus Kas & Beban',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pushed to bottom: Pengaturan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: _buildExpandedNavItem(
              index: 6,
              icon: Icons.settings_rounded,
              label: 'Pengaturan',
            ),
          ),
          const SizedBox(height: 4),

          // Minimalist User & Logout Footer
          _buildExpandedFooter(context, user),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Compact Collapsed Sidebar Rail (Width: 68px)
  // ---------------------------------------------------------------------------
  Widget _buildCollapsedSidebar(BuildContext context, dynamic user) {
    return SizedBox(
      width: 68,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header (52px height - matches top bar)
          Container(
            height: 52,
            alignment: Alignment.center,
            child: Tooltip(
              message: 'Buka Sidebar',
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: controller.toggleSidebar,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.point_of_sale_rounded,
                          color: AppColors.secondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),

          // Menu Items (Centered) in Expanded SingleChildScrollView
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    _buildCollapsedNavItem(
                      index: 0,
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard Bisnis',
                    ),
                    const SizedBox(height: 4),
                    _buildCollapsedNavItem(
                      index: 1,
                      icon: Icons.receipt_long_rounded,
                      label: 'Riwayat Transaksi',
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => _buildCollapsedNavItem(
                        index: 4,
                        icon: Icons.table_restaurant_rounded,
                        label: 'Pesanan & Meja',
                        badgeCount: controller.openBillsTotalActive.value,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildCollapsedNavItem(
                      index: 3,
                      icon: Icons.assignment_rounded,
                      label: 'Shift Kasir',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ),
                    _buildCollapsedNavItem(
                      index: 2,
                      icon: Icons.restaurant_menu_rounded,
                      label: 'Penjualan Menu',
                    ),
                    const SizedBox(height: 4),
                    _buildCollapsedNavItem(
                      index: 5,
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Arus Kas & Beban',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pushed to bottom: Pengaturan
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildCollapsedNavItem(
              index: 6,
              icon: Icons.settings_rounded,
              label: 'Pengaturan',
            ),
          ),

          // Minimalist Collapsed Footer
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
        color: isSelected ? AppColors.secondarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () => controller.switchTab(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.secondary
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.secondary
                          : const Color(0xFF334155),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondary
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFB45309),
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
          color: isSelected ? AppColors.secondarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () => controller.switchTab(index),
            child: Container(
              width: 44,
              height: 40,
              alignment: Alignment.center,
              child: Badge(
                isLabelVisible: badgeCount > 0,
                label: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: AppColors.warning,
                textColor: Colors.white,
                child: Icon(
                  icon,
                  size: 19,
                  color: isSelected
                      ? AppColors.secondary
                      : const Color(0xFF64748B),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.secondarySoft,
            child: Text(
              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'A',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.name ?? 'Admin',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  user?.role.toUpperCase() == 'OWNER' ? 'Owner' : 'Admin',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(
              Icons.logout_rounded,
              size: 17,
              color: Color(0xFF94A3B8),
            ),
            hoverColor: AppColors.dangerSoft,
            onPressed: () => _confirmLogout(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedFooter(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message:
                '${user?.name ?? "Admin"} (${user?.role.toUpperCase() ?? "OWNER"})',
            child: CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.secondarySoft,
              child: Text(
                user?.name.isNotEmpty == true
                    ? user!.name[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          IconButton(
            tooltip: 'Keluar Akun',
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFF94A3B8),
              size: 16,
            ),
            onPressed: () => _confirmLogout(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Header Bar for Tablet/Desktop (Sleek 52px Linear/Stripe style)
  // ---------------------------------------------------------------------------
  Widget _buildTopHeaderBar(BuildContext context, dynamic user) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          // Sidebar Toggle Button
          Obx(
            () => IconButton(
              tooltip: controller.isSidebarCollapsed.value
                  ? 'Buka Sidebar'
                  : 'Tutup Sidebar',
              icon: Icon(
                controller.isSidebarCollapsed.value
                    ? Icons.menu_rounded
                    : Icons.menu_open_rounded,
                color: const Color(0xFF475569),
                size: 19,
              ),
              onPressed: controller.toggleSidebar,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
          const SizedBox(width: 8),
          Container(height: 16, width: 1, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 12),

          // Dynamic Breadcrumb (Single-line, clean)
          Expanded(
            child: Obx(() {
              final idx = controller.selectedTabIndex.value;
              String title;
              switch (idx) {
                case 0:
                  title = 'Dashboard Bisnis';
                  break;
                case 1:
                  title = 'Riwayat Transaksi';
                  break;
                case 2:
                  title = 'Laporan Penjualan Menu';
                  break;
                case 3:
                  title = 'Shift Kasir';
                  break;
                case 4:
                  title = 'Pesanan & Meja';
                  break;
                case 5:
                  title = 'Arus Kas & Beban Toko';
                  break;
                case 6:
                  title = 'Pengaturan Sistem';
                  break;
                default:
                  title = 'Portal Manajemen';
              }

              return Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              );
            }),
          ),
          const SizedBox(width: 12),

          // Integrated Segmented Date Selector for Dashboard Tab
          Obx(() {
            if (controller.selectedTabIndex.value == 0) {
              final selected = controller.selectedDashboardDate.value;
              final nowStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
              final yesterdayStr = DateFormat(
                'yyyy-MM-dd',
              ).format(DateTime.now().subtract(const Duration(days: 1)));

              return Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSegmentedDateBtn(
                      'Hari Ini',
                      selected == nowStr,
                      () => controller.changeDashboardDate(DateTime.now()),
                    ),
                    _buildSegmentedDateBtn(
                      'Kemarin',
                      selected == yesterdayStr,
                      () => controller.changeDashboardDate(
                        DateTime.now().subtract(const Duration(days: 1)),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final isCustomDate =
                            selected != nowStr && selected != yesterdayStr;
                        return Material(
                          color: isCustomDate
                              ? AppColors.secondary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(7),
                            onTap: () async {
                              final initial =
                                  DateTime.tryParse(selected) ??
                                  DateTime.now();
                              final picked = await AdminDateRangeDialog.show(
                                context,
                                initialStartDate: initial,
                                initialEndDate: initial,
                                title: 'Pilih Tanggal Dashboard',
                                subtitle:
                                    'Pilih tanggal untuk melihat ringkasan performa',
                              );
                              if (picked != null) {
                                controller.changeDashboardDate(picked.start);
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isCustomDate ? 9 : 8,
                                vertical: 5,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: isCustomDate
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                                  ),
                                  if (isCustomDate) ...[
                                    const SizedBox(width: 5),
                                    Text(
                                      DateFormat('d MMM yyyy').format(
                                        DateTime.tryParse(selected) ??
                                            DateTime.now(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(width: 10),

          // Quick Refresh Action
          IconButton(
            tooltip: 'Segarkan Halaman',
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
              color: Color(0xFF64748B),
            ),
            onPressed: () => controller.refreshCurrentTab(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedDateBtn(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Material(
      color: isSelected ? AppColors.secondary : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      elevation: isSelected ? 0.5 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTab(int index) {
    switch (index) {
      case 0:
        return const AdminDashboardTab();
      case 1:
        return const AdminTransactionsTab();
      case 2:
        return const AdminMenuSalesTab();
      case 3:
        return const AdminShiftsTab();
      case 4:
        return const AdminOpenBillsTab();
      case 5:
        return const AdminCashFlowTab();
      case 6:
        return _buildSettingsPlaceholder();
      default:
        return const AdminDashboardTab();
    }
  }

  Widget _buildSettingsPlaceholder() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.secondarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.settings_suggest_rounded,
                        color: AppColors.secondary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Pengaturan Toko & Sistem',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Segera Hadir',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pusat konfigurasi operasional POS, profil outlet, integrasi printer, dan preferensi akun.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Placeholder Sections Preview
              const Text(
                'MODUL PENGATURAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 12),

              _buildSettingPreviewTile(
                icon: Icons.storefront_rounded,
                title: 'Profil & Informasi Outlet',
                subtitle:
                    'Nama toko, alamat cabang, kontak WhatsApp, dan logo bisnis untuk struk.',
              ),
              const SizedBox(height: 10),
              _buildSettingPreviewTile(
                icon: Icons.print_rounded,
                title: 'Konfigurasi Printer & Hardware',
                subtitle:
                    'Koneksi printer thermal Bluetooth/USB, ukuran kertas struk (58mm/80mm), dan laci kasir.',
              ),
              const SizedBox(height: 10),
              _buildSettingPreviewTile(
                icon: Icons.receipt_rounded,
                title: 'Pajak (PB1), Service Charge & Diskon',
                subtitle:
                    'Pengaturan persentase pajak restoran otomatis, biaya layanan meja, dan promo voucher.',
              ),
              const SizedBox(height: 10),
              _buildSettingPreviewTile(
                icon: Icons.badge_rounded,
                title: 'Manajemen Staf & Hak Akses',
                subtitle:
                    'Kelola akun kasir, PIN otorisasi diskon/void kasir, dan audit aktivitas operator.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingPreviewTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF64748B), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Akan Datang',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Keluar dari Panel Admin',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dan kembali ke halaman login?',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              controller.logout();
            },
            child: const Text(
              'Keluar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
