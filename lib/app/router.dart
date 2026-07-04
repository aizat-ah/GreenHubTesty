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
import '../features/admin/admin_driver_management.dart';
import '../features/admin/admin_assign_driver_screen.dart';
import '../features/admin/manage_products_screen.dart';
import '../features/admin/sales_report_screen.dart';
import '../features/supplier/supplier_dashboard.dart';
import '../features/supplier/supplier_orders_screen.dart';
import '../features/supplier/crop_suggestion_screen.dart';
import '../features/supplier/all_crop_stats_screen.dart';
import '../features/supplier/planting_plan_screen.dart';
import '../features/driver/driver_dashboard.dart';
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

      // Logged in but Firestore user document is missing/null —
      // sign out to prevent getting stuck on the splash screen forever.
      if (isLoggedIn && user == null) {
        ref.read(authNotifierProvider.notifier).signOut();
        return '/login';
      }

      final location = state.matchedLocation;
      String targetHome;
      bool isAllowed;

      if (user?.isAdmin == true) {
        targetHome = '/admin';
        isAllowed = location.startsWith('/admin') ||
            location == '/profile' ||
            isSplashPage ||
            isAuthPage;
      } else if (user?.isSupplier == true) {
        targetHome = '/supplier';
        isAllowed = location.startsWith('/supplier') ||
            location == '/profile' ||
            isSplashPage ||
            isAuthPage;
      } else if (user?.isDriver == true) {
        targetHome = '/driver';
        isAllowed = location.startsWith('/driver') ||
            location == '/profile' ||
            isSplashPage ||
            isAuthPage;
      } else {
        // Default to buyer
        targetHome = '/home';
        final isBuyerPath = location == '/home' ||
            location == '/products' ||
            location == '/cart' ||
            location == '/checkout' ||
            location == '/order-success' ||
            location == '/orders';
        isAllowed = isBuyerPath ||
            location == '/profile' ||
            isSplashPage ||
            isAuthPage;
      }

      if (!isAllowed || isAuthPage || isSplashPage) {
        return targetHome;
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
        path: '/supplier/suggestions',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const CropSuggestionScreen()),
      ),
      GoRoute(
        path: '/supplier/suggestions/all',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const AllCropStatsScreen()),
      ),
      GoRoute(
        path: '/supplier/suggestions/plan',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const PlantingPlanScreen()),
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
      GoRoute(
        path: '/admin/drivers',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const AdminDriverManagement()),
      ),
      GoRoute(
        path: '/admin/assign-driver',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const AdminAssignDriverScreen()),
      ),
      GoRoute(
        path: '/admin/reports',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const SalesReportScreen()),
      ),
      // ── Driver ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/driver',
        pageBuilder: (context, state) =>
            _buildSmoothPage(state, const DriverDashboard()),
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
