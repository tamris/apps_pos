import 'package:flutter/material.dart';
import 'package:noli_apps/app/data/models/admin_menu_sales_model.dart';

class DashboardMenuSalesShortcutCard extends StatelessWidget {
  final AdminMenuSalesSummaryModel summary;
  final VoidCallback onViewMenu;

  const DashboardMenuSalesShortcutCard({
    super.key,
    required this.summary,
    required this.onViewMenu,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = summary.totalQuantitySold > 0;
    final topMenu = summary.topSellingProduct;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              size: 22,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Laporan Penjualan Menu',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF09090B),
                      ),
                    ),
                    if (hasData) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${summary.totalQuantitySold} Terjual',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  topMenu != null
                      ? 'Menu terlaris: ${topMenu.name} (${topMenu.quantitySold} porsi terjual)'
                      : 'Pantau ranking menu terlaris, omset per varian, tren harian, dan margin laba.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF71717A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF18181B),
              side: const BorderSide(color: Color(0xFFE4E4E7)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onViewMenu,
            icon: const Icon(Icons.arrow_forward_rounded, size: 14),
            label: const Text(
              'Lihat Menu',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
