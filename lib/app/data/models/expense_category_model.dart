class ExpenseCategoryModel {
  final int id;
  final String name;
  final String slug;
  final String type; // 'expense', 'cash_in', 'both'
  final String? description;
  final bool isDefault;
  final bool isActive;

  ExpenseCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    this.description,
    this.isDefault = false,
    this.isActive = true,
  });

  bool get isExpense => type == 'expense' || type == 'both';
  bool get isCashIn => type == 'cash_in' || type == 'both';

  factory ExpenseCategoryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      type: json['type']?.toString() ?? 'expense',
      description: json['description']?.toString(),
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      isActive: json['is_active'] != false && json['is_active'] != 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'type': type,
      'description': description,
      'is_default': isDefault,
      'is_active': isActive,
    };
  }
}
