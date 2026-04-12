
enum UserRole { buyer, supplier, admin }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? photoUrl;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl,
    required this.createdAt,
  });

  bool get isBuyer   => role == UserRole.buyer;
  bool get isSupplier => role == UserRole.supplier;
  bool get isAdmin   => role == UserRole.admin;

  // Supplier AND admin can access the supplier/admin panel
  bool get hasSupplierAccess => role == UserRole.supplier || role == UserRole.admin;

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: _parseRole(map['role']),
      photoUrl: map['photoUrl'],
      createdAt: _parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name, // 'buyer' | 'supplier' | 'admin'
      'photoUrl': photoUrl,
      'createdAt': createdAt,
    };
  }

  static UserRole _parseRole(String? value) {
    switch (value) {
      case 'supplier': return UserRole.supplier;
      case 'admin':    return UserRole.admin;
      default:         return UserRole.buyer;
    }
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try { return value.toDate(); } catch (_) { return DateTime.now(); }
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? photoUrl,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }
}