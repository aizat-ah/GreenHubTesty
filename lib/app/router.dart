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
import '../features/admin/admin_orders_screen.dart';
import '../features/admin/manage_products_screen.dart';
import '../features/supplier/supplier_dashboard.dart';
import '../features/supplier/supplier_orders_screen.dart';
import '../features/supplier/manage_products_screen.dart' hide ManageProductsScreen;

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
        return '/home';
      }

      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Buyer ─────────────────────────────────────────────
      GoRoute(
        path: '/home',
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListScreen(),
      ),

      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-success',
        builder: (context, state) {
          final order = state.extra as OrderModel;
          return OrderSuccessScreen(order: order);
        },
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const MyOrdersScreen(),
      ),

      // ── Supplier / Admin ───────────────────────────────────
      GoRoute(path: '/supplier', builder: (_, __) => const SupplierDashboard()),
      GoRoute(
        path: '/supplier/orders',
        builder: (_, __) => const SupplierOrdersScreen(),
      ),
      GoRoute(
        path: '/supplier/products',
        builder: (_, __) => const ManageProductsScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const ManageProductsScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );
});
