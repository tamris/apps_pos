import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/storage_service.dart';
import '../theme/app_colors.dart';
import 'app_shimmer.dart';

class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final IconData placeholderIcon;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
    this.placeholderIcon = Icons.coffee_rounded,
    this.placeholder,
    this.errorWidget,
  });

  String _formatUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Jika path relatif (misal /storage/...), gabungkan dengan Base URL dari storage
    if (Get.isRegistered<StorageService>()) {
      final baseUrl = Get.find<StorageService>().baseUrl;
      final uri = Uri.tryParse(baseUrl);
      if (uri != null) {
        final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
        final cleanPath = url.startsWith('/') ? url : '/$url';
        return '$origin$cleanPath';
      }
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = imageUrl?.trim() ?? '';

    // Jika URL kosong atau null, tampilkan fallback placeholder langsung
    if (rawUrl.isEmpty) {
      return _buildFallback(context);
    }

    final formattedUrl = _formatUrl(rawUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: formattedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) {
          if (placeholder != null) return placeholder!;
          return AppShimmer(
            child: ShimmerBox(
              width: width ?? double.infinity,
              height: height ?? double.infinity,
              borderRadius: borderRadius,
            ),
          );
        },
        errorWidget: (context, url, error) {
          if (errorWidget != null) return errorWidget!;
          return _buildFallback(context);
        },
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Icon(
        placeholderIcon,
        size: (width != null && height != null)
            ? (width! < height! ? width! * 0.45 : height! * 0.45)
            : 24,
        color: AppColors.primary.withAlpha(120),
      ),
    );
  }
}
