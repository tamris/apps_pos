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
          ? '$openBillsCount Meja Belum Lunas'
          : 'Semua Tagihan Meja Lunas',
      subtitle: openBillsCount > 0
          ? 'Potensi tertunda: ${CurrencyFormatter.format(openBillsPotential)}'
          : 'Tidak ada open bill / tagihan gantung',
      subtitleColor: openBillsCount > 0
          ? const Color(0xFFD97706)
          : const Color(0xFF94A3B8),
      actionText: openBillsCount > 0 ? 'Lihat Meja' : 'Denah',
      actionColor: openBillsCount > 0
          ? AppColors.secondary
          : const Color(0xFF64748B),
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
          ? '$cancellationsCount Pembatalan Nota (Void)'
          : 'Nol Pembatalan Nota (Void)',
      subtitle: cancellationsCount > 0
          ? 'Total nominal: ${CurrencyFormatter.format(cancellationsNominal)}'
          : 'Seluruh transaksi hari ini tercatat valid',
      subtitleColor: cancellationsCount > 0
          ? const Color(0xFFDC2626)
          : const Color(0xFF94A3B8),
      actionText: cancellationsCount > 0 ? 'Audit Void' : 'Riwayat',
      actionColor: cancellationsCount > 0
          ? const Color(0xFFDC2626)
          : const Color(0xFF64748B),
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
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: totalIssues > 0
                      ? const Color(0xFFFFFBEB)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: totalIssues > 0
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      size: 6,
                      color: totalIssues > 0
                          ? const Color(0xFFD97706)
                          : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      totalIssues > 0
                          ? '$totalIssues Isu Perlu Perhatian'
                          : 'Operasional Tertib',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: totalIssues > 0
                            ? const Color(0xFFB45309)
                            : const Color(0xFF047857),
                      ),
                    ),
                  ],
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
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
                        fontSize: 11,
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: actionBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: actionColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: actionColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
