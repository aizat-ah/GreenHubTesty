import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
 
final productServiceProvider = Provider<ProductService>((ref) => ProductService());
 
// All available products stream
final productsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(productServiceProvider).productsStream();
});
 
// All products stream (admin)
final allProductsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(productServiceProvider).allProductsStream();
});
 
// Selected category filter ('' means all)
final selectedCategoryProvider = StateProvider<String>((ref) => '');
 
// Derived: products filtered by selected category + search query
final filteredProductsProvider = Provider<AsyncValue<List<ProductModel>>>((ref) {
  final productsAsync = ref.watch(productsStreamProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
 
  return productsAsync.whenData((products) {
    var filtered = products;
 
    if (selectedCategory.isNotEmpty) {
      filtered = filtered
          .where((p) => p.category == selectedCategory)
          .toList();
    }
 
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(searchQuery) ||
              p.category.toLowerCase().contains(searchQuery))
          .toList();
    }
 
    return filtered;
  });
});
 
// Search query
final searchQueryProvider = StateProvider<String>((ref) => '');
 
// Derived: unique categories from products
final categoriesProvider = Provider<AsyncValue<List<String>>>((ref) {
  return ref.watch(productsStreamProvider).whenData((products) {
    final cats = products.map((p) => p.category).toSet().toList();
    cats.sort();
    return cats;
  });
});