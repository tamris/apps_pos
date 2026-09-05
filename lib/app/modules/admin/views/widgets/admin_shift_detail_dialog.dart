import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/admin_shift_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

class AdminShiftDetailDialog extends StatelessWidget {
  final AdminShiftDetailModel shift;

  const AdminShiftDetailDialog({super.key, required this.shift});

  static void show(BuildContext context, {required AdminShiftDetailModel shift}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AdminShiftDetailDialog(shift: shift),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.secondarySoft,
                      child: const Icon(Icons.point_of_sale_rounded, color: AppColors.secondary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Shift #${shift.id} - ${shift.cashierName}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(shift),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shift.cashierEmail.isNotEmpty ? shift.cashierEmail : 'Kasir Toko',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Content scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Waktu Shift
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.lightBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 18, color: AppColors.secondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Mulai: ${_formatDateTime(shift.startTime)}  ➔  Selesai: ${_formatDateTime(shift.endTime)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 1: Ringkasan Penjualan & Laci Kasir
                        const Text(
                          'Audit Laci Kasir (Cash Discrepancy)',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _getDiscrepancyBgColor(shift.discrepancyStatus),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _getDiscrepancyBorderColor(shift.discrepancyStatus)),
                          ),
                          child: Column(
                            children: [
                              _buildRowItem('Modal Awal (Cash Awal)', CurrencyFormatter.format(shift.startingCash)),
                              _buildRowItem('Penjualan Tunai (+)', CurrencyFormatter.format(shift.cashSales)),
                              const Divider(height: 16),
                              _buildRowItem(
                                'Estimasi Uang Sistem (Expected)',
                                CurrencyFormatter.format(shift.expectedCash),
                                isBold: true,
                              ),
                              _buildRowItem(
                                'Hitungan Fisik Kasir (Actual)',
                                shift.actualCash != null ? CurrencyFormatter.format(shift.actualCash) : 'Belum Ditutup',
                                isBold: true,
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Selisih Laci (Difference)',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    shift.difference != null
                                        ? (shift.difference! > 0
                                            ? '+${CurrencyFormatter.format(shift.difference)} (Lebih)'
                                            : shift.difference! < 0
                                                ? '-${CurrencyFormatter.format(shift.difference!.abs())} (Kurang)'
                                                : 'Rp 0 (Pas/Seimbang)')
                                        : (shift.isOpen ? 'Sedang Berjalan' : '-'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _getDiscrepancyTextColor(shift.discrepancyStatus),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 2: Breakdown Metode Pembayaran
                        const Text(
                          'Total Omset per Metode Pembayaran',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.lightBorder),
                          ),
                          child: Column(
                            children: [
                              _buildRowItem('Uang Tunai (Cash)', CurrencyFormatter.format(shift.cashSales)),
                              _buildRowItem('QRIS Digital', CurrencyFormatter.format(shift.qrisSales)),
                              _buildRowItem('Transfer Bank', CurrencyFormatter.format(shift.transferSales)),
                              const Divider(height: 16),
                              _buildRowItem(
                                'Total Penjualan (${shift.totalTransactions} transaksi)',
                                CurrencyFormatter.format(shift.totalSales),
                                isBold: true,
                                valueColor: AppColors.secondary,
                              ),
                            ],
                          ),
                        ),

                        if (shift.notes.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Catatan Kasir:',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              shift.notes,
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Section 3: Daftar Transaksi dalam Shift
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Transaksi dalam Shift Ini',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              '${shift.transactions.length} transaksi',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (shift.transactions.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Belum ada transaksi pada shift ini.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: shift.transactions.length,
                            separatorBuilder: (context, i) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final item = shift.transactions[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.status == 'cancelled'
                                          ? Icons.cancel_outlined
                                          : Icons.check_circle_outline_rounded,
                                      color: item.status == 'cancelled' ? AppColors.danger : AppColors.success,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.invoiceNumber,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              decoration: item.status == 'cancelled'
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                          Text(
                                            '${item.orderType.toUpperCase()} • ${item.paymentMethod.toUpperCase()}',
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(item.total),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: item.status == 'cancelled' ? AppColors.textMuted : AppColors.textPrimary,
                                        decoration: item.status == 'cancelled'
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRowItem(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(AdminShiftModel s) {
    String label = 'Selesai';
    Color bg = AppColors.successSoft;
    Color fg = AppColors.success;

    if (s.isOpen) {
      label = 'Sedang Berjalan';
      bg = AppColors.secondarySoft;
      fg = AppColors.secondary;
    } else if (s.isShortage) {
      label = 'Selisih Minus';
      bg = AppColors.dangerSoft;
      fg = AppColors.danger;
    } else if (s.isOverage) {
      label = 'Selisih Lebih';
      bg = AppColors.warningSoft;
      fg = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Color _getDiscrepancyBgColor(String status) {
    switch (status) {
      case 'shortage':
        return AppColors.dangerSoft.withValues(alpha: 0.6);
      case 'overage':
        return AppColors.warningSoft.withValues(alpha: 0.6);
      case 'in_progress':
        return AppColors.secondarySoft.withValues(alpha: 0.6);
      case 'balanced':
      default:
        return AppColors.successSoft.withValues(alpha: 0.6);
    }
  }

  Color _getDiscrepancyBorderColor(String status) {
    switch (status) {
      case 'shortage':
        return AppColors.danger.withValues(alpha: 0.3);
      case 'overage':
        return AppColors.warning.withValues(alpha: 0.3);
      case 'in_progress':
        return AppColors.secondary.withValues(alpha: 0.3);
      case 'balanced':
      default:
        return AppColors.success.withValues(alpha: 0.3);
    }
  }

  Color _getDiscrepancyTextColor(String status) {
    switch (status) {
      case 'shortage':
        return AppColors.danger;
      case 'overage':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.secondary;
      case 'balanced':
      default:
        return AppColors.success;
    }
  }

  String _formatDateTime(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dtStr).toLocal();
      return DateFormat('dd MMM HH:mm').format(dt);
    } catch (_) {
      return dtStr;
    }
  }
}
