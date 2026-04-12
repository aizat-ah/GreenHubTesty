import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import 'widgets/product_card.dart';
import 'widgets/category_filter_bar.dart';
import 'widgets/product_detail_sheet.dart';
 
class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).maybeWhen(
      data: (userData) => userData,
      orElse: () => null,
    );
    final productsAsync = ref.watch(filteredProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final cartCount = ref.watch(cartCountProvider);
    final searchQuery = ref.watch(searchQueryProvider);
 
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.name.split(' ').first ?? 'there'} 👋',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMid,
                            ),
                          ),
                          const Text(
                            'Fresh Vegetables',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
 
                    // Cart icon with badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () => context.go('/cart'),
                          icon: const Icon(Icons.shopping_basket_outlined),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.surface,
                            foregroundColor: AppTheme.textDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppTheme.divider),
                            ),
                          ),
                        ),
                        if (cartCount > 0)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(
                                '$cartCount',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Account menu
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'logout') {
                          ref.read(authNotifierProvider.notifier).signOut();
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout_rounded, size: 20),
                              SizedBox(width: 12),
                              Text('Logout'),
                            ],
                          ),
                        ),
                      ],
                      icon: const Icon(Icons.account_circle_outlined),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surface,
                        foregroundColor: AppTheme.textDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppTheme.divider),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
 
            // Search bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: TextField(
                  onChanged: (v) =>
                      ref.read(searchQueryProvider.notifier).state = v,
                  decoration: InputDecoration(
                    hintText: 'Search vegetables...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: AppTheme.textLight),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: AppTheme.textLight),
                            onPressed: () =>
                                ref.read(searchQueryProvider.notifier).state = '',
                          )
                        : null,
                  ),
                ),
              ),
            ),
 
            // Category filter
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                data: (categories) => CategoryFilterBar(
                  categories: categories,
                  selected: selectedCategory,
                  onSelected: (cat) =>
                      ref.read(selectedCategoryProvider.notifier).state = cat,
                ),
                loading: () => const SizedBox(height: 38),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
 
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
 
            // Products grid
            productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return SliverFillRemaining(
                    child: _EmptyState(
                      hasSearch: searchQuery.isNotEmpty || selectedCategory.isNotEmpty,
                    ),
                  );
                }
 
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return ProductCard(
                          product: product,
                          onTap: () => _showDetail(context, ref, product),
                          onAddToCart: () {
                            ref.read(cartProvider.notifier).addItem(product, 1);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('${product.name} added to cart'),
                              duration: const Duration(seconds: 1),
                            ));
                          },
                        );
                      },
                      childCount: products.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: _LoadingGrid()),
              error: (error, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: AppTheme.error),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load products\n$error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textMid),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  void _showDetail(BuildContext context, WidgetRef ref, product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => ProductDetailSheet(
          product: product,
          onAddToCart: (quantity) {
            ref.read(cartProvider.notifier).addItem(product, quantity);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('${product.name} x$quantity added to cart'),
              duration: const Duration(seconds: 1),
            ));
          },
        ),
      ),
    );
  }
}
 
class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded,
              size: 56, color: AppTheme.primaryLight),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No vegetables found' : 'No products available',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasSearch ? 'Try a different search or category' : 'Check back soon!',
            style: const TextStyle(fontSize: 13, color: AppTheme.textMid),
          ),
        ],
      ),
    );
  }
}
 
class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3EC),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}