import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/product_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../controllers/cart_controller.dart';
import 'product_customization_sheet.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final isAvailable = product.isActive;

    return Opacity(
      opacity: isAvailable ? 1.0 : 0.55,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (!isAvailable) {
              AppSnackbar.warning('Menu Habis', 'Menu "${product.name}" sedang dinonaktifkan / tidak tersedia.');
              return;
            }
            // 1-Tap Quick Add: Langsung masukkan menu ke keranjang kasir
            cartController.addItem(product);
          },
          onLongPress: isAvailable
              ? () {
                  // Long Press: Buka sheet kustomisasi jika ada permintaan khusus
                  ProductCustomizationSheet.show(context, product);
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAvailable ? AppColors.lightBorder : AppColors.lightBorder.withAlpha(120),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar Menu / Initial Avatar & Badges
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isAvailable ? AppColors.primarySoft : AppColors.lightBackground,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11),
                          ),
                        ),
                        child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(11),
                                ),
                                child: Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildInitialsPlaceholder(),
                                ),
                              )
                            : _buildInitialsPlaceholder(),
                      ),

                      // Overlay "HABIS" jika produk tidak aktif
                      if (!isAvailable)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(110),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                            ),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: AppColors.danger,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(50),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'HABIS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Badge Kategori (Pojok Kiri Atas)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(140),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.categoryName,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Cart Quantity Badge (Pojok Kanan Atas - hanya jika produk tersedia)
                      if (isAvailable)
                        Obx(() {
                          final countInCart = cartController.items
                              .where((item) => item.product.id == product.id)
                              .fold(0, (sum, item) => sum + item.quantity);

                          if (countInCart == 0) return const SizedBox.shrink();

                          return Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withAlpha(102),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '$countInCart',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),

                // Detail Menu & Harga
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 6.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? AppColors.textPrimary : AppColors.textMuted,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              CurrencyFormatter.format(product.price),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isAvailable ? AppColors.primaryDark : AppColors.textMuted,
                              ),
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isAvailable ? AppColors.primarySoft : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              isAvailable ? Icons.add_rounded : Icons.block_rounded,
                              color: isAvailable ? AppColors.primary : AppColors.textMuted,
                              size: 15,
                            ),
                          ),
                        ],
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

  /// Placeholder inisial nama produk dengan warna soft hijau tema POS yang konsisten
  Widget _buildInitialsPlaceholder() {
    final initials = _getInitials(product.name);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: product.isActive ? AppColors.primarySoft : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: initials.length > 1 ? 28 : 34,
            fontWeight: FontWeight.w900,
            color: product.isActive ? AppColors.primary.withAlpha(190) : AppColors.textMuted.withAlpha(150),
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  /// Ambil inisial 1-2 huruf dari nama produk (contoh: "Americano" -> "A", "Caffe Latte" -> "CL")
  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'P';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts[1].isNotEmpty ? parts[1][0] : '';
    return ('$first$second').toUpperCase();
  }
}
