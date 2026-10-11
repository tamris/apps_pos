import 'package:flutter/material.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/core/widgets/app_cached_image.dart';
import 'package:noli_apps/app/data/models/admin_product_model.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'admin_product_form_dialog.dart';
import 'admin_product_detail_dialog.dart';

class ProductCard extends StatefulWidget {
  final AdminProductModel product;
  final AdminController controller;

  const ProductCard({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final controller = widget.controller;

    // Status margin
    final isHealthy = product.marginPercent >= 45.0;
    final isCritical = product.marginPercent < 35.0;
    final marginColor = isCritical
        ? const Color(0xFFDC2626)
        : isHealthy
            ? const Color(0xFF059669)
            : const Color(0xFFD97706);
    final marginBgColor = isCritical
        ? const Color(0xFFFEF2F2)
        : isHealthy
            ? const Color(0xFFECFDF5)
            : const Color(0xFFFFFBEB);
    final marginBorderColor = isCritical
        ? const Color(0xFFFECACA)
        : isHealthy
            ? const Color(0xFFA7F3D0)
            : const Color(0xFFFDE68A);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? AppColors.primary.withValues(alpha: 0.6)
                : (product.isActive
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFFCBD5E1)),
            width: _isHovered ? 1.2 : 1.0,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => AdminProductDetailDialog.show(context, product: product),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Identity Row (Thumbnail + Info + Actions)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail
                      _buildThumbnail(product),
                      const SizedBox(width: 12),

                      // Name, Category, Badges
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: product.isActive
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF64748B),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.categoryName,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                if (product.sku.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      product.sku,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                if (product.ingredientsCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Text(
                                      '${product.ingredientsCount} Bahan',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Status Badge + Popup Menu
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatusBadge(product, controller),
                          const SizedBox(width: 4),
                          _buildPopupMenu(context, product, controller),
                        ],
                      ),
                    ],
                  ),

                  // Divider
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

                  // 2. Financial Breakdown Row
                  Row(
                    children: [
                      // 1. Harga Jual
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'HARGA JUAL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              CurrencyFormatter.format(product.price),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Vertical Divider
                      Container(
                        width: 1,
                        height: 22,
                        color: const Color(0xFFE2E8F0),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),

                      // 2. Estimasi HPP
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'ESTIMASI HPP',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              CurrencyFormatter.format(product.hargaBeli),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // 3. Cup Capacity Badge (Jika ada resep)
                      if (product.estimatedStock != null) ...[
                        _buildCupCapacityBadge(product.estimatedStock!),
                        const SizedBox(width: 6),
                      ],

                      // 4. Margin Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: marginBgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: marginBorderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCritical ? Icons.trending_down_rounded : Icons.trending_up_rounded,
                              size: 12,
                              color: marginColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${product.marginPercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: marginColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(AdminProductModel product) {
    final hasImage = product.imageUrl != null && product.imageUrl!.trim().isNotEmpty;

    if (hasImage) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: AppCachedImage(
            imageUrl: product.imageUrl,
            width: 52,
            height: 52,
            borderRadius: 9,
            placeholderIcon: Icons.local_cafe_outlined,
          ),
        ),
      );
    }

    // Smart Category-Themed Placeholder
    final cat = product.categoryName.toLowerCase();
    IconData icon = Icons.local_cafe_outlined;
    Color iconColor = AppColors.primary;
    Color bgColor = const Color(0xFFF0FDF4);
    Color borderColor = const Color(0xFFDCFCE7);

    if (cat.contains('non-coffee') ||
        cat.contains('tea') ||
        cat.contains('matcha') ||
        cat.contains('chocolate') ||
        cat.contains('taro')) {
      icon = Icons.emoji_food_beverage_outlined;
      iconColor = const Color(0xFF0284C7);
      bgColor = const Color(0xFFF0F9FF);
      borderColor = const Color(0xFFE0F2FE);
    } else if (cat.contains('food') ||
        cat.contains('snack') ||
        cat.contains('bakery') ||
        cat.contains('roti') ||
        cat.contains('pastry')) {
      icon = Icons.bakery_dining_outlined;
      iconColor = const Color(0xFFD97706);
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFEF3C7);
    } else if (cat.contains('coffee') || cat.contains('espresso')) {
      icon = Icons.coffee_outlined;
      iconColor = const Color(0xFF92400E);
      bgColor = const Color(0xFFFDF8F6);
      borderColor = const Color(0xFFF5EBE6);
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 24,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AdminProductModel product, AdminController controller) {
    if (product.isArchived) {
      return InkWell(
        onTap: () => controller.toggleArchiveProduct(product),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.archive_outlined, size: 12, color: Color(0xFFD97706)),
              SizedBox(width: 4),
              Text(
                'Arsip',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => controller.toggleProductStatus(product),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: product.isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: product.isActive ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: product.isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              product.isActive ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: product.isActive ? const Color(0xFF047857) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(
    BuildContext context,
    AdminProductModel product,
    AdminController controller,
  ) {
    return Material(
      color: Colors.transparent,
      child: PopupMenuButton<String>(
        tooltip: 'Opsi Menu',
        icon: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Icon(
            Icons.more_vert_rounded,
            size: 15,
            color: Color(0xFF64748B),
          ),
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 4,
        onSelected: (val) {
          switch (val) {
            case 'detail':
              AdminProductDetailDialog.show(context, product: product);
              break;
            case 'edit':
              AdminProductFormDialog.show(context, product: product);
              break;
            case 'toggle':
              controller.toggleProductStatus(product);
              break;
            case 'archive':
              _confirmArchive(context, product, controller);
              break;
            case 'restore':
              controller.toggleArchiveProduct(product);
              break;
            case 'permanent_delete':
              _confirmPermanentDelete(context, product, controller);
              break;
          }
        },
        itemBuilder: (ctx) {
          // If already in Arsip: show Pulihkan & Hapus Permanen
          if (product.isArchived) {
            return [
              const PopupMenuItem<String>(
                value: 'detail',
                height: 36,
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 15, color: Color(0xFF475569)),
                    SizedBox(width: 8),
                    Text('Lihat Detail & Resep', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'restore',
                height: 36,
                child: Row(
                  children: [
                    Icon(Icons.unarchive_outlined, size: 15, color: Color(0xFF047857)),
                    SizedBox(width: 8),
                    Text(
                      'Pulihkan dari Arsip',
                      style: TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem<String>(
                value: 'permanent_delete',
                height: 36,
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_rounded, size: 15, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text(
                      'Hapus Permanen',
                      style: TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ];
          }

          // Active product: show Lihat, Edit, Toggle Aktif/Nonaktif, and Arsipkan
          return [
            const PopupMenuItem<String>(
              value: 'detail',
              height: 36,
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 15, color: Color(0xFF475569)),
                  SizedBox(width: 8),
                  Text('Lihat Detail & Resep', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'edit',
              height: 36,
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 15, color: Color(0xFF475569)),
                  SizedBox(width: 8),
                  Text('Edit Produk', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle',
              height: 36,
              child: Row(
                children: [
                  Icon(
                    product.isActive ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
                    size: 15,
                    color: product.isActive ? const Color(0xFF64748B) : const Color(0xFF047857),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    product.isActive ? 'Nonaktifkan Menu' : 'Aktifkan Menu',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(height: 1),
            const PopupMenuItem<String>(
              value: 'archive',
              height: 36,
              child: Row(
                children: [
                  Icon(Icons.archive_outlined, size: 15, color: Color(0xFFB45309)),
                  SizedBox(width: 8),
                  Text(
                    'Arsipkan Menu',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB45309), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }

  void _confirmArchive(
    BuildContext context,
    AdminProductModel product,
    AdminController controller,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.archive_outlined, color: Color(0xFFD97706), size: 20),
            SizedBox(width: 8),
            Text('Arsipkan Menu?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Menu '${product.name}' akan dipindahkan ke Arsip dan dinonaktifkan dari katalog POS kasir. Anda dapat memulihkannya kapan saja melalui filter 'Arsip'.",
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await controller.toggleArchiveProduct(product);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Arsipkan Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildCupCapacityBadge(int cups) {
    Color bg;
    Color border;
    Color textColor;
    String label;

    if (cups <= 0) {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFECACA);
      textColor = const Color(0xFFDC2626);
      label = '0 Cup';
    } else if (cups <= 10) {
      bg = const Color(0xFFFFF7ED);
      border = const Color(0xFFFED7AA);
      textColor = const Color(0xFFEA580C);
      label = 'Sisa $cups cup';
    } else if (cups <= 30) {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      textColor = const Color(0xFFD97706);
      label = '~$cups cup';
    } else {
      bg = const Color(0xFFF0FDF4);
      border = const Color(0xFFBBF7D0);
      textColor = const Color(0xFF059669);
      label = '~$cups cup';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.coffee_rounded, size: 11, color: textColor),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(
    BuildContext context,
    AdminProductModel product,
    AdminController controller,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.danger, size: 20),
            SizedBox(width: 8),
            Text('Hapus Permanen?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Apakah Anda yakin ingin menghapus permanen '${product.name}'? Data menu dan resep bahan bakunya akan dihapus selamanya dari sistem.",
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await controller.deleteProduct(product.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus Permanen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
