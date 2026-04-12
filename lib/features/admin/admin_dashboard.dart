import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Hi, ${userAsync.maybeWhen(data: (user) => user?.name.split(' ').first, orElse: () => null) ?? 'Admin'} 👋',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => ref
                                .read(authNotifierProvider.notifier)
                                .signOut(),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Here's your store overview",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Stats ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: ordersAsync.when(
                data: (orders) => _StatsGrid(orders: orders),
                loading: () => const SizedBox(
                  height: 90,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Quick Actions ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MANAGE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textLight,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _QuickActionTile(
                    icon: Icons.receipt_long_rounded,
                    title: 'Orders',
                    subtitle: 'View and update all orders',
                    badge: ordersAsync.maybeWhen(
                      data: (orders) => orders
                          .where((o) => o.status == OrderStatus.pending)
                          .length,
                      orElse: () => null,
                    ),
                    onTap: () => context.push('/admin/orders'),
                  ),
                  const SizedBox(height: 12),

                  _QuickActionTile(
                    icon: Icons.eco_rounded,
                    title: 'Products',
                    subtitle: 'Add, edit and manage all listings',
                    onTap: () => context.push('/admin/products'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final List<OrderModel> orders;
  const _StatsGrid({required this.orders});

  @override
  Widget build(BuildContext context) {
    final pending =
        orders.where((o) => o.status == OrderStatus.pending).length;
    final confirmed =
        orders.where((o) => o.status == OrderStatus.confirmed).length;
    final completed =
        orders.where((o) => o.status == OrderStatus.completed).length;
    final revenue = orders
        .where((o) => o.status == OrderStatus.completed)
        .fold(0.0, (sum, o) => sum + o.totalPrice);

    return Column(
      children: [
        Row(children: [
          Expanded(
              child: _StatCard(
                  label: 'Pending',
                  value: '$pending',
                  icon: '🕐',
                  color: const Color(0xFFE65100),
                  bg: const Color(0xFFFFF3E0))),
          const SizedBox(width: 12),
          Expanded(
              child: _StatCard(
                  label: 'Confirmed',
                  value: '$confirmed',
                  icon: '✅',
                  color: const Color(0xFF2E7D32),
                  bg: const Color(0xFFE8F5E9))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _StatCard(
                  label: 'Completed',
                  value: '$completed',
                  icon: '🎉',
                  color: const Color(0xFF1565C0),
                  bg: const Color(0xFFE3F2FD))),
          const SizedBox(width: 12),
          Expanded(
              child: _StatCard(
                  label: 'Revenue',
                  value: 'RM ${revenue.toStringAsFixed(0)}',
                  icon: '💰',
                  color: AppTheme.primary,
                  bg: AppTheme.primary.withOpacity(0.08))),
        ]),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, icon;
  final Color color, bg;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: color.withOpacity(0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick action tile ────────────────────────────────────────────────────────

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final int? badge;
  final VoidCallback onTap;

  const _QuickActionTile({
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
        padding: const EdgeInsets.all(18),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textMid,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null && badge! > 0) ...[
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}