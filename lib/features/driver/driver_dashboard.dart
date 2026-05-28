// lib/features/driver/driver_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/driver_model.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import '../../services/driver_service.dart';

class DriverDashboard extends ConsumerWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final ordersAsync = ref.watch(driverOrdersProvider(user.uid));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, ref, user.name)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(context, ref, user.uid, ordersAsync),
                  const SizedBox(height: 24),
                  Text(
                    'My Deliveries',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
          _buildDeliveryList(context, ref, user.uid, ordersAsync),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String name) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.delivery_dining,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $name 👋',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                Text(
                  'Driver Dashboard',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Log out',
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    WidgetRef ref,
    String driverId,
    AsyncValue<List<OrderModel>> ordersAsync,
  ) {
    final driversAsync = ref.watch(allDriversProvider);
    final driver = driversAsync.value?.firstWhere(
      (d) => d.uid == driverId,
      orElse: () => DriverModel(
        uid: driverId,
        name: '',
        email: '',
        phone: '',
        vehicleType: '',
        vehiclePlate: '',
        status: DriverStatus.available,
        createdAt: DateTime.now(),
      ),
    );

    final totalDeliveries = ordersAsync.value?.length ?? 0;
    final completedDeliveries = ordersAsync.value
            ?.where((o) => o.status == OrderStatus.completed)
            .length ??
        0;
    final activeDeliveries = ordersAsync.value
            ?.where((o) => o.status == OrderStatus.outForDelivery)
            .length ??
        0;

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Status',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const Spacer(),
              if (driver != null)
                _StatusToggleButton(driver: driver),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statTile('Total', totalDeliveries.toString()),
              const SizedBox(width: 12),
              _statTile('Active', activeDeliveries.toString()),
              const SizedBox(width: 12),
              _statTile('Done', completedDeliveries.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryList(
    BuildContext context,
    WidgetRef ref,
    String driverId,
    AsyncValue<List<OrderModel>> ordersAsync,
  ) {
    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Icon(Icons.inbox_outlined,
                        size: 56, color: AppTheme.textLight),
                    const SizedBox(height: 12),
                    Text('No deliveries assigned yet',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMid)),
                  ],
                ),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: _DeliveryCard(order: orders[i], driverId: driverId),
            ),
            childCount: orders.length,
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SliverToBoxAdapter(
          child: Center(child: Text('Error: $e'))),
    );
  }
}

// ── Status Toggle ─────────────────────────────────────────────────────────────

class _StatusToggleButton extends ConsumerStatefulWidget {
  final DriverModel driver;
  const _StatusToggleButton({required this.driver});

  @override
  ConsumerState<_StatusToggleButton> createState() =>
      _StatusToggleButtonState();
}

class _StatusToggleButtonState
    extends ConsumerState<_StatusToggleButton> {
  bool _loading = false;

  Future<void> _toggle() async {
    final newStatus = widget.driver.status == DriverStatus.offline
        ? DriverStatus.available
        : DriverStatus.offline;
    setState(() => _loading = true);
    await ref
        .read(driverServiceProvider)
        .updateDriverStatus(widget.driver.uid, newStatus);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = widget.driver.status == DriverStatus.offline;
    return GestureDetector(
      onTap: _loading ? null : _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isOffline
              ? Colors.white.withValues(alpha: 0.2)
              : AppTheme.success.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: _loading
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(
                isOffline ? '⚫ Go Online' : '🟢 Online',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
      ),
    );
  }
}

// ── Delivery Card ─────────────────────────────────────────────────────────────

class _DeliveryCard extends ConsumerStatefulWidget {
  final OrderModel order;
  final String driverId;

  const _DeliveryCard({required this.order, required this.driverId});

  @override
  ConsumerState<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends ConsumerState<_DeliveryCard> {
  bool _marking = false;

  Future<void> _markDelivered() async {
    setState(() => _marking = true);
    try {
      await ref.read(driverServiceProvider).markDelivered(
            orderId: widget.order.id,
            driverId: widget.driverId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as delivered! ✅'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isActive = order.status == OrderStatus.outForDelivery;
    final isCompleted = order.status == OrderStatus.completed;
    final dateStr =
        DateFormat('dd MMM, hh:mm a').format(order.createdAt);

    final statusColor = isCompleted
        ? AppTheme.success
        : isActive
            ? AppTheme.warning
            : AppTheme.textLight;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: isActive
            ? Border.all(color: AppTheme.warning.withValues(alpha: 0.4))
            : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${order.id.substring(0, 6).toUpperCase()}',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.customerName,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${order.status.emoji} ${order.status.label}',
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 13, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Text(order.customerPhone,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppTheme.textMid)),
              const Spacer(),
              Text(order.formattedTotal,
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            order.items
                .map((i) => '${i.quantity}× ${i.productName}')
                .join(', '),
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppTheme.textMid),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: GoogleFonts.poppins(
                fontSize: 11, color: AppTheme.textLight),
          ),
          if (order.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDim,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_outlined,
                      size: 13, color: AppTheme.textLight),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.note,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppTheme.textMid),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isActive) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _marking ? null : _markDelivered,
                icon: _marking
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  'Mark as Delivered',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
