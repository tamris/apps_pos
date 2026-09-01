import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../app_shimmer.dart';

class ListItemSkeleton extends StatelessWidget {
  final int itemCount;

  const ListItemSkeleton({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: const Row(
              children: [
                ShimmerBox(width: 44, height: 44, borderRadius: 10),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 130, height: 14, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 90, height: 11, borderRadius: 4),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShimmerBox(width: 75, height: 14, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 50, height: 11, borderRadius: 4),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
