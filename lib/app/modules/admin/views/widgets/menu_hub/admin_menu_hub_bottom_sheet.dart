import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/data/services/storage_service.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class AdminMenuHubBottomSheet extends StatelessWidget {
  final AdminController controller;

  const AdminMenuHubBottomSheet({
    super.key,
    required this.controller,
  });

  static void show(BuildContext context, AdminController controller) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdminMenuHubBottomSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Get.find<StorageService>();
    final user = storageService.user;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1E000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Drag Handle
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.secondarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Menu & Hub Fitur',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'Pusat navigasi & modul operasional toko',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // 3. Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Context Card: Kasir & Shift Aktif + Quick POS Button
                      Obx(() {
                        final activeShift =
                            controller.dashboardData.value.activeShift;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.secondarySoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.storefront_rounded,
                                  color: AppColors.secondary,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          user?.name ?? 'Admin',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondarySoft,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            user?.role.toUpperCase() == 'OWNER'
                                                ? 'Owner'
                                                : 'Admin',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    if (activeShift != null)
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF10B981),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              'Shift: ${activeShift.cashierName} • Kas ${currencyFormat.format(activeShift.expectedCash)}',
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                color: Color(0xFF475569),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      const Text(
                                        'Tidak ada shift kasir aktif',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: activeShift != null
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: activeShift != null
                                        ? const Color(0xFFA7F3D0)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: activeShift != null
                                            ? const Color(0xFF059669)
                                            : const Color(0xFF94A3B8),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      activeShift != null
                                          ? 'Shift Aktif'
                                          : 'Tutup',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: activeShift != null
                                            ? const Color(0xFF047857)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 18),

                      // Section 1: OPERASIONAL & KASIR
                      _buildSectionHeader('OPERASIONAL & KASIR'),
                      const SizedBox(height: 8),
                      Obx(() => _buildHubItem(
                            context: context,
                            index: 3,
                            icon: Icons.assignment_rounded,
                            iconColor: const Color(0xFF0D9488),
                            iconBgColor: const Color(0xFFCCFBF1),
                            title: 'Audit Shift Kasir',
                            subtitle:
                                'Cek kas laci, selisih & Z-Report kasir',
                            isSelected:
                                controller.selectedTabIndex.value == 3,
                          )),
                      const SizedBox(height: 8),
                      Obx(() => _buildHubItem(
                            context: context,
                            index: 4,
                            icon: Icons.table_restaurant_rounded,
                            iconColor: const Color(0xFFD97706),
                            iconBgColor: const Color(0xFFFEF3C7),
                            title: 'Pesanan & Meja',
                            subtitle:
                                'Open bills & tagihan meja yang masih aktif',
                            badgeCount:
                                controller.openBillsTotalActive.value,
                            isSelected:
                                controller.selectedTabIndex.value == 4,
                          )),
                      const SizedBox(height: 18),

                      // Section 2: LAPORAN & ANALITIK
                      _buildSectionHeader('LAPORAN & ANALITIK'),
                      const SizedBox(height: 8),
                      Obx(() => _buildHubItem(
                            context: context,
                            index: 2,
                            icon: Icons.restaurant_menu_rounded,
                            iconColor: const Color(0xFFEA580C),
                            iconBgColor: const Color(0xFFFFEDD5),
                            title: 'Laporan Penjualan Menu',
                            subtitle:
                                'Analisis produk terlaris, kategori & omzet menu',
                            isSelected:
                                controller.selectedTabIndex.value == 2,
                          )),
                      const SizedBox(height: 8),
                      Obx(() => _buildHubItem(
                            context: context,
                            index: 5,
                            icon: Icons.account_balance_wallet_rounded,
                            iconColor: const Color(0xFF059669),
                            iconBgColor: const Color(0xFFD1FAE5),
                            title: 'Arus Kas & Beban Toko',
                            subtitle:
                                'Pencatatan beban operasional & mutasi uang kas',
                            isSelected:
                                controller.selectedTabIndex.value == 5,
                          )),
                      const SizedBox(height: 18),

                      // Section 3: RINGKASAN & SISTEM
                      _buildSectionHeader('NAVIGASI UTAMA & SISTEM'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Obx(() => _buildCompactTile(
                                  context: context,
                                  index: 0,
                                  icon: Icons.dashboard_rounded,
                                  label: 'Dashboard',
                                  isSelected:
                                      controller.selectedTabIndex.value == 0,
                                )),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Obx(() => _buildCompactTile(
                                  context: context,
                                  index: 1,
                                  icon: Icons.receipt_long_rounded,
                                  label: 'Transaksi',
                                  isSelected:
                                      controller.selectedTabIndex.value == 1,
                                )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Obx(() => _buildHubItem(
                            context: context,
                            index: 6,
                            icon: Icons.settings_rounded,
                            iconColor: const Color(0xFF475569),
                            iconBgColor: const Color(0xFFF1F5F9),
                            title: 'Pengaturan Toko & Akun',
                            subtitle:
                                'Konfigurasi printer, akun kasir & preferensi sistem',
                            isSelected:
                                controller.selectedTabIndex.value == 6,
                          )),
                    ],
                  ),
                ),
              ),

              // 4. Bottom Quick Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          controller.refreshCurrentTab();
                        },
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                        label: const Text(
                          'Segarkan Tab Ini',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFF8FAFC),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildHubItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool isSelected,
    int badgeCount = 0,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).pop();
          controller.switchTab(index);
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondarySoft : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.secondary.withValues(alpha: 0.5)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.secondary
                                  : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badgeCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$badgeCount',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSelected)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTile({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).pop();
          controller.switchTab(index);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondarySoft : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.secondary.withValues(alpha: 0.5)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected
                    ? AppColors.secondary
                    : const Color(0xFF475569),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.secondary
                      : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
