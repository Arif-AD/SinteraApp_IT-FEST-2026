import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../../points/providers/points_provider.dart';

class OrderPreviewPage extends ConsumerStatefulWidget {
  const OrderPreviewPage({super.key, required this.previewProducts});

  final List<Map<String, dynamic>> previewProducts;

  @override
  ConsumerState<OrderPreviewPage> createState() => _OrderPreviewPageState();
}

class _OrderPreviewPageState extends ConsumerState<OrderPreviewPage> {
  bool _isCreatingOrder = false;
  int _quantity = 1;
  bool _usePoints = false;
  bool _isShippingDetailExpanded = false;
  Map<String, dynamic>? _createdOrder;
  late List<Map<String, dynamic>> _previewProducts;

  @override
  void initState() {
    super.initState();
    _previewProducts = widget.previewProducts.map((item) => Map<String, dynamic>.from(item)).toList();
    if (_previewProducts.length == 1) {
      _quantity = _parseQuantity(_previewProducts.first);
    }
  }

  int _parseQuantity(Map<String, dynamic> item) {
    return int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
  }

  void _syncPreviewQuantity(int quantity) {
    if (_previewProducts.isEmpty) {
      return;
    }

    final item = _previewProducts.first;
    item['quantity'] = quantity;
    item['subtotal'] = quantity * _parseRupiah(item['price']?.toString() ?? '0');
  }

  int _lineSubtotal(Map<String, dynamic> item) {
    return _parseQuantity(item) * _parseRupiah(item['price']?.toString() ?? '0');
  }

  int get _subtotalValue {
    return _previewProducts.fold(0, (sum, item) => sum + _lineSubtotal(item));
  }

  int get _cartTotalItems {
    return _previewProducts.fold(0, (sum, item) => sum + _parseQuantity(item));
  }

  bool _isOrderDeliveredLike(Map<String, dynamic> order) {
    final status = order['status']?.toString().toLowerCase() ?? '';
    final deliveryStatus = order['delivery_status']?.toString().toLowerCase() ?? '';

    return status == 'completed' ||
        status == 'selesai' ||
        status == 'delivered' ||
        deliveryStatus == 'completed' ||
        deliveryStatus == 'selesai' ||
        deliveryStatus == 'delivered';
  }

  bool _isOrderCancelledLike(Map<String, dynamic> order) {
    final status = order['status']?.toString().toLowerCase() ?? '';
    return status == 'cancelled' ||
        status == 'canceled' ||
        status == 'batal' ||
        status == 'dibatalkan';
  }

  bool _isOrderStillActive(Map<String, dynamic> order) {
    return !_isOrderDeliveredLike(order) && !_isOrderCancelledLike(order);
  }

  Future<bool> _guardAgainstActiveOrder() async {
    final role = ref.read(authStorageProvider).value?.role;
    if (role != UserRole.warga) {
      return false;
    }

    try {
      final orders = await ref.read(laravelAuthServiceProvider).getWargaOrders();
      if (!mounted) return false;

      final hasActiveOrder = orders.any(_isOrderStillActive);
      if (!hasActiveOrder) {
        return false;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.all(AppSpacing.lg),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 30),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Pesanan Masih Berjalan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Kamu masih memiliki pesanan yang belum selesai. Selesaikan pesanan sebelumnya sebelum membuat pesanan baru.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _confirmPurchase() async {
    setState(() {
      _isCreatingOrder = true;
    });

    final blocked = await _guardAgainstActiveOrder();
    if (!mounted) return;

    if (blocked) {
      setState(() {
        _isCreatingOrder = false;
      });
      return;
    }

    final receiverPayload = _buildReceiverPayload(_previewProducts.first);

    try {
      final int usedPointsPayload = _usePoints
          ? (() {
              final pointsAvailableRupiah = (ref.read(wargaPointsProvider).maybeWhen(data: (v) => v, orElse: () => 0)) * 10;
              final appliedRupiah = pointsAvailableRupiah < _subtotalValue ? pointsAvailableRupiah : _subtotalValue;
              return (appliedRupiah / 10).floor();
            })()
          : 0;

      if (_previewProducts.length == 1) {
        final item = _previewProducts.first;

        final orderResponse = await ref.read(laravelAuthServiceProvider).createOrder({
          'product_id': item['id'],
          'quantity': _quantity,
          'use_points': _usePoints ? 1 : 0,
          if (usedPointsPayload > 0) 'used_points': usedPointsPayload,
          ...receiverPayload,
        });

        if (!mounted) return;

        setState(() {
          _createdOrder = orderResponse;
          _isCreatingOrder = false;
        });

        if (_usePoints) {
          ref.refresh(wargaPointsProvider.future);
          ref.read(wargaPointsOverrideProvider.notifier).state = null;
        }
      } else {
        final itemsPayload = _previewProducts.map((item) {
          return {
            'product_id': item['id'],
            'quantity': _parseQuantity(item),
          };
        }).toList();

        final orderResponse = await ref.read(laravelAuthServiceProvider).createOrder({
          'items': itemsPayload,
          'use_points': _usePoints ? 1 : 0,
          if (usedPointsPayload > 0) 'used_points': usedPointsPayload,
          ...receiverPayload,
        });

        if (!mounted) return;
        setState(() {
          _createdOrder = orderResponse;
          _isCreatingOrder = false;
        });

        if (_usePoints) {
          ref.refresh(wargaPointsProvider.future);
          ref.read(wargaPointsOverrideProvider.notifier).state = null;
        }
      }

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.all(AppSpacing.lg),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 30),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Pembayaran Berhasil',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Pesanan Anda berhasil dibuat. Silakan cek status pesanan Anda pada halaman pesanan.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.go(AppRoutes.orders);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Lihat Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isCreatingOrder = false;
      });
    }
  }

  String _formatAuthAddress() {
    final currentUser = ref.watch(authStorageProvider).value;
    if (currentUser == null) return '-';
    final address = currentUser.address.trim();
    final detailHouse = currentUser.detailHouse.trim();
    final formatted = [address, detailHouse].where((part) => part.isNotEmpty).join(', ');
    return formatted.isNotEmpty ? formatted : '-';
  }

  String _formatAddressFromPayload(Map<String, dynamic> payload) {
    final address = payload['receiver_address']?.toString().trim() ?? '';
    final detailHouse = payload['receiver_detail_house']?.toString().trim() ?? '';
    final formatted = [address, detailHouse].where((part) => part.isNotEmpty).join(', ');
    return formatted.isNotEmpty ? formatted : '-';
  }

  String _formatReceiverNameFromPayload(Map<String, dynamic> payload) {
    final name = payload['receiver_name']?.toString().trim() ?? '';
    return name.isNotEmpty ? name : '-';
  }

  String _formatReceiverPhoneFromPayload(Map<String, dynamic> payload) {
    final phone = payload['receiver_phone']?.toString().trim() ?? '';
    return phone.isNotEmpty ? phone : '-';
  }

  Map<String, dynamic> _buildReceiverPayload(Map<String, dynamic> payload) {
    final receiverId = payload['receiver_id'];
    if (receiverId == null || receiverId.toString().trim().isEmpty) {
      return {};
    }

    return {
      'receiver_id': int.tryParse(receiverId.toString()) ?? receiverId,
      'receiver_name': payload['receiver_name'] ?? '',
      'receiver_phone': payload['receiver_phone'] ?? '',
      'receiver_address': payload['receiver_address'] ?? '',
      'receiver_detail_house': payload['receiver_detail_house'] ?? '',
    };
  }

  String _formatAuthName() {
    final currentUser = ref.watch(authStorageProvider).value;
    if (currentUser == null) return '-';
    return currentUser.name.trim().isNotEmpty ? currentUser.name.trim() : '-';
  }

  String _formatAuthPhone() {
    final currentUser = ref.watch(authStorageProvider).value;
    if (currentUser == null) return '-';
    return currentUser.phone.trim().isNotEmpty ? currentUser.phone.trim() : '-';
  }

  String _resolveFarmerAddress(Map<String, dynamic> payload) {
    final directAddress = payload['farmer_address']?.toString().trim();
    if (directAddress != null && directAddress.isNotEmpty) {
      return directAddress;
    }

    final farmer = payload['farmer'];
    if (farmer is Map<String, dynamic>) {
      final user = farmer['user'];
      if (user is Map<String, dynamic>) {
        final userAddress = user['address'];
        if (userAddress is Map<String, dynamic>) {
          final nestedAddress = userAddress['address']?.toString().trim();
          if (nestedAddress != null && nestedAddress.isNotEmpty) {
            return nestedAddress;
          }
        }
      }
    }

    return '';
  }

  String _resolveFarmerDetailHouse(Map<String, dynamic> payload) {
    final directDetailHouse = payload['farmer_detail_house']?.toString().trim();
    if (directDetailHouse != null && directDetailHouse.isNotEmpty) {
      return directDetailHouse;
    }

    final farmer = payload['farmer'];
    if (farmer is Map<String, dynamic>) {
      final user = farmer['user'];
      if (user is Map<String, dynamic>) {
        final userAddress = user['address'];
        if (userAddress is Map<String, dynamic>) {
          final nestedDetailHouse = userAddress['detail_house']?.toString().trim();
          if (nestedDetailHouse != null && nestedDetailHouse.isNotEmpty) {
            return nestedDetailHouse;
          }
        }
      }
    }

    return '';
  }

  int _parseRupiah(String value) {
    final numeric = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(numeric) ?? 0;
  }

  String _formatRupiah(int value) {
    final formatted = value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');
    return 'Rp$formatted';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewProducts = _previewProducts;
    final previewProduct = previewProducts.first;
    final hasMultipleItems = previewProducts.length > 1;

    final farmerAddress = _resolveFarmerAddress(previewProduct);
    final farmerDetailHouse = _resolveFarmerDetailHouse(previewProduct);
    final formattedFarmerAddress = [farmerAddress, farmerDetailHouse].where((part) => part.isNotEmpty).join(', ');
    final productImage = previewProduct['image']?.toString() ?? previewProduct['image_url']?.toString();

    final pickupAddressDisplay = formattedFarmerAddress.isNotEmpty
        ? formattedFarmerAddress
        : previewProduct['farmer_name']?.toString() ?? 'Alamat Petani Belum Diatur';

    final receiverNamePayload = _formatReceiverNameFromPayload(previewProduct);
    final receiverPhonePayload = _formatReceiverPhoneFromPayload(previewProduct);
    final receiverAddressPayload = _formatAddressFromPayload(previewProduct);
    final receiverAddressRaw = _formatAuthAddress();
    final receiverNameRaw = _formatAuthName();
    final receiverPhoneRaw = _formatAuthPhone();

    final receiverAddress = receiverAddressPayload != '-'
        ? receiverAddressPayload
        : receiverAddressRaw != '-'
            ? receiverAddressRaw
            : 'Alamat Warga Belum Diatur';
    final receiverName = receiverNamePayload != '-'
        ? receiverNamePayload
        : receiverNameRaw != '-'
            ? receiverNameRaw
            : 'Nama Warga Belum Diatur';
    final receiverPhone = receiverPhonePayload != '-'
        ? receiverPhonePayload
        : receiverPhoneRaw != '-'
            ? receiverPhoneRaw
            : 'Telepon belum tersedia';
    final receiverInfo = '$receiverName • $receiverPhone';

    final orderPayload = _createdOrder ?? previewProduct;
    final productName = hasMultipleItems ? 'Keranjang Belanja ($_cartTotalItems item)' : previewProduct['name']?.toString() ?? 'Produk';
    final unit = previewProduct['unit']?.toString() ?? 'pcs';
    final price = previewProduct['price']?.toString() ?? '0';
    final unitPriceValue = _parseRupiah(price);

    final subtotalValue = _subtotalValue;
    final distanceKm = (orderPayload['shipping_distance_km'] as num?)?.toDouble() ??
        (previewProduct['shipping_distance_km'] as num?)?.toDouble() ?? 0.0;

    final int baseFee = 2000;
    final int distanceFee = (distanceKm * 2000).round();
    final int totalShipping = baseFee + distanceFee;

    int farmerSubsidy = 0;
    int customerShipping = totalShipping;
    double targetThreshold = 0;

    if (distanceKm <= 3.0) {
      targetThreshold = 30000;
      if (subtotalValue >= 30000) {
        customerShipping = baseFee;
        farmerSubsidy = distanceFee;
      }
    } else if (distanceKm > 3.0 && distanceKm <= 5.0) {
      targetThreshold = 50000;
      if (subtotalValue >= 50000) {
        customerShipping = baseFee;
        farmerSubsidy = distanceFee;
      }
    }

    int remainingForFreeShipping = 0;
    if (targetThreshold > 0 && subtotalValue < targetThreshold) {
      remainingForFreeShipping = (targetThreshold - subtotalValue).round();
    }

    final shippingNote = orderPayload['shipping_note']?.toString() ??
        previewProduct['shipping_note']?.toString() ??
        (distanceKm > 0 ? 'Jarak pengiriman sekitar $distanceKm km.' : 'Biaya pengiriman dihitung otomatis berdasarkan jarak.');

    // Points handling: 100 poin = 1000 rupiah (1 poin = 10 rupiah)
    final pointsBalance = ref.watch(effectiveWargaPointsProvider);
    final int availableRupiahFromPoints = pointsBalance * 10;
    // Only subtotal is eligible to be covered by points
    final int appliedRupiahFromPoints = _usePoints
        ? (availableRupiahFromPoints < subtotalValue ? availableRupiahFromPoints : subtotalValue)
        : 0;
    final int finalTotalAfterPoints = (subtotalValue - appliedRupiahFromPoints) + customerShipping;

    final subtotal = _formatRupiah(subtotalValue);
    final unitPriceDisplay = hasMultipleItems ? '$_cartTotalItems produk' : _formatRupiah(unitPriceValue);
    final finalTotal = _formatRupiah(finalTotalAfterPoints);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          } else {
            context.go(AppRoutes.home);
          }
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Preview Pesanan',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              navigator.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.black.withValues(alpha: 0.05),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. KARTU INFORMASI ALAMAT
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alamat Pengiriman',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildAddressTile(
                          Icons.storefront_outlined,
                          'Alamat Penjemputan (Petani)',
                          pickupAddressDisplay,
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 32, top: 8, bottom: 8),
                          child: Divider(height: 1, color: Color(0xFFF1F3F5)),
                        ),
                        _buildAddressTile(
                          Icons.person_outline,
                          'Penerima Warga',
                          receiverInfo,
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 32, top: 8, bottom: 8),
                          child: Divider(height: 1, color: Color(0xFFF1F3F5)),
                        ),
                        _buildAddressTile(
                          Icons.location_on_outlined,
                          'Alamat Penerima (Warga)',
                          receiverAddress,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 2. KARTU RINCIAN PRODUK
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rincian Produk',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          productName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (hasMultipleItems) ...previewProducts.map((item) {
                          final itemImage = item['image']?.toString() ?? item['image_url']?.toString() ?? '';
                          final itemName = item['name']?.toString() ?? 'Produk';
                          final itemUnit = item['unit']?.toString() ?? 'pcs';
                          final itemPrice = _formatRupiah(_parseRupiah(item['price']?.toString() ?? '0'));
                          final itemQuantity = _parseQuantity(item);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: itemImage.isNotEmpty
                                        ? Image.network(
                                            itemImage,
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                                          )
                                        : const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        itemName,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'x$itemQuantity • $itemPrice/$itemUnit',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList() else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: productImage != null && productImage.isNotEmpty
                                      ? Image.network(
                                          productImage,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                                        )
                                      : const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$unit • $unitPriceDisplay',
                                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: _quantity > 1
                                          ? () {
                                              setState(() {
                                                _quantity -= 1;
                                                _syncPreviewQuantity(_quantity);
                                              });
                                            }
                                          : null,
                                      icon: const Icon(Icons.remove, size: 16),
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text(
                                        '$_quantity',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _quantity += 1;
                                          _syncPreviewQuantity(_quantity);
                                        });
                                      },
                                      icon: const Icon(Icons.add, size: 16),
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 3. BANNER INFO / PESAN JARAK & GRATIS ONGKIR
                  if (distanceKm > 5.0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Perhatian: Jarak pengiriman di atas 5 km berada di luar cakupan subsidi. Biaya pengiriman dikenakan secara penuh sesuai jarak aktual.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ] else if (remainingForFreeShipping > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined, color: AppColors.warning, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Tambah belanja ${_formatRupiah(remainingForFreeShipping)} lagi untuk dapat gratis ongkir!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ] else if (farmerSubsidy > 0) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.celebration_outlined, color: AppColors.success, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Yay, kamu dapat gratis ongkir!',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // 4. KARTU RINCIAN PEMBAYARAN DENGAN DROPDOWN ONGKIR INTERAKTIF
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rincian Pembayaran',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal Produk',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                            Text(subtotal, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        
                        // Bagian Ongkir dengan Tombol Panah Bawah (Expandable)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isShippingDetailExpanded = !_isShippingDetailExpanded;
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Ongkir Ditanggung Warga',
                                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _isShippingDetailExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                                Text(_formatRupiah(customerShipping), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),

                        // Detail yang muncul saat panah diklik
                        if (_isShippingDetailExpanded) ...[
                          Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 4),
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('• Biaya Dasar', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11.5)),
                                    Text(_formatRupiah(baseFee), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, fontSize: 11.5)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('• Biaya Jarak ($distanceKm km x Rp2.000)', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11.5)),
                                    Text(_formatRupiah(distanceFee), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, fontSize: 11.5)),
                                  ],
                                ),
                                if (farmerSubsidy > 0) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('• Gratis Ongkir', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.success, fontSize: 11.5)),
                                      Text('-${_formatRupiah(farmerSubsidy)}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500, color: AppColors.success, fontSize: 11.5)),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        if (farmerSubsidy > 0 && !_isShippingDetailExpanded) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Gratis Ongkir', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.success)),
                              Text('-${_formatRupiah(farmerSubsidy)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.success)),
                            ],
                          ),
                        ],

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Divider(height: 1, color: Color(0xFFF1F3F5)),
                        ),
                        // Toggle menggunakan poin
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('Gunakan Poin (100 poin = Rp1.000)', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                            ),
                            Row(
                              children: [
                                Text('${pointsBalance.toString()} Poin', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                const SizedBox(width: 8),
                                Switch(
                                  value: _usePoints,
                                  onChanged: (v) {
                                    setState(() => _usePoints = v);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Pembayaran',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    shippingNote,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              finalTotal,
                              textAlign: TextAlign.right,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // TOMBOL BAYAR SEKARANG
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isCreatingOrder ? null : _confirmPurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text(
                        _isCreatingOrder ? 'Memproses Pembayaran...' : 'Bayar Sekarang',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildAddressTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 11, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}