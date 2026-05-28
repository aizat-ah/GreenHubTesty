// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_models.dart';
import '../models/driver_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Stream<UserModel?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    });
  }

  // Register with specified role (defaults to buyer).
  // For driver role, also pass vehicleType and vehiclePlate.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    UserRole role = UserRole.buyer,
    String vehicleType = 'Motorcycle',
    String vehiclePlate = '',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      final user = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        createdAt: DateTime.now(),
      );

      final batch = _db.batch();

      // Always write to users collection
      batch.set(_db.collection('users').doc(uid), user.toMap());

      // If driver, also write to drivers collection
      if (role == UserRole.driver) {
        final driver = DriverModel(
          uid: uid,
          name: name.trim(),
          email: email.trim(),
          phone: phone.trim(),
          vehicleType: vehicleType,
          vehiclePlate: vehiclePlate.trim().toUpperCase(),
          status: DriverStatus.available,
          createdAt: DateTime.now(),
        );
        batch.set(_db.collection('drivers').doc(uid), driver.toMap());
      }

      await batch.commit();
      await credential.user!.updateDisplayName(name.trim());
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = await getUserData(credential.user!.uid);
      if (user == null) throw Exception('User profile not found.');
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  Future<void> signOut() async => await _auth.signOut();

  Future<void> updateUserData(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).update({
        'name': user.name,
        'phone': user.phone,
        'photoUrl': user.photoUrl,
      });
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':  return 'This email is already registered.';
      case 'invalid-email':         return 'Please enter a valid email address.';
      case 'weak-password':         return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':    return 'Incorrect email or password.';
      case 'user-disabled':         return 'This account has been disabled.';
      case 'too-many-requests':     return 'Too many attempts. Please try again later.';
      default:                      return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
