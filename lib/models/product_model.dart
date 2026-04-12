
class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String unit; // e.g. "kg", "bunch", "piece"
  final String imageUrl;
  final String category;
  final double stock;
  final bool isAvailable;
  final DateTime createdAt;
 
  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.imageUrl,
    required this.category,
    required this.stock,
    required this.isAvailable,
    required this.createdAt,
  });
 
  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'kg',
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? 'Others',
      stock: (map['stock'] ?? 0).toDouble(),
      isAvailable: map['isAvailable'] ?? true,
      createdAt: _parseDate(map['createdAt']),
    );
  }
 
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'unit': unit,
      'imageUrl': imageUrl,
      'category': category,
      'stock': stock,
      'isAvailable': isAvailable,
      'createdAt': createdAt,
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
 
  ProductModel copyWith({
    String? name,
    String? description,
    double? price,
    String? unit,
    String? imageUrl,
    String? category,
    double? stock,
    bool? isAvailable,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
    );
  }
 
  String get formattedPrice => 'RM ${price.toStringAsFixed(2)}';
  String get priceWithUnit => 'RM ${price.toStringAsFixed(2)} / $unit';
  bool get isInStock => stock > 0 && isAvailable;
}