import 'package:flutter/material.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/core/widgets/app_cached_image.dart';
import 'package:noli_apps/app/data/models/admin_menu_sales_model.dart';
import '../admin_menu_sales_detail_dialog.dart';

class MenuSalesCard extends StatelessWidget {
  final AdminMenuSalesItemModel item;

  const MenuSalesCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => AdminMenuSalesDetailDialog.show(context, item.productId),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Rank Tag + Category + Sales Share Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildRankBadge(item.rank),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                item.categoryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildShareBadge(item.salesSharePercentage),
                  ],
                ),

                // Middle Row: Thumbnail + Product Name + Unit Price & SKU
                Row(
                  children: [
                    _buildProductThumbnail(item.imageUrl),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${CurrencyFormatter.format(item.unitPrice)} • SKU: ${item.sku.isNotEmpty ? item.sku : '-'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Bottom Row: Sales Volume & Order Frequency
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantitySold} Porsi Terjual',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.transactionsCount}x Pesanan',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductThumbnail(String? imageUrl) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: AppCachedImage(
        imageUrl: imageUrl,
        width: 40,
        height: 40,
        borderRadius: 7,
        placeholderIcon: Icons.restaurant_menu_rounded,
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bg;
    Color border;
    Color text;

    if (rank == 1) {
      bg = const Color(0xFFFEF3C7);
      border = const Color(0xFFFDE68A);
      text = const Color(0xFFB45309);
    } else if (rank <= 3) {
      bg = const Color(0xFFF1F5F9);
      border = const Color(0xFFE2E8F0);
      text = const Color(0xFF334155);
    } else {
      bg = const Color(0xFFF8FAFC);
      border = const Color(0xFFE2E8F0);
      text = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        '#$rank',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: text,
        ),
      ),
    );
  }

  Widget _buildShareBadge(num share) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.secondarySoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.secondaryLight.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        '$share% Pangsa',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}
