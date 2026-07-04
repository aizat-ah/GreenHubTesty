import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_model.dart';
import '../models/sales_report_model.dart';

final salesReportServiceProvider = Provider<SalesReportService>((ref) {
  return SalesReportService();
});

// Canonical product categories, mirrored from the dropdown in
// lib/features/admin/product_form_sheet.dart (_kCategories). Kept here too
// so the report can always show all categories, including ones with zero
// sales in the selected range.
const _kReportCategories = [
  'Leafy Greens',
  'Root Vegetables',
  'Gourds & Squash',
  'Beans & Pods',
  'Herbs & Spices',
  'Fruits & Tomatoes',
  'Mushrooms',
  'Others',
];

class SalesReportService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Builds a Sales Report for [start]..[end] (inclusive) by scanning the
  /// `orders` collection and joining each order's line items against the
  /// `products` collection to resolve category.
  ///
  /// SCALABILITY NOTE (flagged for thesis discussion): this fetches every
  /// order in range plus the entire `products` catalog into the client and
  /// aggregates in Dart. That's acceptable at this project's data volume,
  /// but at production scale this should move to a scheduled Cloud Function
  /// (or Firestore aggregation query) that maintains pre-computed rollup
  /// documents instead of re-scanning raw orders on every report request.
  Future<SalesReportData> generateReport({
    required DateTime start,
    required DateTime end,
  }) async {
    final ordersSnap = await _db
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final qualifyingOrders = ordersSnap.docs
        .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
        .where((o) => o.status == OrderStatus.completed && o.isPaid)
        .toList();

    if (qualifyingOrders.isEmpty) {
      return SalesReportData.empty(start, end);
    }

    final productsSnap = await _db.collection('products').get();
    final categoryByProductId = <String, String>{
      for (final doc in productsSnap.docs)
        doc.id: (doc.data()['category'] as String?) ?? 'Others',
    };

    double totalRevenue = 0;
    // Seeded with all canonical categories so ones with zero sales in this
    // range still appear in the report (a category selling nothing is
    // itself useful admin information).
    final categoryRevenue = <String, double>{
      for (final c in _kReportCategories) c: 0,
    };
    final categoryQuantity = <String, int>{
      for (final c in _kReportCategories) c: 0,
    };
    final categoryOrderIds = <String, Set<String>>{
      for (final c in _kReportCategories) c: {},
    };
    final productQuantity = <String, int>{};
    final productNames = <String, String>{};

    for (final order in qualifyingOrders) {
      totalRevenue += order.totalPrice;

      for (final item in order.items) {
        final category = categoryByProductId[item.productId] ?? 'Others';

        categoryRevenue.update(
          category,
          (v) => v + item.subtotal,
          ifAbsent: () => item.subtotal,
        );
        categoryQuantity.update(
          category,
          (v) => v + item.quantity,
          ifAbsent: () => item.quantity,
        );
        categoryOrderIds.putIfAbsent(category, () => {}).add(order.id);

        productQuantity.update(
          item.productId,
          (v) => v + item.quantity,
          ifAbsent: () => item.quantity,
        );
        productNames[item.productId] = item.productName;
      }
    }

    final categoryBreakdown = categoryRevenue.keys
        .map((category) => CategorySales(
              category: category,
              revenue: categoryRevenue[category]!,
              orderCount: categoryOrderIds[category]!.length,
              quantitySold: categoryQuantity[category]!,
            ))
        .toList()
      ..sort((a, b) {
        final revenueCompare = b.revenue.compareTo(a.revenue);
        return revenueCompare != 0 ? revenueCompare : a.category.compareTo(b.category);
      });

    // Products with zero sales in range are excluded entirely (unlike
    // categories, which always show all 8 for visibility into "nothing
    // sold" cases).
    final topProducts = productQuantity.entries
        .map((e) => ProductSales(
              productId: e.key,
              productName: productNames[e.key] ?? 'Unknown product',
              quantitySold: e.value,
            ))
        .toList()
      ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

    return SalesReportData(
      rangeStart: start,
      rangeEnd: end,
      totalRevenue: totalRevenue,
      totalOrders: qualifyingOrders.length,
      categoryBreakdown: categoryBreakdown,
      topProducts: topProducts.take(10).toList(),
    );
  }
}
