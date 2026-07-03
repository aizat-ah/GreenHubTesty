import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order_model.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, ref)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroStats(context, ref),
                  const SizedBox(height: 24),
                  _buildQuickNav(context),
                  const SizedBox(height: 24),
                  _buildStatusBreakdown(ref),
                  const SizedBox(height: 24),
                  Text(
                    'Recent Orders',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildRecentOrders(ref),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final adminName = userAsync.value?.name ?? 'Admin';

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        20,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Admin Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _buildActionIcon(
                icon: Icons.people_outline,
                tooltip: 'User Management',
                onPressed: () => context.push('/admin/users'),
              ),
              _buildActionIcon(
                icon: Icons.receipt_long_outlined,
                tooltip: 'Order Monitor',
                onPressed: () => context.push('/admin/orders'),
              ),
              _buildActionIcon(
                icon: Icons.logout,
                tooltip: 'Log out',
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).signOut(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Hi, $adminName 👋',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Platform overview',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 38,
      height: 38,
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildHeroStats(BuildContext context, WidgetRef ref) {
    final revenue = ref.watch(adminTotalRevenueProvider);
    final users = ref.watch(adminTotalUsersProvider);
    final orders = ref.watch(adminOrdersProvider).value?.length ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Revenue',
            value: 'RM\n${revenue.toStringAsFixed(2)}',
            icon: Icons.attach_money,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Users',
            value: '$users',
            icon: Icons.people,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Orders',
            value: '$orders',
            icon: Icons.shopping_bag,
            color: AppTheme.info,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickNav(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => context.push('/admin/users'),
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.manage_accounts,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Manage Users',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.textMid),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DriverNavCard(
                label: 'Manage Drivers',
                icon: Icons.delivery_dining_outlined,
                iconColor: AppTheme.accent,
                iconBgAlpha: 0.15,
                onTap: () => context.push('/admin/drivers'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DriverNavCard(
                label: 'Assign Drivers',
                icon: Icons.person_pin_outlined,
                iconColor: AppTheme.info,
                iconBgAlpha: 0.1,
                onTap: () => context.push('/admin/assign-driver'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBreakdown(WidgetRef ref) {
    final pending = ref.watch(adminPendingOrdersCountProvider);
    final confirmed = ref.watch(adminConfirmedOrdersCountProvider);
    final completed = ref.watch(adminCompletedOrdersCountProvider);
    final cancelled = ref.watch(adminCancelledOrdersCountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Status',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatusItem(
                label: 'Pending',
                count: pending,
                color: const Color(0xFFE65100),
                bgColor: const Color(0xFFFFF3E0),
                emoji: '🕐',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatusItem(
                label: 'Confirmed',
                count: confirmed,
                color: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
                emoji: '✅',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatusItem(
                label: 'Completed',
                count: completed,
                color: const Color(0xFF1565C0),
                bgColor: const Color(0xFFE3F2FD),
                emoji: '🎉',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatusItem(
                label: 'Cancelled',
                count: cancelled,
                color: const Color(0xFFC62828),
                bgColor: const Color(0xFFFFEBEE),
                emoji: '❌',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentOrders(WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('No orders found.'),
              ),
            ),
          );
        }

        final recentOrders = orders.take(5).toList();

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final order = recentOrders[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: InkWell(
                onTap: () => context.push('/admin/orders'),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDim,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            order.status.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.items.length} items • RM ${order.totalPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          order.status.label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(order.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }, childCount: recentOrders.length),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) =>
          SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppTheme.warning;
      case OrderStatus.confirmed:
        return AppTheme.info;
      case OrderStatus.completed:
        return AppTheme.success;
      case OrderStatus.cancelled:
        return AppTheme.error;
      case OrderStatus.outForDelivery:
        return AppTheme.primary;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMid,
            ),
          ),
        ],
      ),
    );
  }
}

// Vertical nav card used for "Manage Drivers" / "Assign Drivers": icon on
// top, centered label below (unlike the icon-beside-text row layout used
// by "Manage Users"), with the tap-affordance chevron pinned to the
// card's top-right corner instead of trailing the label. Giving the label
// the full card width (rather than sharing it with the icon) is what lets
// it wrap at word boundaries instead of mid-word.
class _DriverNavCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final double iconBgAlpha;
  final VoidCallback onTap;

  const _DriverNavCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBgAlpha,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Stack(
          children: [
            const Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.chevron_right,
                color: AppTheme.textMid,
                size: 20,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: iconBgAlpha),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bgColor;
  final String emoji;

  const _StatusItem({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
