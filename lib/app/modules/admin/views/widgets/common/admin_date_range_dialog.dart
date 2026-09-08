import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';

class AdminDateRangeDialog extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final String title;
  final String subtitle;

  const AdminDateRangeDialog({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    this.title = 'Pilih Rentang Tanggal',
    this.subtitle = 'Tentukan periode laporan transaksi & menu',
  });

  static Future<DateTimeRange?> show(
    BuildContext context, {
    required DateTime initialStartDate,
    required DateTime initialEndDate,
    String title = 'Pilih Rentang Tanggal',
    String subtitle = 'Tentukan periode laporan transaksi & menu',
  }) {
    return showDialog<DateTimeRange>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AdminDateRangeDialog(
        initialStartDate: initialStartDate,
        initialEndDate: initialEndDate,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<AdminDateRangeDialog> createState() => _AdminDateRangeDialogState();
}

class _AdminDateRangeDialogState extends State<AdminDateRangeDialog> {
  late DateTime _startDate;
  late DateTime? _endDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(
      widget.initialStartDate.year,
      widget.initialStartDate.month,
      widget.initialStartDate.day,
    );
    _endDate = DateTime(
      widget.initialEndDate.year,
      widget.initialEndDate.month,
      widget.initialEndDate.day,
    );
    _currentMonth = DateTime(_endDate!.year, _endDate!.month, 1);
  }

  void _onDateTapped(DateTime date) {
    setState(() {
      if (_endDate != null) {
        // If already selected a range, restart with clicked date as new start
        _startDate = date;
        _endDate = null;
      } else {
        // Waiting for end date
        if (date.isBefore(_startDate)) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      }
    });
  }

  void _applyPreset(DateTime start, DateTime end) {
    setState(() {
      _startDate = DateTime(start.year, start.month, start.day);
      _endDate = DateTime(end.year, end.month, end.day);
      _currentMonth = DateTime(_endDate!.year, _endDate!.month, 1);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isInRange(DateTime date) {
    if (_endDate == null) return false;
    return date.isAfter(_startDate) && date.isBefore(_endDate!);
  }

  int get _daysSelected {
    if (_endDate == null) return 1;
    return _endDate!.difference(_startDate).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Selected Range Banner Strip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _endDate != null
                              ? '${DateFormat('d MMM yyyy').format(_startDate)} — ${DateFormat('d MMM yyyy').format(_endDate!)}'
                              : '${DateFormat('d MMM yyyy').format(_startDate)} — (Pilih tanggal akhir)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _endDate != null
                                ? const Color(0xFF0F172A)
                                : AppColors.secondary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$_daysSelected Hari',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Quick Preset Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip(
                        label: 'Hari Ini',
                        onTap: () => _applyPreset(now, now),
                      ),
                      _buildPresetChip(
                        label: '7 Hari Terakhir',
                        onTap: () => _applyPreset(
                            now.subtract(const Duration(days: 6)), now),
                      ),
                      _buildPresetChip(
                        label: '30 Hari Terakhir',
                        onTap: () => _applyPreset(
                            now.subtract(const Duration(days: 29)), now),
                      ),
                      _buildPresetChip(
                        label: 'Bulan Ini',
                        onTap: () {
                          final first = DateTime(now.year, now.month, 1);
                          final last = DateTime(now.year, now.month + 1, 0);
                          _applyPreset(first, last);
                        },
                      ),
                      _buildPresetChip(
                        label: 'Bulan Lalu',
                        onTap: () {
                          final first = DateTime(now.year, now.month - 1, 1);
                          final last = DateTime(now.year, now.month, 0);
                          _applyPreset(first, last);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Month Navigation Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 22),
                      color: const Color(0xFF475569),
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(
                            _currentMonth.year,
                            _currentMonth.month - 1,
                            1,
                          );
                        });
                      },
                      splashRadius: 18,
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_currentMonth),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 22),
                      color: const Color(0xFF475569),
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(
                            _currentMonth.year,
                            _currentMonth.month + 1,
                            1,
                          );
                        });
                      },
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 5. Weekday Names
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _WeekdayText('Min'),
                    _WeekdayText('Sen'),
                    _WeekdayText('Sel'),
                    _WeekdayText('Rab'),
                    _WeekdayText('Kam'),
                    _WeekdayText('Jum'),
                    _WeekdayText('Sab'),
                  ],
                ),
                const SizedBox(height: 6),

                // 6. Calendar Days Grid
                _buildCalendarGrid(),
                const SizedBox(height: 20),

                // 7. Footer Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          final end = _endDate ?? _startDate;
                          Navigator.of(context).pop(
                            DateTimeRange(start: _startDate, end: end),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Terapkan Rentang'),
                        ),
                      ),
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

  Widget _buildPresetChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0, Monday = 1

    final totalCells = ((startWeekday + daysInMonth) / 7).ceil() * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.15,
        mainAxisSpacing: 3,
        crossAxisSpacing: 0,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < startWeekday || index >= startWeekday + daysInMonth) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - startWeekday + 1;
        final cellDate =
            DateTime(_currentMonth.year, _currentMonth.month, dayNumber);

        final isStart = _isSameDay(cellDate, _startDate);
        final isEnd = _endDate != null && _isSameDay(cellDate, _endDate!);
        final inRange = _isInRange(cellDate);

        BoxDecoration? rangeBg;
        if (inRange) {
          rangeBg = const BoxDecoration(color: Color(0xFFEEF2FF));
        } else if (isStart && _endDate != null && !isEnd) {
          rangeBg = const BoxDecoration(
            color: Color(0xFFEEF2FF),
            borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
          );
        } else if (isEnd && !_isSameDay(_startDate, _endDate!)) {
          rangeBg = const BoxDecoration(
            color: Color(0xFFEEF2FF),
            borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
          );
        }

        return Container(
          decoration: rangeBg,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _onDateTapped(cellDate),
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (isStart || isEnd)
                        ? AppColors.secondary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$dayNumber',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: (isStart || isEnd || inRange)
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: (isStart || isEnd)
                          ? Colors.white
                          : inRange
                              ? AppColors.secondary
                              : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WeekdayText extends StatelessWidget {
  final String text;
  const _WeekdayText(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
