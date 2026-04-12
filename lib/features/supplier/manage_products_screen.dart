import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../services/product_service.dart';
import 'product_form_sheet.dart';

class ManageProductsScreen extends ConsumerWidget {
  const ManageProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Manage Products'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco_rounded,
                      size: 64, color: AppTheme.primaryLight),
                  const SizedBox(height: 16),
                  const Text(
                    'No products yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the button below to add your first product',
                    style: TextStyle(color: AppTheme.textMid),
                  ),
                ],
              ),
            );
          }

          // Group by category
          final Map<String, List<ProductModel>> grouped = {};
          for (final p in products) {
            grouped.putIfAbsent(p.category, () => []).add(p);
          }
          final categories = grouped.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final cat = categories[i];
              final items = grouped[cat]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      cat,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...items.map((product) => _ProductTile(
                        product: product,
                        onEdit: () => _openForm(context, ref, product),
                        onDelete: () =>
                            _confirmDelete(context, ref, product),
                        onToggle: (val) => ref
                            .read(productServiceProvider)
                            .toggleAvailability(product.id, val),
                      )),
                  const SizedBox(height: 4),
                ],
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _openForm(
      BuildContext context, WidgetRef ref, ProductModel? product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductFormSheet(existingProduct: product),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product'),
        content: Text(
            'Remove "${product.name}" from your store? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(productServiceProvider)
                  .deleteProduct(product.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('${product.name} deleted')),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Product tile ─────────────────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _ProductTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: product.isAvailable ? AppTheme.surface : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: product.isAvailable ? AppTheme.divider : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(13)),
            child: SizedBox(
              width: 72,
              height: 72,
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

          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: product.isAvailable
                                ? AppTheme.textDark
                                : AppTheme.textLight,
                          ),
                        ),
                      ),
                      if (!product.isAvailable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Hidden',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${product.formattedPrice} / ${product.unit}  ·  Stock: ${product.stock}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMid),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Available toggle
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: product.isAvailable,
                  onChanged: onToggle,
                  activeColor: AppTheme.primary,
                ),
              ),
              // Edit + delete row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: AppTheme.primary),
                    onPressed: onEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppTheme.error),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                    tooltip: 'Delete',
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFEEF3EC),
      child: const Center(
        child: Icon(Icons.eco_rounded,
            color: AppTheme.primaryLight, size: 28),
      ),
    );
  }
}