import 'package:flutter/material.dart';
import 'package:noli_apps/app/core/widgets/app_shimmer.dart';

/// Skeleton shimmer untuk kartu bahan baku individual
class IngredientCardSkeleton extends StatelessWidget {
  const IngredientCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Identity Row (Icon + Title & Category + Badges)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerBox(width: 38, height: 38, borderRadius: 10),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 120, height: 14, borderRadius: 4),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        ShimmerBox(width: 55, height: 10, borderRadius: 4),
                        SizedBox(width: 6),
                        ShimmerBox(width: 40, height: 12, borderRadius: 3),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const ShimmerBox(width: 52, height: 20, borderRadius: 6),
              const SizedBox(width: 5),
              const ShimmerBox(width: 58, height: 20, borderRadius: 6),
            ],
          ),

          const SizedBox(height: 8),

          // 2. Metric Highlight Box (Stok & Nilai Inventaris)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // Sisi Kiri: Sisa Stok
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 65, height: 10, borderRadius: 3),
                      SizedBox(height: 5),
                      ShimmerBox(width: 80, height: 16, borderRadius: 4),
                      SizedBox(height: 4),
                      ShimmerBox(width: 55, height: 9, borderRadius: 3),
                    ],
                  ),
                ),

                // Divider Vertikal
                Container(
                  width: 1,
                  height: 32,
                  color: const Color(0xFFE2E8F0),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),

                // Sisi Kanan: Valuasi
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 70, height: 10, borderRadius: 3),
                      SizedBox(height: 5),
                      ShimmerBox(width: 85, height: 16, borderRadius: 4),
                      SizedBox(height: 4),
                      ShimmerBox(width: 60, height: 9, borderRadius: 3),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 3. Action Buttons Row (Restock, Opname, More)
          const Row(
            children: [
              Expanded(
                child: ShimmerBox(height: 34, borderRadius: 8),
              ),
              SizedBox(width: 6),
              Expanded(
                child: ShimmerBox(height: 34, borderRadius: 8),
              ),
              SizedBox(width: 6),
              ShimmerBox(width: 34, height: 34, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton shimmer untuk Grid / List Bahan Baku responsif
class IngredientGridSkeleton extends StatelessWidget {
  final int itemCount;

  const IngredientGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1150;
        final isTablet = width >= 750;
        final crossAxisCount = isDesktop ? 3 : 2;

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
                    mainAxisExtent: 198,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) => const IngredientCardSkeleton(),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: itemCount,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => const SizedBox(
                    height: 198,
                    child: IngredientCardSkeleton(),
                  ),
                ),
        );
      },
    );
  }
}

/// Skeleton shimmer untuk Metric KPI Strip di bagian atas
class IngredientMetricsSkeleton extends StatelessWidget {
  const IngredientMetricsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        Widget buildCard({double? cardWidth}) {
          return Container(
            width: cardWidth,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                ShimmerBox(width: 36, height: 36, borderRadius: 8),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ShimmerBox(width: 80, height: 10, borderRadius: 3),
                      SizedBox(height: 5),
                      ShimmerBox(width: 60, height: 16, borderRadius: 4),
                      SizedBox(height: 4),
                      ShimmerBox(width: 90, height: 9, borderRadius: 3),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (isNarrow) {
          return AppShimmer(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: List.generate(
                  4,
                  (index) => Padding(
                    padding: EdgeInsets.only(right: index < 3 ? 10 : 0),
                    child: buildCard(cardWidth: 195),
                  ),
                ),
              ),
            ),
          );
        }

        return AppShimmer(
          child: Row(
            children: [
              Expanded(child: buildCard()),
              const SizedBox(width: 10),
              Expanded(child: buildCard()),
              const SizedBox(width: 10),
              Expanded(child: buildCard()),
              const SizedBox(width: 10),
              Expanded(child: buildCard()),
            ],
          ),
        );
      },
    );
  }
}
