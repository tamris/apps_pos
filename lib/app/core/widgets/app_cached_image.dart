import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/storage_service.dart';
import 'app_shimmer.dart';

/// Komponen universal terbaik untuk memuat gambar network dengan caching,
/// animasi fade-in halus, dan skeleton shimmer placeholder modern.
class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final bool isCircle;
  final IconData placeholderIcon;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Map<String, String>? httpHeaders;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
    this.isCircle = false,
    this.placeholderIcon = Icons.restaurant_menu_rounded,
    this.placeholder,
    this.errorWidget,
    this.httpHeaders,
    this.fadeInDuration = const Duration(milliseconds: 220),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.memCacheWidth,
    this.memCacheHeight,
  });

  /// Factory constructor khusus untuk avatar / gambar bulat
  const AppCachedImage.circle({
    super.key,
    required this.imageUrl,
    required double size,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.person_rounded,
    this.placeholder,
    this.errorWidget,
    this.httpHeaders,
    this.fadeInDuration = const Duration(milliseconds: 220),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.memCacheWidth,
    this.memCacheHeight,
  })  : width = size,
        height = size,
        borderRadius = 0,
        isCircle = true;

  String _formatUrl(String url) {
    final clean = url.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }
    // Jika path relatif (misal /storage/...), gabungkan dengan Base URL dari storage service
    if (Get.isRegistered<StorageService>()) {
      final baseUrl = Get.find<StorageService>().baseUrl;
      final uri = Uri.tryParse(baseUrl);
      if (uri != null) {
        final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
        final cleanPath = clean.startsWith('/') ? clean : '/$clean';
        return '$origin$cleanPath';
      }
    }
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = imageUrl?.trim() ?? '';

    // Jika URL kosong atau null, tampilkan fallback placeholder langsung
    if (rawUrl.isEmpty) {
      return _buildFallback(context);
    }

    final formattedUrl = _formatUrl(rawUrl);

    final imageWidget = CachedNetworkImage(
      imageUrl: formattedUrl,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: httpHeaders ?? const {'ngrok-skip-browser-warning': 'true'},
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
      memCacheWidth: memCacheWidth ?? ((width != null && width! > 0 && width!.isFinite) ? (width! * 2).toInt() : null),
      memCacheHeight: memCacheHeight ?? ((height != null && height! > 0 && height!.isFinite) ? (height! * 2).toInt() : null),
      placeholder: (context, url) {
        if (placeholder != null) return placeholder!;
        return ShimmerImagePlaceholder(
          width: width,
          height: height,
          borderRadius: borderRadius,
          isCircle: isCircle,
          icon: placeholderIcon,
        );
      },
      errorWidget: (context, url, error) {
        if (errorWidget != null) return errorWidget!;
        return _buildFallback(context);
      },
    );

    if (isCircle) {
      return ClipOval(child: imageWidget);
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: Icon(
        placeholderIcon,
        size: (width != null && height != null && width! > 0 && height! > 0)
            ? (width! < height! ? width! * 0.42 : height! * 0.42).clamp(16.0, 36.0)
            : 24,
        color: const Color(0xFF94A3B8),
      ),
    );
  }
}
