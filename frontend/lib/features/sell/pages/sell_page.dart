import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../../utils/app_navigation.dart';
import '../../../utils/cloudinary_upload.dart';
import '../../../utils/responsive.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/sell_product_model.dart';
import '../widgets/sell_empty_state.dart';
import '../widgets/sell_product_card.dart';
import '../widgets/sell_summary_card.dart';

class SellPage extends ConsumerStatefulWidget {
  const SellPage({super.key});

  @override
  ConsumerState<SellPage> createState() => _SellPageState();
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final numericOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final value = int.parse(numericOnly);
    final formatted = value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
        );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _SellPageState extends ConsumerState<SellPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _shelfLifeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = 'Sayur';
  String _searchQuery = '';
  String _selectedFilterCategory = 'Semua';
  bool _isAddingProduct = false;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  SellProduct? _editingProduct;
  bool _isEditing = false;
  final ImagePicker _imagePicker = ImagePicker();
  String? _productImageUrl;

  final List<String> _categories = ['Sayur', 'Buah'];
  final List<String> _filterCategories = ['Semua', 'Sayur', 'Buah'];

  final List<SellProduct> _products = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _shelfLifeController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFormView() {
    setState(() {
      _isAddingProduct = !_isAddingProduct;
      if (_isAddingProduct) {
        _nameController.clear();
        _priceController.clear();
        _unitController.clear();
        _stockController.clear();
        _shelfLifeController.clear();
        _descriptionController.clear();
        _selectedCategory = 'Sayur';
        _productImageUrl = null;
        _isEditing = false;
        _editingProduct = null;
      }
    });
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ref.read(laravelAuthServiceProvider).getFarmerProducts();
      if (!mounted) return;
      setState(() {
        _products.clear();
        _products.addAll(products.map((item) => SellProduct.fromApiMap(item)));
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data produk dari server.')),
        );
      }
    }
  }

  void _startEdit(SellProduct product) {
    setState(() {
      _editingProduct = product;
      _isEditing = true;
      _isAddingProduct = true;
      _nameController.text = product.name;
      final rawPrice = product.price.replaceAll(RegExp(r'[^0-9]'), '');
      if (rawPrice.isNotEmpty) {
        final val = int.tryParse(rawPrice) ?? 0;
        _priceController.text = val.toString().replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (match) => '${match[1]}.',
            );
      } else {
        _priceController.clear();
      }
      _unitController.text = product.unit;
      _stockController.text = product.stock;
      _selectedCategory = product.category;
      _productImageUrl = product.imageUrl;
      _descriptionController.text = product.description ?? '';
      if (product.availableUntil != null && product.availableUntil!.isNotEmpty && product.updatedAt != null && product.updatedAt!.isNotEmpty) {
        try {
          final avail = DateTime.parse(product.availableUntil!);
          final upd = DateTime.parse(product.updatedAt!);
          final diff = avail.difference(upd).inDays;
          _shelfLifeController.text = diff > 0 ? diff.toString() : '0';
        } catch (_) {
          _shelfLifeController.clear();
        }
      } else {
        _shelfLifeController.clear();
      }
    });
  }

  Future<void> _pickProductImage() async {
    final imageSource = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Ambil Foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (imageSource == null) return;

    try {
      setState(() => _isUploadingImage = true);
      final pickedFile = await _imagePicker.pickImage(
        source: imageSource,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (pickedFile == null) return;

      final uploadedUrl = await CloudinaryUpload.uploadImage(pickedFile);
      if (!mounted) return;
      setState(() {
        _productImageUrl = uploadedUrl;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _deleteProduct(String id) async {
    try {
      await ref.read(laravelAuthServiceProvider).deleteFarmerProduct(id);
      if (!mounted) return;
      setState(() {
        _products.removeWhere((item) => item.id == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil dihapus')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final price = _priceController.text.trim();
    final unit = _unitController.text.trim();
    final stock = _stockController.text.trim();

    if (_productImageUrl == null || _productImageUrl!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto produk wajib diisi')),
      );
      return;
    }

    if (name.isEmpty || price.isEmpty || unit.isEmpty || stock.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field terlebih dahulu')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'name': name,
        'category': _selectedCategory,
        'description': _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        'price': int.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        'unit': unit,
        'stock': int.tryParse(stock) ?? 0,
        'status': 'available',
        'image': _productImageUrl,
        if (_shelfLifeController.text.trim().isNotEmpty) 'masa_simpan': int.tryParse(_shelfLifeController.text.trim()) ?? 0,
      };

      if (_isEditing && _editingProduct != null) {
        final updatedProduct = await ref.read(laravelAuthServiceProvider).updateFarmerProduct(
          _editingProduct!.id,
          payload,
        );

        if (!mounted) return;

        setState(() {
          final index = _products.indexWhere((item) => item.id == _editingProduct!.id);
          if (index != -1) {
            _products[index] = SellProduct(
              id: updatedProduct['id']?.toString() ?? _editingProduct!.id,
              name: updatedProduct['name']?.toString() ?? name,
              category: SellProduct.normalizeCategory(updatedProduct['category'] ?? _selectedCategory),
              price: 'Rp${((updatedProduct['price'] as num?) ?? 0).toStringAsFixed(0)}',
              unit: updatedProduct['unit']?.toString() ?? unit,
              stock: updatedProduct['stock']?.toString() ?? stock,
              status: 'Aktif',
              imageUrl: updatedProduct['image']?.toString() ?? _productImageUrl,
              description: updatedProduct['description']?.toString() ?? _descriptionController.text.trim(),
              availableUntil: updatedProduct['available_until']?.toString(),
              updatedAt: updatedProduct['updated_at']?.toString(),
            );
          }
          _isAddingProduct = false;
          _isEditing = false;
          _editingProduct = null;
          _nameController.clear();
          _priceController.clear();
          _unitController.clear();
          _stockController.clear();
          _shelfLifeController.clear();
          _selectedCategory = 'Sayur';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil diperbarui')),
        );
      } else {
        final createdProduct = await ref.read(laravelAuthServiceProvider).createFarmerProduct(payload);

        if (!mounted) return;

        setState(() {
          _products.insert(
            0,
            SellProduct(
              id: createdProduct['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              name: createdProduct['name']?.toString() ?? name,
              category: SellProduct.normalizeCategory(createdProduct['category'] ?? _selectedCategory),
              price: 'Rp${((createdProduct['price'] as num?) ?? 0).toStringAsFixed(0)}',
              unit: createdProduct['unit']?.toString() ?? unit,
              stock: createdProduct['stock']?.toString() ?? stock,
              status: 'Aktif',
              imageUrl: createdProduct['image']?.toString(),
              description: createdProduct['description']?.toString() ?? _descriptionController.text.trim(),
              availableUntil: createdProduct['available_until']?.toString(),
              updatedAt: createdProduct['updated_at']?.toString(),
            ),
          );
          _isAddingProduct = false;
          _nameController.clear();
          _priceController.clear();
          _unitController.clear();
          _stockController.clear();
          _selectedCategory = 'Sayur';
          _descriptionController.clear();
          _shelfLifeController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil ditambahkan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const petaniGradientColors = [Color(0xFF1B3B6F), Color(0xFF0C2340)];
    const Color primaryBlue = Color(0xFF1B3B6F);

    final filteredProducts = _products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedFilterCategory == 'Semua' || p.category == _selectedFilterCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: petaniGradientColors,
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  IconButton(
                                    onPressed: () => safePopOrGoHome(context),
                                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kelola Toko & Jualan',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.58,
                                      child: Text(
                                        'Kelola hasil panen dan produk pertanian Anda di sini',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.normal,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                child: SellSummaryCard(
                                  activeCount: _products.where((p) => p.status == 'Aktif').length,
                                  totalStock: _products.fold<int>(0, (sum, p) => sum + (int.tryParse(p.stock) ?? 0)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -130,
                      top: -60,
                      child: IgnorePointer(
                        child: Container(
                          width: 230,
                          height: 230,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -40,
                      top: 10,
                      child: IgnorePointer(
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 5,
                      top: 62,
                      child: IgnorePointer(
                        child: Image(
                          image: AssetImage('assets/images/petani.png'),
                          height: 155,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isAddingProduct ? (_isEditing ? 'Perbarui Produk' : 'Tambah Produk') : 'Daftar Produk (${_products.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _toggleFormView,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: Icon(_isAddingProduct ? Icons.list_alt_rounded : Icons.add_rounded, size: 16),
                            label: Text(
                              _isAddingProduct ? 'Daftar Produk' : 'Tambah Baru',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (!_isAddingProduct) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Cari produk hasil panen...',
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary),
                              prefixIcon: const Icon(Icons.search_rounded, color: primaryBlue),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filterCategories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final cat = _filterCategories[index];
                              final isSelected = _selectedFilterCategory == cat;
                              return InkWell(
                                onTap: () => setState(() => _selectedFilterCategory = cat),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? primaryBlue : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? primaryBlue : Colors.black.withValues(alpha: 0.12),
                                      width: isSelected ? 1.5 : 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _isAddingProduct
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, AppSpacing.xxl),
                        child: Column(
                          children: [
                            // SECTION 1: FOTO PRODUK (Wajib)
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Foto Produk',
                                            style: theme.textTheme.labelLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const Text(
                                            ' *',
                                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      if (_isUploadingImage)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: _isUploadingImage ? null : _pickProductImage,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 85,
                                          height: 85,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8F9FA),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: primaryBlue.withValues(alpha: 0.3),
                                              style: BorderStyle.solid,
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.camera_alt_rounded, color: primaryBlue, size: 24),
                                              const SizedBox(height: 4),
                                              Text(
                                                _productImageUrl != null && _productImageUrl!.isNotEmpty
                                                    ? 'Ganti Foto'
                                                    : 'Tambah Foto',
                                                style: const TextStyle(
                                                  color: primaryBlue,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (_productImageUrl != null && _productImageUrl!.isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 85,
                                          height: 85,
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  _productImageUrl!,
                                                  height: 85,
                                                  width: 85,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => Container(
                                                    height: 85,
                                                    width: 85,
                                                    color: Colors.grey.shade100,
                                                    alignment: Alignment.center,
                                                    child: const Text('Gagal', style: TextStyle(fontSize: 10)),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () => setState(() => _productImageUrl = null),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(2),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.black54,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Icons.close, size: 12, color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // SECTION 2: KATEGORI & SPESIFIKASI PRODUK
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kategori Produk',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildCategoryCard(
                                          title: 'Sayur',
                                          subtitle: 'Segar & Organik',
                                          isSelected: _selectedCategory == 'Sayur',
                                          onTap: () => setState(() => _selectedCategory = 'Sayur'),
                                          primaryColor: primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildCategoryCard(
                                          title: 'Buah',
                                          subtitle: 'Pilihan Terbaik',
                                          isSelected: _selectedCategory == 'Buah',
                                          onTap: () => setState(() => _selectedCategory = 'Buah'),
                                          primaryColor: primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(color: Color(0xFFF1F3F5), height: 1),
                                  ),
                                  _buildShopeeTextField(
                                    label: 'Nama Produk',
                                    controller: _nameController,
                                    hint: 'Contoh: Bayam Segar',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Divider(color: Color(0xFFF1F3F5), height: 1),
                                  ),
                                  _buildShopeeTextField(
                                    label: 'Harga (Rp)',
                                    controller: _priceController,
                                    hint: 'Contoh: 5.000',
                                    isNumber: true,
                                    inputFormatters: [_CurrencyInputFormatter()],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Divider(color: Color(0xFFF1F3F5), height: 1),
                                  ),
                                  _buildShopeeTextField(
                                    label: 'Satuan',
                                    controller: _unitController,
                                    hint: 'Contoh: Ikat / Kg',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Divider(color: Color(0xFFF1F3F5), height: 1),
                                  ),
                                  _buildShopeeTextField(
                                    label: 'Stok Tersedia',
                                    controller: _stockController,
                                    hint: '0',
                                    isNumber: true,
                                    hasCounter: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // SECTION 3: INFORMASI TAMBAHAN (MASA SIMPAN & DESKRIPSI)
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildShopeeTextField(
                                    label: 'Masa Simpan',
                                    controller: _shelfLifeController,
                                    hint: '0',
                                    isNumber: true,
                                    suffixText: 'Hari',
                                    hasCounter: true,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    child: Divider(color: Color(0xFFF1F3F5), height: 1),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Deskripsi Produk',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _descriptionController,
                                    maxLines: 3,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                    decoration: const InputDecoration(
                                      hintText: 'Tuliskan deskripsi atau detail kualitas produk...',
                                      hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // TOMBOL SIMPAN
                            Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1B3B6F), Color(0xFF0C2340)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryBlue.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _saveProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.zero,
                                  alignment: Alignment.center,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Center(
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Text(
                                          'Simpan',
                                          style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : filteredProducts.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: SellEmptyState(
                            onAdd: _toggleFormView,
                            isFiltered: _searchQuery.isNotEmpty || _selectedFilterCategory != 'Semua',
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = filteredProducts[index];
                                return SellProductCard(
                                  product: product,
                                  onDelete: () => _deleteProduct(product.id),
                                  onEdit: () => _startEdit(product),
                                );
                              },
                              childCount: filteredProducts.length,
                            ),
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopeeTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
    String? suffixText,
    bool hasCounter = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                if (hasCounter) ...[
                  InkWell(
                    onTap: () {
                      final currentVal = int.tryParse(controller.text) ?? 0;
                      if (currentVal > 0) {
                        controller.text = (currentVal - 1).toString();
                        setState(() {});
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.remove, size: 16, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: hasCounter
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 45,
                              child: TextFormField(
                                controller: controller,
                                keyboardType: isNumber ? TextInputType.number : TextInputType.text,
                                textAlign: TextAlign.center,
                                inputFormatters: inputFormatters,
                                onChanged: isNumber ? (val) => setState(() {}) : null,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: hint,
                                  hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (suffixText != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                suffixText,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: TextFormField(
                                controller: controller,
                                keyboardType: isNumber ? TextInputType.number : TextInputType.text,
                                textAlign: TextAlign.start,
                                inputFormatters: inputFormatters,
                                onChanged: isNumber ? (val) => setState(() {}) : null,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: hint,
                                  hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (suffixText != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                suffixText,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                ),
                if (hasCounter) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      final currentVal = int.tryParse(controller.text) ?? 0;
                      controller.text = (currentVal + 1).toString();
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B3B6F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.add, size: 16, color: Color(0xFF1B3B6F)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.black.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? primaryColor.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 4 : 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primaryColor : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 16, color: primaryColor)
            else
              Icon(Icons.radio_button_unchecked_rounded, size: 16, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}