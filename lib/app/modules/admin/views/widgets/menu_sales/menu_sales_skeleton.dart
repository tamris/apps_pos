import 'package:flutter/material.dart';
import 'package:noli_apps/app/core/widgets/app_shimmer.dart';

class MenuSalesSkeleton extends StatelessWidget {
  const MenuSalesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= 1100;
          final isTablet = width >= 650;

          if (isTablet) {
            final crossAxisCount = isDesktop ? 3 : 2;
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                mainAxisExtent: 148,
              ),
              itemCount: 6,
              itemBuilder: (_, __) => _buildSkeletonCard(),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => _buildSkeletonCard(),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  ShimmerBox(width: 38, height: 18, borderRadius: 6),
                  SizedBox(width: 6),
                  ShimmerBox(width: 60, height: 18, borderRadius: 5),
                ],
              ),
              const ShimmerBox(width: 70, height: 18, borderRadius: 6),
            ],
          ),
          Row(
            children: [
              const ShimmerBox(width: 42, height: 42, borderRadius: 8),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 120, height: 13, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 160, height: 11, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    ShimmerBox(width: 90, height: 12, borderRadius: 4),
                    ShimmerBox(width: 60, height: 12, borderRadius: 4),
                  ],
                ),
                const SizedBox(height: 5),
                const ShimmerBox(
                  width: double.infinity,
                  height: 3.5,
                  borderRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
