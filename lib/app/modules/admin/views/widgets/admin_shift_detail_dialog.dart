import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/admin_shift_model.dart';
import '../../../../core/utils/currency_formatter.dart';

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                  blurRadius: 36,
                  offset: const Offset(0, 14),
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
  // 1. Header (Cashier Identity & Status)
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context) {
    final initials = shift.cashierName.isNotEmpty
        ? shift.cashierName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'KS';

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shift.cashierName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
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
                          fontSize: 10.5,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _buildDiscrepancyBadge(shift),
                    if (shift.cashierEmail.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '• ${shift.cashierEmail}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF8FAFC),
              hoverColor: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Timeline Card (Shift Start, End, & Total Duration)
  // ---------------------------------------------------------------------------
  Widget _buildTimelineCard() {
    final duration = _calculateDuration(shift.startTime, shift.endTime);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;

        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF4F46E5)),
                          ),
                          const SizedBox(width: 7),
                          const Expanded(
                            child: Text(
                              'PERIODE SHIFT',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, size: 10.5, color: Color(0xFF4F46E5)),
                          const SizedBox(width: 3),
                          Text(
                            duration,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                          ),
                        ],
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
                          const Text('WAKTU MULAI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 1),
                          Text(
                            _formatDateTime(shift.startTime),
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF94A3B8)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('WAKTU SELESAI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 1),
                          Text(
                            shift.isOpen ? 'Sedang Berjalan' : _formatDateTime(shift.endTime),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: shift.isOpen ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('WAKTU MULAI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 1),
                          Text(
                            _formatDateTime(shift.startTime),
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF94A3B8)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('WAKTU SELESAI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 1),
                          Text(
                            shift.isOpen ? 'Sedang Berjalan' : _formatDateTime(shift.endTime),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: shift.isOpen ? const Color(0xFF4F46E5) : const Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 11, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 3),
                    Text(
                      duration,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Reconciliation Card (Audit & Discrepancy Reconciliation)
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
    IconData bannerIcon = Icons.check_circle_rounded;
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
      bannerIcon = Icons.sync_rounded;
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
      bannerIcon = Icons.warning_amber_rounded;
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
      bannerIcon = Icons.info_outline_rounded;
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined, size: 14, color: Color(0xFF4F46E5)),
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Text(
                    'Audit & Rekonsiliasi Laci Kasir',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
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
                      fontSize: 10.5,
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
                // 1. Kas Masuk (Komponen Sistem)
                _buildCleanLedgerRow(
                  icon: Icons.login_rounded,
                  iconColor: const Color(0xFF64748B),
                  iconBg: const Color(0xFFF1F5F9),
                  label: 'Modal Awal Kasir (Cash Float)',
                  value: CurrencyFormatter.format(shift.startingCash),
                  valueColor: const Color(0xFF1E293B),
                ),
                const SizedBox(height: 8),
                _buildCleanLedgerRow(
                  icon: Icons.add_rounded,
                  iconColor: const Color(0xFF059669),
                  iconBg: const Color(0xFFECFDF5),
                  label: 'Omzet Penjualan Tunai (+)',
                  value: '+ ${CurrencyFormatter.format(shift.cashSales)}',
                  valueColor: const Color(0xFF059669),
                ),
                const SizedBox(height: 10),

                // 2. Ekspektasi Uang Laci (Sistem) - Highlighted Subtotal
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calculate_outlined, size: 14, color: Color(0xFF334155)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Ekspektasi Uang Laci (Sistem)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CurrencyFormatter.format(shift.expectedCash),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 3. Hitungan Fisik Aktual (Kasir) - Comparison Block
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isOpen ? const Color(0xFFF8FAFC) : const Color(0xFFEEF2FF).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOpen ? const Color(0xFFE2E8F0) : const Color(0xFFC7D2FE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isOpen ? const Color(0xFFF1F5F9) : const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.payments_outlined,
                          size: 14,
                          color: isOpen ? const Color(0xFF64748B) : const Color(0xFF4F46E5),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hitungan Fisik Aktual (Kasir)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              isOpen ? 'Dihitung saat Tutup Shift' : 'Klaim uang fisik oleh kasir',
                              style: const TextStyle(
                                fontSize: 10,
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
                          fontSize: shift.actualCash != null ? 13 : 11,
                          fontWeight: FontWeight.w800,
                          color: shift.actualCash != null
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                          fontFamily: shift.actualCash != null ? 'monospace' : null,
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: bannerBg,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
                  border: Border(top: BorderSide(color: bannerBorder)),
                ),
                child: isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(bannerIcon, size: 17, color: bannerText),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  statusTitle,
                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: bannerText),
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
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'monospace',
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
                            style: TextStyle(fontSize: 10, color: bannerDescText),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(bannerIcon, size: 18, color: bannerText),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusTitle,
                                  style: TextStyle(fontSize: 11.8, fontWeight: FontWeight.w700, color: bannerText),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  statusDesc,
                                  style: TextStyle(fontSize: 10.2, color: bannerDescText),
                                ),
                              ],
                            ),
                          ),
                          if (shift.difference != null) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: badgeBorder, width: 0.8),
                              ),
                              child: Text(
                                diffText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
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

  Widget _buildCleanLedgerRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, size: 12, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
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
            fontSize: 11.8,
            fontWeight: FontWeight.w600,
            color: valueColor,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Payment Breakdown Card (Adaptive: 3 Columns on Desktop, List on Mobile)
  // ---------------------------------------------------------------------------
  Widget _buildPaymentBreakdownCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.pie_chart_outline_rounded, size: 14, color: Color(0xFF4F46E5)),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Rincian Pembayaran Shift',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '${shift.totalTransactions} Transaksi',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
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
                      _buildPaymentHorizontalRow(
                        icon: Icons.payments_outlined,
                        iconColor: const Color(0xFF059669),
                        iconBg: const Color(0xFFECFDF5),
                        title: 'Uang Tunai',
                        amount: CurrencyFormatter.format(shift.cashSales),
                      ),
                      const SizedBox(height: 6),
                      _buildPaymentHorizontalRow(
                        icon: Icons.qr_code_scanner_rounded,
                        iconColor: const Color(0xFF4F46E5),
                        iconBg: const Color(0xFFEEF2FF),
                        title: 'QRIS Digital',
                        amount: CurrencyFormatter.format(shift.qrisSales),
                      ),
                      const SizedBox(height: 6),
                      _buildPaymentHorizontalRow(
                        icon: Icons.account_balance_outlined,
                        iconColor: const Color(0xFF0284C7),
                        iconBg: const Color(0xFFF0F9FF),
                        title: 'Transfer Bank',
                        amount: CurrencyFormatter.format(shift.transferSales),
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildPaymentMiniCard(
                        icon: Icons.payments_outlined,
                        iconColor: const Color(0xFF059669),
                        iconBg: const Color(0xFFECFDF5),
                        title: 'Uang Tunai',
                        amount: CurrencyFormatter.format(shift.cashSales),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPaymentMiniCard(
                        icon: Icons.qr_code_scanner_rounded,
                        iconColor: const Color(0xFF4F46E5),
                        iconBg: const Color(0xFFEEF2FF),
                        title: 'QRIS Digital',
                        amount: CurrencyFormatter.format(shift.qrisSales),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPaymentMiniCard(
                        icon: Icons.account_balance_outlined,
                        iconColor: const Color(0xFF0284C7),
                        iconBg: const Color(0xFFF0F9FF),
                        title: 'Transfer Bank',
                        amount: CurrencyFormatter.format(shift.transferSales),
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
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(13)),
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Total Pendapatan Omzet Shift',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  CurrencyFormatter.format(shift.totalSales),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4F46E5),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHorizontalRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String amount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(5)),
            child: Icon(icon, size: 13, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMiniCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String amount,
  }) {
    return Container(
      padding: const EdgeInsets.all(9),
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
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(5)),
                child: Icon(icon, size: 13, color: iconColor),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Notes Card (Cashier Shift Notes)
  // ---------------------------------------------------------------------------
  Widget _buildNotesCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2_outlined, size: 15, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan Penutupan Kasir:',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 2),
                Text(
                  shift.notes,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B), fontStyle: FontStyle.italic),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              backgroundColor: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tutup', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
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
    IconData icon = Icons.check_circle_rounded;

    if (s.isOpen) {
      label = 'Shift Berjalan';
      bg = const Color(0xFFEEF2FF);
      fg = const Color(0xFF4F46E5);
      icon = Icons.bolt_rounded;
    } else if (s.isShortage) {
      label = 'Selisih Minus';
      bg = const Color(0xFFFEF2F2);
      fg = const Color(0xFFDC2626);
      icon = Icons.warning_rounded;
    } else if (s.isOverage) {
      label = 'Selisih Plus';
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFFD97706);
      icon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
          ),
        ],
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
