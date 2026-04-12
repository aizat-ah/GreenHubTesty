import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greenhub/models/user_models.dart';
 
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
 
  // Stream of Firebase auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
 
  // Current Firebase user
  User? get currentUser => _auth.currentUser;
 
  // Fetch user document from Firestore
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
 
  // Stream user data (live updates)
  Stream<UserModel?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    });
  }
 
  // Register with email & password
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
 
      final user = UserModel(
        uid: credential.user!.uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: UserRole.customer, // all new users are customers by default
        createdAt: DateTime.now(),
      );
 
      // Save user document to Firestore
      await _db
          .collection('users')
          .doc(credential.user!.uid)
          .set(user.toMap());
 
      // Update Firebase display name
      await credential.user!.updateDisplayName(name.trim());
 
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }
 
  // Sign in with email & password
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
 
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
 
  // Password reset
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e);
    }
  }
 
  // Map Firebase error codes to readable messages
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}