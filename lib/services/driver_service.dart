// lib/services/driver_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/driver_model.dart';
import '../models/order_model.dart';

final driverServiceProvider = Provider<DriverService>((ref) {
  return DriverService();
});

class DriverService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _drivers => _db.collection('drivers');
  CollectionReference get _orders => _db.collection('orders');

  // ── Driver CRUD ───────────────────────────────────────────────────────────

  Stream<List<DriverModel>> driversStream() {
    return _drivers
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                DriverModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<DriverModel>> availableDriversStream() {
    return _drivers
        .where('status', isEqualTo: 'available')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                DriverModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> addDriver({
    required String name,
    required String email,
    required String phone,
    required String vehicleType,
    required String vehiclePlate,
    required String password,
  }) async {
    // Use a secondary app so we don't log out the current admin
    final tempApp = await Firebase.initializeApp(
      name: 'temp_driver_creation_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      final auth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      final driver = DriverModel(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        vehicleType: vehicleType,
        vehiclePlate: vehiclePlate,
        status: DriverStatus.available,
        createdAt: DateTime.now(),
      );

      // Store in both 'drivers' and 'users' collections for role-based routing
      final batch = _db.batch();
      batch.set(_drivers.doc(uid), driver.toMap());
      batch.set(_db.collection('users').doc(uid), {
        ...driver.toMap(),
        'role': 'driver',
      });
      await batch.commit();
    } finally {
      await tempApp.delete();
    }
  }

  Future<void> updateDriver(DriverModel driver) async {
    final batch = _db.batch();
    batch.update(_drivers.doc(driver.uid), {
      'name': driver.name,
      'phone': driver.phone,
      'vehicleType': driver.vehicleType,
      'vehiclePlate': driver.vehiclePlate,
      'status': driver.status.name,
    });
    batch.update(_db.collection('users').doc(driver.uid), {
      'name': driver.name,
      'phone': driver.phone,
    });
    await batch.commit();
  }

  Future<void> updateDriverStatus(String driverId, DriverStatus status) async {
    await _drivers.doc(driverId).update({'status': status.name});
  }

  Future<void> deleteDriver(String driverId) async {
    final batch = _db.batch();
    batch.delete(_drivers.doc(driverId));
    batch.delete(_db.collection('users').doc(driverId));
    await batch.commit();
  }

  // ── Order Assignment ──────────────────────────────────────────────────────

  /// Assigns a driver to an order and marks the order as outForDelivery.
  /// Also marks the driver as onDelivery.
  Future<void> assignDriverToOrder({
    required String orderId,
    required DriverModel driver,
  }) async {
    final batch = _db.batch();

    batch.update(_orders.doc(orderId), {
      'driverId': driver.uid,
      'driverName': driver.name,
      'driverPhone': driver.phone,
      'driverVehiclePlate': driver.vehiclePlate,
      'status': OrderStatus.outForDelivery.name,
    });

    batch.update(_drivers.doc(driver.uid), {
      'status': DriverStatus.onDelivery.name,
    });

    await batch.commit();
  }

  /// Unassigns a driver from an order (reverts status to confirmed).
  Future<void> unassignDriver({
    required String orderId,
    required String driverId,
  }) async {
    final batch = _db.batch();

    batch.update(_orders.doc(orderId), {
      'driverId': FieldValue.delete(),
      'driverName': FieldValue.delete(),
      'driverPhone': FieldValue.delete(),
      'driverVehiclePlate': FieldValue.delete(),
      'status': OrderStatus.confirmed.name,
    });

    batch.update(_drivers.doc(driverId), {
      'status': DriverStatus.available.name,
    });

    await batch.commit();
  }

// ── Driver's own orders ───────────────────────────────────────────────────

  Stream<List<OrderModel>> driverOrdersStream(String driverId) {
    return _orders
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Driver marks a delivery as completed
  Future<void> markDelivered({
    required String orderId,
    required String driverId,
  }) async {
    final batch = _db.batch();

    batch.update(_orders.doc(orderId), {
      'status': OrderStatus.completed.name,
    });

    batch.update(_drivers.doc(driverId), {
      'status': DriverStatus.available.name,
    });

    await batch.commit();
  }

  // ── Confirmed orders needing assignment ──────────────────────────────────

  Stream<List<OrderModel>> confirmedOrdersStream() {
    return _orders
        .where('status', isEqualTo: OrderStatus.confirmed.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
