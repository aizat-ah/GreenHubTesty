import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';

// Supplier all-orders stream provider
final supplierOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(orderServiceProvider).allOrdersStream();
});

// Selected status filter (null = all)
final supplierOrderFilterProvider = StateProvider<OrderStatus?>((ref) => null);

// Filtered supplier orders
final filteredSupplierOrdersProvider = Provider<AsyncValue<List<OrderModel>>>((
  ref,
) {
  final ordersAsync = ref.watch(supplierOrdersProvider);
  final filter = ref.watch(supplierOrderFilterProvider);

  return ordersAsync.whenData((orders) {
    if (filter == null) return orders;
    return orders.where((o) => o.status == filter).toList();
  });
});

class SupplierOrdersScreen extends ConsumerWidget {
  const SupplierOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(filteredSupplierOrdersProvider);
    final allOrdersAsync = ref.watch(supplierOrdersProvider);
    final selectedFilter = ref.watch(supplierOrderFilterProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Buyer Orders',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          allOrdersAsync.when(
            data: (orders) {
              final pendingCount = orders
                  .where((o) => o.status == OrderStatus.pending)
                  .length;
              if (pendingCount == 0) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pendingCount new',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter bar
          _StatusFilterBar(
            selected: selectedFilter,
            onSelected: (status) =>
                ref.read(supplierOrderFilterProvider.notifier).state = status,
            allOrders: allOrdersAsync.maybeWhen(
              data: (orders) => orders,
              orElse: () => [],
            ),
          ),
          const SizedBox(height: 8),

          // Orders list
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return _EmptyOrders(hasFilter: selectedFilter != null);
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _AdminOrderCard(order: orders[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status filter bar ────────────────────────────────────────────────────────

class _StatusFilterBar extends StatelessWidget {
  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelected;
  final List<OrderModel> allOrders;

  const _StatusFilterBar({
    required this.selected,
    required this.onSelected,
    required this.allOrders,
  });

  int _count(OrderStatus? status) {
    if (status == null) return allOrders.length;
    return allOrders.where((o) => o.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final filters = <OrderStatus?>[
      null,
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.completed,
      OrderStatus.cancelled,
    ];

    final labels = {
      null: 'All',
      OrderStatus.pending: '🕐 Pending',
      OrderStatus.confirmed: '✅ Confirmed',
      OrderStatus.completed: '🎉 Done',
      OrderStatus.cancelled: '❌ Cancelled',
    };

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selected == filter;
          final count = _count(filter);

          return GestureDetector(
            onTap: () => onSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.primaryGradient : null,
                color: isSelected ? null : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Text(
                    labels[filter]!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textMid,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : AppTheme.surfaceDim,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.textMid,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Admin order card ─────────────────────────────────────────────────────────

class _AdminOrderCard extends ConsumerWidget {
  final OrderModel order;

  const _AdminOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
        border: order.status == OrderStatus.pending
            ? Border.all(
                color: const Color(0xFFF4A261).withValues(alpha: 0.5),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat(
                          'dd MMM yyyy, hh:mm a',
                        ).format(order.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
          ),

          // Customer info
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDim,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _callCustomer(order.customerPhone),
                    child: Text(
                      order.customerPhone,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Divider(color: AppTheme.divider.withValues(alpha: 0.6), height: 1),

          // Order items
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.eco_rounded,
                          size: 13,
                          color: AppTheme.primaryLight,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${item.productName} × ${item.quantity} ${item.unit}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textMid,
                            ),
                          ),
                        ),
                        Text(
                          item.formattedSubtotal,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (order.note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDE7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📝 ', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Text(
                            order.note,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF5D4037),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(color: AppTheme.divider.withValues(alpha: 0.6), height: 1),

          // Footer: total + actions
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            child: Row(
              children: [
                Text(
                  order.formattedTotal,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
                const Spacer(),
                _ActionButton(
                  icon: '📲',
                  label: 'Chat',
                  color: const Color(0xFF25D366),
                  onTap: () => _whatsappCustomer(order),
                ),
                const SizedBox(width: 8),
                if (order.status != OrderStatus.completed &&
                    order.status != OrderStatus.cancelled)
                  _ActionButton(
                    icon: '✏️',
                    label: 'Status',
                    color: AppTheme.primary,
                    onTap: () => _showStatusSheet(context, ref, order),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _callCustomer(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  void _whatsappCustomer(OrderModel order) async {
    final shortId = order.id.substring(0, 8).toUpperCase();
    String messageText;

    switch (order.status) {
      case OrderStatus.pending:
        messageText =
            'Hi ${order.customerName}, thank you for your order #$shortId (${order.formattedTotal}) from GreenHub! We\'ve received it and will confirm shortly. 🥬';
        break;
      case OrderStatus.confirmed:
        messageText =
            'Hi ${order.customerName}, great news! Your order #$shortId (${order.formattedTotal}) has been confirmed. We\'ll arrange delivery soon. Please prepare cash payment upon receiving. 💚';
        break;
      case OrderStatus.completed:
        messageText =
            'Hi ${order.customerName}, your order #$shortId (${order.formattedTotal}) has been completed. Thank you for shopping with GreenHub! Hope to see you again soon. 🎉';
        break;
      case OrderStatus.cancelled:
        messageText =
            'Hi ${order.customerName}, we\'re sorry but your order #$shortId (${order.formattedTotal}) has been cancelled. Please contact us if you have any questions. 🙏';
        break;
      case OrderStatus.outForDelivery:
        // TODO: Handle this case.
        throw UnimplementedError();
    }

    final msg = Uri.encodeComponent(messageText);
    final uri = Uri.parse('https://wa.me/${order.customerPhone}?text=$msg');
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showStatusSheet(BuildContext context, WidgetRef ref, OrderModel order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _StatusUpdateSheet(order: order),
    );
  }
}

// ─── Status update bottom sheet ───────────────────────────────────────────────

class _StatusUpdateSheet extends ConsumerWidget {
  final OrderModel order;

  const _StatusUpdateSheet({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = _nextStatuses(order.status);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Update Order #${order.id.substring(0, 8).toUpperCase()}',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Current: ${order.status.emoji} ${order.status.label}',
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textMid),
          ),
          const SizedBox(height: 20),
          ...options.map(
            (status) => _StatusOption(
              status: status,
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(orderServiceProvider)
                    .updateStatus(order.id, status);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Order updated to ${status.label} ${status.emoji}',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  List<OrderStatus> _nextStatuses(OrderStatus current) {
    switch (current) {
      case OrderStatus.pending:
        return [OrderStatus.confirmed, OrderStatus.cancelled];
      case OrderStatus.confirmed:
        return [OrderStatus.completed, OrderStatus.cancelled];
      default:
        return [];
    }
  }
}

class _StatusOption extends StatelessWidget {
  final OrderStatus status;
  final VoidCallback onTap;

  const _StatusOption({required this.status, required this.onTap});

  Color get _color {
    switch (status) {
      case OrderStatus.confirmed:
        return const Color(0xFF2E7D32);
      case OrderStatus.completed:
        return const Color(0xFF1565C0);
      case OrderStatus.cancelled:
        return AppTheme.error;
      default:
        return AppTheme.textMid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(status.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Text(
              'Mark as ${status.label}',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _color,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _color),
          ],
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  Color get _bg {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFFFF3E0);
      case OrderStatus.confirmed:
        return const Color(0xFFE8F5E9);
      case OrderStatus.completed:
        return const Color(0xFFE3F2FD);
      case OrderStatus.cancelled:
        return const Color(0xFFFFEBEE);
      case OrderStatus.outForDelivery:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Color get _fg {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFE65100);
      case OrderStatus.confirmed:
        return const Color(0xFF2E7D32);
      case OrderStatus.completed:
        return const Color(0xFF1565C0);
      case OrderStatus.cancelled:
        return const Color(0xFFC62828);
      case OrderStatus.outForDelivery:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${status.emoji} ${status.label}',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _fg,
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final bool hasFilter;

  const _EmptyOrders({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDim,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: AppTheme.textLight.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasFilter ? 'No orders with this status' : 'No orders yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? 'Try a different filter'
                : 'Orders will appear here once customers place them',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }
}
