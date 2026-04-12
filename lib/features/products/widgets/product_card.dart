import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/product_model.dart';
import '../../../core/theme/app_theme.dart';
 
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
 
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox.expand(
                  child: product.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _imagePlaceholder(),
                          errorWidget: (context, url, error) =>
                              _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              ),
            ),
 
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.category,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
 
                  // Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
 
                  // Price + add button row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.formattedPrice,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                              ),
                            ),
                            Text(
                              '/ ${product.unit}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
 
                      // Add to cart button
                      if (product.isInStock)
                        GestureDetector(
                          onTap: onAddToCart,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.divider,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Out',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFEEF3EC),
      child: const Center(
        child: Icon(
          Icons.eco_rounded,
          color: AppTheme.primaryLight,
          size: 40,
        ),
      ),
    );
  }
}