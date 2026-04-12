import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.whenData((data) => data).value;
    if (user == null) return;

    final order = await ref.read(placeOrderProvider.notifier).placeOrder(
          user: user,
          note: _noteController.text,
        );

    if (!mounted) return;

    if (order != null) {
      context.pushReplacement('/order-success', extra: order);
    } else {
      final error = ref.read(placeOrderProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? 'Failed to place order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartItemsProvider);
    final total = ref.watch(cartTotalProvider);
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.whenData((data) => data).value;
    final orderState = ref.watch(placeOrderProvider);
    final isLoading = orderState.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer info card
            _SectionCard(
              title: 'Your Details',
              child: Column(
                children: [
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Name',
                    value: user?.name ?? '—',
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'WhatsApp',
                    value: user?.phone ?? '—',
                  ),
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user?.email ?? '—',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Order items
            _SectionCard(
              title: 'Order Items',
              child: Column(
                children: [
                  ...cartItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return Column(
                      children: [
                        if (i > 0) const Divider(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  Text(
                                    '${item.product.formattedPrice} / ${item.product.unit} × ${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'RM ${item.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'RM ${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment method
            _SectionCard(
              title: 'Payment Method',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.payments_outlined,
                        color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash on Delivery',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        'Pay when you receive your order',
                        style:
                            TextStyle(fontSize: 12, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Note field
            _SectionCard(
              title: 'Note to Seller (Optional)',
              child: TextField(
                controller: _noteController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. Please call before delivery, preferred time, etc.',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  counterStyle: TextStyle(fontSize: 11, color: AppTheme.textLight),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // WhatsApp notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: const Row(
                children: [
                  Text('📲', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'After placing your order, you\'ll be redirected to WhatsApp to confirm with the seller.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2E7D32),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Place order button
            ElevatedButton(
              onPressed: isLoading ? null : _placeOrder,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Place Order'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textLight,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textLight),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style:
              const TextStyle(fontSize: 13, color: AppTheme.textLight),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}