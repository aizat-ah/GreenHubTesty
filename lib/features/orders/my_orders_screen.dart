import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../services/whatsapp_service.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: AppTheme.primaryLight),
                  SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your order history will appear here',
                    style: TextStyle(color: AppTheme.textMid),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _OrderCard(order: orders[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a')
                            .format(order.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
          ),

          const Divider(height: 1),

          // Items preview
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.take(3).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '• ${item.productName} × ${item.quantity} ${item.unit}',
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textMid),
                      ),
                    )),
                if (order.items.length > 3)
                  Text(
                    '+ ${order.items.length - 3} more item(s)',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textLight),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Footer: total + WhatsApp
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                Text(
                  order.formattedTotal,
                  style: const TextStyle(
                    fontSize: 16,
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
                            content:
                                Text('Could not open WhatsApp.')),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Text('📲', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 4),
                        Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1B7A40),
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
        ],
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _fg,
        ),
      ),
    );
  }
}