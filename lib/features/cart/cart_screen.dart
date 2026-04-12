import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/cart_provider.dart';
import '../products/widgets/bottom_nav_bar.dart';
 
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartItemsProvider);
    final total = ref.watch(cartTotalProvider);
 
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, ref),
              child: const Text(
                'Clear',
                style: TextStyle(color: AppTheme.error, fontSize: 14),
              ),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? const _EmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _CartItemTile(
                        item: item,
                        onRemove: () => ref
                            .read(cartProvider.notifier)
                            .removeItem(item.product.id),
                        onIncrement: () => ref
                            .read(cartProvider.notifier)
                            .updateQuantity(
                                item.product.id, item.quantity + 1),
                        onDecrement: () => ref
                            .read(cartProvider.notifier)
                            .updateQuantity(
                                item.product.id, item.quantity - 1),
                      );
                    },
                  ),
                ),
 
                // Order summary + checkout
                _OrderSummaryBar(
                  total: total,
                  itemCount: cartItems.length,
                  onCheckout: () => context.push('/checkout'),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavBar(currentRoute: '/cart'),
    );
  }
 
  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(ctx);
            },
            child: const Text('Clear',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
 
class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
 
  const _CartItemTile({
    required this.item,
    required this.onRemove,
    required this.onIncrement,
    required this.onDecrement,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          // Icon placeholder
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco_rounded,
                color: AppTheme.primaryLight, size: 28),
          ),
          const SizedBox(width: 12),
 
          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.product.priceWithUnit,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textLight),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: ${item.product.formattedPrice.replaceFirst('RM ', 'RM ')} × ${item.quantity} = RM ${item.subtotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
 
          // Quantity stepper + remove
          Column(
            children: [
              // Remove button
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppTheme.error),
              ),
              const SizedBox(height: 8),
 
              // Stepper
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _stepBtn(Icons.remove_rounded, onDecrement),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _stepBtn(Icons.add_rounded, onIncrement),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
 
  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: AppTheme.textDark),
      ),
    );
  }
}
 
class _OrderSummaryBar extends StatelessWidget {
  final double total;
  final int itemCount;
  final VoidCallback onCheckout;
 
  const _OrderSummaryBar({
    required this.total,
    required this.itemCount,
    required this.onCheckout,
  });
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$itemCount item${itemCount > 1 ? 's' : ''}',
                style:
                    const TextStyle(fontSize: 14, color: AppTheme.textMid),
              ),
              Text(
                'RM ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onCheckout,
            child: const Text('Proceed to Checkout'),
          ),
        ],
      ),
    );
  }
}
 
class _EmptyCart extends StatelessWidget {
  const _EmptyCart();
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_basket_outlined,
              size: 64, color: AppTheme.primaryLight),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some fresh vegetables!',
            style: TextStyle(color: AppTheme.textMid),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: () => context.go('/products'),
              child: const Text('Browse Products'),
            ),
          ),
        ],
      ),
    );
  }
}