import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin_controller.dart';
import '../../../../data/models/admin_shift_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/skeletons/list_item_skeleton.dart';
import '../widgets/admin_shift_detail_dialog.dart';

class AdminShiftsTab extends GetView<AdminController> {
  const AdminShiftsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Filter bar
        _buildFilterBar(context),

        // 2. Responsive Shifts Grid / List
        Expanded(
          child: Obx(() {
            if (controller.isLoadingShifts.value && controller.shifts.isEmpty) {
              return const ListItemSkeleton();
            }

            if (controller.shifts.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppColors.secondarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.assignment_late_outlined, size: 48, color: AppColors.secondary),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Belum Ada Riwayat Shift',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tidak ada rekaman audit shift kasir yang cocok dengan filter yang Anda pilih.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: AppColors.secondary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () {
                          controller.selectedShiftStatus.value = 'all';
                          controller.selectedShiftDate.value = null;
                          controller.fetchShifts();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Reset Filter', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.secondary,
              onRefresh: () => controller.fetchShifts(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 768;

                  if (isTablet) {
                    final crossAxisCount = constraints.maxWidth >= 1200 ? 3 : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 155,
                      ),
                      itemCount: controller.shifts.length,
                      itemBuilder: (context, i) {
                        final s = controller.shifts[i];
                        return _buildShiftCard(context, s);
                      },
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: controller.shifts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final s = controller.shifts[i];
                      return _buildShiftCard(context, s);
                    },
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Filter Bar
  // ---------------------------------------------------------------------------
  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          Obx(() => Row(
            children: [
              _buildFilterChip('Semua Shift', 'all'),
              const SizedBox(width: 6),
              _buildFilterChip('Ditutup', 'closed'),
              const SizedBox(width: 6),
              _buildFilterChip('Aktif Berjalan', 'open'),
            ],
          )),
          const Spacer(),
          Obx(() {
            final date = controller.selectedShiftDate.value;
            return Material(
              color: date != null ? AppColors.secondarySoft : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.secondary,
                            onPrimary: Colors.white,
                            onSurface: AppColors.textPrimary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    controller.selectedShiftDate.value = DateFormat('yyyy-MM-dd').format(picked);
                    controller.fetchShifts();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: date != null ? AppColors.secondary : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: date != null ? AppColors.secondary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date != null ? _formatFilterDate(date) : 'Pilih Tgl',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: date != null ? AppColors.secondary : AppColors.textSecondary,
                        ),
                      ),
                      if (date != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            controller.selectedShiftDate.value = null;
                            controller.fetchShifts();
                          },
                          child: const Icon(Icons.close_rounded, size: 14, color: AppColors.secondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = controller.selectedShiftStatus.value == value;
    return Material(
      color: isSelected ? AppColors.secondary : AppColors.lightBackground,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          controller.selectedShiftStatus.value = value;
          controller.fetchShifts();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.secondary : AppColors.lightBorder,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shift Card
  // ---------------------------------------------------------------------------
  Widget _buildShiftCard(BuildContext context, AdminShiftModel s) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightBorder, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final detail = await controller.fetchShiftDetail(s.id);
          if (detail != null && context.mounted) {
            AdminShiftDetailDialog.show(context, shift: detail);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header: Kasir Avatar, Nama & Status Badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.secondarySoft,
                    child: Text(
                      s.cashierName.isNotEmpty ? s.cashierName[0].toUpperCase() : 'K',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.cashierName} (Shift #${s.id})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_formatDate(s.startTime)} • ${_formatTime(s.startTime)} - ${_formatTime(s.endTime)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _buildDiscrepancyBadge(s),
                ],
              ),
              const Divider(height: 14),

              // Mini metrics: Modal Awal, Penjualan, Selisih Laci
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem('Modal Awal', CurrencyFormatter.format(s.startingCash)),
                  ),
                  Container(height: 26, width: 1, color: AppColors.lightBorder),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricItem('Total Sales', CurrencyFormatter.format(s.totalSales)),
                  ),
                  Container(height: 26, width: 1, color: AppColors.lightBorder),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricItem(
                      'Selisih Laci',
                      s.difference != null
                          ? (s.difference! > 0
                              ? '+${CurrencyFormatter.format(s.difference)}'
                              : s.difference! < 0
                                  ? '-${CurrencyFormatter.format(s.difference!.abs())}'
                                  : 'Pas (Rp 0)')
                          : (s.isOpen ? 'Sedang Jalan' : '-'),
                      valueColor: _getDiscrepancyColor(s.discrepancyStatus),
                      isBold: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscrepancyBadge(AdminShiftModel s) {
    String text = 'Sesuai (Rp 0)';
    Color bg = AppColors.successSoft;
    Color fg = AppColors.success;

    if (s.isOpen) {
      text = 'BERJALAN';
      bg = AppColors.secondarySoft;
      fg = AppColors.secondary;
    } else if (s.isShortage) {
      text = 'MINUS';
      bg = AppColors.dangerSoft;
      fg = AppColors.danger;
    } else if (s.isOverage) {
      text = 'LEBIH';
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
        text,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Color _getDiscrepancyColor(String status) {
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

  String _formatFilterDate(String dtStr) {
    try {
      final dt = DateTime.parse(dtStr);
      return DateFormat('dd MMM').format(dt);
    } catch (_) {
      return dtStr;
    }
  }

  String _formatDate(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dtStr).toLocal();
      return DateFormat('dd MMM').format(dt);
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
