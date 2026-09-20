import 'package:flutter/material.dart';
import 'package:noli_apps/app/core/widgets/app_shimmer.dart';

/// Skeleton shimmer untuk kartu produk individual (tinggi 140px, rounded 14)
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Identity Row (Thumbnail + Name & Category + Menu Action)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Box
              ShimmerBox(width: 48, height: 48, borderRadius: 10),
              SizedBox(width: 12),

              // Name, Category, SKU Badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 130, height: 14, borderRadius: 4),
                    SizedBox(height: 5),
                    ShimmerBox(width: 70, height: 11, borderRadius: 4),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        ShimmerBox(width: 50, height: 15, borderRadius: 4),
                        SizedBox(width: 6),
                        ShimmerBox(width: 45, height: 15, borderRadius: 4),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6),

              // Action button skeleton
              ShimmerBox(width: 32, height: 32, borderRadius: 8),
            ],
          ),

          // 2. Price & Margin Metrics Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Harga Jual & HPP
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 50, height: 10, borderRadius: 3),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      ShimmerBox(width: 85, height: 15, borderRadius: 4),
                      SizedBox(width: 6),
                      ShimmerBox(width: 65, height: 11, borderRadius: 3),
                    ],
                  ),
                ],
              ),

              // Margin Pill
              ShimmerBox(width: 72, height: 24, borderRadius: 20),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton shimmer untuk Grid / List Produk responsif
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const ProductGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWideScreen = width >= 1500;
        final isDesktop = width >= 1100;
        final isTablet = width >= 700;
        final crossAxisCount = isWideScreen ? 4 : (isDesktop ? 3 : 2);

        return AppShimmer(
          child: isTablet
              ? GridView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : 16,
                    vertical: isTablet ? 16 : 14,
                  ),
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 140,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) => const ProductCardSkeleton(),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: itemCount,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => const ProductCardSkeleton(),
                ),
        );
      },
    );
  }
}

/// Skeleton shimmer untuk Strip Metrik Ringkasan Produk atas
class ProductMetricsSkeleton extends StatelessWidget {
  const ProductMetricsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;

          Widget buildCard() {
            return Container(
              width: isNarrow ? 195 : null,
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  ShimmerBox(width: 36, height: 36, borderRadius: 10),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShimmerBox(width: 60, height: 11, borderRadius: 3),
                        SizedBox(height: 5),
                        ShimmerBox(width: 90, height: 16, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (isNarrow) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  buildCard(),
                  const SizedBox(width: 10),
                  buildCard(),
                  const SizedBox(width: 10),
                  buildCard(),
                  const SizedBox(width: 10),
                  buildCard(),
                ],
              ),
            );
          }

          return Row(
            children: [
              Expanded(child: buildCard()),
              const SizedBox(width: 10),
              Expanded(child: buildCard()),
              const SizedBox(width: 10),
              Expanded(child: buildCard()),
              const SizedBox(width: 10),
              Expanded(child: buildCard()),
            ],
          );
        },
      ),
    );
  }
}
