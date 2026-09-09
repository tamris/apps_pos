import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/data/models/cash_movement_model.dart';

class CashFlowCard extends StatelessWidget {
  final CashMovementModel movement;
  final VoidCallback onTap;

  const CashFlowCard({
    super.key,
    required this.movement,
    required this.onTap,
  });

  String _formatDate(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dtStr).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return 'Hari ini, ${DateFormat('HH:mm').format(dt)}';
      }
      return DateFormat('d MMM, HH:mm').format(dt);
    } catch (_) {
      if (dtStr.length > 17) {
        return dtStr.substring(0, 17);
      }
      return dtStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOut = movement.isOut;
    final amountColor = isOut ? const Color(0xFFDC2626) : const Color(0xFF059669);
    final iconBg = isOut ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5);
    final iconBorder = isOut ? const Color(0xFFFECDD3) : const Color(0xFFA7F3D0);
    final iconColor = isOut ? const Color(0xFFDC2626) : const Color(0xFF059669);

    final dateDisplay = _formatDate(movement.movementDate ?? movement.createdAt);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. TOP BAR: [Direction Badge] + [Source Badge] & [Date/Time]
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDirectionBadge(isOut),
                        const SizedBox(width: 6),
                        _buildSourceBadge(movement),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateDisplay,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // 2. MIDDLE ROW: Big Icon Avatar + Category + Notes
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: iconBorder),
                    ),
                    child: Center(
                      child: Icon(
                        isOut ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: iconColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          movement.categoryName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          movement.notes.isNotEmpty
                              ? movement.notes
                              : (isOut ? 'Pengeluaran operasional toko' : 'Kas masuk toko'),
                          style: TextStyle(
                            fontSize: 12,
                            color: movement.notes.isNotEmpty
                                ? const Color(0xFF475569)
                                : const Color(0xFF94A3B8),
                            height: 1.25,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 3. BOTTOM ROW: Kasir + Nota Badge | Big Bold Nominal Amount
              Container(
                padding: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Cashier & Receipt Badge (Expanded to prevent overflow)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              movement.cashierName,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (movement.hasReceiptImage) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFC7D2FE), width: 0.8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.receipt_long_rounded, size: 10.5, color: AppColors.secondary),
                                  SizedBox(width: 2.5),
                                  Text(
                                    'Nota',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Right: Big Bold Nominal Amount + Chevron
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isOut ? '- ' : '+ '}${CurrencyFormatter.format(movement.amount)}',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: amountColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
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

  Widget _buildDirectionBadge(bool isOut) {
    final bg = isOut ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);
    final border = isOut ? const Color(0xFFFECDD3) : const Color(0xFFA7F3D0);
    final color = isOut ? const Color(0xFFDC2626) : const Color(0xFF059669);
    final label = isOut ? 'Kas Keluar' : 'Kas Masuk';
    final icon = isOut ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge(CashMovementModel movement) {
    final isBank = movement.source == 'bank';
    final Color bg = isBank ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4);
    final Color color = isBank ? const Color(0xFF2563EB) : const Color(0xFF16A34A);
    final Color border = isBank ? const Color(0xFFBFDBFE) : const Color(0xFFBBF7D0);
    final IconData icon = isBank ? Icons.account_balance_rounded : Icons.payments_rounded;
    final String label = isBank ? 'Non-Tunai' : 'Tunai';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
