import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'package:noli_apps/app/data/models/admin_transaction_model.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import '../admin_transaction_detail_dialog.dart';
import '../admin_void_dialog.dart';

class DashboardRecentActivitySection extends GetView<AdminController> {
  final double availableWidth;

  const DashboardRecentActivitySection({
    super.key,
    required this.availableWidth,
  });

  String _formatTime(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dtStr).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return dtStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = availableWidth >= 860;
    final isTablet = availableWidth >= 640;

    return Obx(() {
      final list = controller.dashboardRecentTransactions;
      final displayList = list.take(6).toList();
      final isToday = controller.selectedDashboardDate.value ==
          DateFormat('yyyy-MM-dd').format(DateTime.now());

      return Container(
        padding: const EdgeInsets.all(18),
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
            // Section Header
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          availableWidth < 480
                              ? 'Aktivitas Transaksi'
                              : (isToday
                                  ? 'Aktivitas Transaksi Hari Ini'
                                  : 'Aktivitas Transaksi (${controller.selectedDashboardDate.value})'),
                          style: const TextStyle(
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
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          availableWidth < 400
                              ? '${list.length}'
                              : '${list.length} Transaksi',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => controller.switchTab(1),
                  iconAlignment: IconAlignment.end,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                  label: Text(
                    isTablet ? 'Riwayat Lengkap' : 'Semua',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (controller.isLoadingDashboardRecentTrx.value && list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.secondary,
                  ),
                ),
              )
            else if (displayList.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: const [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 28,
                      color: Color(0xFF94A3B8),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Belum ada transaksi pada periode ini',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Transaksi yang masuk akan tampil di sini secara otomatis.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              )
            else ...[
              // Unified Table Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Tablet & Desktop Header
                    if (isTablet)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 58,
                              child: Text(
                                'WAKTU',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 3,
                              child: Text(
                                'INVOICE & PELANGGAN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'TIPE PESANAN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            if (isDesktop)
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'METODE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            const Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  'STATUS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Text(
                                'TOTAL',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),
                      ),

                    // Rows List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayList.length,
                      separatorBuilder: (context, i) =>
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, i) {
                        final tx = displayList[i];
                        final isDineIn = tx.orderType == 'dine_in';

                        return InkWell(
                          hoverColor: const Color(0xFFF8FAFC),
                          onTap: () async {
                            final fullTrx =
                                await controller.fetchTransactionDetail(
                                  tx.id,
                                ) ??
                                tx;
                            if (context.mounted) {
                              AdminTransactionDetailDialog.show(
                                context,
                                transaction: fullTrx,
                                onVoidPressed: () => AdminVoidDialog.show(
                                  context,
                                  transaction: fullTrx,
                                  onConfirmVoid: (reason) => controller
                                      .voidTransaction(fullTrx.id, reason),
                                ),
                              );
                            }
                          },
                          child: isTablet
                              ? _buildTabletRow(tx, isDineIn, isDesktop)
                              : _buildMobileRow(tx, isDineIn),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildTabletRow(
    AdminTransactionModel tx,
    bool isDineIn,
    bool isDesktop,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      child: Row(
        children: [
          // 1. Waktu
          SizedBox(
            width: 58,
            child: Text(
              _formatTime(tx.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 2. Invoice & Pelanggan
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.invoiceNumber,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tx.isCancelled
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0F172A),
                    decoration: tx.isCancelled
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 2),
                Text(
                  tx.isSelfOrder
                      ? '${tx.customerName.isNotEmpty ? tx.customerName : "Pelanggan"} • Online (Self-Order)'
                      : '${tx.customerName.isNotEmpty ? tx.customerName : "Pelanggan Umum"} • Kasir: ${tx.cashierName}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          // 3. Tipe Pesanan Pill
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildOrderTypeBadge(tx, isDineIn),
            ),
          ),

          // 4. Metode Pill
          if (isDesktop)
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildPaymentMethodBadge(tx.paymentMethod),
              ),
            ),

          // 5. Status Pill
          Expanded(flex: 2, child: Center(child: _buildCleanStatus(tx))),

          // 6. Total
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CurrencyFormatter.format(tx.total),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: tx.isCancelled
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0F172A),
                    decoration: tx.isCancelled
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (!isDesktop) ...[
                  const SizedBox(height: 2),
                  Text(
                    tx.paymentMethod.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 7. Chevron
          const SizedBox(
            width: 20,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeBadge(AdminTransactionModel tx, bool isDineIn) {
    if (tx.isSelfOrder) {
      final isTable =
          tx.tableNumber != null && tx.tableNumber!.isNotEmpty;
      final label = isTable
          ? 'Online • Meja ${tx.tableNumber}'
          : (tx.orderType == 'takeaway' ? 'Online (Takeaway)' : 'Online');

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4338CA),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final isTable =
        isDineIn && tx.tableNumber != null && tx.tableNumber!.isNotEmpty;
    final label = isTable
        ? 'Meja ${tx.tableNumber}'
        : (isDineIn ? 'Dine-in' : 'Takeaway');
    final bg = isDineIn ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);
    final textCol = isDineIn
        ? const Color(0xFF047857)
        : const Color(0xFFB45309);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: textCol,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPaymentMethodBadge(String method) {
    final m = method.toLowerCase();
    Color bg = const Color(0xFFF1F5F9);
    Color textCol = const Color(0xFF475569);

    if (m.contains('cash') || m.contains('tunai')) {
      bg = const Color(0xFFF1F5F9);
      textCol = const Color(0xFF334155);
    } else if (m.contains('qris')) {
      bg = const Color(0xFFEEF2FF);
      textCol = AppColors.secondary;
    } else if (m.contains('transfer') || m.contains('bank')) {
      bg = const Color(0xFFF0F9FF);
      textCol = const Color(0xFF0284C7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textCol,
        ),
      ),
    );
  }

  Widget _buildMobileRow(AdminTransactionModel tx, bool isDineIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.invoiceNumber,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tx.isCancelled
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF0F172A),
                        decoration: tx.isCancelled
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatTime(tx.createdAt)} • ${tx.customerName.isNotEmpty ? tx.customerName : "Pelanggan Umum"}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(tx.total),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: tx.isCancelled
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF0F172A),
                      decoration: tx.isCancelled
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _buildCleanStatus(tx),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildOrderTypeBadge(tx, isDineIn),
              const SizedBox(width: 6),
              _buildPaymentMethodBadge(tx.paymentMethod),
              const SizedBox(width: 6),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    tx.isSelfOrder ? 'Online' : 'Kasir: ${tx.cashierName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: Color(0xFFCBD5E1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCleanStatus(AdminTransactionModel tx) {
    if (tx.isCancelled) {
      final isExpired =
          tx.cancelledInfo?.cancelledReason.toLowerCase().contains('kadaluarsa') == true ||
          (tx.isSelfOrder && (tx.paymentStatus.toLowerCase() == 'failed' || tx.paid == 0));

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isExpired ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          isExpired ? 'Kadaluarsa' : 'Batal',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isExpired ? const Color(0xFFEA580C) : const Color(0xFFDC2626),
          ),
        ),
      );
    }
    if (tx.isPending) {
      if (tx.isSelfOrder) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Menunggu Bayar',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEA580C),
            ),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Open Bill',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD97706),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Selesai',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF047857),
        ),
      ),
    );
  }
}
