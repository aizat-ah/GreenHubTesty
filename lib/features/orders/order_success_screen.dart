import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_model.dart';
import '../../services/whatsapp_service.dart';

class OrderSuccessScreen extends ConsumerWidget {
  final OrderModel order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Success icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primary,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Order Placed! 🎉',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Order #${order.id.substring(0, 8).toUpperCase()}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),

              // Order summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.eco_rounded,
                                  size: 14, color: AppTheme.primaryLight),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${item.productName} × ${item.quantity} ${item.unit}',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppTheme.textDark),
                                ),
                              ),
                              Text(
                                item.formattedSubtotal,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                        )),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          order.formattedTotal,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info text
              const Text(
                'Tap the button below to send your order details to the seller via WhatsApp to arrange delivery and payment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMid,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // WhatsApp button
              ElevatedButton.icon(
                onPressed: () async {
                  final sent =
                      await WhatsAppService.sendOrderToSeller(order);
                  if (!sent && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Could not open WhatsApp. Please contact the seller manually.'),
                      ),
                    );
                  }
                },
                icon: const Text('📲', style: TextStyle(fontSize: 18)),
                label: const Text('Send Order via WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp green
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // View orders button
              OutlinedButton(
                onPressed: () => context.go('/orders'),
                child: const Text('View My Orders'),
              ),
              const SizedBox(height: 12),

              // Continue shopping
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text(
                  'Continue Shopping',
                  style: TextStyle(color: AppTheme.textMid),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}