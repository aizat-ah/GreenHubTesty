import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import 'admin_orders_screen.dart';
 
class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});
 
@override
Widget build(BuildContext context, WidgetRef ref) {
  final userAsync = ref.watch(currentUserProvider);
  final ordersAsync = ref.watch(adminOrdersProvider);

  return Scaffold(
    backgroundColor: AppTheme.background,
    appBar: AppBar(
      title: const Text('Dashboard'),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: () =>
              ref.read(authNotifierProvider.notifier).signOut(),
          tooltip: 'Sign out',
        ),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            'Hi, ${userAsync.maybeWhen(data: (user) => user?.name.split(' ').first, orElse: () => null) ?? 'Admin'} 👋',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Here\'s your store overview',
              style: TextStyle(fontSize: 14, color: AppTheme.textMid),
            ),
            const SizedBox(height: 24),
 
            // Stats row
            ordersAsync.when(
              data: (orders) => _StatsRow(orders: orders),
              loading: () => const SizedBox(
                height: 90,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
 
            // Quick actions
            const Text(
              'Manage',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textLight,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
 
            _QuickAction(
              icon: Icons.receipt_long_rounded,
              title: 'Orders',
              subtitle: 'View and update all customer orders',
              badge: ordersAsync.maybeWhen(
                data: (orders) => orders
                    .where((o) => o.status == OrderStatus.pending)
                    .length,
                orElse: () => null,
              ),
              onTap: () => context.push('/admin/orders'),
            ),
            const SizedBox(height: 10),
            _QuickAction(
              icon: Icons.eco_rounded,
              title: 'Products',
              subtitle: 'Add, edit, and manage stock',
              onTap: () => context.push('/admin/products'),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ─── Stats summary row ────────────────────────────────────────────────────────
 
class _StatsRow extends StatelessWidget {
  final List<OrderModel> orders;
 
  const _StatsRow({required this.orders});
 
  @override
  Widget build(BuildContext context) {
    final pending =
        orders.where((o) => o.status == OrderStatus.pending).length;
    final confirmed =
        orders.where((o) => o.status == OrderStatus.confirmed).length;
    final completed =
        orders.where((o) => o.status == OrderStatus.completed).length;
    final totalRevenue = orders
        .where((o) => o.status == OrderStatus.completed)
        .fold(0.0, (sum, o) => sum + o.totalPrice);
 
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pending',
                value: '$pending',
                color: const Color(0xFFE65100),
                bg: const Color(0xFFFFF3E0),
                icon: '🕐',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Confirmed',
                value: '$confirmed',
                color: const Color(0xFF2E7D32),
                bg: const Color(0xFFE8F5E9),
                icon: '✅',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Completed',
                value: '$completed',
                color: const Color(0xFF1565C0),
                bg: const Color(0xFFE3F2FD),
                icon: '🎉',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Revenue',
                value: 'RM ${totalRevenue.toStringAsFixed(0)}',
                color: AppTheme.primary,
                bg: AppTheme.primary.withOpacity(0.08),
                icon: '💰',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
 
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final String icon;
 
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.icon,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
 
// ─── Quick action tile ────────────────────────────────────────────────────────
 
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int? badge;
  final VoidCallback onTap;
 
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMid),
                  ),
                ],
              ),
            ),
            if (badge != null && badge! > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}