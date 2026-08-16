import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import 'order_chat_page.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  final String orderId;
  final Map<String, dynamic> orderData;

  String _formatAddress(Map<String, dynamic>? userOrReceiver) {
    if (userOrReceiver == null) return '-';
    final address = userOrReceiver['address']?.toString() ?? '';
    final detailHouse = userOrReceiver['detail_house']?.toString() ?? '';
    final formatted = [address, detailHouse].where((part) => part.isNotEmpty).join(', ');
    return formatted.isNotEmpty ? formatted : '-';
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'menunggu':
        return AppColors.warning;
      case 'confirmed':
      case 'proses':
      case 'sukses':
      case 'paid':
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
      case 'gagal':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = orderData['status']?.toString() ?? '-';
    final paymentStatus = orderData['payment_status']?.toString() ?? '-';
    final deliveryStatus = orderData['delivery_status']?.toString() ?? '-';
    final total = orderData['final_amount']?.toString() ?? '0';
    final baseFee = orderData['base_fee']?.toString() ?? '0';
    final distanceFee = orderData['distance_fee']?.toString() ?? '0';
    final farmerSubsidy = orderData['farmer_subsidy']?.toString() ?? '0';
    final customerShipping = orderData['customer_shipping']?.toString() ?? '0';
    final shippingNote = orderData['shipping_note']?.toString() ?? 'Biaya pengiriman dihitung otomatis.';
    final deliveryTask = orderData['delivery_task'] as Map<String, dynamic>?;
    final deliveryPerson = deliveryTask?['delivery_person'] as Map<String, dynamic>?;
    final deliveryPersonName = deliveryPerson?['name']?.toString() ?? '-';

    final user = orderData['user'] as Map<String, dynamic>?;
    final receiver = orderData['receiver'] as Map<String, dynamic>?;
    final receiverName = receiver?['name']?.toString() ?? user?['name']?.toString() ?? '-';
    final receiverPhone = receiver?['phone']?.toString() ?? '-';
    final receiverAddress = _formatAddress(receiver ?? user);
    final pickupAddress = deliveryTask?['pickup_address']?.toString() ?? '-';

    final items = (orderData['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>();
    final hasMultipleItems = items != null && items.length > 1;
    final firstItem = items != null && items.isNotEmpty ? items.first : null;
    final product = orderData['product'] as Map<String, dynamic>?;
    final productName = hasMultipleItems
      ? 'Keranjang Belanja (${items.length} item)'
      : firstItem?['name']?.toString() ?? product?['name']?.toString() ?? orderData['product_name']?.toString() ?? 'Produk';
    final productImageUrl = firstItem?['image']?.toString() ?? product?['image']?.toString() ?? orderData['product_image']?.toString() ?? '';
    final productQuantity = firstItem?['quantity']?.toString() ?? orderData['product_quantity']?.toString() ?? '1';
    final productUnit = firstItem?['unit']?.toString() ?? orderData['product_unit']?.toString() ?? product?['unit']?.toString() ?? '';
    final productSubtotal = firstItem?['subtotal']?.toString() ?? orderData['total_amount']?.toString() ?? '0';

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
          'Detail Pesanan',
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
                          'No. Pesanan: #$orderId',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          status.toUpperCase(),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

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
                          'Informasi Pengiriman',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildModernInfoTile(Icons.person_outline_rounded, 'Pengantar', deliveryPersonName),
                        const Padding(
                          padding: EdgeInsets.only(left: 32, top: 8, bottom: 8),
                          child: Divider(height: 1, color: Color(0xFFF1F3F5)),
                        ),
                        _buildModernInfoTile(Icons.storefront_outlined, 'Alamat Penjemputan (Petani)', pickupAddress),
                        const Padding(
                          padding: EdgeInsets.only(left: 32, top: 8, bottom: 8),
                          child: Divider(height: 1, color: Color(0xFFF1F3F5)),
                        ),
                        if (receiver != null) ...[
                          _buildModernInfoTile(Icons.person_outline_rounded, 'Penerima', receiverName),
                          const Padding(
                            padding: EdgeInsets.only(left: 32, top: 8, bottom: 8),
                            child: Divider(height: 1, color: Color(0xFFF1F3F5)),
                          ),
                          if (receiverPhone.isNotEmpty)
                            _buildModernInfoTile(Icons.phone_outlined, 'Telepon Penerima', receiverPhone),
                          if (receiverPhone.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(left: 32, top: 8, bottom: 8),
                              child: Divider(height: 1, color: Color(0xFFF1F3F5)),
                            ),
                        ],
                        _buildModernInfoTile(Icons.location_on_outlined, 'Alamat Penerima (Warga)', receiverAddress),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

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
                        if (hasMultipleItems)
                          ...items.map((item) {
                            final itemName = item['name']?.toString() ?? 'Produk';
                            final itemQuantity = item['quantity']?.toString() ?? '1';
                            final itemUnit = item['unit']?.toString() ?? '';
                            final itemPrice = item['price']?.toString() ?? '0';
                            final itemImage = item['image']?.toString() ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                      child: itemImage.isNotEmpty
                                          ? Image.network(
                                              itemImage,
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
                                          itemName,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$itemQuantity $itemUnit',
                                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text(
                                    _formatCurrency(itemPrice),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                  child: productImageUrl.isNotEmpty
                                      ? Image.network(
                                          productImageUrl,
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
                                      productName,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$productQuantity $productUnit',
                                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                _formatCurrency(productSubtotal),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

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
                        _buildSummaryRow('Status Pembayaran', paymentStatus),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSummaryRow('Status Pengiriman', deliveryStatus),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Divider(height: 1, color: Color(0xFFF1F3F5)),
                        ),
                        _buildSummaryRow('Subtotal', _formatCurrency(orderData['total_amount'] ?? '0')),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSummaryRow('Biaya dasar', _formatCurrency(baseFee)),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSummaryRow('Biaya jarak', _formatCurrency(distanceFee)),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSummaryRow('Subsidi petani', '-${_formatCurrency(farmerSubsidy)}'),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSummaryRow('Biaya yang dibayar warga', _formatCurrency(customerShipping)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          shippingNote,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Divider(height: 1, color: Color(0xFFF1F3F5)),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Harga',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatCurrency(total),
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
                  const SizedBox(height: AppSpacing.md),
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
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final orderType = receiver != null ? 'sharing_order' : 'order';
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                            builder: (context) => OrderChatPage(
                              orderId: orderId,
                              orderType: orderType,
                              orderData: orderData,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                      label: const Text('Chat Pesanan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildModernInfoTile(IconData icon, String label, String value) {
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

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.textPrimary)),
      ],
    );
  }
}