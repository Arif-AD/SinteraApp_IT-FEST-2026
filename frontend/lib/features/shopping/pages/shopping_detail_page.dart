import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/pages/order_preview_page.dart';
import '../models/shopping_product_model.dart';

class ShoppingDetailPage extends ConsumerStatefulWidget {
  const ShoppingDetailPage({
    super.key,
    required this.product,
    this.isFarmer = false,
    this.receiver,
  });

  final ShoppingProduct product;
  final bool isFarmer;
  final Map<String, String>? receiver;

  @override
  ConsumerState<ShoppingDetailPage> createState() => _ShoppingDetailPageState();
}

class _ShoppingDetailPageState extends ConsumerState<ShoppingDetailPage> {
  Widget _buildProductImage(ShoppingProduct product) {
    final imageUrl = product.imageUrl?.trim();
    final hasValidImageUrl = imageUrl != null && imageUrl.isNotEmpty;

    if (!hasValidImageUrl) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Image.asset(
            product.imageAsset,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Image.asset(
            product.imageAsset,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  void _handleBack() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Warna otomatis menyesuaikan berdasarkan role: Biru untuk petani, Merah untuk pembeli/umum[cite: 8]
    final Color primaryColor = widget.isFarmer ? const Color(0xFF1B3B6F) : const Color(0xFFB71C1C);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
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
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 10.0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _handleBack,
                            icon: Icon(Icons.arrow_back_rounded, color: primaryColor),
                          ),
                          Expanded(
                            child: Text(
                              'Detail Produk',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: Container(
                          color: Colors.white,
                          child: Stack(
                            children: [
                              _buildProductImage(widget.product),
                              if (widget.product.discount != null)
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF4D4F),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      (widget.product.availableUntil != null && widget.product.availableUntil!.isNotEmpty)
                                          ? (() {
                                              try {
                                                final avail = DateTime.parse(widget.product.availableUntil!).toLocal();
                                                final diff = avail.difference(DateTime.now());
                                                if (diff.inSeconds <= 0) return 'Kadaluarsa';
                                                if (diff.inDays >= 1) return 'Tersisa ${diff.inDays} hari';
                                                if (diff.inHours >= 1) return 'Tersisa ${diff.inHours} jam';
                                                return 'Tersisa beberapa menit';
                                              } catch (_) {
                                                return '';
                                              }
                                            })()
                                          : '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  widget.product.price,
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '/${widget.product.unit}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (widget.product.originalPrice != null)
                                  Text(
                                    widget.product.originalPrice!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.product.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFC107)),
                                const SizedBox(width: 4),
                                Text(
                                  widget.product.rating,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '|  ${widget.product.sold}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: primaryColor.withValues(alpha: 0.1),
                              foregroundImage: widget.product.farmerProfileImageUrl != null && widget.product.farmerProfileImageUrl!.isNotEmpty
                                  ? NetworkImage(widget.product.farmerProfileImageUrl!)
                                  : null,
                              child: widget.product.farmerProfileImageUrl == null || widget.product.farmerProfileImageUrl!.isEmpty
                                  ? Icon(Icons.storefront_rounded, color: primaryColor)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.product.farmerName.isNotEmpty ? widget.product.farmerName : 'Petani Lokal',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Aktif • Kategori ${widget.product.category}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!widget.isFarmer)
                              OutlinedButton(
                                onPressed: () {
                                  final encodedSellerName = Uri.encodeComponent(widget.product.farmerName);
                                  final sellerId = widget.product.sellerId;
                                  final query = sellerId != null
                                      ? '?sellerName=$encodedSellerName&sellerId=${Uri.encodeComponent(sellerId)}'
                                      : '?sellerName=$encodedSellerName';
                                  context.push('${AppRoutes.sellerProfile}$query');
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: primaryColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                child: Text('Kunjungi', style: TextStyle(color: primaryColor, fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        color: Colors.white,
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deskripsi Produk',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.product.description != null && widget.product.description!.isNotEmpty
                                  ? widget.product.description!
                                  : 'Deskripsi produk belum tersedia.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              if (!widget.isFarmer)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final currentUser = ref.read(authStorageProvider).value;
                            final previewProduct = {
                              'id': widget.product.id,
                              'name': widget.product.name,
                              'price': widget.product.price,
                              'unit': widget.product.unit,
                              'farmer_name': widget.product.farmerName,
                              'farmer_address': widget.product.farmerAddress,
                              'farmer_detail_house': widget.product.farmerDetailHouse,
                              'base_fee': widget.product.shippingBaseFee,
                              'distance_fee': widget.product.shippingDistanceFee,
                              'farmer_subsidy': widget.product.shippingFarmerSubsidy,
                              'customer_shipping': widget.product.shippingCustomerShipping,
                              'shipping_distance_km': widget.product.shippingDistanceKm,
                              'shipping_note': widget.product.shippingNote,
                              'farm_address': widget.product.farmerAddress,
                              'category': widget.product.category,
                              'address': widget.product.farmerAddress,
                              'farmer': {
                                'farm_address': widget.product.farmerAddress,
                                'detail_house': widget.product.farmerDetailHouse,
                                'user': {
                                  'address': {
                                    'address': widget.product.farmerAddress,
                                    'detail_house': widget.product.farmerDetailHouse,
                                  }
                                }
                              },
                              'receiver_id': widget.receiver?['receiver_id'] ?? '',
                              'receiver_name': widget.receiver?['receiver_name'] ?? '',
                              'receiver_phone': widget.receiver?['receiver_phone'] ?? '',
                              'receiver_address': widget.receiver?['receiver_address'] ?? currentUser?.address ?? '',
                              'receiver_detail_house': widget.receiver?['receiver_detail_house'] ?? currentUser?.detailHouse ?? '',
                            };

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderPreviewPage(
                                  previewProducts: [previewProduct],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text(
                            'Beli Sekarang',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
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