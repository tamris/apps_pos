import 'package:flutter/material.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/data/models/admin_dashboard_model.dart';

class DashboardChannelDistributionCard extends StatelessWidget {
  final AdminDashboardModel data;
  final bool isTablet;
  final double? height;

  const DashboardChannelDistributionCard({
    super.key,
    required this.data,
    this.isTablet = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final posCount = data.orderSourceBreakdown.pos.count;
    final onlineCount = data.orderSourceBreakdown.onlineOrder.count;
    final posTotal = data.orderSourceBreakdown.pos.total;
    final onlineTotal = data.orderSourceBreakdown.onlineOrder.total;
    final channelCountSum = posCount + onlineCount;
    final channelSum = posTotal + onlineTotal;

    final takeawayCount = data.orderTypeBreakdown.takeaway.count;
    final dineInCount = data.orderTypeBreakdown.dineIn.count;
    final takeawayTotal = data.orderTypeBreakdown.takeaway.total;
    final dineInTotal = data.orderTypeBreakdown.dineIn.total;
    final typeCountSum = takeawayCount + dineInCount;
    final typeSum = takeawayTotal + dineInTotal;

    final posPercent = channelCountSum > 0
        ? (posCount / channelCountSum)
        : (channelSum > 0 ? (posTotal / channelSum) : 0.0);
    final onlinePercent = channelCountSum > 0 ? (1.0 - posPercent) : 0.0;

    final takeawayPercent = typeCountSum > 0
        ? (takeawayCount / typeCountSum)
        : (typeSum > 0 ? (takeawayTotal / typeSum) : 0.0);
    final dineInPercent = typeCountSum > 0 ? (1.0 - takeawayPercent) : 0.0;

    final totalOrders = channelCountSum > 0 ? channelCountSum : typeCountSum;

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Judul & Subjudul di Kiri, Pill Badge Total Pesanan di Kanan)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Distribusi Pesanan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Analisis kanal dan cara konsumsi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$totalOrders Pesanan',
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),

          // 2. Dual Sub-cards: SALURAN & TIPE LAYANAN (Mengisi ruang penuh seimbang)
          if (height != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sub-card 1: SALURAN
                    Expanded(
                      child: _buildSubCard(
                        title: 'SALURAN',
                        isExpanded: true,
                        barSegments: [
                          if (posPercent > 0)
                            _BarSegment(
                              flex: (posPercent * 1000).toInt().clamp(1, 1000),
                              color: AppColors.secondary,
                            ),
                          if (onlinePercent > 0)
                            _BarSegment(
                              flex: (onlinePercent * 1000).toInt().clamp(
                                1,
                                1000,
                              ),
                              color: const Color(0xFF0EA5E9),
                            ),
                        ],
                        items: [
                          _ItemData(
                            label: 'Kasir POS',
                            count: posCount,
                            percentage: posPercent,
                            color: AppColors.secondary,
                          ),
                          _ItemData(
                            label: 'Online',
                            count: onlineCount,
                            percentage: onlinePercent,
                            color: const Color(0xFF0EA5E9),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sub-card 2: TIPE LAYANAN
                    Expanded(
                      child: _buildSubCard(
                        title: 'TIPE LAYANAN',
                        isExpanded: true,
                        barSegments: [
                          if (dineInPercent > 0)
                            _BarSegment(
                              flex: (dineInPercent * 1000).toInt().clamp(
                                1,
                                1000,
                              ),
                              color: const Color(0xFF10B981),
                            ),
                          if (takeawayPercent > 0)
                            _BarSegment(
                              flex: (takeawayPercent * 1000).toInt().clamp(
                                1,
                                1000,
                              ),
                              color: const Color(0xFFF59E0B),
                            ),
                        ],
                        items: [
                          _ItemData(
                            label: 'Dine-in',
                            count: dineInCount,
                            percentage: dineInPercent,
                            color: const Color(0xFF10B981),
                          ),
                          _ItemData(
                            label: 'Takeaway',
                            count: takeawayCount,
                            percentage: takeawayPercent,
                            color: const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sub-card 1: SALURAN
                Expanded(
                  child: _buildSubCard(
                    title: 'SALURAN',
                    isExpanded: false,
                    barSegments: [
                      if (posPercent > 0)
                        _BarSegment(
                          flex: (posPercent * 1000).toInt().clamp(1, 1000),
                          color: AppColors.secondary,
                        ),
                      if (onlinePercent > 0)
                        _BarSegment(
                          flex: (onlinePercent * 1000).toInt().clamp(1, 1000),
                          color: const Color(0xFF0EA5E9),
                        ),
                    ],
                    items: [
                      _ItemData(
                        label: 'Kasir POS',
                        count: posCount,
                        percentage: posPercent,
                        color: AppColors.secondary,
                      ),
                      _ItemData(
                        label: 'Online',
                        count: onlineCount,
                        percentage: onlinePercent,
                        color: const Color(0xFF0EA5E9),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Sub-card 2: TIPE LAYANAN
                Expanded(
                  child: _buildSubCard(
                    title: 'TIPE LAYANAN',
                    isExpanded: false,
                    barSegments: [
                      if (dineInPercent > 0)
                        _BarSegment(
                          flex: (dineInPercent * 1000).toInt().clamp(1, 1000),
                          color: const Color(0xFF10B981),
                        ),
                      if (takeawayPercent > 0)
                        _BarSegment(
                          flex: (takeawayPercent * 1000).toInt().clamp(1, 1000),
                          color: const Color(0xFFF59E0B),
                        ),
                    ],
                    items: [
                      _ItemData(
                        label: 'Dine-in',
                        count: dineInCount,
                        percentage: dineInPercent,
                        color: const Color(0xFF10B981),
                      ),
                      _ItemData(
                        label: 'Takeaway',
                        count: takeawayCount,
                        percentage: takeawayPercent,
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubCard({
    required String title,
    required bool isExpanded,
    required List<_BarSegment> barSegments,
    required List<_ItemData> items,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isExpanded ? 12 : 9,
        vertical: isExpanded ? 14 : 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Bagian Atas Sub-Card: Judul & Progress Bar
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 5,
              child: Row(
                children: barSegments.isNotEmpty
                    ? barSegments
                          .map(
                            (s) => Expanded(
                              flex: s.flex,
                              child: Container(color: s.color),
                            ),
                          )
                          .toList()
                    : [
                        Expanded(
                          child: Container(color: const Color(0xFFE2E8F0)),
                        ),
                      ],
              ),
            ),
          ),

          if (isExpanded) const Spacer() else const SizedBox(height: 14),

          // 2. Item Baris Pertama (Kasir POS / Takeaway)
          _buildItemRow(items[0]),

          if (isExpanded) const Spacer() else const SizedBox(height: 10),

          // 3. Item Baris Kedua (Online / Dine-in)
          _buildItemRow(items[1]),
        ],
      ),
    );
  }

  Widget _buildItemRow(_ItemData item) {
    final percentInt = (item.percentage * 100).clamp(0, 100).toInt();
    final hasCount = item.count > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Dot & Label
        Expanded(
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: hasCount
                        ? const Color(0xFF334155)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),

        // Angka & Persentase (Font size sama rata 12.5px, scale down aman tanpa overflow)
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${item.count}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: hasCount ? FontWeight.w700 : FontWeight.w500,
                      color: hasCount
                          ? const Color(0xFF0F172A)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  TextSpan(
                    text: ' ($percentInt%)',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BarSegment {
  final int flex;
  final Color color;

  const _BarSegment({required this.flex, required this.color});
}

class _ItemData {
  final String label;
  final int count;
  final double percentage;
  final Color color;

  const _ItemData({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });
}
