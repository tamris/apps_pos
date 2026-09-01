import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  double price;
  String sugarLevel; // 'Normal', 'Less Sugar (50%)', 'No Sugar (0%)', 'Extra'
  String iceLevel;   // 'Normal Ice', 'Less Ice', 'No Ice', 'Hot'
  String notes;      // e.g. "Bungkus terpisah", "Pedas level 3"

  CartItemModel({
    required this.product,
    this.quantity = 1,
    double? price,
    this.sugarLevel = 'Normal',
    this.iceLevel = 'Normal Ice',
    this.notes = '',
  }) : price = price ?? product.price;

  double get subtotal => price * quantity;

  /// Generate a unique custom hash key to distinguish same product with different customizations
  String get itemKey => '${product.id}_${sugarLevel}_${iceLevel}_${notes.trim()}';

  /// Human readable customization summary for UI & receipt
  String get customizationSummary {
    final List<String> parts = [];
    if (sugarLevel != 'Normal' && sugarLevel.isNotEmpty) {
      parts.add(sugarLevel);
    }
    if (iceLevel != 'Normal Ice' && iceLevel.isNotEmpty) {
      parts.add(iceLevel);
    }
    if (notes.trim().isNotEmpty) {
      parts.add(notes.trim());
    }
    return parts.join(' • ');
  }

  /// Format full notes string sent to backend / receipt
  String get fullNotesString {
    final summary = customizationSummary;
    return summary.isEmpty ? '' : summary;
  }

  /// For checkout payload
  Map<String, dynamic> toApiJson() {
    return {
      'id': product.id,
      'quantity': quantity,
      'price': price,
      'notes': fullNotesString.isEmpty ? null : fullNotesString,
    };
  }

  CartItemModel copyWith({
    ProductModel? product,
    int? quantity,
    double? price,
    String? sugarLevel,
    String? iceLevel,
    String? notes,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      sugarLevel: sugarLevel ?? this.sugarLevel,
      iceLevel: iceLevel ?? this.iceLevel,
      notes: notes ?? this.notes,
    );
  }
}
