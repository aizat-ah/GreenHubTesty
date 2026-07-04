/// Aggregated result of UC010 "Generate Report" for a given date range.
class SalesReportData {
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final double totalRevenue;
  final int totalOrders;
  final List<CategorySales> categoryBreakdown; // sorted by revenue desc
  final List<ProductSales> topProducts; // top 5 by quantity sold

  const SalesReportData({
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalRevenue,
    required this.totalOrders,
    required this.categoryBreakdown,
    required this.topProducts,
  });

  bool get isEmpty => totalOrders == 0;

  factory SalesReportData.empty(DateTime start, DateTime end) {
    return SalesReportData(
      rangeStart: start,
      rangeEnd: end,
      totalRevenue: 0,
      totalOrders: 0,
      categoryBreakdown: const [],
      topProducts: const [],
    );
  }
}

class CategorySales {
  final String category;
  final double revenue;
  final int orderCount; // distinct orders containing >=1 item of this category
  final int quantitySold;

  const CategorySales({
    required this.category,
    required this.revenue,
    required this.orderCount,
    required this.quantitySold,
  });
}

class ProductSales {
  final String productId;
  final String productName;
  final int quantitySold;

  const ProductSales({
    required this.productId,
    required this.productName,
    required this.quantitySold,
  });
}
