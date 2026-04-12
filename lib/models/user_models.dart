import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;


enum UserRole { customer, admin }
 
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final DateTime createdAt;
 
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
  });
 
  bool get isAdmin => role == UserRole.admin;
 
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.customer,
      createdAt: _parseDate(map['createdAt']),
    );
  }
 
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role == UserRole.admin ? 'admin' : 'customer',
      'createdAt': createdAt,
    };
  }
 
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return value.toDate();
    } catch (_) {
      return DateTime.now();
    }
  }
 
  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }
}