import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          product.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: product.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => _placeholder(),
                                  errorWidget: (_, _, _) => _placeholder(),
                                )
                              : _placeholder(),
                          // Bottom scrim
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.15),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Category + availability
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          product.category,
                          style: GoogleFonts.inter(
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
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Out of stock',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Name
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Price
                  Text(
                    product.priceWithUnit,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  if (product.description.isNotEmpty) ...[
                    Text(
                      'About',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textMid,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Stock info
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDim,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 18, color: AppTheme.textLight),
                        const SizedBox(width: 8),
                        Text(
                          'Stock: ${product.stock} ${product.unit}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textMid,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: product.isInStock
                                ? AppTheme.success
                                : AppTheme.error,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          product.isInStock ? 'Available' : 'Unavailable',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: product.isInStock
                                ? AppTheme.success
                                : AppTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom: quantity + add to cart
          if (product.isInStock)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Quantity stepper
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDim,
                      borderRadius: BorderRadius.circular(14),
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
                          width: 40,
                          child: Text(
                            '$_quantity',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
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
                  const SizedBox(width: 14),

                  // Add to cart
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onAddToCart(_quantity);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Add — RM ${_total.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceDim,
                    disabledBackgroundColor: AppTheme.surfaceDim,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Out of Stock',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
        width: 40,
        height: 44,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? AppTheme.divider : AppTheme.textDark,
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