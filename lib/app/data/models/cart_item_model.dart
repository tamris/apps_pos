import 'addon_model.dart';
import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  double basePrice;
  List<AddonModel> addons;
  String sugarLevel; // 'Normal', 'Less Sugar (50%)', 'No Sugar (0%)', 'Extra'
  String iceLevel;   // 'Normal Ice', 'Less Ice', 'No Ice', 'Hot'
  String notes;      // e.g. "Bungkus terpisah", "Pedas level 3"
  double? _customPrice;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    double? basePrice,
    double? price,
    List<AddonModel>? addons,
    this.sugarLevel = 'Normal',
    this.iceLevel = 'Normal Ice',
    this.notes = '',
  })  : basePrice = basePrice ?? product.price,
        addons = addons ?? [],
        _customPrice = price;

  double get totalAddonsPrice => addons.fold(0.0, (sum, a) => sum + a.price);

  double get price => _customPrice ?? (basePrice + totalAddonsPrice);
  set price(double value) => _customPrice = value;

  double get subtotal => price * quantity;

  /// Generate a unique custom hash key to distinguish same product with different customizations and addons
  String get itemKey {
    final sortedAddonIds = addons.map((a) => a.id).toList()..sort();
    return '${product.id}_${sugarLevel}_${iceLevel}_${sortedAddonIds.join(",")}_${notes.trim()}';
  }

  /// Human readable customization summary for UI & receipt
  String get customizationSummary {
    final List<String> parts = [];
    if (addons.isNotEmpty) {
      parts.add(addons.map((a) => '+ ${a.name}').join(', '));
    }
    if (sugarLevel != 'Normal' && sugarLevel.isNotEmpty) {
      parts.add(sugarLevel);
    }
    if (iceLevel != 'Normal Ice' && iceLevel != 'Normal' && iceLevel.isNotEmpty) {
      parts.add(iceLevel);
    }
    if (notes.trim().isNotEmpty) {
      parts.add(notes.trim());
    }
    return parts.join(' • ');
  }

  /// Format variant/options & manual notes for backend (excluding addons which have their own field)
  String get variantNotesString {
    final List<String> parts = [];
    if (sugarLevel != 'Normal' && sugarLevel.isNotEmpty) {
      parts.add(sugarLevel);
    }
    if (iceLevel != 'Normal Ice' && iceLevel != 'Normal' && iceLevel.isNotEmpty) {
      parts.add(iceLevel);
    }
    if (notes.trim().isNotEmpty) {
      parts.add(notes.trim());
    }
    return parts.join(' - ');
  }

  /// Format full notes string sent to backend
  String get fullNotesString {
    final summary = variantNotesString;
    return summary.isEmpty ? '' : summary;
  }

  /// For checkout payload
  Map<String, dynamic> toApiJson() {
    return {
      'id': product.id,
      'product_id': product.id,
      'name': product.name,
      'quantity': quantity,
      'price': price,
      'unit_price': price,
      'total_price': subtotal,
      'notes': fullNotesString.isEmpty ? null : fullNotesString,
      'addons': addons.map((a) => a.toApiJson()).toList(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'base_price': basePrice,
      'price': price,
      'addons': addons.map((a) => a.toJson()).toList(),
      'sugar_level': sugarLevel,
      'ice_level': iceLevel,
      'notes': notes,
    };
  }

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    double? basePrice,
    double? price,
    List<AddonModel>? addons,
    String? sugarLevel,
    String? iceLevel,
    String? notes,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      basePrice: basePrice ?? this.basePrice,
      price: price ?? _customPrice,
      addons: addons ?? List.from(this.addons),
      sugarLevel: sugarLevel ?? this.sugarLevel,
      iceLevel: iceLevel ?? this.iceLevel,
      notes: notes ?? this.notes,
    );
  }
}
