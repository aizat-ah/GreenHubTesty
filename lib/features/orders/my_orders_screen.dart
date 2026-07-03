import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../services/whatsapp_service.dart';
import '../products/widgets/bottom_nav_bar.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
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
                    'No orders yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your order history will appear here',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              return _OrderCard(order: orders[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: const BottomNavBar(currentRoute: '/orders'),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  // Cancellation only makes sense while the order hasn't reached a final
  // state yet. There's no driver-pickup signal wired into the UI (the
  // DeliveryStage enum on OrderModel isn't rendered anywhere today), so
  // status is the only real gate available: once it's completed or
  // already cancelled, there's nothing to cancel.
  bool get _canCancel =>
      order.status == OrderStatus.pending ||
      order.status == OrderStatus.confirmed;

  Future<void> _confirmAndCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text(
          'Are you sure you want to cancel this order? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No, keep order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Yes, cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(orderServiceProvider).cancelPlacedOrder(order.id);
      // No manual refresh needed — myOrdersProvider is a Firestore stream,
      // so the status change (and the restocked product) show up live.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: Text(
                      order.status.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 1),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a')
                            .format(order.createdAt),
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

          Divider(color: AppTheme.divider.withValues(alpha: 0.6), height: 1),

          // Items
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.take(3).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppTheme.textLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${item.productName} × ${item.quantity} ${item.unit}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.textMid,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                if (order.items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      '+ ${order.items.length - 3} more',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Divider(color: AppTheme.divider.withValues(alpha: 0.6), height: 1),

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
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
                GestureDetector(
                  onTap: () async {
                    final sent =
                        await WhatsAppService.sendOrderToSeller(order);
                    if (!sent && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Could not open WhatsApp.')),
                      );
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📲', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 5),
                        Text(
                          'WhatsApp',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF1B7A40),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_canCancel)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _confirmAndCancel(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Cancel Order',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
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
        return const Color(0xFF6A1B9A);
    }
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
        return const Color(0xFFF3E5F5);
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
        return const Color(0xFF6A1B9A);
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
        status.label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _fg,
        ),
      ),
    );
  }
}