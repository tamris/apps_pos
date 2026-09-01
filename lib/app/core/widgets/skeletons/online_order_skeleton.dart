import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../app_shimmer.dart';

class OnlineOrderSkeleton extends StatelessWidget {
  final int itemCount;

  const OnlineOrderSkeleton({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1100
            ? 3
            : (constraints.maxWidth >= 650 ? 2 : 1);

        if (crossAxisCount == 1) {
          return AppShimmer(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: _buildCardSkeleton(),
                );
              },
            ),
          );
        }

        return AppShimmer(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: 330,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              return _buildCardSkeleton();
            },
          ),
        );
      },
    );
  }

  Widget _buildCardSkeleton() {
    return Container(
      height: 330,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Table chip, Order No & Status chip
          Row(
            children: [
              ShimmerBox(width: 70, height: 26, borderRadius: 8),
              SizedBox(width: 8),
              ShimmerBox(width: 40, height: 16, borderRadius: 4),
              Spacer(),
              ShimmerBox(width: 100, height: 26, borderRadius: 20),
            ],
          ),
          SizedBox(height: 14),

          // Customer info
          Row(
            children: [
              ShimmerBox(width: 16, height: 16, borderRadius: 8),
              SizedBox(width: 8),
              ShimmerBox(width: 120, height: 14, borderRadius: 4),
              Spacer(),
              ShimmerBox(width: 60, height: 12, borderRadius: 4),
            ],
          ),
          Divider(height: 20),

          // Items list
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    ShimmerBox(width: 24, height: 18, borderRadius: 4),
                    SizedBox(width: 8),
                    ShimmerBox(width: 140, height: 14, borderRadius: 4),
                    Spacer(),
                    ShimmerBox(width: 60, height: 14, borderRadius: 4),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    ShimmerBox(width: 24, height: 18, borderRadius: 4),
                    SizedBox(width: 8),
                    ShimmerBox(width: 110, height: 14, borderRadius: 4),
                    Spacer(),
                    ShimmerBox(width: 50, height: 14, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 16),

          // Footer: Total & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 90, height: 22, borderRadius: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShimmerBox(width: 60, height: 10, borderRadius: 3),
                  SizedBox(height: 4),
                  ShimmerBox(width: 80, height: 16, borderRadius: 4),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),

          // Button
          ShimmerBox(width: double.infinity, height: 42, borderRadius: 10),
        ],
      ),
    );
  }
}
