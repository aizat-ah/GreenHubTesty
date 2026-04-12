import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
 
class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
 
  CollectionReference get _products => _db.collection('products');
 
  // Stream all available products (live updates)
  Stream<List<ProductModel>> productsStream() {
    return _products
        .orderBy('category')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((product) => product.isAvailable)
            .toList());
  }
 
  // Stream products by category
  Stream<List<ProductModel>> productsByCategoryStream(String category) {
    return _products
        .where('category', isEqualTo: category)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((product) => product.isAvailable)
            .toList());
  }
 
  // Stream ALL products (for admin — includes unavailable)
  Stream<List<ProductModel>> allProductsStream() {
    return _products
        .orderBy('category')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
 
  // Fetch single product
  Future<ProductModel?> getProduct(String id) async {
    final doc = await _products.doc(id).get();
    if (!doc.exists) return null;
    return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
 
  // Admin: add product
  Future<void> addProduct(ProductModel product) async {
    await _products.add(product.toMap());
  }
 
  // Admin: update product
  Future<void> updateProduct(ProductModel product) async {
    await _products.doc(product.id).update(product.toMap());
  }
 
  // Admin: toggle availability
  Future<void> toggleAvailability(String id, bool isAvailable) async {
    await _products.doc(id).update({'isAvailable': isAvailable});
  }
 
  // Admin: delete product
  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }
}