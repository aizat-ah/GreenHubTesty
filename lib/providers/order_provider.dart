// lib/providers/order_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:greenhub/models/user_models.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

// Buyer's own orders stream
final myOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(orderServiceProvider).buyerOrdersStream(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, _) => Stream.error('Failed to load user data'),
  );
});

// Place order notifier
class PlaceOrderNotifier extends StateNotifier<AsyncValue<OrderModel?>> {
  final OrderService _orderService;
  final Ref _ref;

  PlaceOrderNotifier(this._orderService, this._ref)
      : super(const AsyncValue.data(null));

  Future<OrderModel?> placeOrder({
    required UserModel user,
    required String note,
  }) async {
    state = const AsyncValue.loading();

    try {
      final cartItems = _ref.read(cartItemsProvider);
      if (cartItems.isEmpty) throw Exception('Your cart is empty.');

      final orderItems = cartItems
          .map((ci) => OrderItem(
                productId: ci.product.id,
                productName: ci.product.name,
                unit: ci.product.unit,
                quantity: ci.quantity,
                price: ci.product.price,
              ))
          .toList();

      final totalPrice =
          cartItems.fold(0.0, (sum, ci) => sum + ci.subtotal);

      final order = OrderModel(
        id: '', // will be set after Firestore creates the doc
        customerId: user.uid,
        customerName: user.name,
        customerPhone: user.phone,
        items: orderItems,
        totalPrice: totalPrice,
        status: OrderStatus.pending,
        note: note.trim(),
        createdAt: DateTime.now(),
      );

      final placed = await _orderService.placeOrder(order);

      // Clear cart after successful order
      _ref.read(cartProvider.notifier).clearCart();

      state = AsyncValue.data(placed);
      return placed;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final placeOrderProvider =
    StateNotifierProvider<PlaceOrderNotifier, AsyncValue<OrderModel?>>(
  (ref) => PlaceOrderNotifier(ref.watch(orderServiceProvider), ref),
);