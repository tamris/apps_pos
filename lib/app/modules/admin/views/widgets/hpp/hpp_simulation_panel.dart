import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/app_snackbar.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/data/models/hpp_calculation_model.dart';
import 'package:noli_apps/app/data/models/product_ingredient_model.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import '../products/admin_product_form_dialog.dart';

enum _IngredientCategory {
  coffee,
  liquid,
  ice,
  packaging,
  other,
}

class _IngredientVisualHelper {
  static _IngredientCategory getCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('kopi') ||
        lower.contains('coffee') ||
        lower.contains('espresso') ||
        lower.contains('arabica') ||
        lower.contains('robusta') ||
        lower.contains('blend') ||
        lower.contains('biji') ||
        lower.contains('beans')) {
      return _IngredientCategory.coffee;
    }
    if (lower.contains('es ') || lower.contains('es batu') || lower.contains('ice') || lower.contains('batu')) {
      return _IngredientCategory.ice;
    }
    if (lower.contains('cup') ||
        lower.contains('lid') ||
        lower.contains('tutup') ||
        lower.contains('sedotan') ||
        lower.contains('straw') ||
        lower.contains('plastik') ||
        lower.contains('packaging') ||
        lower.contains('kemasan') ||
        lower.contains('kantong') ||
        lower.contains('paper') ||
        lower.contains('box') ||
        lower.contains('gelas')) {
      return _IngredientCategory.packaging;
    }
    if (lower.contains('air') ||
        lower.contains('susu') ||
        lower.contains('milk') ||
        lower.contains('syrup') ||
        lower.contains('sirup') ||
        lower.contains('aren') ||
        lower.contains('sauce') ||
        lower.contains('saus') ||
        lower.contains('powder') ||
        lower.contains('bubuk') ||
        lower.contains('tea') ||
        lower.contains('teh') ||
        lower.contains('liquid') ||
        lower.contains('cream') ||
        lower.contains('krim')) {
      return _IngredientCategory.liquid;
    }
    return _IngredientCategory.other;
  }

  static Color getColor(_IngredientCategory cat) {
    switch (cat) {
      case _IngredientCategory.coffee:
        return const Color(0xFFB45309);
      case _IngredientCategory.liquid:
        return const Color(0xFF0284C7);
      case _IngredientCategory.ice:
        return const Color(0xFF0891B2);
      case _IngredientCategory.packaging:
        return const Color(0xFF7C3AED);
      case _IngredientCategory.other:
        return const Color(0xFF059669);
    }
  }

  static String getLabel(_IngredientCategory cat) {
    switch (cat) {
      case _IngredientCategory.coffee:
        return 'Kopi / Base';
      case _IngredientCategory.liquid:
        return 'Cairan / Susu';
      case _IngredientCategory.ice:
        return 'Es Batu';
      case _IngredientCategory.packaging:
        return 'Packaging';
      case _IngredientCategory.other:
        return 'Bahan Lain';
    }
  }
}

class HppSimulationPanel extends StatefulWidget {
  final AdminController controller;

  const HppSimulationPanel({super.key, required this.controller});

  @override
  State<HppSimulationPanel> createState() => _HppSimulationPanelState();
}

class _HppSimulationPanelState extends State<HppSimulationPanel> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final TextEditingController _sellingPriceCtrl = TextEditingController();
  final TextEditingController _opsCostCtrl = TextEditingController(text: '1.000');
  final TextEditingController _targetProfitCtrl = TextEditingController(text: '5.000.000');

  double _markupPercent = 0.0;
  final int _targetUnits = 3000;
  String _selectedTierKey = 'standar';

  void _selectTier(String key, double price) {
    setState(() {
      _selectedTierKey = key;
      _sellingPriceCtrl.text = CurrencyFormatter.formatWithoutSymbol(price);
    });
    _recalculate();
  }

  @override
  void initState() {
    super.initState();
    _syncFormFromController();
  }

  @override
  void didUpdateWidget(covariant HppSimulationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFormFromController();
  }

  void _syncFormFromController() {
    if (widget.controller.simulationSellingPrice.value > 0) {
      _sellingPriceCtrl.text = CurrencyFormatter.formatWithoutSymbol(
        widget.controller.simulationSellingPrice.value,
      );
    }
    if (widget.controller.simulationOperationalCost.value > 0) {
      _opsCostCtrl.text = CurrencyFormatter.formatWithoutSymbol(
        widget.controller.simulationOperationalCost.value,
      );
    }
  }

  @override
  void dispose() {
    _sellingPriceCtrl.dispose();
    _opsCostCtrl.dispose();
    _targetProfitCtrl.dispose();
    super.dispose();
  }

  void _recalculate() {
    final price = double.tryParse(_sellingPriceCtrl.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0;
    final ops = double.tryParse(_opsCostCtrl.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 1000.0;
    final targetProfit = double.tryParse(_targetProfitCtrl.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 5000000.0;

    widget.controller.simulationSellingPrice.value = price;
    widget.controller.simulationOperationalCost.value = ops;
    widget.controller.simulationKenaikanPersen.value = _markupPercent;
    widget.controller.simulationTargetMonthlyUnits.value = _targetUnits;
    widget.controller.simulationTargetMonthlyProfit.value = targetProfit;

    widget.controller.calculateHppSimulation(
      ingredients: widget.controller.simulationIngredients,
      sellingPrice: price,
      operationalCost: ops,
      kenaikanPersen: _markupPercent,
      targetMonthlyUnits: _targetUnits,
      targetMonthlyProfit: targetProfit,
    );
  }

  void _showIngredientDialog({int? index}) {
    final ingredients = widget.controller.simulationIngredients;
    final isEditing = index != null && index >= 0 && index < ingredients.length;
    final existing = isEditing ? ingredients[index] : null;

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final amountCtrl = TextEditingController(
      text: existing != null
          ? (existing.amount % 1 == 0 ? existing.amount.toInt().toString() : existing.amount.toString())
          : '15',
    );
    String unit = existing?.unit ?? 'gram';
    final buyPriceCtrl = TextEditingController(
      text: existing != null
          ? CurrencyFormatter.formatWithoutSymbol(existing.buyPrice)
          : '100.000',
    );
    final buyAmountCtrl = TextEditingController(
      text: existing != null
          ? (existing.buyAmount % 1 == 0 ? existing.buyAmount.toInt().toString() : existing.buyAmount.toString())
          : '1',
    );
    String buyUnit = existing?.buyUnit ?? 'kg';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final amt = double.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
          final bp = double.tryParse(buyPriceCtrl.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0;
          final ba = double.tryParse(buyAmountCtrl.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 1.0;
          final liveSubtotal = ProductIngredientModel.calculateLocalSubtotal(amt, unit, bp, ba, buyUnit);

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            elevation: 8,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog Header
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isEditing ? const Color(0xFFE0F2FE) : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                            color: isEditing ? const Color(0xFF0284C7) : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? 'Edit Bahan Baku Resep' : 'Tambah Bahan Baku Baru',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Tentukan takaran porsi & biaya beli kemasannya',
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                          onPressed: () => Navigator.of(ctx).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Inputs
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nama Bahan Baku', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: nameCtrl,
                            decoration: InputDecoration(
                              hintText: 'Contoh: Susu Segar (Fresh Milk)',
                              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 14),

                          // Takaran & Satuan
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Takaran Porsi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: amountCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (_) => setDlgState(() {}),
                                      decoration: InputDecoration(
                                        hintText: '15',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        isDense: true,
                                      ),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Satuan Porsi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      initialValue: ['gram', 'ml', 'pcs', 'sachet', 'kg', 'liter'].contains(unit) ? unit : 'gram',
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                        isDense: true,
                                      ),
                                      items: ['gram', 'ml', 'pcs', 'sachet', 'kg', 'liter']
                                          .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) setDlgState(() => unit = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Harga Beli Kemasan
                          const Text('Harga Beli Kemasan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: buyPriceCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              CurrencyInputFormatter(),
                            ],
                            onChanged: (_) => setDlgState(() {}),
                            decoration: InputDecoration(
                              prefixText: 'Rp ',
                              prefixStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              hintText: '100.000',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 14),

                          // Isi Kemasan Beli & Satuan
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Isi Kemasan Beli', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: buyAmountCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      onChanged: (_) => setDlgState(() {}),
                                      decoration: InputDecoration(
                                        hintText: '1',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        isDense: true,
                                      ),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Satuan Beli', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      initialValue: ['kg', 'liter', 'pcs', 'gram', 'ml', 'sachet'].contains(buyUnit) ? buyUnit : 'kg',
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                        isDense: true,
                                      ),
                                      items: ['kg', 'liter', 'pcs', 'gram', 'ml', 'sachet']
                                          .map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))))
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) setDlgState(() => buyUnit = val);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Live Calculation Banner
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.calculate_rounded, size: 18, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Estimasi Biaya per Porsi:',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                                      ),
                                      Text(
                                        _currencyFormat.format(liveSubtotal),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF14532D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dialog Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            foregroundColor: const Color(0xFF64748B),
                          ),
                          child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final name = nameCtrl.text.trim();
                            final amount = double.tryParse(amountCtrl.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;
                            final buyPrice = double.tryParse(buyPriceCtrl.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
                            final buyAmount = double.tryParse(buyAmountCtrl.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 1;

                            if (name.isEmpty || amount <= 0 || buyPrice < 0) {
                              AppSnackbar.warning('Data Belum Lengkap', 'Lengkapi nama dan takaran bahan (harga beli minimal Rp 0).');
                              return;
                            }

                            final newIng = ProductIngredientModel(
                              id: existing?.id,
                              productId: existing?.productId,
                              name: name,
                              amount: amount,
                              unit: unit,
                              buyPrice: buyPrice,
                              buyAmount: buyAmount,
                              buyUnit: buyUnit,
                              subtotal: liveSubtotal,
                            );

                            if (isEditing) {
                              widget.controller.simulationIngredients[index] = newIng;
                            } else {
                              widget.controller.simulationIngredients.add(newIng);
                            }
                            _recalculate();
                            Navigator.of(ctx).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            isEditing ? 'Simpan Perubahan' : 'Tambah Bahan',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ingredients = widget.controller.simulationIngredients;
      final result = widget.controller.simulationCalculationResult.value;
      final productName = widget.controller.simulationProductName.value;

      if (ingredients.isEmpty) {
        return const SizedBox.shrink();
      }

      final summary = result?.summary;
      final tiers = result?.pricingTiers ?? {};

      // Calculate total food cost & ingredient percentage shares
      final double totalFoodCost = summary?.totalVariableCost ??
          ingredients.fold<double>(0.0, (sum, item) => sum + item.subtotal);

      final double effectiveOpsCost = double.tryParse(_opsCostCtrl.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 1000.0;
      final double effectiveTotalHpp = (summary?.simulatedHpp != null && (summary?.simulatedHpp ?? 0) > 0)
          ? summary!.simulatedHpp
          : (totalFoodCost * (1.0 + (_markupPercent / 100.0)) + effectiveOpsCost);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SECTION HEADER BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 650;
                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                              ),
                              child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                productName.isNotEmpty
                                    ? 'Hasil Estimasi Resep: $productName'
                                    : 'Komposisi Resep Bahan Baku',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                '${ingredients.length} Bahan Baku',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome_rounded, size: 11, color: AppColors.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'Kalkulasi Otomatis',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Klik baris bahan untuk mengedit takaran atau harga beli. Perubahan akan mengkalkulasi HPP seketika.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showIngredientDialog(),
                            icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                            label: const Text(
                              'Tambah Bahan Baku',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    productName.isNotEmpty
                                        ? 'Hasil Estimasi Resep: $productName'
                                        : 'Komposisi Resep Bahan Baku',
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: Text(
                                    '${ingredients.length} Bahan Baku',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome_rounded, size: 11, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'Kalkulasi Otomatis',
                                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Klik baris bahan untuk mengedit takaran atau harga beli. Perubahan akan mengkalkulasi HPP seketika.',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showIngredientDialog(),
                        icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                        label: const Text(
                          'Tambah Bahan Baku',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // 2. INGREDIENTS TABLE & SUMMARY CARD
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x03000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 650;

                  return Column(
                    children: [
                      // Modern Table Header
                      if (isCompact)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'RINCIAN BAHAN BAKU',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.3),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${ingredients.length} item',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'NAMA BAHAN BAKU',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.3),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'TAKARAN PORSI',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.3),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'HARGA BELI KEMASAN',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.3),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'SUBTOTAL / CUP',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.3),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              SizedBox(width: 72),
                            ],
                          ),
                        ),

                      // Table Rows
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ingredients.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, idx) {
                          final ing = ingredients[idx];
                          final cat = _IngredientVisualHelper.getCategory(ing.name);
                          final catColor = _IngredientVisualHelper.getColor(cat);

                          final sharePercent = totalFoodCost > 0 ? (ing.subtotal / totalFoodCost) * 100.0 : 0.0;
                          final isDominantCost = sharePercent >= 35.0;

                          if (isCompact) {
                            // Mobile Compact Card Row
                            return Material(
                              color: Colors.white,
                              child: InkWell(
                                onTap: () => _showIngredientDialog(index: idx),
                                hoverColor: const Color(0xFFF8FAFC),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${idx + 1}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  ing.name,
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 1),
                                                Text(
                                                  _IngredientVisualHelper.getLabel(cat),
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: catColor),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF475569)),
                                            tooltip: 'Edit Bahan',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                            onPressed: () => _showIngredientDialog(index: idx),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                            tooltip: 'Hapus Bahan',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                            onPressed: () {
                                              widget.controller.simulationIngredients.removeAt(idx);
                                              _recalculate();
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Takaran & Kemasan Pill
                                          Expanded(
                                            child: Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                                  ),
                                                  child: Text(
                                                    '${ing.amount % 1 == 0 ? ing.amount.toInt() : ing.amount} ${ing.unit}',
                                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                                  ),
                                                ),
                                                Text(
                                                  '(${_currencyFormat.format(ing.buyPrice)} / ${ing.buyAmount % 1 == 0 ? ing.buyAmount.toInt() : ing.buyAmount} ${ing.buyUnit})',
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Subtotal & % porsi
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                _currencyFormat.format(ing.subtotal),
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                              ),
                                              const SizedBox(height: 2),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                decoration: BoxDecoration(
                                                  color: isDominantCost ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${sharePercent.toStringAsFixed(1)}% porsi',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDominantCost ? const Color(0xFFB45309) : const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          // Desktop Row
                          return Material(
                            color: Colors.white,
                            child: InkWell(
                              onTap: () => _showIngredientDialog(index: idx),
                              hoverColor: const Color(0xFFF8FAFC),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    // Number Indicator
                                    SizedBox(
                                      width: 32,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${idx + 1}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Name with Category Subtitle
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            ing.name,
                                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _IngredientVisualHelper.getLabel(cat),
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: catColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Takaran Porsi Pill
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(7),
                                              border: Border.all(color: const Color(0xFFE2E8F0)),
                                            ),
                                            child: Text(
                                              '${ing.amount % 1 == 0 ? ing.amount.toInt() : ing.amount} ${ing.unit}',
                                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Harga Beli Kemasan
                                    Expanded(
                                      flex: 3,
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: _currencyFormat.format(ing.buyPrice),
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                                            ),
                                            TextSpan(
                                              text: ' / ${ing.buyAmount % 1 == 0 ? ing.buyAmount.toInt() : ing.buyAmount} ${ing.buyUnit}',
                                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Subtotal / Cup with Contribution Pill
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _currencyFormat.format(ing.subtotal),
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: isDominantCost ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${sharePercent.toStringAsFixed(1)}% porsi',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                                color: isDominantCost ? const Color(0xFFB45309) : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Actions (Edit & Delete)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF475569)),
                                          tooltip: 'Edit Bahan',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                          onPressed: () => _showIngredientDialog(index: idx),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                          tooltip: 'Hapus Bahan',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                          onPressed: () {
                                            widget.controller.simulationIngredients.removeAt(idx);
                                            _recalculate();
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Table Footer Summary & Proportion Bar
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Main Summary
                            if (isCompact)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.pie_chart_outline_rounded, size: 16, color: Color(0xFF334155)),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Biaya Bahan Murni (Food Cost)',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'Total pengeluaran bahan dasar per 1 porsi saji',
                                              style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Flexible(
                                          child: Text(
                                            'Total Food Cost:',
                                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _currencyFormat.format(totalFoodCost),
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE2E8F0),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.pie_chart_outline_rounded, size: 16, color: Color(0xFF334155)),
                                      ),
                                      const SizedBox(width: 10),
                                      const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total Biaya Bahan Murni (Food Cost)',
                                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                                          ),
                                          Text(
                                            'Total pengeluaran bahan dasar per 1 porsi saji',
                                            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Subtotal: ',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                        ),
                                        Text(
                                          _currencyFormat.format(totalFoodCost),
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 12),

                        // Mini Multi-Color Proportion Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 6,
                            child: Row(
                              children: ingredients.map((ing) {
                                final share = totalFoodCost > 0 ? (ing.subtotal / totalFoodCost) : 0.0;
                                final cat = _IngredientVisualHelper.getCategory(ing.name);
                                final color = _IngredientVisualHelper.getColor(cat);
                                return Expanded(
                                  flex: (share * 1000).toInt().clamp(1, 1000),
                                  child: Container(color: color),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Compact Legend
                        Wrap(
                          spacing: 14,
                          runSpacing: 4,
                          children: _IngredientCategory.values.map((cat) {
                            final hasCat = ingredients.any((i) => _IngredientVisualHelper.getCategory(i.name) == cat);
                            if (!hasCat) return const SizedBox.shrink();
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _IngredientVisualHelper.getColor(cat),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _IngredientVisualHelper.getLabel(cat),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),

            // 3. SIMULATION CONTROLS (OVERHEAD & FLUCTUATION)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x03000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Simulasi Beban Operasional & Fluktuasi Pasar',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Kombinasikan biaya bahan baku dengan beban toko dan skenario lonjakan harga pasar.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3-Card Balanced Dashboard Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 850;
                      final isMobile = constraints.maxWidth < 550;

                      // Card 1: Overhead / Store Cost
                      final card1 = Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  child: const Icon(Icons.storefront_outlined, size: 15, color: Color(0xFF334155)),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Alokasi Beban Toko',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                                      ),
                                      Text(
                                        'Sewa, listrik & barista / cup',
                                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 38,
                              child: TextField(
                                controller: _opsCostCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  CurrencyInputFormatter(),
                                ],
                                onChanged: (_) => _recalculate(),
                                decoration: InputDecoration(
                                  prefixText: 'Rp ',
                                  prefixStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [500, 1000, 1500, 2000].asMap().entries.map((entry) {
                                final val = entry.value;
                                final isLast = entry.key == 3;
                                final isSelected = effectiveOpsCost == val.toDouble();
                                final formatted = CurrencyFormatter.formatWithoutSymbol(val.toDouble());
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: isLast ? 0 : 4),
                                    child: InkWell(
                                      onTap: () {
                                        _opsCostCtrl.text = formatted;
                                        _recalculate();
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(vertical: 4.5),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected ? AppColors.primarySoft : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                                            width: isSelected ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Text(
                                          'Rp $formatted',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                            color: isSelected ? AppColors.primary : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );

                      // Card 2: Price Fluctuation Slider
                      final card2 = Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: _markupPercent > 15
                                              ? const Color(0xFFFEE2E2)
                                              : (_markupPercent > 0 ? const Color(0xFFFEF3C7) : AppColors.primarySoft),
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        child: Icon(
                                          Icons.trending_up_rounded,
                                          size: 15,
                                          color: _markupPercent > 15
                                              ? AppColors.danger
                                              : (_markupPercent > 0 ? const Color(0xFFB45309) : AppColors.primary),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Flexible(
                                        child: Text(
                                          'Fluktuasi Bahan',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: _markupPercent > 15
                                        ? const Color(0xFFFEE2E2)
                                        : (_markupPercent > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFF0FDF4)),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _markupPercent > 15
                                          ? const Color(0xFFFECACA)
                                          : (_markupPercent > 0 ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0)),
                                    ),
                                  ),
                                  child: Text(
                                    _markupPercent == 0
                                        ? 'Stabil (0%)'
                                        : (_markupPercent <= 15 ? 'Wajar (+${_markupPercent.toInt()}%)' : 'Waspada (+${_markupPercent.toInt()}%)'),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _markupPercent > 15
                                          ? const Color(0xFFB91C1C)
                                          : (_markupPercent > 0 ? const Color(0xFFB45309) : const Color(0xFF15803D)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                activeTrackColor: _markupPercent > 15 ? AppColors.danger : AppColors.primary,
                                inactiveTrackColor: const Color(0xFFCBD5E1),
                                thumbColor: _markupPercent > 15 ? AppColors.danger : AppColors.primary,
                                overlayColor: AppColors.primary.withValues(alpha: 0.12),
                              ),
                              child: Slider(
                                value: _markupPercent,
                                min: 0,
                                max: 30,
                                divisions: 6,
                                onChanged: (val) {
                                  setState(() => _markupPercent = val);
                                  _recalculate();
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('0% Normal', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      _markupPercent > 0
                                          ? '+${_currencyFormat.format(totalFoodCost * (_markupPercent / 100.0))}'
                                          : 'Harga Resep',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: _markupPercent > 0 ? FontWeight.bold : FontWeight.w600,
                                        color: _markupPercent > 0 ? const Color(0xFFB45309) : const Color(0xFF64748B),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const Text('+30% Krisis', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ],
                        ),
                      );

                      // Card 3: Total HPP Result Card
                      final card3 = Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        child: const Icon(Icons.calculate_rounded, size: 16, color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 8),
                                      const Flexible(
                                        child: Text(
                                          'Total HPP Efektif',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF14532D)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Modal / Cup',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _currencyFormat.format(effectiveTotalHpp),
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bahan: ${_currencyFormat.format(totalFoodCost * (1.0 + (_markupPercent / 100.0)))} • Beban: ${_currencyFormat.format(effectiveOpsCost)}',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );

                      // Responsive Layout
                      if (isWide) {
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: card1),
                              const SizedBox(width: 12),
                              Expanded(child: card2),
                              const SizedBox(width: 12),
                              Expanded(child: card3),
                            ],
                          ),
                        );
                      }

                      if (isMobile) {
                        return Column(
                          children: [
                            card1,
                            const SizedBox(height: 10),
                            card2,
                            const SizedBox(height: 10),
                            card3,
                          ],
                        );
                      }

                      // Medium tablet: top 2 cards, bottom result
                      return Column(
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: card1),
                                const SizedBox(width: 12),
                                Expanded(child: card2),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          card3,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. 3-TIER PRICING RECOMMENDATION
            if (tiers.isNotEmpty) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sell_outlined, size: 16, color: Color(0xFF0F172A)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Rekomendasi 3 Tier Harga Jual Cafe',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Dibulatkan kelipatan Rp 500 • Klik kartu untuk memilih harga',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 680;
                  final activeKey = tiers.containsKey(_selectedTierKey)
                      ? _selectedTierKey
                      : (tiers.containsKey('standar') ? 'standar' : (tiers.keys.firstOrNull ?? 'standar'));

                  final items = [
                    _buildTierCard(
                      tierKey: 'kompetitif',
                      tierItem: tiers['kompetitif'],
                      title: 'Tier Kompetitif',
                      badge: 'Volume / Promo',
                      targetMargin: 'Target Margin ~50%',
                      color: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFF0F9FF),
                      isSelected: activeKey == 'kompetitif',
                      totalHpp: effectiveTotalHpp,
                      onTap: () {
                        if (tiers['kompetitif'] != null) {
                          _selectTier('kompetitif', tiers['kompetitif']!.harga);
                        }
                      },
                    ),
                    _buildTierCard(
                      tierKey: 'standar',
                      tierItem: tiers['standar'],
                      title: 'Tier Standar Cafe',
                      badge: 'REKOMENDASI CAFE',
                      targetMargin: 'Target Margin ~58%',
                      color: AppColors.primary,
                      bgColor: AppColors.primarySoft,
                      isSelected: activeKey == 'standar',
                      totalHpp: effectiveTotalHpp,
                      onTap: () {
                        if (tiers['standar'] != null) {
                          _selectTier('standar', tiers['standar']!.harga);
                        }
                      },
                    ),
                    _buildTierCard(
                      tierKey: 'premium',
                      tierItem: tiers['premium'],
                      title: 'Tier Premium',
                      badge: 'Specialty Quality',
                      targetMargin: 'Target Margin ~67%',
                      color: const Color(0xFF7C3AED),
                      bgColor: const Color(0xFFF5F3FF),
                      isSelected: activeKey == 'premium',
                      totalHpp: effectiveTotalHpp,
                      onTap: () {
                        if (tiers['premium'] != null) {
                          _selectTier('premium', tiers['premium']!.harga);
                        }
                      },
                    ),
                  ];

                  if (isNarrow) {
                    return Column(
                      children: items.map((w) => Padding(padding: const EdgeInsets.only(bottom: 10), child: w)).toList(),
                    );
                  }

                  return Row(
                    children: items.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: w))).toList(),
                  );
                },
              ),
            ],
            const SizedBox(height: 18),

            // 5. BOTTOM CTA BUTTON
            Builder(
              builder: (context) {
                final sourceProduct = widget.controller.simulationSourceProduct.value;
                final isExistingProduct = sourceProduct != null;

                final activeKey = tiers.containsKey(_selectedTierKey)
                    ? _selectedTierKey
                    : (tiers.containsKey('standar') ? 'standar' : (tiers.keys.firstOrNull ?? 'standar'));
                final selectedTierItem = tiers[activeKey];
                final selectedPrice = selectedTierItem?.harga ?? result?.customAnalysis?.sellingPrice ?? result?.pricingTiers['standar']?.harga;

                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final success = await AdminProductFormDialog.show(
                        context,
                        product: sourceProduct,
                        initialName: widget.controller.simulationProductName.value.isNotEmpty
                            ? widget.controller.simulationProductName.value
                            : sourceProduct?.name,
                        initialPrice: selectedPrice,
                        prefilledIngredients: widget.controller.simulationIngredients.toList(),
                      );
                      if (success == true) {
                        widget.controller.setProductManagementSubTab(0);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isExistingProduct ? Icons.check_circle_outline_rounded : Icons.add_task_rounded,
                          size: 19,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            isExistingProduct
                                ? (selectedTierItem != null && selectedPrice != null && selectedPrice > 0
                                    ? 'Perbarui Menu "${sourceProduct.name}" (${selectedTierItem.label} • ${_currencyFormat.format(selectedPrice)})'
                                    : 'Perbarui Menu "${sourceProduct.name}"')
                                : (selectedTierItem != null && selectedPrice != null && selectedPrice > 0
                                    ? 'Terapkan ke Katalog (${selectedTierItem.label} • ${_currencyFormat.format(selectedPrice)})'
                                    : 'Terapkan ke Katalog Produk Baru'),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white70),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTierCard({
    required String tierKey,
    required HppPricingTierItem? tierItem,
    required String title,
    required String badge,
    required String targetMargin,
    required Color color,
    required Color bgColor,
    required bool isSelected,
    required double totalHpp,
    required VoidCallback onTap,
  }) {
    if (tierItem == null) return const SizedBox.shrink();

    final marginPercent = tierItem.margin.clamp(0.0, 100.0);
    final costRatio = (100.0 - marginPercent).clamp(0.0, 100.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        hoverColor: color.withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Color(0x03000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tier Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: isSelected ? color : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? color : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Price
              Text(
                _currencyFormat.format(tierItem.harga),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? color : const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),

              // Margin & Profit
              Text(
                'Margin: ${tierItem.margin.toStringAsFixed(1)}% • Untung: ${_currencyFormat.format(tierItem.profit)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color.withValues(alpha: 0.95) : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),

              // Visual Cost vs Profit Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 5,
                  child: Row(
                    children: [
                      Expanded(
                        flex: costRatio.toInt().clamp(1, 100),
                        child: Container(color: const Color(0xFFCBD5E1)),
                      ),
                      Expanded(
                        flex: marginPercent.toInt().clamp(1, 100),
                        child: Container(color: color),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Bottom status & Selected Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      targetMargin,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, size: 12, color: color),
                          const SizedBox(width: 3),
                          Text(
                            'Dipilih',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
