import 'package:noli_apps/app/core/widgets/app_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/data/models/admin_product_model.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'admin_product_form_dialog.dart';

class AdminProductDetailDialog {
  static void show(BuildContext context, {required AdminProductModel product}) {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    if (isTablet) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 12,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
            child: _ProductDetailContent(product: product),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.90,
          ),
          child: _ProductDetailContent(product: product, isSheet: true),
        ),
      );
    }
  }
}

class _ProductDetailContent extends StatefulWidget {
  final AdminProductModel product;
  final bool isSheet;

  const _ProductDetailContent({required this.product, this.isSheet = false});

  @override
  State<_ProductDetailContent> createState() => _ProductDetailContentState();
}

class _ProductDetailContentState extends State<_ProductDetailContent> {
  final AdminController controller = Get.find<AdminController>();
  AdminProductModel? _detailedProduct;
  bool _isLoadingDetail = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _detailedProduct = widget.product;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoadingDetail = true);
    final detail = await controller.fetchProductDetail(widget.product.id);
    if (detail != null && mounted) {
      setState(() {
        _detailedProduct = detail;
        _isLoadingDetail = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingDetail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _detailedProduct ?? widget.product;

    final isHealthy = p.marginPercent >= 45.0;
    final isCritical = p.marginPercent < 35.0;
    final marginColor = isCritical
        ? AppColors.danger
        : isHealthy
            ? AppColors.primary
            : AppColors.warningDark;
    final marginBgColor = isCritical
        ? AppColors.dangerSoft
        : isHealthy
            ? AppColors.primarySoft
            : AppColors.warningSoft;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.isSheet) ...[
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.secondarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${p.categoryName} • ${p.sku}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(6),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Content
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Card: Photo + Main Pricing Metrics
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCachedImage(
                      imageUrl: p.imageUrl,
                      width: 80,
                      height: 80,
                      borderRadius: 12,
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.restaurant_menu_rounded,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: p.isActive ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  p.isActive ? 'Menu Aktif' : 'Nonaktif',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: p.isActive ? const Color(0xFF047857) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (p.barcode != null && p.barcode!.isNotEmpty)
                                Text(
                                  'Barcode: ${p.barcode}',
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currencyFormat.format(p.price),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Estimasi HPP: ${_currencyFormat.format(p.hargaBeli)} • Laba: ${_currencyFormat.format(p.profit)}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3 Key Financial Cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: marginBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: marginColor.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Margin Profit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              '${p.marginPercent.toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: marginColor),
                            ),
                            Text(
                              isHealthy ? 'Sangat Sehat (>=45%)' : isCritical ? 'Waspada (<35%)' : 'Cukup Baik',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: marginColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Food Cost %', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Text(
                              '${p.foodCostPercent.toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                            const Text('Rasio Modal vs Jual', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Biaya Ops / Cup', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Text(
                              _currencyFormat.format(p.operationalCost),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const Text('Alokasi Beban Toko', style: TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Recipe & Ingredients Breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Komposisi Resep Bahan Baku', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    if (_isLoadingDetail)
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    else
                      Text('${p.ingredients.length} Bahan Baku', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 10),

                if (p.ingredients.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'Menu ini menggunakan HPP Manual tanpa rincian takaran bahan baku.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: p.ingredients.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final ing = p.ingredients[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ing.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                  Text(
                                    'Takaran: ${ing.amount % 1 == 0 ? ing.amount.toInt() : ing.amount} ${ing.unit} • Beli: ${_currencyFormat.format(ing.buyPrice)} / ${ing.buyAmount % 1 == 0 ? ing.buyAmount.toInt() : ing.buyAmount} ${ing.buyUnit}',
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _currencyFormat.format(ing.subtotal),
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
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

        // Bottom Actions: Edit Menu
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Tutup', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    AdminProductFormDialog.show(context, product: p);
                  },
                  icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                  label: const Text('Edit Menu & Resep', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
