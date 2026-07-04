import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/invoice_model.dart';
import '../services/invoice_service.dart';

final invoiceServiceProvider = Provider<InvoiceService>((ref) => InvoiceService());

// Whether an invoice already exists for a given order, so the sheet can
// show "view/download" instead of "generate" on repeat visits.
final invoiceForOrderProvider =
    FutureProvider.autoDispose.family<InvoiceModel?, String>((ref, orderId) {
  return ref.watch(invoiceServiceProvider).getInvoiceForOrder(orderId);
});
