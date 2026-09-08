import 'package:flutter/material.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/data/models/admin_dashboard_model.dart';

class DashboardOperationsWatchlistCard extends StatelessWidget {
  final AdminDashboardModel data;
  final double? height;
  final VoidCallback onOpenBillsTap;
  final VoidCallback onCancellationsTap;

  const DashboardOperationsWatchlistCard({
    super.key,
    required this.data,
    this.height,
    required this.onOpenBillsTap,
    required this.onCancellationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final int openBillsCount = data.openBillsSummary.count;
    final double openBillsPotential = data.openBillsSummary.potentialRevenue;
    final int cancellationsCount = data.cancellationsSummary.count;
    final double cancellationsNominal = data.cancellationsSummary.totalNominal;
    final int totalIssues = openBillsCount + cancellationsCount;

    final Widget openBillsTile = _buildOperationActionTile(
      icon: Icons.table_restaurant_outlined,
      iconBg: openBillsCount > 0
          ? const Color(0xFFFEF3C7)
          : const Color(0xFFF1F5F9),
      iconColor: openBillsCount > 0
          ? const Color(0xFFD97706)
          : const Color(0xFF64748B),
      title: openBillsCount > 0
          ? '$openBillsCount Meja Belum Bayar'
          : 'Semua Tagihan Selesai',
      subtitle: openBillsCount > 0
          ? 'Tertunda: ${CurrencyFormatter.format(openBillsPotential)}'
          : 'Tidak ada tagihan meja gantung',
      subtitleColor: openBillsCount > 0
          ? const Color(0xFFD97706)
          : const Color(0xFF64748B),
      actionText: openBillsCount > 0 ? 'Lihat Meja' : 'Denah',
      actionColor: openBillsCount > 0
          ? AppColors.secondary
          : const Color(0xFF475569),
      actionBg: openBillsCount > 0
          ? const Color(0xFFEEF2FF)
          : const Color(0xFFF1F5F9),
      cardBg: openBillsCount > 0
          ? const Color(0xFFFFFDF5)
          : const Color(0xFFF8FAFC),
      borderColor: openBillsCount > 0
          ? const Color(0xFFFDE68A)
          : const Color(0xFFE2E8F0),
      onTap: onOpenBillsTap,
    );

    final Widget cancellationsTile = _buildOperationActionTile(
      icon: cancellationsCount > 0
          ? Icons.delete_sweep_outlined
          : Icons.verified_outlined,
      iconBg: cancellationsCount > 0
          ? const Color(0xFFFEE2E2)
          : const Color(0xFFF1F5F9),
      iconColor: cancellationsCount > 0
          ? const Color(0xFFDC2626)
          : const Color(0xFF64748B),
      title: cancellationsCount > 0
          ? '$cancellationsCount Pembatalan (Void)'
          : 'Pembatalan (Void)',
      subtitle: cancellationsCount > 0
          ? 'Total nominal: ${CurrencyFormatter.format(cancellationsNominal)}'
          : 'Tidak ada nota dibatalkan',
      subtitleColor: cancellationsCount > 0
          ? const Color(0xFFDC2626)
          : const Color(0xFF64748B),
      actionText: cancellationsCount > 0 ? 'Audit Void' : 'Riwayat',
      actionColor: cancellationsCount > 0
          ? const Color(0xFFDC2626)
          : const Color(0xFF475569),
      actionBg: cancellationsCount > 0
          ? const Color(0xFFFEF2F2)
          : const Color(0xFFF1F5F9),
      cardBg: cancellationsCount > 0
          ? const Color(0xFFFFFBFB)
          : const Color(0xFFF8FAFC),
      borderColor: cancellationsCount > 0
          ? const Color(0xFFFECACA)
          : const Color(0xFFE2E8F0),
      onTap: onCancellationsTap,
    );

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Pengawasan Operasional',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: totalIssues > 0
                      ? const Color(0xFFFFFBEB)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: totalIssues > 0
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  totalIssues > 0
                      ? '$totalIssues Perhatian'
                      : 'Tertib',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: totalIssues > 0
                        ? const Color(0xFFB45309)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),

          // Two Action Tiles filling available space
          if (height != null) ...[
            const SizedBox(height: 12),
            Expanded(child: openBillsTile),
            const SizedBox(height: 10),
            Expanded(child: cancellationsTile),
          ] else ...[
            const SizedBox(height: 12),
            openBillsTile,
            const SizedBox(height: 10),
            cancellationsTile,
          ],
        ],
      ),
    );
  }

  Widget _buildOperationActionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required String actionText,
    required Color actionColor,
    required Color actionBg,
    required Color cardBg,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: subtitleColor,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: actionBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  actionText,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: actionColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
