/// Per SDS domain model: invoiceId, supplierId, orderId, totalAmount,
/// dateIssued. `note` is an addition on top of that base entity to support
/// the SRS UC009 optional-notes alternative flow.
class InvoiceModel {
  final String id;
  final String supplierId;
  final String orderId;
  final double totalAmount;
  final DateTime dateIssued;
  final String note;

  const InvoiceModel({
    required this.id,
    required this.supplierId,
    required this.orderId,
    required this.totalAmount,
    required this.dateIssued,
    this.note = '',
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    return InvoiceModel(
      id: id,
      supplierId: map['supplierId'] ?? '',
      orderId: map['orderId'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      dateIssued: _parseDate(map['dateIssued']),
      note: map['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'supplierId': supplierId,
      'orderId': orderId,
      'totalAmount': totalAmount,
      'dateIssued': dateIssued,
      'note': note,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      return value.toDate();
    } catch (_) {
      return DateTime.now();
    }
  }
}
