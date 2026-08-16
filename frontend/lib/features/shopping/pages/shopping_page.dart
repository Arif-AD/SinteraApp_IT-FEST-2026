import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/shopping_product_model.dart';
import '../widgets/shopping_search_bar.dart';
import '../widgets/shopping_category_filter.dart';
import '../widgets/shopping_product_card.dart';

class ShoppingPage extends ConsumerStatefulWidget {
  const ShoppingPage({
    super.key,
    this.receiver,
  });

  final Map<String, String>? receiver;

  @override
  ConsumerState<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends ConsumerState<ShoppingPage> {
  final TextEditingController _searchController = TextEditingController();

  void _handleBack() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  final List<String> _categories = ['Semua', 'Sayur', 'Buah'];
  final List<ShoppingProduct> _allProducts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ref.read(laravelAuthServiceProvider).getWargaProducts();
      if (!mounted) return;
      setState(() {
        _allProducts
          ..clear()
          ..addAll(products);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredProducts = _allProducts.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Semua' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    const Color customLightBackground = Color(0xFFF7F9FA);
    const LinearGradient geminiGradient = LinearGradient(
      colors: [Color(0xFF4285F4), Color(0xFF9C27B0), Color(0xFFFF9800)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
      backgroundColor: customLightBackground,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShoppingSearchBar(
                      controller: _searchController,
                      searchQuery: _searchQuery,
                      gradient: geminiGradient,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      onClear: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    ),
                    const SizedBox(height: 1.0),
                    Divider(
                      height: 0,
                      thickness: 1.2,
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: 8.0),
                    ShoppingCategoryFilter(
                      categories: _categories,
                      selectedCategory: _selectedCategory,
                      gradient: geminiGradient,
                      backgroundColor: customLightBackground,
                      onSelected: (cat) => setState(() => _selectedCategory = cat),
                    ),
                    const SizedBox(height: 2.0),
                  ],
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(6.0, 6.0, 6.0, AppSpacing.lg),
                      sliver: filteredProducts.isEmpty
                          ? SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 60.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off_rounded, size: 54, color: AppColors.textTertiary),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      'Produk tidak ditemukan',
                                      style: theme.textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 6.0,
                                crossAxisSpacing: 6.0,
                                childAspectRatio: 0.62,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final product = filteredProducts[index];
                                  return ShoppingProductCard(product: product, receiver: widget.receiver);
                                },
                                childCount: filteredProducts.length,
                              ),
                            ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xxxl),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}