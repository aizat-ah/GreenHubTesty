// lib/models/driver_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum DriverStatus { available, onDelivery, offline }

extension DriverStatusExt on DriverStatus {
  String get label {
    switch (this) {
      case DriverStatus.available:
        return 'Available';
      case DriverStatus.onDelivery:
        return 'On Delivery';
      case DriverStatus.offline:
        return 'Offline';
    }
  }

  String get emoji {
    switch (this) {
      case DriverStatus.available:
        return '🟢';
      case DriverStatus.onDelivery:
        return '🚚';
      case DriverStatus.offline:
        return '⚫';
    }
  }
}

class DriverModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehiclePlate;
  final DriverStatus status;
  final String? photoUrl;
  final DateTime createdAt;

  const DriverModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.status,
    this.photoUrl,
    required this.createdAt,
  });

  bool get isAvailable => status == DriverStatus.available;

  factory DriverModel.fromMap(Map<String, dynamic> map, String uid) {
    return DriverModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      vehicleType: map['vehicleType'] ?? 'Motorcycle',
      vehiclePlate: map['vehiclePlate'] ?? '',
      status: _parseStatus(map['status']),
      photoUrl: map['photoUrl'],
      createdAt: _parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'vehicleType': vehicleType,
      'vehiclePlate': vehiclePlate,
      'status': status.name,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'role': 'driver',
    };
  }

  DriverModel copyWith({
    String? name,
    String? phone,
    String? vehicleType,
    String? vehiclePlate,
    DriverStatus? status,
    String? photoUrl,
  }) {
    return DriverModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      status: status ?? this.status,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }

  static DriverStatus _parseStatus(String? value) {
    switch (value) {
      case 'onDelivery':
        return DriverStatus.onDelivery;
      case 'offline':
        return DriverStatus.offline;
      default:
        return DriverStatus.available;
    }
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return (value as Timestamp).toDate();
    } catch (_) {
      return DateTime.now();
    }
  }
}
