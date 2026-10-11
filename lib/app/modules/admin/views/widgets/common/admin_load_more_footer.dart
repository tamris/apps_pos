import 'package:flutter/material.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';

/// Reusable load more footer indicator for Admin tabs,
/// matching the exact visual aesthetics and behavior of POS "Riwayat Transaksi Hari Ini".
class AdminLoadMoreFooter extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;
  final int itemCount;
  final int threshold;
  final String itemName;

  const AdminLoadMoreFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
    required this.itemCount,
    this.threshold = 20,
    required this.itemName,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Memuat $itemName berikutnya...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!hasMore && itemCount >= threshold) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Semua $itemName telah ditampilkan',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return const SizedBox(height: 16);
  }
}
