import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  // NEW: called after Stripe confirms payment succeeded.
  Future<void> markPaid(String orderId) async {
    await _orders.doc(orderId).update({
      'isPaid': true,
      'status': OrderStatus.confirmed.name,
    });
  }

  // NEW: called if Stripe payment fails/cancels, to clean up the
  // pending order created just before the payment sheet was shown.
  Future<void> deleteOrder(String orderId) async {
    await _orders.doc(orderId).delete();
  }
}