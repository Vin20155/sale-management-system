class UserModel {
  final int id;
  String name;
  String email;
  String role; // 'admin', 'stock_controller', 'cashier'
  String phone;
  bool isActive;
  final String createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.isActive = true,
    this.createdAt = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'cashier',
      phone: json['phone'] ?? '',
      isActive: json['is_active'] == null
          ? true
          : (json['is_active'] == 1 ||
              json['is_active'] == true ||
              json['is_active'] == '1'),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };
}
