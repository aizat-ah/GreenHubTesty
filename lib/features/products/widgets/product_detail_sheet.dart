import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/product_model.dart';
import '../../../core/theme/app_theme.dart';
 
class ProductDetailSheet extends StatefulWidget {
  final ProductModel product;
  final Function(int quantity) onAddToCart;
 
  const ProductDetailSheet({
    super.key,
    required this.product,
    required this.onAddToCart,
  });
 
  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}
 
class _ProductDetailSheetState extends State<ProductDetailSheet> {
  int _quantity = 1;
 
  double get _total => widget.product.price * _quantity;
 
  @override
  Widget build(BuildContext context) {
    final product = widget.product;
 
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
 
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: product.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _placeholder(),
                              errorWidget: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                  ),
                  const SizedBox(height: 20),
 
                  // Category + availability
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!product.isInStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Out of stock',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
 
                  // Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
 
                  // Price
                  Text(
                    product.priceWithUnit,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
 
                  // Description
                  if (product.description.isNotEmpty) ...[
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMid,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
 
                  // Stock info
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 16, color: AppTheme.textLight),
                      const SizedBox(width: 6),
                      Text(
                        'Stock: ${product.stock} ${product.unit}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
 
          // Bottom: quantity + add to cart
          if (product.isInStock)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(
                    top: BorderSide(color: AppTheme.divider)),
              ),
              child: Row(
                children: [
                  // Quantity stepper
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.divider),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _stepperButton(
                          icon: Icons.remove_rounded,
                          onTap: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '$_quantity',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _stepperButton(
                          icon: Icons.add_rounded,
                          onTap: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
 
                  // Add to cart
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onAddToCart(_quantity);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Add to Cart — RM ${_total.toStringAsFixed(2)}',
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.divider),
                child: const Text('Out of Stock',
                    style: TextStyle(color: AppTheme.textLight)),
              ),
            ),
        ],
      ),
    );
  }
 
  Widget _stepperButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? AppTheme.textLight : AppTheme.textDark,
        ),
      ),
    );
  }
 
  Widget _placeholder() {
    return Container(
      color: const Color(0xFFEEF3EC),
      child: const Center(
        child: Icon(Icons.eco_rounded, color: AppTheme.primaryLight, size: 48),
      ),
    );
  }
}