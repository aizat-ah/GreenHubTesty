import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Must match the region the Cloud Functions were deployed to (same
  // region as createPaymentIntent in payment_service.dart).
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  CollectionReference get _orders => _db.collection('orders');

  // Place a new order — returns the created order with its Firestore ID
  Future<OrderModel> placeOrder(OrderModel order) async {
    final docRef = await _orders.add(order.toMap());
    return OrderModel.fromMap(order.toMap(), docRef.id);
  }

  // Stream orders for a specific buyer
  Stream<List<OrderModel>> buyerOrdersStream(String customerId) {
    return _orders
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Stream ALL orders (supplier/admin)
  Stream<List<OrderModel>> allOrdersStream() {
    return _orders
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Stream orders by status (admin filtering)
  Stream<List<OrderModel>> ordersByStatusStream(OrderStatus status) {
    return _orders
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Admin: update order status
  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await _orders.doc(orderId).update({'status': status.name});
  }

  // Called after Stripe confirms payment succeeded.
  //
  // This used to write `isPaid`/`status` straight to Firestore from the
  // client. It now calls the `confirmOrderPayment` Cloud Function instead,
  // because that function is the only place allowed to decrement product
  // stock — it runs with the Admin SDK and re-checks stock inside a
  // Firestore transaction before marking the order paid. Doing that from
  // the client isn't possible: security rules forbid buyers from writing
  // to `products` directly, and even if they could, a client-side check
  // could be bypassed.
  Future<void> markPaid(String orderId) async {
    try {
      await _functions.httpsCallable('confirmOrderPayment').call({
        'orderId': orderId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw OrderActionFailure(
        e.message ?? 'Could not confirm your order. Please try again.',
      );
    }
  }

  // Called ONLY when Stripe payment fails/cancels before the order was
  // ever confirmed, to clean up the pending placeholder order. Deletes
  // the doc outright (via the `cancelOrder` Cloud Function) since stock
  // was never decremented for it — there's nothing to restock, and no
  // reason to keep a phantom unpaid order in the buyer's history.
  //
  // For cancelling a REAL, already-placed order (COD or Stripe, pending
  // or confirmed), use cancelPlacedOrder() instead — that one restocks
  // and keeps the order visible as "Cancelled" rather than deleting it.
  Future<void> deleteOrder(String orderId) async {
    try {
      await _functions.httpsCallable('cancelOrder').call({
        'orderId': orderId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw OrderActionFailure(
        e.message ?? 'Could not cancel your order. Please try again.',
      );
    }
  }

  // Cash-on-Delivery has no separate "payment succeeded" step the way
  // Stripe does, so this is called right after a COD order is created
  // (see order_provider.dart) — it's the COD equivalent of markPaid():
  // checks + decrements stock for every item in one transaction, then
  // marks the order confirmed. Throws OrderActionFailure with a
  // buyer-facing message if any item no longer has enough stock.
  Future<void> confirmCodOrder(String orderId) async {
    try {
      await _functions.httpsCallable('confirmCodOrder').call({
        'orderId': orderId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw OrderActionFailure(
        e.message ?? 'Could not confirm your order. Please try again.',
      );
    }
  }

  // Cancels a real, already-placed order (pending or confirmed — COD or
  // Stripe) and restocks its items if stock had been decremented for it.
  // Unlike deleteOrder(), the order document is kept and its status is
  // set to "cancelled" so it still appears in order history.
  Future<void> cancelPlacedOrder(String orderId) async {
    try {
      await _functions.httpsCallable('cancelPlacedOrder').call({
        'orderId': orderId,
      });
    } on FirebaseFunctionsException catch (e) {
      throw OrderActionFailure(
        e.message ?? 'Could not cancel your order. Please try again.',
      );
    }
  }
}

// Thrown by markPaid()/deleteOrder() when the confirmOrderPayment/
// cancelOrder Cloud Functions reject the request (e.g. insufficient
// stock). toString() returns just the message so it can be shown
// directly to the buyer (e.g. in a SnackBar), mirroring PaymentFailure
// in payment_service.dart.
class OrderActionFailure implements Exception {
  final String message;

  OrderActionFailure(this.message);

  @override
  String toString() => message;
}