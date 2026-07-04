import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/invoice_model.dart';
import '../models/order_model.dart';

class InvoiceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _invoices => _db.collection('invoices');

  Future<InvoiceModel?> getInvoiceForOrder(String orderId) async {
    final snap = await _invoices.where('orderId', isEqualTo: orderId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return InvoiceModel.fromMap(snap.docs.first.data() as Map<String, dynamic>, snap.docs.first.id);
  }

  /// Generates an invoice for [order], or returns the one already on file
  /// for it (an order can only ever have one invoice — re-opening the
  /// sheet re-downloads the same record instead of creating a duplicate).
  ///
  /// Throws [InvoiceActionFailure] with the exact SRS/STD wording if the
  /// order isn't delivered yet, regardless of whether the calling UI
  /// already hid the button for this case.
  Future<InvoiceModel> getOrCreateInvoice({
    required OrderModel order,
    required String supplierId,
    String note = '',
  }) async {
    if (order.status != OrderStatus.completed) {
      throw InvoiceActionFailure('Invoice available only for delivered orders');
    }

    final existing = await getInvoiceForOrder(order.id);
    if (existing != null) return existing;

    final docRef = _invoices.doc();
    final invoice = InvoiceModel(
      id: docRef.id,
      supplierId: supplierId,
      orderId: order.id,
      totalAmount: order.totalPrice,
      dateIssued: DateTime.now(),
      note: note,
    );
    await docRef.set(invoice.toMap());
    return invoice;
  }
}

class InvoiceActionFailure implements Exception {
  final String message;

  InvoiceActionFailure(this.message);

  @override
  String toString() => message;
}
