import 'package:flutter/material.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/data/models/admin_open_bill_model.dart';

class OnlineOrderCard extends StatelessWidget {
  final AdminOpenBillModel bill;
  final VoidCallback onTap;

  const OnlineOrderCard({
    super.key,
    required this.bill,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnpaid = !bill.isPaid;
    final bool hasTable = bill.tableNumber.isNotEmpty && bill.tableNumber != '-';
    final String tableLabel = hasTable
        ? 'MEJA ${bill.tableNumber.toUpperCase()}'
        : 'ONLINE (TANPA MEJA)';

    final initials = bill.customerName.isNotEmpty
        ? bill.customerName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'SO';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnpaid ? const Color(0xFFFDBA74) : const Color(0xFFE2E8F0),
          width: isUnpaid ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnpaid
                ? const Color(0xFFEA580C).withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: isUnpaid ? 8 : 4,
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
                // Top Row: Table / Order Origin Capsule & Payment/Kitchen Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Table / Online Capsule
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFC7D2FE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasTable ? Icons.table_restaurant_rounded : Icons.phonelink_ring_rounded,
                              size: 13,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                tableLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF312E81),
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

                    // Payment & Kitchen Timer Badge
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isUnpaid)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFFFED7AA)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.hourglass_top_rounded, size: 10, color: Color(0xFFC2410C)),
                                SizedBox(width: 3),
                                Text(
                                  'Belum Bayar',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFC2410C),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded, size: 10, color: Color(0xFF047857)),
                                const SizedBox(width: 3),
                                Text(
                                  bill.status.toLowerCase() == 'ready'
                                      ? 'Siap'
                                      : (bill.status.toLowerCase() == 'processing' ? 'Dimasak' : 'Lunas'),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            bill.elapsedMinutes > 0 ? '${bill.elapsedMinutes}m' : 'Baru',
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Middle Info: Customer & Order Source
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
                            '${bill.invoiceNumber} • Self-Order QRIS',
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
                              : '${bill.itemsCount} Menu dipesan',
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

                // Bottom Row: Items count, Payment Status Tag & Total
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
                            color: isUnpaid ? const Color(0xFFFFF7ED) : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isUnpaid ? const Color(0xFFFED7AA) : const Color(0xFFA7F3D0),
                            ),
                          ),
                          child: Text(
                            isUnpaid ? 'Belum Bayar' : 'Lunas',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isUnpaid ? const Color(0xFFC2410C) : const Color(0xFF047857),
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
