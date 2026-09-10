import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class OpenBillsFilterBar extends StatelessWidget {
  final AdminController controller;

  const OpenBillsFilterBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Segmented Mode Switcher (Semua, Pesanan Online, Meja Belum Lunas)
          _buildModeSegmentSwitcher(),
          const SizedBox(height: 12),

          // Row 2: Search Box + Refresh Button
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: _buildSearchTextField(),
                ),
              ),
              const SizedBox(width: 10),
              _buildRefreshActionBtn(),
            ],
          ),
          const SizedBox(height: 10),

          // Row 3: Sub-Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildFilterChipsRow(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSegmentSwitcher() {
    return Obx(() {
      final currentMode = controller.selectedActiveOrderMode.value;
      final totalOnline = controller.activeOnlineOrders.length;
      final totalTables = controller.activeTableBills.length;

      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildSegmentItem(
                modeKey: 'tables',
                currentMode: currentMode,
                label: 'Meja Belum Lunas',
                badgeCount: totalTables,
                icon: Icons.table_restaurant_rounded,
                activeColor: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildSegmentItem(
                modeKey: 'online',
                currentMode: currentMode,
                label: 'Pesanan Online',
                badgeCount: totalOnline,
                icon: Icons.phonelink_ring_rounded,
                activeColor: const Color(0xFF4F46E5),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSegmentItem({
    required String modeKey,
    required String currentMode,
    required String label,
    required int badgeCount,
    required IconData icon,
    Color? activeColor,
  }) {
    final isSelected = currentMode == modeKey;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          controller.selectedActiveOrderMode.value = modeKey;
          controller.selectedOpenBillFilter.value = 'all';
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? (activeColor ?? AppColors.secondary)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (activeColor ?? const Color(0xFF0F172A))
                        : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (activeColor ?? AppColors.secondary).withValues(alpha: 0.12)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? (activeColor ?? AppColors.secondary)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchTextField() {
    return TextField(
      controller: controller.openBillSearchController,
      textInputAction: TextInputAction.search,
      onChanged: controller.onOpenBillSearchChanged,
      onSubmitted: (_) => controller.submitOpenBillSearch(),
      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: 'Cari nomor meja, nama tamu, invoice, atau kasir...',
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
        suffixIcon: Obx(() {
          if (controller.hasOpenBillSearch.value) {
            return IconButton(
              icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
              onPressed: controller.clearOpenBillSearch,
            );
          }
          return const SizedBox.shrink();
        }),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        fillColor: const Color(0xFFF8FAFC),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.2),
        ),
      ),
    );
  }

  Widget _buildRefreshActionBtn() {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: () => controller.fetchOpenBills(),
        icon: const Icon(Icons.refresh_rounded, size: 16),
        label: const Text('Segarkan', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFilterChipsRow() {
    return Obx(() {
      final mode = controller.selectedActiveOrderMode.value;
      final list = controller.openBills;
      final isFilterActive = controller.selectedOpenBillFilter.value != 'all' ||
          controller.openBillSearchQuery.value.isNotEmpty;

      List<Widget> chips = [];

      if (mode == 'online') {
        final onlineList = controller.activeOnlineOrders;
        final unpaidCount = onlineList.where((b) => !b.isPaid).length;
        final cookingCount = onlineList.where((b) => b.status.toLowerCase() == 'processing' || b.status.toLowerCase() == 'cooking').length;
        final readyCount = onlineList.where((b) => b.status.toLowerCase() == 'ready').length;

        chips = [
          _buildFilterChip('Semua Online', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Menunggu Bayar (QRIS)',
            'unpaid',
            dotColor: const Color(0xFFEA580C),
            badgeCount: unpaidCount,
            badgeColor: const Color(0xFFEA580C),
          ),
          const SizedBox(width: 8),
          _buildFilterChip('Lunas QRIS', 'paid', dotColor: const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Sedang Dimasak',
            'cooking',
            dotColor: const Color(0xFF0284C7),
            badgeCount: cookingCount,
            badgeColor: const Color(0xFF0284C7),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Siap Diambil',
            'ready',
            dotColor: const Color(0xFF059669),
            badgeCount: readyCount,
            badgeColor: const Color(0xFF059669),
          ),
        ];
      } else if (mode == 'tables') {
        final tableList = controller.activeTableBills;
        final freshCount = tableList.where((b) => b.elapsedMinutes < 30).length;
        final longStayCount = tableList.where((b) => b.elapsedMinutes >= 60).length;

        chips = [
          _buildFilterChip('Semua Meja', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Baru Duduk (< 30m)',
            'fresh',
            dotColor: const Color(0xFF10B981),
            badgeCount: freshCount,
            badgeColor: const Color(0xFF059669),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Santai / Duduk Lama (> 60m)',
            'critical',
            dotColor: const Color(0xFF6366F1),
            badgeCount: longStayCount,
            badgeColor: const Color(0xFF6366F1),
          ),
        ];
      } else {
        // Mode 'all' (Exact match for tests)
        final criticalCount = list.where((b) => b.elapsedMinutes >= 60).length;
        final freshCount = list.where((b) => b.elapsedMinutes < 30).length;

        chips = [
          _buildFilterChip('Semua Meja', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Perlu Perhatian (> 60m)',
            'critical',
            dotColor: const Color(0xFFDC2626),
            badgeCount: criticalCount,
            badgeColor: const Color(0xFFDC2626),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Baru Dipesan (< 30m)',
            'fresh',
            dotColor: const Color(0xFF10B981),
            badgeCount: freshCount,
            badgeColor: const Color(0xFF059669),
          ),
          const SizedBox(width: 8),
          _buildFilterChip('Online (Self-Order)', 'self_order', dotColor: AppColors.secondary),
          const SizedBox(width: 8),
          _buildFilterChip('Kasir POS', 'pos', dotColor: const Color(0xFF64748B)),
        ];
      }

      return Row(
        children: [
          ...chips,
          if (isFilterActive) ...[
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                controller.selectedOpenBillFilter.value = 'all';
                controller.openBillSearchQuery.value = '';
                controller.openBillSearchController.clear();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.restart_alt_rounded, size: 13, color: Color(0xFFE11D48)),
                    SizedBox(width: 4),
                    Text(
                      'Reset Filter',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE11D48)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildFilterChip(
    String label,
    String value, {
    Color? dotColor,
    int? badgeCount,
    Color? badgeColor,
  }) {
    return Obx(() {
      final isSelected = controller.selectedOpenBillFilter.value == value;

      return Material(
        color: isSelected ? AppColors.secondarySoft : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            controller.selectedOpenBillFilter.value = value;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.secondaryLight.withValues(alpha: 0.5)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null && (badgeCount == null || badgeCount == 0)) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.secondary : const Color(0xFF475569),
                  ),
                ),
                if (badgeCount != null && badgeCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: badgeColor ?? const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
