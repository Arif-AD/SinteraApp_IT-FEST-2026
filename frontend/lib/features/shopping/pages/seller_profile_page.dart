import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/pages/order_preview_page.dart';
import '../../shopping/models/shopping_product_model.dart';
import '../../shopping/widgets/shopping_product_card.dart';

class SellerProfilePage extends ConsumerStatefulWidget {
  const SellerProfilePage({
    super.key,
    required this.sellerName,
    this.sellerId,
  });

  final String sellerName;
  final String? sellerId;

  @override
  ConsumerState<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends ConsumerState<SellerProfilePage> {
  late final Future<List<ShoppingProduct>> _sellerProductsFuture;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, int> _cartQuantities = {};
  final Map<String, ShoppingProduct> _cartProducts = {};
  
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  final List<String> _categories = ['Semua', 'Sayur', 'Buah'];

  @override
  void initState() {
    super.initState();
    _sellerProductsFuture = _loadSellerProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _parsePrice(String price) {
    final numeric = price.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numeric) ?? 0;
  }

  String _formatRupiah(int amount) {
    final text = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final position = text.length - i;
      buffer.write(text[i]);
      if (position > 1 && position % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp${buffer.toString()}';
  }

  void _addToCart(ShoppingProduct product) {
    final productId = product.id ?? product.name;
    _cartProducts[productId] = product;
    _cartQuantities[productId] = (_cartQuantities[productId] ?? 0) + 1;
    setState(() {});
  }

  int get _cartTotalPrice {
    return _cartProducts.entries.fold(0, (sum, entry) {
      final quantity = _cartQuantities[entry.key] ?? 0;
      return sum + quantity * _parsePrice(entry.value.price);
    });
  }

  int get _cartTotalItems {
    return _cartQuantities.values.fold(0, (sum, qty) => sum + qty);
  }

  Future<List<ShoppingProduct>> _loadSellerProducts() async {
    final products = await ref.read(laravelAuthServiceProvider).getWargaProducts();
    return products.where((product) {
      if (widget.sellerId != null && product.sellerId != null) {
        return widget.sellerId == product.sellerId;
      }
      return product.farmerName == widget.sellerName;
    }).toList();
  }

  String _sellerInitials(String name) {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'TB';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String? _sellerProfileImageUrl(List<ShoppingProduct> products) {
    for (final product in products) {
      final url = product.farmerProfileImageUrl;
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color backgroundGrey = Color(0xFFF7F9FA);

    return Scaffold(
      backgroundColor: backgroundGrey,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
            child: FutureBuilder<List<ShoppingProduct>>(
              future: _sellerProductsFuture,
              builder: (context, snapshot) {
                final products = snapshot.data ?? [];
                
                final filteredProducts = products.where((p) {
                  final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategory == 'Semua' || p.category == _selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                final bottomSpacer = _cartProducts.isNotEmpty ? 96.0 : 0.0;
                return Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: bottomSpacer),
                      child: NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      // 1. APP BAR UTAMA
                      SliverAppBar(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        pinned: true,
                        floating: true,
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        titleSpacing: 0,
                        title: Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.md),
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              textAlignVertical: TextAlignVertical.center,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Cari produk di toko ini...',
                                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textTertiary),
                                prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: Colors.white,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.15), width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.15), width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 2. HEADER PROFIL TOKO
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                foregroundImage: _sellerProfileImageUrl(products) != null
                                    ? NetworkImage(_sellerProfileImageUrl(products)!)
                                    : null,
                                child: _sellerProfileImageUrl(products) == null
                                    ? Text(
                                        _sellerInitials(widget.sellerName),
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.sellerName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Aktif',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.agriculture_rounded, size: 16, color: AppColors.primary),
                                label: const Text(
                                  'Petani',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 3. FILTER KATEGORI PRODUK
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverCategoryBarDelegate(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                              ),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              child: Row(
                                children: _categories.map((category) {
                                  final isSelected = _selectedCategory == category;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(category),
                                      selected: isSelected,
                                      showCheckmark: false,
                                      selectedColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.15),
                                        ),
                                      ),
                                      onSelected: (selected) {
                                        setState(() {
                                          _selectedCategory = category;
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ];
                  },
                  body: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : filteredProducts.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 40.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.remove_shopping_cart_outlined, size: 54, color: AppColors.textTertiary),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      'Tidak ada produk ditemukan di toko ini',
                                      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : CustomScrollView(
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(6.0, AppSpacing.md, 6.0, 6.0),
                                  sliver: SliverGrid(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 6.0,
                                      crossAxisSpacing: 6.0,
                                      childAspectRatio: 0.62,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                              (context, index) {
                                        final product = filteredProducts[index];
                                        return ShoppingProductCard(
                                          product: product,
                                          showPlusIcon: true,
                                          onPlusPressed: () => _addToCart(product),
                                        );
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
                    ),
                    if (_cartProducts.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          margin: const EdgeInsets.all(AppSpacing.sm),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Image.asset('assets/images/icon/icon_belanja.png'),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Total $_cartTotalItems produk',
                                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatRupiah(_cartTotalPrice),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final previewProducts = _cartProducts.entries.map((entry) {
                                    final product = entry.value;
                                    final quantity = _cartQuantities[entry.key] ?? 1;
                                    return {
                                      'id': product.id,
                                      'name': product.name,
                                      'price': product.price,
                                      'unit': product.unit,
                                      'image_url': product.imageUrl ?? '',
                                      'farmer_name': product.farmerName,
                                      'farmer_address': product.farmerAddress,
                                      'farmer_detail_house': product.farmerDetailHouse,
                                      'shipping_distance_km': product.shippingDistanceKm,
                                      'shipping_note': product.shippingNote,
                                      'quantity': quantity,
                                      'base_fee': product.shippingBaseFee,
                                      'distance_fee': product.shippingDistanceFee,
                                      'farmer_subsidy': product.shippingFarmerSubsidy,
                                      'customer_shipping': product.shippingCustomerShipping,
                                      'address': product.farmerAddress,
                                    };
                                  }).toList();

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderPreviewPage(previewProducts: previewProducts),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Beli'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverCategoryBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverCategoryBarDelegate({required this.child});
  final Widget child;

  @override
  double get minExtent => 50.0;
  @override
  double get maxExtent => 50.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverCategoryBarDelegate oldDelegate) {
    return false;
  }
}