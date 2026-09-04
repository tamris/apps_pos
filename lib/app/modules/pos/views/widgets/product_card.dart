import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../data/models/product_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../controllers/cart_controller.dart';
import 'product_customization_sheet.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.product.isActive) {
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.product.isActive) {
      _scaleController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.product.isActive) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final isAvailable = widget.product.isActive;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Opacity(
        opacity: isAvailable ? 1.0 : 0.6,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAvailable ? AppColors.lightBorder : AppColors.lightBorder.withAlpha(120),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isAvailable ? 8 : 2),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onTap: () {
                  if (!isAvailable) {
                    HapticFeedback.vibrate();
                    AppSnackbar.warning(
                      'Menu Habis',
                      'Menu "${widget.product.name}" sedang dinonaktifkan / tidak tersedia.',
                    );
                    return;
                  }
                  // Haptic feedback sentuhan responsif kasir
                  HapticFeedback.lightImpact();
                  // 1-Tap Quick Add: Langsung masukkan menu ke keranjang kasir
                  cartController.addItem(widget.product);
                },
                onLongPress: isAvailable
                    ? () {
                        HapticFeedback.mediumImpact();
                        // Long Press: Buka sheet kustomisasi jika ada permintaan khusus
                        ProductCustomizationSheet.show(context, widget.product);
                      }
                    : null,
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
                            ),
                            child: (widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: widget.product.imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    httpHeaders: const {'ngrok-skip-browser-warning': 'true'},
                                    fadeInDuration: const Duration(milliseconds: 180),
                                    placeholder: (context, url) => AppShimmer(
                                      child: Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        color: Colors.white,
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => _buildInitialsPlaceholder(),
                                  )
                                : _buildInitialsPlaceholder(),
                          ),

                          // Overlay "HABIS" jika produk tidak aktif
                          if (!isAvailable)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(120),
                                ),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(60),
                                          blurRadius: 6,
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
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Cart Quantity Badge (Pojok Kanan Atas - beranimasi saat bertambah)
                          if (isAvailable)
                            Obx(() {
                              final countInCart = cartController.items
                                  .where((item) => item.product.id == widget.product.id)
                                  .fold(0, (sum, item) => sum + item.quantity);

                              return Positioned(
                                top: 6,
                                right: 6,
                                child: AnimatedScale(
                                  scale: countInCart > 0 ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.elasticOut,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.primaryLight, AppColors.primaryDark],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryDark.withAlpha(120),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 150),
                                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                      child: Text(
                                        '$countInCart',
                                        key: ValueKey<int>(countInCart),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),

                    // Detail Menu & Harga
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: AppColors.lightBorder, width: 0.8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isAvailable ? AppColors.textPrimary : AppColors.textMuted,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  CurrencyFormatter.format(widget.product.price),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isAvailable ? AppColors.primaryDark : AppColors.textMuted,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isAvailable ? AppColors.primarySoft : AppColors.lightBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isAvailable
                                        ? AppColors.primary.withAlpha(60)
                                        : AppColors.lightBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  isAvailable ? Icons.add_rounded : Icons.block_rounded,
                                  color: isAvailable ? AppColors.primary : AppColors.textMuted,
                                  size: 16,
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
        ),
      ),
    );
  }

  /// Placeholder inisial nama produk dengan warna soft hijau tema POS yang konsisten (gaya asli)
  Widget _buildInitialsPlaceholder() {
    final initials = _getInitials(widget.product.name);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.product.isActive ? AppColors.primarySoft : AppColors.lightBackground,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: initials.length > 1 ? 28 : 34,
            fontWeight: FontWeight.w900,
            color: widget.product.isActive
                ? AppColors.primary.withAlpha(190)
                : AppColors.textMuted.withAlpha(150),
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
