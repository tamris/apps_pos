import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/admin_shift_model.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/theme/app_colors.dart';

class AdminShiftDetailDialog extends StatelessWidget {
  final AdminShiftDetailModel shift;

  const AdminShiftDetailDialog({super.key, required this.shift});

  static void show(BuildContext context, {required AdminShiftDetailModel shift}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => AdminShiftDetailDialog(shift: shift),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 740),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTimelineCard(),
                        const SizedBox(height: 14),
                        _buildReconciliationCard(),
                        const SizedBox(height: 14),
                        _buildPaymentBreakdownCard(),
                        if (shift.notes.trim().isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildNotesCard(),
                        ],
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildFooter(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Header (Clean Cashier Identity & Status)
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    final bool isShortage = shift.isShortage;
    final bool isOpen = shift.isOpen;

    Color iconBg;
    Color iconColor;
    IconData icon;

    if (isOpen) {
      iconBg = const Color(0xFFEEF2FF);
      iconColor = AppColors.secondary;
      icon = Icons.storefront_rounded;
    } else if (isShortage) {
      iconBg = const Color(0xFFFEF2F2);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.warning_amber_rounded;
    } else {
      iconBg = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF059669);
      icon = Icons.verified_outlined;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        shift.cashierName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '#SHF-${shift.id.toString().padLeft(4, '0')}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildDiscrepancyBadge(shift),
                    if (shift.cashierEmail.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shift.cashierEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Timeline Card (Shift Start, End, & Duration)
  // ---------------------------------------------------------------------------
  Widget _buildTimelineCard() {
    final duration = _calculateDuration(shift.startTime, shift.endTime);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 420;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Periode Shift',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        duration,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Waktu Mulai',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDateTime(shift.startTime),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFCBD5E1)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Waktu Selesai',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shift.isOpen ? 'Sedang Berjalan' : _formatDateTime(shift.endTime),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: shift.isOpen ? AppColors.secondary : const Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Waktu Mulai',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDateTime(shift.startTime),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFFCBD5E1)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Waktu Selesai',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      shift.isOpen ? 'Sedang Berjalan' : _formatDateTime(shift.endTime),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: shift.isOpen ? AppColors.secondary : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Reconciliation Card (Audit & Reconciliation)
  // ---------------------------------------------------------------------------
  Widget _buildReconciliationCard() {
    final bool isShortage = shift.isShortage;
    final bool isOverage = shift.isOverage;
    final bool isOpen = shift.isOpen;

    Color bannerBg = const Color(0xFFECFDF5);
    Color bannerBorder = const Color(0xFFA7F3D0);
    Color bannerText = const Color(0xFF065F46);
    Color bannerDescText = const Color(0xFF047857);
    Color badgeBg = const Color(0xFFD1FAE5);
    Color badgeBorder = const Color(0xFF6EE7B7);
    Color badgeText = const Color(0xFF047857);
    String statusTitle = 'Hasil Audit: Kas Fisik Seimbang';
    String statusDesc = 'Jumlah uang fisik di laci kasir cocok persis dengan kalkulasi sistem.';

    Color headerBadgeBg = const Color(0xFFECFDF5);
    Color headerBadgeBorder = const Color(0xFFA7F3D0);
    Color headerBadgeText = const Color(0xFF059669);
    String headerBadgeLabel = 'Kas Pas';

    if (isOpen) {
      bannerBg = const Color(0xFFEEF2FF);
      bannerBorder = const Color(0xFFC7D2FE);
      bannerText = const Color(0xFF3730A3);
      bannerDescText = const Color(0xFF4338CA);
      badgeBg = const Color(0xFFE0E7FF);
      badgeBorder = const Color(0xFFA5B4FC);
      badgeText = const Color(0xFF4338CA);
      statusTitle = 'Shift Masih Aktif';
      statusDesc = 'Penghitungan fisik laci kasir dilakukan saat kasir melakukan Tutup Shift (Z-Report).';
      headerBadgeBg = const Color(0xFFEEF2FF);
      headerBadgeBorder = const Color(0xFFC7D2FE);
      headerBadgeText = const Color(0xFF4F46E5);
      headerBadgeLabel = 'Shift Aktif';
    } else if (isShortage) {
      bannerBg = const Color(0xFFFEF2F2);
      bannerBorder = const Color(0xFFFECACA);
      bannerText = const Color(0xFF991B1B);
      bannerDescText = const Color(0xFFB91C1C);
      badgeBg = const Color(0xFFFEE2E2);
      badgeBorder = const Color(0xFFFCA5A5);
      badgeText = const Color(0xFFB91C1C);
      statusTitle = 'Hasil Audit: Selisih Kurang (Defisit)';
      statusDesc = 'Uang fisik di laci lebih sedikit daripada catatan transaksi sistem.';
      headerBadgeBg = const Color(0xFFFEF2F2);
      headerBadgeBorder = const Color(0xFFFECACA);
      headerBadgeText = const Color(0xFFDC2626);
      headerBadgeLabel = 'Selisih Minus';
    } else if (isOverage) {
      bannerBg = const Color(0xFFFFFBEB);
      bannerBorder = const Color(0xFFFDE68A);
      bannerText = const Color(0xFF92400E);
      bannerDescText = const Color(0xFFB45309);
      badgeBg = const Color(0xFFFEF3C7);
      badgeBorder = const Color(0xFFFCD34D);
      badgeText = const Color(0xFFB45309);
      statusTitle = 'Hasil Audit: Selisih Lebih (Surplus)';
      statusDesc = 'Uang fisik di laci lebih banyak daripada catatan transaksi sistem.';
      headerBadgeBg = const Color(0xFFFFFBEB);
      headerBadgeBorder = const Color(0xFFFDE68A);
      headerBadgeText = const Color(0xFFD97706);
      headerBadgeLabel = 'Selisih Lebih';
    }

    final String diffText = shift.difference == null
        ? ''
        : (shift.difference! == 0
            ? 'Rp 0 (Pas)'
            : (shift.difference! > 0
                ? '+${CurrencyFormatter.format(shift.difference)}'
                : '-${CurrencyFormatter.format(shift.difference!.abs())}'));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Audit & Rekonsiliasi Laci Kasir',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: headerBadgeBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: headerBadgeBorder, width: 0.8),
                  ),
                  child: Text(
                    headerBadgeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: headerBadgeText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Ledger Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLedgerLine(
                  label: 'Modal Awal Kasir (Cash Float)',
                  value: CurrencyFormatter.format(shift.startingCash),
                  valueColor: const Color(0xFF1E293B),
                ),
                const SizedBox(height: 8),
                _buildLedgerLine(
                  label: 'Omzet Penjualan Tunai (+)',
                  value: '+ ${CurrencyFormatter.format(shift.cashSales)}',
                  valueColor: const Color(0xFF059669),
                ),
                const SizedBox(height: 12),

                // Subtotal Box (Ekspektasi Uang Laci)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Ekspektasi Uang Laci (Sistem)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CurrencyFormatter.format(shift.expectedCash),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Hitungan Fisik Aktual Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isOpen ? const Color(0xFFF8FAFC) : const Color(0xFFEEF2FF).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOpen ? const Color(0xFFE2E8F0) : const Color(0xFFC7D2FE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hitungan Fisik Aktual (Kasir)',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              isOpen ? 'Dihitung saat Tutup Shift' : 'Klaim uang fisik oleh kasir',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        shift.actualCash != null
                            ? CurrencyFormatter.format(shift.actualCash)
                            : (shift.isOpen ? 'Sedang Berjalan' : '-'),
                        style: TextStyle(
                          fontSize: shift.actualCash != null ? 13.5 : 12,
                          fontWeight: FontWeight.w700,
                          color: shift.actualCash != null
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Discrepancy Result Banner (Responsive Layout)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bannerBg,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
                  border: Border(top: BorderSide(color: bannerBorder)),
                ),
                child: isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  statusTitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: bannerText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (shift.difference != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: badgeBorder, width: 0.8),
                                  ),
                                  child: Text(
                                    diffText,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: badgeText,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            statusDesc,
                            style: TextStyle(fontSize: 11, color: bannerDescText),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusTitle,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: bannerText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  statusDesc,
                                  style: TextStyle(fontSize: 11, color: bannerDescText),
                                ),
                              ],
                            ),
                          ),
                          if (shift.difference != null) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: badgeBorder, width: 0.8),
                              ),
                              child: Text(
                                diffText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: badgeText,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerLine({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF475569),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Payment Breakdown Card
  // ---------------------------------------------------------------------------
  Widget _buildPaymentBreakdownCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Rincian Pembayaran Shift',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${shift.totalTransactions} Transaksi',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 450;

                if (isNarrow) {
                  return Column(
                    children: [
                      _buildPaymentRow(
                        title: 'Uang Tunai',
                        amount: CurrencyFormatter.format(shift.cashSales),
                        dotColor: const Color(0xFF059669),
                      ),
                      const SizedBox(height: 8),
                      _buildPaymentRow(
                        title: 'QRIS Digital',
                        amount: CurrencyFormatter.format(shift.qrisSales),
                        dotColor: const Color(0xFF4F46E5),
                      ),
                      const SizedBox(height: 8),
                      _buildPaymentRow(
                        title: 'Transfer Bank',
                        amount: CurrencyFormatter.format(shift.transferSales),
                        dotColor: const Color(0xFF0284C7),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildPaymentMiniCard(
                        title: 'Uang Tunai',
                        amount: CurrencyFormatter.format(shift.cashSales),
                        accentColor: const Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPaymentMiniCard(
                        title: 'QRIS Digital',
                        amount: CurrencyFormatter.format(shift.qrisSales),
                        accentColor: const Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPaymentMiniCard(
                        title: 'Transfer Bank',
                        amount: CurrencyFormatter.format(shift.transferSales),
                        accentColor: const Color(0xFF0284C7),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(11)),
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Total Pendapatan Omzet Shift',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  CurrencyFormatter.format(shift.totalSales),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow({
    required String title,
    required String amount,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMiniCard({
    required String title,
    required String amount,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Notes Card
  // ---------------------------------------------------------------------------
  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan Penutupan Kasir:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            shift.notes,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Footer Action
  // ---------------------------------------------------------------------------
  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              backgroundColor: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Widget _buildDiscrepancyBadge(AdminShiftModel s) {
    String label = 'Seimbang';
    Color bg = const Color(0xFFECFDF5);
    Color fg = const Color(0xFF059669);

    if (s.isOpen) {
      label = 'Shift Berjalan';
      bg = const Color(0xFFEEF2FF);
      fg = const Color(0xFF4F46E5);
    } else if (s.isShortage) {
      label = 'Selisih Minus';
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFDC2626);
    } else if (s.isOverage) {
      label = 'Selisih Plus';
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  String _formatDateTime(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dtStr).toLocal();
      return DateFormat('dd MMM, HH:mm').format(dt);
    } catch (_) {
      return dtStr;
    }
  }

  String _calculateDuration(String? startStr, String? endStr) {
    if (startStr == null || startStr.isEmpty) return '-';
    try {
      final start = DateTime.parse(startStr).toLocal();
      final end = endStr != null && endStr.isNotEmpty ? DateTime.parse(endStr).toLocal() : DateTime.now();
      final diff = end.difference(start);
      if (diff.isNegative) return '-';
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      if (hours == 0) return '$minutes mnt';
      return '$hours jam $minutes mnt';
    } catch (_) {
      return '-';
    }
  }
}
