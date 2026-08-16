import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../shopping/models/shopping_product_model.dart' as shopping_model;
import '../../shopping/pages/shopping_detail_page.dart';
import '../models/sell_product_model.dart';

class SellProductCard extends StatelessWidget {
  const SellProductCard({
    super.key,
    required this.product,
    required this.onDelete,
    required this.onEdit,
  });

  final SellProduct product;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final shoppingProduct = shopping_model.ShoppingProduct(
                name: product.name,
                category: product.category,
                price: product.price,
                unit: product.unit,
                imageAsset: 'assets/images/icon/icon_belanja.png',
                imageUrl: product.imageUrl,
                farmerName: product.farmerName.isNotEmpty ? product.farmerName : 'Petani Lokal',
                farmerProfileImageUrl: product.farmerProfileImageUrl,
                farmerAddress: product.farmerAddress,
                farmerDetailHouse: product.farmerDetailHouse,
                rating: product.rating,
                sold: '${product.stock} Tersedia',
                description: product.description,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShoppingDetailPage(
                    product: shoppingProduct,
                    isFarmer: true,
                  ),
                ),
              );
            },
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 6,
                    color: const Color(0xFF1B3B6F),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B3B6F).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: product.imageUrl != null
                                  ? Image.network(
                                      product.imageUrl!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Image.asset(
                                          'assets/images/icon/icon_belanja.png',
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Image.asset(
                                        'assets/images/icon/icon_belanja.png',
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product.name,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.success.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        product.status,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.success,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${product.price} / ${product.unit}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF1B3B6F),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                  Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B3B6F).withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        product.category,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: const Color(0xFF1B3B6F),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      'Stok: ${product.stock} ${product.unit}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                  const SizedBox(height: 6),
                                  Builder(builder: (context) {
                                    String? shelfText;
                                    Color shelfColor = AppColors.textSecondary;
                                    final availRaw = product.availableUntil;
                                    if (availRaw != null && availRaw.isNotEmpty) {
                                      try {
                                        final avail = DateTime.parse(availRaw).toLocal();
                                        final diff = avail.difference(DateTime.now());
                                        if (diff.inSeconds <= 0) {
                                          shelfText = 'Kadaluarsa';
                                          shelfColor = AppColors.error;
                                        } else if (diff.inDays >= 1) {
                                          shelfText = 'Tersisa ${diff.inDays} hari';
                                          shelfColor = AppColors.warning;
                                        } else if (diff.inHours >= 1) {
                                          shelfText = 'Tersisa ${diff.inHours} jam';
                                          shelfColor = AppColors.warning;
                                        } else {
                                          shelfText = 'Tersisa beberapa menit';
                                          shelfColor = AppColors.warning;
                                        }
                                      } catch (_) {
                                        shelfText = null;
                                      }
                                    }

                                    if (shelfText == null) return const SizedBox.shrink();

                                    return Text(
                                      shelfText,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: shelfColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEdit();
                              } else if (value == 'delete') {
                                onDelete();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                                    SizedBox(width: 8),
                                    Text('Edit Produk'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ],
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
      ),
    );
  }
}