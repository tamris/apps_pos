class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'cashier',
      isActive: json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_active': isActive,
    };
  }

  bool get isAdmin => role.toLowerCase() == 'admin' || role.toLowerCase() == 'owner';
  bool get isOwner => role.toLowerCase() == 'owner';
  bool get isCashier => role.toLowerCase() == 'kasir' || role.toLowerCase() == 'cashier';
}
