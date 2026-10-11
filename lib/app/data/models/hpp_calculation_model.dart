import 'product_ingredient_model.dart';

class HppPricingTierItem {
  final String tier;
  final String label;
  final double harga;
  final double margin;
  final double profit;

  HppPricingTierItem({
    required this.tier,
    required this.label,
    required this.harga,
    required this.margin,
    required this.profit,
  });

  factory HppPricingTierItem.fromJson(Map<String, dynamic> json) {
    return HppPricingTierItem(
      tier: (json['tier'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      harga: double.tryParse(json['harga']?.toString() ?? '0') ?? 0.0,
      margin: double.tryParse(json['margin']?.toString() ?? '0') ?? 0.0,
      profit: double.tryParse(json['profit']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier': tier,
      'label': label,
      'harga': harga,
      'margin': margin,
      'profit': profit,
    };
  }
}

class HppCalculationSummary {
  final double totalVariableCost;
  final double simulatedVariableCost;
  final double kenaikanPersen;
  final String modeAlokasiOps;
  final double operationalCostPerUnit;
  final double totalBiayaTetapBulanan;
  final int targetPenjualanBulanan;
  final double baseHpp;
  final double simulatedHpp;
  final double effectiveHpp;

  HppCalculationSummary({
    this.totalVariableCost = 0.0,
    this.simulatedVariableCost = 0.0,
    this.kenaikanPersen = 0.0,
    this.modeAlokasiOps = 'manual',
    this.operationalCostPerUnit = 0.0,
    this.totalBiayaTetapBulanan = 0.0,
    this.targetPenjualanBulanan = 3000,
    this.baseHpp = 0.0,
    this.simulatedHpp = 0.0,
    this.effectiveHpp = 0.0,
  });

  factory HppCalculationSummary.fromJson(Map<String, dynamic> json) {
    return HppCalculationSummary(
      totalVariableCost: double.tryParse(json['total_variable_cost']?.toString() ?? '0') ?? 0.0,
      simulatedVariableCost: double.tryParse(json['simulated_variable_cost']?.toString() ?? '0') ?? 0.0,
      kenaikanPersen: double.tryParse(json['kenaikan_persen']?.toString() ?? '0') ?? 0.0,
      modeAlokasiOps: (json['mode_alokasi_ops'] ?? 'manual').toString(),
      operationalCostPerUnit: double.tryParse(json['operational_cost_per_unit']?.toString() ?? '0') ?? 0.0,
      totalBiayaTetapBulanan: double.tryParse(json['total_biaya_tetap_bulanan']?.toString() ?? '0') ?? 0.0,
      targetPenjualanBulanan: int.tryParse(json['target_penjualan_bulanan']?.toString() ?? '3000') ?? 3000,
      baseHpp: double.tryParse(json['base_hpp']?.toString() ?? '0') ?? 0.0,
      simulatedHpp: double.tryParse(json['simulated_hpp']?.toString() ?? '0') ?? 0.0,
      effectiveHpp: double.tryParse(json['effective_hpp']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_variable_cost': totalVariableCost,
      'simulated_variable_cost': simulatedVariableCost,
      'kenaikan_persen': kenaikanPersen,
      'mode_alokasi_ops': modeAlokasiOps,
      'operational_cost_per_unit': operationalCostPerUnit,
      'total_biaya_tetap_bulanan': totalBiayaTetapBulanan,
      'target_penjualan_bulanan': targetPenjualanBulanan,
      'base_hpp': baseHpp,
      'simulated_hpp': simulatedHpp,
      'effective_hpp': effectiveHpp,
    };
  }
}

class HppCustomAnalysis {
  final double sellingPrice;
  final double profit;
  final double marginPercent;
  final double foodCostPercent;
  final bool isHealthyMargin;

  HppCustomAnalysis({
    required this.sellingPrice,
    required this.profit,
    required this.marginPercent,
    required this.foodCostPercent,
    required this.isHealthyMargin,
  });

  factory HppCustomAnalysis.fromJson(Map<String, dynamic> json) {
    return HppCustomAnalysis(
      sellingPrice: double.tryParse(json['selling_price']?.toString() ?? '0') ?? 0.0,
      profit: double.tryParse(json['profit']?.toString() ?? '0') ?? 0.0,
      marginPercent: double.tryParse(json['margin_percent']?.toString() ?? '0') ?? 0.0,
      foodCostPercent: double.tryParse(json['food_cost_percent']?.toString() ?? '0') ?? 0.0,
      isHealthyMargin: json['is_healthy_margin'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selling_price': sellingPrice,
      'profit': profit,
      'margin_percent': marginPercent,
      'food_cost_percent': foodCostPercent,
      'is_healthy_margin': isHealthyMargin,
    };
  }
}

class HppSalesProjection {
  final double sellingPrice;
  final double unitCost;
  final double netMarginPerUnit;
  final double targetLabaBulanan;
  final int hariOperasionalSebulan;
  final int targetUnitsPerDay;
  final int targetUnitsPerMonth;
  final double potensiOmzet;
  final double totalBiayaProduksi;
  final double totalBiayaTetap;
  final double proyeksiLabaBersih;

  HppSalesProjection({
    this.sellingPrice = 0.0,
    this.unitCost = 0.0,
    this.netMarginPerUnit = 0.0,
    this.targetLabaBulanan = 0.0,
    this.hariOperasionalSebulan = 30,
    this.targetUnitsPerDay = 0,
    this.targetUnitsPerMonth = 0,
    this.potensiOmzet = 0.0,
    this.totalBiayaProduksi = 0.0,
    this.totalBiayaTetap = 0.0,
    this.proyeksiLabaBersih = 0.0,
  });

  factory HppSalesProjection.fromJson(Map<String, dynamic> json) {
    return HppSalesProjection(
      sellingPrice: double.tryParse(json['selling_price']?.toString() ?? '0') ?? 0.0,
      unitCost: double.tryParse(json['unit_cost']?.toString() ?? '0') ?? 0.0,
      netMarginPerUnit: double.tryParse(json['net_margin_per_unit']?.toString() ?? '0') ?? 0.0,
      targetLabaBulanan: double.tryParse(json['target_laba_bulanan']?.toString() ?? '0') ?? 0.0,
      hariOperasionalSebulan: int.tryParse(json['hari_operasional_sebulan']?.toString() ?? '30') ?? 30,
      targetUnitsPerDay: int.tryParse(json['target_units_per_day']?.toString() ?? '0') ?? 0,
      targetUnitsPerMonth: int.tryParse(json['target_units_per_month']?.toString() ?? '0') ?? 0,
      potensiOmzet: double.tryParse(json['potensi_omzet']?.toString() ?? '0') ?? 0.0,
      totalBiayaProduksi: double.tryParse(json['total_biaya_produksi']?.toString() ?? '0') ?? 0.0,
      totalBiayaTetap: double.tryParse(json['total_biaya_tetap']?.toString() ?? '0') ?? 0.0,
      proyeksiLabaBersih: double.tryParse(json['proyeksi_laba_bersih']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'selling_price': sellingPrice,
      'unit_cost': unitCost,
      'net_margin_per_unit': netMarginPerUnit,
      'target_laba_bulanan': targetLabaBulanan,
      'hari_operasional_sebulan': hariOperasionalSebulan,
      'target_units_per_day': targetUnitsPerDay,
      'target_units_per_month': targetUnitsPerMonth,
      'potensi_omzet': potensiOmzet,
      'total_biaya_produksi': totalBiayaProduksi,
      'total_biaya_tetap': totalBiayaTetap,
      'proyeksi_laba_bersih': proyeksiLabaBersih,
    };
  }
}

class HppCalculationModel {
  final List<ProductIngredientModel> ingredients;
  final HppCalculationSummary summary;
  final Map<String, HppPricingTierItem> pricingTiers;
  final HppCustomAnalysis? customAnalysis;
  final HppSalesProjection? salesProjection;

  HppCalculationModel({
    this.ingredients = const [],
    required this.summary,
    this.pricingTiers = const {},
    this.customAnalysis,
    this.salesProjection,
  });

  factory HppCalculationModel.fromJson(Map<String, dynamic> json) {
    final rawIngredients = json['ingredients'];
    List<ProductIngredientModel> parsedIngredients = [];
    if (rawIngredients is List) {
      parsedIngredients = rawIngredients
          .whereType<Map>()
          .map((i) => ProductIngredientModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }

    final rawTiers = json['pricing_tiers'];
    Map<String, HppPricingTierItem> parsedTiers = {};
    if (rawTiers is Map) {
      rawTiers.forEach((key, val) {
        if (val is Map) {
          parsedTiers[key.toString()] = HppPricingTierItem.fromJson(Map<String, dynamic>.from(val));
        }
      });
    }

    return HppCalculationModel(
      ingredients: parsedIngredients,
      summary: json['summary'] is Map
          ? HppCalculationSummary.fromJson(Map<String, dynamic>.from(json['summary']))
          : HppCalculationSummary(),
      pricingTiers: parsedTiers,
      customAnalysis: json['custom_analysis'] is Map
          ? HppCustomAnalysis.fromJson(Map<String, dynamic>.from(json['custom_analysis']))
          : null,
      salesProjection: json['sales_projection'] is Map
          ? HppSalesProjection.fromJson(Map<String, dynamic>.from(json['sales_projection']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'summary': summary.toJson(),
      'pricing_tiers': pricingTiers.map((k, v) => MapEntry(k, v.toJson())),
      'custom_analysis': customAnalysis?.toJson(),
      'sales_projection': salesProjection?.toJson(),
    };
  }
}
