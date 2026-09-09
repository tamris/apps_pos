import 'package:flutter/material.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/data/models/admin_open_bill_model.dart';

class TableBillCard extends StatelessWidget {
  final AdminOpenBillModel bill;
  final VoidCallback onTap;

  const TableBillCard({
    super.key,
    required this.bill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLongStay = bill.elapsedMinutes >= 60;
    final bool isFresh = bill.elapsedMinutes < 30;

    final initials = bill.customerName.isNotEmpty
        ? bill.customerName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'TM';

    final bool hasTable = bill.tableNumber.isNotEmpty && bill.tableNumber != '-';
    final String tableLabel = hasTable
        ? 'MEJA ${bill.tableNumber.toUpperCase()}'
        : 'PESANAN LANGSUNG';

    final String timeDisplay = bill.formattedTime != null && bill.formattedTime!.isNotEmpty && bill.formattedTime != '-'
        ? '${bill.formattedTime} • Duduk ${bill.elapsedMinutes > 0 ? '${bill.elapsedMinutes}m' : 'Baru'}'
        : (bill.elapsedMinutes > 0 ? 'Duduk ${bill.elapsedMinutes}m' : 'Baru Datang');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Table Capsule & Occupancy Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Table Capsule
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasTable ? Icons.table_restaurant_rounded : Icons.takeout_dining_rounded,
                              size: 13,
                              color: const Color(0xFF334155),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                tableLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Occupancy Badge (Friendly stay timer, not panic critical alarm)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Text(
                            'POS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isLongStay
                                ? const Color(0xFFEEF2FF)
                                : (isFresh ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isLongStay
                                  ? const Color(0xFFC7D2FE)
                                  : (isFresh ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLongStay ? Icons.deck_rounded : Icons.access_time_rounded,
                                size: 10.5,
                                color: isLongStay
                                    ? const Color(0xFF4F46E5)
                                    : (isFresh ? const Color(0xFF15803D) : const Color(0xFF475569)),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                timeDisplay,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isLongStay
                                      ? const Color(0xFF4338CA)
                                      : (isFresh ? const Color(0xFF15803D) : const Color(0xFF334155)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Middle Info: Customer & Cashier
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12.5,
                      backgroundColor: const Color(0xFFEEF2FF),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.customerName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            '${bill.invoiceNumber} • Kasir: ${bill.cashierName}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Item Preview Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 11.5,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          (bill.itemsSummary != null && bill.itemsSummary!.isNotEmpty)
                              ? bill.itemsSummary!
                              : '${bill.itemsCount} Menu dinikmati',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Row: Items count, Open Bill Tag & Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${bill.itemsCount} Menu',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Text(
                            'Open Bill',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyFormatter.format(bill.total),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 13,
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
}
