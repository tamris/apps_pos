class AdminCategoryModel {
  final int id;
  final String name;
  final String? description;
  final int productsCount;

  AdminCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.productsCount = 0,
  });

  factory AdminCategoryModel.fromJson(Map<String, dynamic> json) {
    return AdminCategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      productsCount: json['products_count'] is int
          ? json['products_count']
          : int.tryParse(json['products_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'products_count': productsCount,
    };
  }
}
