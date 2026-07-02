// lib/providers/order_provider.dart
//
// CHANGES in current file:
//   - `placeOrder()` now takes a `paymentMethod` param.
//   - Cart is now cleared only AFTER a successful flow (immediately for
//     COD, after Stripe confirms for card) — previously it cleared right
//     after the Firestore write, before payment even happened.
//   - If paymentMethod is cardStripe: creates the order (pending), calls
//     PaymentService.payWithStripe, then marks it paid+confirmed on
//     success. On failure/cancel, the pending order is deleted and the
//     error is rethrown so the checkout screen can show it.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:greenhub/models/user_models.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
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
    required PaymentMethod paymentMethod,
  }) async {
    state = const AsyncValue.loading();

    String? createdOrderId;

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

      final draftOrder = OrderModel(
        id: '', // will be set after Firestore creates the doc
        customerId: user.uid,
        customerName: user.name,
        customerPhone: user.phone,
        items: orderItems,
        totalPrice: totalPrice,
        status: OrderStatus.pending,
        note: note.trim(),
        createdAt: DateTime.now(),
        paymentMethod: paymentMethod,
      );

      var placed = await _orderService.placeOrder(draftOrder);
      createdOrderId = placed.id;

      if (paymentMethod == PaymentMethod.cardStripe) {
        // This throws PaymentFailure on cancel/failure — caught below,
        // where we clean up the pending order we just created.
        await _ref.read(paymentServiceProvider).payWithStripe(
              orderId: placed.id,
              amountInRM: totalPrice,
            );

        await _orderService.markPaid(placed.id);
        placed = placed.copyWith(
          status: OrderStatus.confirmed,
          isPaid: true,
        );
      }

      // Only clear the cart once we know the order is actually settled
      // (COD: settled immediately: Stripe: settled after payment).
      _ref.read(cartProvider.notifier).clearCart();

      state = AsyncValue.data(placed);
      return placed;
    } catch (e, st) {
      // If payment failed/cancelled after the order doc was already
      // created, delete it rather than leaving a phantom unpaid order.
      if (createdOrderId != null) {
        try {
          await _orderService.deleteOrder(createdOrderId);
        } catch (_) {
          // Best-effort cleanup — don't let a cleanup failure mask the
          // original error shown to the buyer.
        }
      }
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