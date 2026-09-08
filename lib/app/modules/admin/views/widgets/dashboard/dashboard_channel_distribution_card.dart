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
    required this.isTablet,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final posTotal = data.orderSourceBreakdown.pos.total;
    final onlineTotal = data.orderSourceBreakdown.onlineOrder.total;
    final posCount = data.orderSourceBreakdown.pos.count;
    final onlineCount = data.orderSourceBreakdown.onlineOrder.count;
    final channelCountSum = posCount + onlineCount;
    final channelSum = posTotal + onlineTotal;
    final hasChannelData = channelCountSum > 0 || channelSum > 0;

    final dineInTotal = data.orderTypeBreakdown.dineIn.total;
    final takeawayTotal = data.orderTypeBreakdown.takeaway.total;
    final dineInCount = data.orderTypeBreakdown.dineIn.count;
    final takeawayCount = data.orderTypeBreakdown.takeaway.count;
    final typeCountSum = dineInCount + takeawayCount;
    final typeSum = dineInTotal + takeawayTotal;
    final hasTypeData = typeCountSum > 0 || typeSum > 0;

    final posPercent = channelSum > 0
        ? (posTotal / channelSum)
        : (channelCountSum > 0 ? (posCount / channelCountSum) : 0.0);
    final dineInPercent = typeSum > 0
        ? (dineInTotal / typeSum)
        : (typeCountSum > 0 ? (dineInCount / typeCountSum) : 0.0);
    final useSideBySide = isTablet || height != null;

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: height != null
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribusi Pesanan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
          ),
          if (height == null) const SizedBox(height: 10),

          // Side-by-side or stacked
          if (useSideBySide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Saluran Penjualan
                Expanded(
                  child: _buildProportionSection(
                    title: 'SALURAN',
                    labelA: 'Kasir POS',
                    countA: data.orderSourceBreakdown.pos.count,
                    totalA: posTotal,
                    colorA: AppColors.secondary,
                    labelB: 'Online',
                    countB: data.orderSourceBreakdown.onlineOrder.count,
                    totalB: onlineTotal,
                    colorB: const Color(0xFF0EA5E9),
                    ratioA: posPercent,
                  ),
                ),
                Container(
                  width: 1,
                  height: 65,
                  color: const Color(0xFFE2E8F0),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                // Tipe Pesanan
                Expanded(
                  child: _buildProportionSection(
                    title: 'TIPE',
                    labelA: 'Dine-in',
                    countA: data.orderTypeBreakdown.dineIn.count,
                    totalA: dineInTotal,
                    colorA: const Color(0xFF10B981),
                    labelB: 'Takeaway',
                    countB: data.orderTypeBreakdown.takeaway.count,
                    totalB: takeawayTotal,
                    colorB: const Color(0xFFF59E0B),
                    ratioA: dineInPercent,
                  ),
                ),
              ],
            )
          else ...[
            _buildProportionSection(
              title: 'SALURAN PENJUALAN',
              labelA: 'Kasir POS',
              countA: data.orderSourceBreakdown.pos.count,
              totalA: posTotal,
              colorA: AppColors.secondary,
              labelB: 'Online',
              countB: data.orderSourceBreakdown.onlineOrder.count,
              totalB: onlineTotal,
              colorB: const Color(0xFF0EA5E9),
              ratioA: posPercent,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),
            _buildProportionSection(
              title: 'TIPE PESANAN',
              labelA: 'Dine-in',
              countA: data.orderTypeBreakdown.dineIn.count,
              totalA: dineInTotal,
              colorA: const Color(0xFF10B981),
              labelB: 'Takeaway',
              countB: data.orderTypeBreakdown.takeaway.count,
              totalB: takeawayTotal,
              colorB: const Color(0xFFF59E0B),
              ratioA: dineInPercent,
            ),
          ],

          if (height == null) const SizedBox(height: 10),
          Column(
            children: [
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      hasChannelData
                          ? 'POS: ${(posPercent * 100).toInt()}% • Online: ${((1 - posPercent) * 100).toInt()}%'
                          : 'POS: 0% • Online: 0%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      hasTypeData
                          ? 'Dine-in: ${(dineInPercent * 100).toInt()}% • Takeaway: ${((1 - dineInPercent) * 100).toInt()}%'
                          : 'Dine-in: 0% • Takeaway: 0%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProportionSection({
    required String title,
    required String labelA,
    required int countA,
    required double totalA,
    required Color colorA,
    required String labelB,
    required int countB,
    required double totalB,
    required Color colorB,
    required double ratioA,
  }) {
    final hasData = (countA + countB > 0) || (totalA + totalB > 0);
    final percentA = hasData ? (ratioA * 100).clamp(0, 100).toInt() : 0;
    final percentB = hasData ? (100 - percentA) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                if (!hasData)
                  Expanded(
                    child: Container(color: const Color(0xFFE2E8F0)),
                  )
                else ...[
                  if (percentA > 0)
                    Expanded(
                      flex: percentA,
                      child: Container(color: colorA),
                    ),
                  if (percentB > 0)
                    Expanded(
                      flex: percentB,
                      child: Container(color: colorB),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorA,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      labelA,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$countA ($percentA%)',
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colorB,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      labelB,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$countB ($percentB%)',
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
