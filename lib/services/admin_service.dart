import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_models.dart';
import '../models/order_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService();
});

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ──Users────────────────────────────────────────────────────────────────
  Stream<List<UserModel>> getUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addUser({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required String password,
  }) async {
    // Secondary Firebase app to avoid logging out the current admin
    final tempApp = await Firebase.initializeApp(
      name: 'temp_admin_creation_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      final auth = FirebaseAuth.instanceFor(app: tempApp);
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = userCredential.user!.uid;

      final newUser = UserModel(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(newUser.toMap());
    } finally {
      await tempApp.delete();
    }
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    await _firestore.collection('users').doc(uid).update({
      'role': role.name,
    });
  }

  Future<void> deleteUser(String uid) async {
    // Deletes the Firestore user document.
    // TODO: Firebase Auth account deletion requires a Cloud Function with Admin SDK.
    // Doing it from the client app is not permitted without that user's valid session.
    await _firestore.collection('users').doc(uid).delete();
  }

  // ──Orders───────────────────────────────────────────────────────────────
  Stream<List<OrderModel>> getOrdersStream() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status.name,
    });
  }
}
