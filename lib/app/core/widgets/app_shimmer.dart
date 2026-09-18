import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Wrapper Shimmer efek skeleton modern dengan warna Slate
class AppShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration period;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1200),
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? const Color(0xFFE2E8F0),
      highlightColor: highlightColor ?? const Color(0xFFF8FAFC),
      period: period,
      child: child,
    );
  }
}

/// Kotak skeleton untuk teks, card, atau elemen UI umum
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isCircle;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.isCircle = false,
    this.shape,
    this.margin,
  });

  const ShimmerBox.circle({
    super.key,
    required double size,
    this.margin,
  })  : width = size,
        height = size,
        borderRadius = 0,
        isCircle = true,
        shape = null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: shape != null
          ? ShapeDecoration(shape: shape!, color: Colors.white)
          : BoxDecoration(
              color: Colors.white,
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
            ),
    );
  }
}

/// Skeleton placeholder khusus gambar dengan siluet ikon lembut di tengah
class ShimmerImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isCircle;
  final IconData? icon;

  const ShimmerImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.isCircle = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(
                icon,
                size: (width != null && height != null)
                    ? (width! < height! ? width! * 0.38 : height! * 0.38).clamp(16.0, 36.0)
                    : 24,
                color: const Color(0xFFCBD5E1),
              )
            : null,
      ),
    );
  }
}
