// ISOTOPE — Admin User Model
// Special tier for founders/admins with lifetime free access

class AdminUser {
  final String id;
  final String email;
  final String name;
  final String role; // 'founder', 'admin', 'elon'
  final bool lifetimeFree;
  final DateTime createdAt;
  final List<String> permissions;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.lifetimeFree = true,
    required this.createdAt,
    this.permissions = const ['view_all', 'manage_users', 'view_revenue'],
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'admin',
      lifetimeFree: json['lifetimeFree'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'lifetimeFree': lifetimeFree,
      'createdAt': createdAt.toIso8601String(),
      'permissions': permissions,
    };
  }

  bool get isFounder => role == 'founder';
  bool get isElon => role == 'elon';
  bool get isAdmin => role == 'admin' || isFounder || isElon;

  bool get canManageUsers => permissions.contains('manage_users');
  bool get canViewRevenue => permissions.contains('view_revenue');
  bool get canViewAllSignals => permissions.contains('view_all');
}

// Pre-defined admin accounts
class AdminAccounts {
  static const List<Map<String, dynamic>> defaults = [
    {
      'id': 'admin_elkai',
      'email': 'keitumetse0407@gmail.com',
      'name': 'Elkai',
      'role': 'founder',
      'lifetimeFree': true,
      'permissions': ['view_all', 'manage_users', 'view_revenue', 'admin'],
    },
    {
      'id': 'admin_elon',
      'email': 'elon@musk.com',
      'name': 'Elon Musk',
      'role': 'elon',
      'lifetimeFree': true,
      'permissions': ['view_all', 'view_revenue'],
    },
  ];
}
