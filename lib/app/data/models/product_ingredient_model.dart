class ProductIngredientModel {
  final int? id;
  final int? productId;
  final String name;
  final double amount;
  final String unit;
  final double buyPrice;
  final double buyAmount;
  final String buyUnit;
  final double subtotal;

  ProductIngredientModel({
    this.id,
    this.productId,
    required this.name,
    required this.amount,
    required this.unit,
    required this.buyPrice,
    this.buyAmount = 1.0,
    required this.buyUnit,
    double? subtotal,
  }) : subtotal = (subtotal != null && subtotal > 0)
            ? subtotal
            : calculateLocalSubtotal(amount, unit, buyPrice, buyAmount, buyUnit);

  factory ProductIngredientModel.fromJson(Map<String, dynamic> json) {
    final amountVal = double.tryParse(json['amount']?.toString() ?? json['takaran']?.toString() ?? '0') ?? 0.0;
    final buyPriceVal = double.tryParse(json['buy_price']?.toString() ?? json['harga_beli']?.toString() ?? '0') ?? 0.0;
    final rawBuyAmount = double.tryParse(json['buy_amount']?.toString() ?? json['jumlah_beli']?.toString() ?? '1') ?? 1.0;
    final buyAmountVal = rawBuyAmount <= 0 ? 1.0 : rawBuyAmount;
    final unitVal = (json['unit'] ?? json['satuan_takaran'] ?? 'gram').toString();
    final buyUnitVal = (json['buy_unit'] ?? json['satuan_beli'] ?? 'kg').toString();
    final subtotalVal = (json['subtotal'] != null)
        ? (double.tryParse(json['subtotal'].toString()) ?? 0.0)
        : calculateLocalSubtotal(amountVal, unitVal, buyPriceVal, buyAmountVal, buyUnitVal);

    return ProductIngredientModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      productId: json['product_id'] is int ? json['product_id'] : int.tryParse(json['product_id']?.toString() ?? ''),
      name: (json['name'] ?? json['nama'] ?? '').toString(),
      amount: amountVal,
      unit: unitVal,
      buyPrice: buyPriceVal,
      buyAmount: buyAmountVal,
      buyUnit: buyUnitVal,
      subtotal: subtotalVal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      'name': name,
      'amount': amount,
      'unit': unit,
      'buy_price': buyPrice,
      'buy_amount': buyAmount,
      'buy_unit': buyUnit,
      'subtotal': subtotal,
    };
  }

  ProductIngredientModel copyWith({
    int? id,
    int? productId,
    String? name,
    double? amount,
    String? unit,
    double? buyPrice,
    double? buyAmount,
    String? buyUnit,
    double? subtotal,
  }) {
    final newAmount = amount ?? this.amount;
    final newUnit = unit ?? this.unit;
    final newBuyPrice = buyPrice ?? this.buyPrice;
    final newBuyAmount = buyAmount ?? this.buyAmount;
    final newBuyUnit = buyUnit ?? this.buyUnit;

    return ProductIngredientModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      amount: newAmount,
      unit: newUnit,
      buyPrice: newBuyPrice,
      buyAmount: newBuyAmount,
      buyUnit: newBuyUnit,
      subtotal: subtotal ?? calculateLocalSubtotal(newAmount, newUnit, newBuyPrice, newBuyAmount, newBuyUnit),
    );
  }

  static double calculateLocalSubtotal(
    double amount,
    String unit,
    double buyPrice,
    double buyAmount,
    String buyUnit,
  ) {
    if (amount <= 0 || buyPrice <= 0 || buyAmount <= 0) return 0.0;

    final u = unit.toLowerCase().trim();
    final bu = buyUnit.toLowerCase().trim();

    // Ratio konversi takaran ke satuan beli
    double ratio = 1.0;
    if ((u == 'gram' || u == 'gr' || u == 'g') && (bu == 'kg' || bu == 'kilogram')) {
      ratio = 0.001;
    } else if ((u == 'kg' || u == 'kilogram') && (bu == 'gram' || bu == 'gr' || bu == 'g')) {
      ratio = 1000.0;
    } else if ((u == 'ml' || u == 'mililiter') && (bu == 'liter' || bu == 'l')) {
      ratio = 0.001;
    } else if ((u == 'liter' || u == 'l') && (bu == 'ml' || bu == 'mililiter')) {
      ratio = 1000.0;
    }

    final pricePerBuyUnit = buyPrice / buyAmount;
    return (amount * ratio * pricePerBuyUnit);
  }
}
