import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import 'order_chat_page.dart';
import 'order_detail_page.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  bool _isLoading = true;
  String _ratingSubmittingOrderId = '';
  String _selectedStatusTab = 'pending';
  final Map<String, int> _orderRatings = {};

  static const Map<String, String> _statusTabLabels = {
    'pending': 'Menunggu',
    'proses': 'Dikirim',
    'delivered': 'Selesai',
  };

  static const Map<String, String> _petaniStatusTabLabels = {
    'pending': 'Pesanan',
    'proses': 'Diproses',
    'delivered': 'Selesai',
  };

  void _handleBack() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go(AppRoutes.home);
  }
  String _errorMessage = '';
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final role = ref.read(authStorageProvider).value?.role;
      final orders = role == UserRole.petani
          ? await ref.read(laravelAuthServiceProvider).getFarmerOrders()
          : await ref.read(laravelAuthServiceProvider).getWargaOrders();
      if (!mounted) return;

      // Move completed/delivered orders to the bottom
      final sorted = List<Map<String, dynamic>>.from(orders);
      bool isCompleted(Map<String, dynamic> o) {
        final s = o['status']?.toString().toLowerCase() ?? '';
        final d = o['delivery_status']?.toString().toLowerCase() ?? '';
        return s == 'completed' ||
            s == 'selesai' ||
            s == 'cancelled' ||
            s == 'canceled' ||
            s == 'batal' ||
            d == 'delivered' ||
            d == 'selesai' ||
            d == 'cancelled' ||
            d == 'canceled' ||
            d == 'batal';
      }
      sorted.sort((a, b) {
        final ca = isCompleted(a);
        final cb = isCompleted(b);
        if (ca == cb) return 0;
        return ca ? 1 : -1;
      });
      final ratings = <String, int>{};
      for (final order in sorted) {
        final id = order['id']?.toString();
        final ratingValue = order['product_rating'];
        if (id != null && ratingValue != null) {
          final parsedRating = int.tryParse(ratingValue.toString()) ?? (ratingValue is double ? ratingValue.toInt() : null);
          if (parsedRating != null) {
            ratings[id] = parsedRating;
          }
        }
      }

      setState(() {
        _orders = sorted;
        _orderRatings
          ..clear()
          ..addAll(ratings);
        if (_orders.where((order) => _getOrderStatusTab(order) == _selectedStatusTab).isEmpty) {
          _selectedStatusTab = _firstAvailableOrderTab(sorted);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showNoCourierDialog(String id) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Belum ada pengantar terdaftar'),
          content: const Text('Belum ada pengantar terdaftar di wilayah ini.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tutup'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _cancelOrder(id);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Batalkan Pesanan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processOrder(String id, Color themeColor) async {
    try {
      final response = await ref.read(laravelAuthServiceProvider).processFarmerOrder(id);
      if (!mounted) return;

      final deliveryTask = response['delivery_task'];
      final deliveryPersonId = deliveryTask is Map<String, dynamic>
          ? deliveryTask['delivery_person_id']?.toString()
          : null;
      final status = deliveryTask is Map<String, dynamic>
          ? deliveryTask['status']?.toString().toLowerCase()
          : null;

      final hasCourier = deliveryPersonId != null && deliveryPersonId.isNotEmpty && deliveryPersonId != 'null';
      if (!hasCourier || status == 'pending') {
        await _showNoCourierDialog(id);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pesanan berhasil diproses.'),
          backgroundColor: themeColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _cancelOrder(String id) async {
    try {
      await ref.read(laravelAuthServiceProvider).cancelFarmerOrder(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dibatalkan.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getOrderStatusTab(Map<String, dynamic> order) {
    final status = order['status']?.toString().toLowerCase() ?? '';
    final deliveryStatus = order['delivery_status']?.toString().toLowerCase() ?? '';

    if (status == 'pending' || status == 'menunggu' || status == 'requested' || deliveryStatus == 'pending') {
      return 'pending';
    }

    if (status == 'proses' || status == 'processing' || status == 'confirmed' || status == 'paid' || deliveryStatus == 'proses' || deliveryStatus == 'shipped' || deliveryStatus == 'picked_up') {
      return 'proses';
    }

    if (status == 'delivered' ||
        status == 'completed' ||
        status == 'selesai' ||
        status == 'cancelled' ||
        status == 'canceled' ||
        status == 'batal' ||
        deliveryStatus == 'delivered' ||
        deliveryStatus == 'selesai' ||
        deliveryStatus == 'cancelled' ||
        deliveryStatus == 'canceled' ||
        deliveryStatus == 'batal') {
      return 'delivered';
    }

    return 'pending';
  }

  String _firstAvailableOrderTab(List<Map<String, dynamic>> orders) {
    const tabOrder = ['pending', 'proses', 'delivered'];
    for (final tab in tabOrder) {
      if (orders.any((order) => _getOrderStatusTab(order) == tab)) {
        return tab;
      }
    }
    return 'delivered';
  }

  String _formatCurrency(dynamic amount) {
    final number = double.tryParse(amount?.toString() ?? '0') ?? 0;
    final digits = number.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return 'Rp$buffer';
  }

  String _formatAddress(Map<String, dynamic>? receiver) {
    if (receiver == null) return '-';
    final address = receiver['address']?.toString() ?? '';
    final detailHouse = receiver['detail_house']?.toString() ?? '';
    final formatted = [address, detailHouse].where((part) => part.isNotEmpty).join(', ');
    return formatted.isNotEmpty ? formatted : '-';
  }

  Future<void> _submitRating(String orderId, int rating, Color themeColor) async {
    setState(() {
      _ratingSubmittingOrderId = orderId;
    });

    try {
      await ref.read(laravelAuthServiceProvider).rateOrder(orderId, rating);
      if (!mounted) return;
      setState(() {
        _orderRatings[orderId] = rating;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rating berhasil disimpan: $rating bintang.'),
          backgroundColor: themeColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _ratingSubmittingOrderId = '';
        });
      }
    }
  }

  bool _hasWargaParticipant(Map<String, dynamic> order) {
    return order['receiver_id'] != null || order['receiver'] != null || order['inhabitans_id'] != null || order['receiver_name'] != null;
  }

  bool _hasPetaniParticipant(Map<String, dynamic> order) {
    return order['farmers_id'] != null || order['farmer'] != null || order['product'] != null || order['product_name'] != null;
  }

  bool _hasPengantarParticipant(Map<String, dynamic> order) {
    return order['delivery_id'] != null || order['delivery_task'] != null || order['delivery_person_id'] != null || order['delivery_person'] != null;
  }

  List<Map<String, String>> _chatChannelsForOrder(Map<String, dynamic> order) {
    final role = ref.read(authStorageProvider).value?.role;
    final hasWarga = _hasWargaParticipant(order);
    final hasPetani = _hasPetaniParticipant(order);
    final hasPengantar = _hasPengantarParticipant(order);
    final channels = <Map<String, String>>[];

    if (role == UserRole.pengantar) {
      if (hasPetani) channels.add({'key': 'petani_pengantar', 'label': 'Petani'});
      if (hasWarga) channels.add({'key': 'warga_pengantar', 'label': 'Warga'});
    } else if (role == UserRole.petani) {
      if (hasWarga) channels.add({'key': 'warga_petani', 'label': 'Warga'});
      if (hasPengantar) channels.add({'key': 'petani_pengantar', 'label': 'Pengantar'});
    } else {
      if (hasPetani) channels.add({'key': 'warga_petani', 'label': 'Petani'});
      if (hasPengantar) channels.add({'key': 'warga_pengantar', 'label': 'Pengantar'});
    }

    return channels;
  }

  void _openOrderChat(String orderId, String orderType, Map<String, dynamic> orderData, String chatChannel) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => OrderChatPage(
          orderId: orderId,
          orderType: orderType,
          orderData: orderData,
          chatChannel: chatChannel,
        ),
      ),
    );
  }

  Widget _buildOrderTile(Map<String, dynamic> order, bool isPetani, Color themeColor) {
    final status = order['status']?.toString() ?? '-';
    final deliveryStatus = order['delivery_status']?.toString() ?? '-';
    final createdAt = order['created_at']?.toString() ?? '-';
    final total = order['final_amount'];
    
    final statusLower = status.toLowerCase();
    final deliveryLower = deliveryStatus.toLowerCase();
    
    final isCancelled = statusLower == 'cancelled' || statusLower == 'canceled' || statusLower == 'batal' ||
        deliveryLower == 'cancelled' || deliveryLower == 'canceled' || deliveryLower == 'batal';

    final items = (order['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>();
    final hasMultipleItems = items != null && items.length > 1;
    final firstItem = items != null && items.isNotEmpty ? items.first : null;
    final product = order['product'] as Map<String, dynamic>?;
    final productName = hasMultipleItems
      ? 'Keranjang Belanja (${items.length} item)'
      : firstItem?['name']?.toString() ?? product?['name']?.toString() ?? order['product_name']?.toString() ?? 'Produk';
    final productImageUrl = firstItem?['image']?.toString() ?? product?['image']?.toString() ?? product?['image_url']?.toString() ?? order['product_image']?.toString() ?? '';
    final receiver = order['receiver'] as Map<String, dynamic>?;
    final receiverName = receiver?['name']?.toString() ?? '';
    final receiverAddress = _formatAddress(receiver);
    final productQuantity = firstItem?['quantity']?.toString() ?? order['product_quantity']?.toString() ?? '1';
    final productUnit = firstItem?['unit']?.toString() ?? order['product_unit']?.toString() ?? product?['unit']?.toString() ?? '';
    final productSummary = hasMultipleItems
      ? '${items.length} produk'
      : '$productQuantity $productUnit';

    final completed = (statusLower == 'completed' || statusLower == 'selesai' || deliveryLower == 'delivered' || deliveryLower == 'selesai');

    final orderType = receiver != null ? 'sharing_order' : 'order';
    final chatChannels = _chatChannelsForOrder(order);

    return Container(
      decoration: BoxDecoration(
        color: completed ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1),
      ),
      child: InkWell(
        onTap: () {
          final orderId = order['id']?.toString() ?? '-';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailPage(orderId: orderId, orderData: order),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Produk pada pesanan dengan desain modern & minimalis
              if (firstItem != null || product != null || order['product_name'] != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                      ),
                      child: productImageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                productImageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(Icons.image_outlined, color: themeColor, size: 22),
                              ),
                            )
                          : Icon(Icons.image_outlined, color: themeColor, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: completed ? Colors.grey.shade600 : AppColors.textPrimary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                productSummary,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              if (isCancelled) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Dibatalkan',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (receiver != null && receiverName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Penerima: $receiverName • $receiverAddress',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 11.5,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ],
                ),

              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: Color(0xFFF1F3F5)),
              const SizedBox(height: AppSpacing.sm),

              // Info Waktu & Total Harga Rupiah
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dibuat: $createdAt',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: completed ? Colors.grey.shade600 : AppColors.textTertiary,
                          fontSize: 11,
                        ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Total: ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                      Text(
                        _formatCurrency(total),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: completed ? Colors.grey.shade600 : themeColor,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              if (chatChannels.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: List.generate(chatChannels.length, (index) {
                    final channel = chatChannels[index];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index < chatChannels.length - 1 ? 8.0 : 0),
                        child: OutlinedButton.icon(
                          onPressed: () => _openOrderChat(order['id']?.toString() ?? '-', orderType, order, channel['key']!),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: Text(channel['label']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: themeColor,
                            side: BorderSide(color: themeColor.withOpacity(0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],

              // Rating bintang untuk warga setelah pesanan selesai / delivered
              if (!isPetani && completed) ...[
                const SizedBox(height: AppSpacing.md),
                _buildRatingRow(order['id']?.toString() ?? '-', order, themeColor),
              ],
              // Tombol Proses Khusus Petani
              if (isPetani) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (status == 'pending' || status == 'confirmed') && deliveryStatus != 'shipped'
                            ? () => _processOrder(order['id']?.toString() ?? '-', themeColor)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          disabledBackgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.grey.shade400,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Proses Pesanan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: status != 'cancelled' && deliveryStatus != 'shipped' && deliveryStatus != 'delivered'
                            ? () => _cancelOrder(order['id']?.toString() ?? '-')
                            : null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade400),
                          foregroundColor: status != 'cancelled' && deliveryStatus != 'shipped' && deliveryStatus != 'delivered'
                              ? Colors.red
                              : Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Batalkan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow(String orderId, Map<String, dynamic> order, Color themeColor) {
    final currentRating = _orderRatings[orderId] ?? int.tryParse(order['product_rating']?.toString() ?? '') ?? 0;
    final isSubmitting = _ratingSubmittingOrderId == orderId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentRating > 0 ? 'Rating Anda: $currentRating' : 'Berikan rating produk',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1;
            final filled = currentRating >= starValue;
            return GestureDetector(
              onTap: isSubmitting
                  ? null
                  : () {
                      _submitRating(orderId, starValue, themeColor);
                    },
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: filled ? const Color(0xFFFFC107) : Colors.grey.shade400,
                  size: 20,
                ),
              ),
            );
          }),
        ),
        if (isSubmitting)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: themeColor),
                ),
                const SizedBox(width: AppSpacing.xs),
                const Text('Menyimpan rating...', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatusTabs(bool isPetani, Color themeColor) {
    final tabLabels = isPetani ? _petaniStatusTabLabels : _statusTabLabels;

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: tabLabels.keys.map((statusKey) {
          final isSelected = _selectedStatusTab == statusKey;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedStatusTab = statusKey),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? themeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tabLabels[statusKey] ?? statusKey,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = ref.watch(authStorageProvider).value?.role ?? UserRole.warga;
    
    // Warna tema disesuaikan persis dengan Home (Warga = Hijau, Petani = Biru, Pengantar = Merah)
    final Color themeColor = role == UserRole.pengantar
        ? const Color(0xFFB22222)
        : role == UserRole.petani
            ? const Color(0xFF1B3B6F)
            : AppColors.primary;

    final title = role == UserRole.petani ? 'Kelola Pesanan Petani' : 'Daftar Pesanan Warga';
    final visibleOrders = _orders.where((order) => _getOrderStatusTab(order) == _selectedStatusTab).toList();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Menghilangkan icon kembali secara otomatis
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary, size: 20),
          ),
        ],
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
            child: Column(
              children: [
                _buildStatusTabs(role == UserRole.petani, themeColor),
                Expanded(
                  child: RefreshIndicator(
                    color: themeColor,
                    onRefresh: _loadOrders,
                    child: _isLoading
                        ? ListView(
                            children: [
                              SizedBox(height: 220, child: Center(child: CircularProgressIndicator(color: themeColor))),
                            ],
                          )
                        : _errorMessage.isNotEmpty
                            ? ListView(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    child: Text(
                                      _errorMessage,
                                      style: const TextStyle(color: AppColors.error),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              )
                            : visibleOrders.isEmpty
                                ? ListView(
                                    children: [
                                      SizedBox(
                                        height: 320,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textTertiary),
                                              const SizedBox(height: AppSpacing.sm),
                                              Text(
                                                'Belum ada pesanan saat ini.',
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    itemCount: visibleOrders.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                                    itemBuilder: (context, index) {
                                      return _buildOrderTile(visibleOrders[index], role == UserRole.petani, themeColor);
                                    },
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