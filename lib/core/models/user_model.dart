class UserModel {
  final String id;
  final String name;
  final String username;
  final String role; // 'admin' | 'kasir'
  final bool isActive;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:       json['id'] as String? ?? '',
      name:     json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role:     json['role'] as String? ?? 'kasir',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'role': role,
    'isActive': isActive,
  };
}
