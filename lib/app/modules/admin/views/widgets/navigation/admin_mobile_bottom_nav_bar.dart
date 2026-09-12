import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/menu_hub/admin_menu_hub_bottom_sheet.dart';

class AdminMobileBottomNavBar extends StatelessWidget {
  final AdminController controller;

  const AdminMobileBottomNavBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Obx(() {
          final currentTab = controller.selectedTabIndex.value;
          final isSubTabActive = currentTab == 2 ||
              currentTab == 3 ||
              currentTab == 5 ||
              currentTab == 6;

          return SizedBox(
            height: 58,
            child: Row(
              children: [
                // 1. Tab Dashboard
                _buildNavItem(
                  context: context,
                  label: 'Dashboard',
                  iconOutline: Icons.dashboard_outlined,
                  iconFilled: Icons.dashboard_rounded,
                  isActive: currentTab == 0,
                  onTap: () => controller.switchTab(0),
                ),

                // 2. Tab Transaksi
                _buildNavItem(
                  context: context,
                  label: 'Transaksi',
                  iconOutline: Icons.receipt_long_outlined,
                  iconFilled: Icons.receipt_long_rounded,
                  isActive: currentTab == 1,
                  onTap: () => controller.switchTab(1),
                ),

                // 3. Tab Pesanan (dengan badge real-time)
                _buildNavItem(
                  context: context,
                  label: 'Pesanan',
                  iconOutline: Icons.table_restaurant_outlined,
                  iconFilled: Icons.table_restaurant_rounded,
                  isActive: currentTab == 4,
                  badgeCount: controller.openBillsTotalActive.value,
                  onTap: () => controller.switchTab(4),
                ),

                // 4. Tab Lainnya (Menu Hub)
                _buildNavItem(
                  context: context,
                  label: 'Lainnya',
                  iconOutline: Icons.grid_view_outlined,
                  iconFilled: Icons.grid_view_rounded,
                  isActive: isSubTabActive,
                  showActiveDot: isSubTabActive,
                  onTap: () =>
                      AdminMenuHubBottomSheet.show(context, controller),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String label,
    required IconData iconOutline,
    required IconData iconFilled,
    required bool isActive,
    required VoidCallback onTap,
    int badgeCount = 0,
    bool showActiveDot = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          highlightShape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.secondarySoft.withValues(alpha: 0.6),
          containedInkWell: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container with clean subtle active indicator
              SizedBox(
                height: 28,
                width: 44,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      width: isActive ? 42 : 36,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.secondarySoft
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isActive ? iconFilled : iconOutline,
                        size: 20,
                        color: isActive
                            ? AppColors.secondary
                            : const Color(0xFF64748B),
                      ),
                    ),

                    // Badge Count (misal pesanan meja aktif)
                    if (badgeCount > 0)
                      Positioned(
                        top: -3,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 14,
                          ),
                          child: Text(
                            '$badgeCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),

                    // Dot Active (misal sedang di sub-halaman Menu Hub)
                    if (showActiveDot && badgeCount == 0)
                      Positioned(
                        top: 0,
                        right: 4,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),

              // Text Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? AppColors.secondary
                      : const Color(0xFF64748B),
                  letterSpacing: -0.2,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
