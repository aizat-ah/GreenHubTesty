import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';
import '../models/product_model.dart';
 
class CartItem {
  final ProductModel product;
  final int quantity;
 
  const CartItem({required this.product, required this.quantity});
 
  double get subtotal => product.price * quantity;
 
  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }
}
 
class CartNotifier extends StateNotifier<Map<String, CartItem>> {
  CartNotifier() : super({});
 
  void addItem(ProductModel product, int quantity) {
    final existing = state[product.id];
    if (existing != null) {
      state = {
        ...state,
        product.id: existing.copyWith(quantity: existing.quantity + quantity),
      };
    } else {
      state = {
        ...state,
        product.id: CartItem(product: product, quantity: quantity),
      };
    }
  }
 
  void removeItem(String productId) {
    final newState = Map<String, CartItem>.from(state);
    newState.remove(productId);
    state = newState;
  }
 
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    if (state.containsKey(productId)) {
      state = {
        ...state,
        productId: state[productId]!.copyWith(quantity: quantity),
      };
    }
  }
 
  void clearCart() => state = {};
 
  int get totalItems =>
      state.values.fold(0, (sum, item) => sum + item.quantity);
 
  double get totalPrice =>
      state.values.fold(0.0, (sum, item) => sum + item.subtotal);
}
 
final cartProvider =
    StateNotifierProvider<CartNotifier, Map<String, CartItem>>(
        (ref) => CartNotifier());
 
// Convenient derived values
final cartItemsProvider = Provider<List<CartItem>>((ref) {
  return ref.watch(cartProvider).values.toList();
});
 
final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).values
      .fold(0.0, (sum, item) => sum + item.subtotal);
});
 
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).values
      .fold(0, (sum, item) => sum + item.quantity);
});