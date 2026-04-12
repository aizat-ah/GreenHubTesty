import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:greenhub/models/order_model.dart';

import '../providers/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/products/product_list_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/orders/checkout_screen.dart';
import '../features/orders/order_success_screen.dart';
import '../features/orders/my_orders_screen.dart';
import '../features/admin/admin_dashboard.dart';
import '../features/admin/admin_user_management.dart';
import '../features/admin/admin_order_monitor.dart';
import '../features/admin/manage_products_screen.dart';
import '../features/supplier/supplier_dashboard.dart';
import '../features/supplier/supplier_orders_screen.dart';
import '../features/profile/profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading || currentUser.isLoading;
      final isLoggedIn = authState.hasValue && authState.value != null;
      final user = currentUser.hasValue ? currentUser.value : null;
      final isAuthPage =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isSplashPage = state.matchedLocation == '/splash';

      if (isLoading) {
        return isSplashPage ? null : '/splash';
      }

      if (!isLoggedIn) {
        if (isAuthPage) return null;
        return '/login';
      }

      if (isLoggedIn && (isAuthPage || isSplashPage)) {
        if (user?.isAdmin == true) return '/admin';
        if (user?.isSupplier == true) return '/supplier';
        return '/home';
      }

      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const ProfileScreen()),
      ),

      // ── Buyer ─────────────────────────────────────────────
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const ProductListScreen()),
      ),
      GoRoute(
        path: '/products',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const ProductListScreen()),
      ),
      GoRoute(
        path: '/cart',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const CartScreen()),
      ),
      GoRoute(
        path: '/checkout',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const CheckoutScreen()),
      ),
      GoRoute(
        path: '/order-success',
        pageBuilder: (context, state) {
          final order = state.extra as OrderModel;
          return _buildSmoothPage(state, OrderSuccessScreen(order: order));
        },
      ),
      GoRoute(
        path: '/orders',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const MyOrdersScreen()),
      ),

      // ── Supplier / Admin ───────────────────────────────────
      GoRoute(
        path: '/supplier',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const SupplierDashboard()),
      ),
      GoRoute(
        path: '/supplier/orders',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const SupplierOrdersScreen()),
      ),
      GoRoute(
        path: '/supplier/products',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const ManageProductsScreen()),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const AdminDashboard()),
      ),
      GoRoute(
        path: '/admin/users',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const AdminUserManagement()),
      ),
      GoRoute(
        path: '/admin/orders',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const AdminOrderMonitor()),
      ),
      GoRoute(
        path: '/admin/products',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const ManageProductsScreen()),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
});

CustomTransitionPage _buildSmoothPage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeIn).animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.98,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeOutCirc)).animate(animation),
          child: child,
        ),
      );
    },
  );
}
