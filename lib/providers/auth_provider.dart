import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:greenhub/models/user_models.dart';
import '../services/auth_service.dart';
 
// Auth service singleton
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
 
// Firebase auth state stream (is user logged in?)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
 
// Current UserModel from Firestore (live stream)
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(authServiceProvider).userStream(user.uid);
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});
 
// Notifier for auth actions (login, register, logout)
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;
 
  AuthNotifier(this._authService) : super(const AsyncValue.data(null));
 
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signIn(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
 
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
      );
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
 
  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }
}
 
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});