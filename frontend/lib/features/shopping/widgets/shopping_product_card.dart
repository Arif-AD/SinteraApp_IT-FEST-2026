import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../models/shopping_product_model.dart';
import '../pages/shopping_detail_page.dart';

class ShoppingProductCard extends StatelessWidget {
  Widget _buildProductImage(ShoppingProduct product) {
    final imageUrl = product.imageUrl?.trim();
    final hasValidImageUrl = imageUrl != null && imageUrl.isNotEmpty;

    if (!hasValidImageUrl) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Image.asset(
            product.imageAsset,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: double.infinity,
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
      ),
    );
  }
  const ShoppingProductCard({
    super.key,
    required this.product,
    this.showPlusIcon = false,
    this.onPlusPressed,
    this.receiver,
  });

  final ShoppingProduct product;
  final bool showPlusIcon;
  final VoidCallback? onPlusPressed;
  final Map<String, String>? receiver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              // Navigasi saat kotak produk diklik menuju Halaman Detail Produk
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShoppingDetailPage(product: product, receiver: receiver),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        child: _buildProductImage(product),
                      ),
                    ),
                    // Show remaining shelf-life badge if available
                    if (product.availableUntil != null && product.availableUntil!.isNotEmpty)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Builder(builder: (context) {
                          try {
                            final avail = DateTime.parse(product.availableUntil!).toLocal();
                            final diff = avail.difference(DateTime.now());
                            String text;
                            if (diff.inSeconds <= 0) {
                              text = 'Kadaluarsa';
                            } else if (diff.inDays >= 1) {
                              text = 'Tersisa ${diff.inDays} hari';
                            } else if (diff.inHours >= 1) {
                              text = 'Tersisa ${diff.inHours} jam';
                            } else {
                              text = 'Tersisa beberapa menit';
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF4D4F),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          } catch (_) {
                            return const SizedBox.shrink();
                          }
                        }),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                          ],
                        ),
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
                            if (showPlusIcon)
                              InkWell(
                                onTap: onPlusPressed,
                                borderRadius: BorderRadius.circular(6.0),
                                child: Container(
                                  padding: const EdgeInsets.all(4.0),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}