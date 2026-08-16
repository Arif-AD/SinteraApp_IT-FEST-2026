import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/shopping/models/shopping_product_model.dart';
import '../../../features/shopping/pages/shopping_detail_page.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';

class VegetableDeals extends ConsumerStatefulWidget {
  const VegetableDeals({super.key});

  @override
  ConsumerState<VegetableDeals> createState() => _VegetableDealsState();
}

class _VegetableDealsState extends ConsumerState<VegetableDeals> {
  List<ShoppingProduct> _products = [];
  bool _isLoading = true;
  String? _error;

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
      final sortedProducts = [...products]
        ..sort((a, b) {
          final aDate = _parseDate(a.updatedAt);
          final bDate = _parseDate(b.updatedAt);
          return bDate.compareTo(aDate);
        });

      setState(() {
        _products = sortedProducts;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  DateTime _parseDate(String? value) {
    if (value == null || value.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardWidth = 155.0;
    if (_isLoading) {
      return SizedBox(
        height: Responsive.isTablet(context) ? 280 : 265,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (_, __) => SizedBox(
            width: cardWidth,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 0.8),
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(_error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
      );
    }

    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text('Belum ada produk terbaru.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
      );
    }

    return SizedBox(
      height: Responsive.isTablet(context) ? 280 : 265,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final product = _products[index];
          return SizedBox(
            width: cardWidth,
            child: AnimatedEntry(
              delay: Duration(milliseconds: 70 * index),
              child: _EcommerceProductCard(product: product),
            ),
          );
        },
      ),
    );
  }
}

class _EcommerceProductCard extends StatelessWidget {
  const _EcommerceProductCard({required this.product});

  final ShoppingProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = product.imageUrl?.trim();
    final hasValidImageUrl = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShoppingDetailPage(product: product),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                        ),
                        child: hasValidImageUrl
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    child: Image.asset(
                                      product.imageAsset,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.sm),
                                  child: Image.asset(
                                    product.imageAsset,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (product.discount != null)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4D4F),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${product.discount}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.farmerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (product.originalPrice != null)
                            Text(
                              product.originalPrice!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.textTertiary,
                                fontSize: 9.5,
                              ),
                            ),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  product.price,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              Text(
                                '/${product.unit}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFC107)),
                                const SizedBox(width: 2),
                                Text(
                                  product.rating,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '• ${product.sold}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: AppColors.textTertiary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(6.0),
                            child: Container(
                              padding: const EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Colors.white,
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
        ),
      ),
    );
  }
}
