import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/data/models/admin_shift_model.dart';

class ShiftCard extends StatelessWidget {
  final AdminShiftModel shift;
  final VoidCallback onTap;

  const ShiftCard({
    super.key,
    required this.shift,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final startTimeStr = _formatTime(shift.startTime);
    final endTimeStr = shift.isOpen ? 'Sekarang' : _formatTime(shift.endTime);
    final durationStr = _computeDuration(shift.startTime, shift.endTime, shift.isOpen);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: shift.isOpen
              ? AppColors.secondary.withValues(alpha: 0.35)
              : (shift.isShortage ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: shift.isOpen
                ? AppColors.secondary.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Cashier Profile & Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: shift.isOpen ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        shift.cashierName.isNotEmpty ? shift.cashierName[0].toUpperCase() : 'K',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: shift.isOpen ? AppColors.secondary : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  shift.cashierName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${shift.id}',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 11,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 3.5),
                              Flexible(
                                child: Text(
                                  '${_formatDate(shift.startTime)} • $startTimeStr - $endTimeStr ${durationStr.isNotEmpty ? "($durationStr)" : ""}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildDiscrepancyBadge(shift),
                  ],
                ),

                const SizedBox(height: 8),

                // Financial Ledger Box (3 Metrics: Modal Awal, Penjualan, Kas Fisik)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      // Modal Awal
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MODAL AWAL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(shift.startingCash),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                      const SizedBox(width: 8),

                      // Total Penjualan
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL OMZET',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                CurrencyFormatter.format(shift.totalSales),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                      const SizedBox(width: 8),

                      // Uang Fisik Laci
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KAS FISIK LACI',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                shift.actualCash != null
                                    ? CurrencyFormatter.format(shift.actualCash)
                                    : (shift.isOpen ? 'Sedang Jalan' : '-'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: shift.actualCash != null
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Bottom Row: Volume Struk & Z-Report Action Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_long_rounded,
                            size: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${shift.totalTransactions} Transaksi',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Detail Z-Report',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscrepancyBadge(AdminShiftModel s) {
    if (s.isOpen) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fiber_manual_record, size: 6, color: AppColors.secondary),
            SizedBox(width: 4),
            Text(
              'Aktif',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      );
    }

    if (s.isShortage) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_downward_rounded, size: 10, color: Color(0xFFDC2626)),
            const SizedBox(width: 2),
            Text(
              'Minus ${CurrencyFormatter.format(s.difference?.abs() ?? 0)}',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      );
    }

    if (s.isOverage) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_upward_rounded, size: 10, color: Color(0xFFD97706)),
            const SizedBox(width: 2),
            Text(
              'Lebih ${CurrencyFormatter.format(s.difference ?? 0)}',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD97706),
              ),
            ),
          ],
        ),
      );
    }

    // Balanced / Pas
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded, size: 11, color: Color(0xFF047857)),
          SizedBox(width: 3),
          Text(
            'Kas Pas (Rp 0)',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }

  String _computeDuration(String? startStr, String? endStr, bool isOpen) {
    if (startStr == null || startStr.isEmpty) return '';
    try {
      final start = DateTime.parse(startStr).toLocal();
      final end = (endStr != null && endStr.isNotEmpty)
          ? DateTime.parse(endStr).toLocal()
          : (isOpen ? DateTime.now() : null);
      if (end == null) return '';
      final diff = end.difference(start);
      if (diff.isNegative) return '';
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (hours > 0) {
        return '${hours}j ${minutes}m';
      }
      return '${minutes}m';
    } catch (_) {
      return '';
    }
  }

  String _formatDate(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dtStr).toLocal();
      return DateFormat('d MMM').format(dt);
    } catch (_) {
      return dtStr;
    }
  }

  String _formatTime(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return 'Aktif';
    try {
      final dt = DateTime.parse(dtStr).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return dtStr;
    }
  }
}
