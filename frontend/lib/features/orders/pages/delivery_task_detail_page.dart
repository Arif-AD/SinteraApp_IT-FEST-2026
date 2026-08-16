import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';

class DeliveryTaskDetailPage extends ConsumerStatefulWidget {
  const DeliveryTaskDetailPage({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<DeliveryTaskDetailPage> createState() => _DeliveryTaskDetailPageState();
}

class _DeliveryTaskDetailPageState extends ConsumerState<DeliveryTaskDetailPage> {
  bool _isLoading = true;
  bool _isProcessingAction = false;
  String _error = '';
  Map<String, dynamic>? _task;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final task = await ref.read(laravelAuthServiceProvider).getDeliveryTaskDetail(widget.taskId);
      if (!mounted) return;
      setState(() => _task = task);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _accept() async {
    if (_isProcessingAction) return;
    setState(() => _isProcessingAction = true);
    try {
      await ref.read(laravelAuthServiceProvider).acceptDeliveryTask(widget.taskId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task diterima')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<bool> _complete() async {
    if (_isProcessingAction) return false;
    setState(() => _isProcessingAction = true);
    try {
      await ref.read(laravelAuthServiceProvider).completeDeliveryTask(widget.taskId);
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task diselesaikan')));
      await _load();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      return false;
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Color _statusColor(String status) {
    const Color defaultRed = Color(0xFFB71C1C);
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return defaultRed;
      case 'picked_up':
        return AppColors.info;
      case 'completed':
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'waste_delivery':
        return 'Pengiriman Limbah';
      case 'waste_pickup':
        return 'Pickup Limbah';
      case 'agricultural_delivery':
        return 'Pengiriman Pesanan';
      default:
        return 'Tugas Pengiriman';
    }
  }

  String _formatAddress(Map<String, dynamic>? user) {
    if (user == null) return '-';
    final address = user['address']?.toString().trim() ?? '';
    final detailHouse = user['detail_house']?.toString().trim() ?? '';
    final formatted = [address, detailHouse].where((part) => part.isNotEmpty).join(', ');
    return formatted.isNotEmpty ? formatted : '-';
  }

  Future<void> _openMapsForAddress(String address) async {
    if (address.isEmpty || address == '-') return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _openMapsForCoordinates(String latStr, String lngStr) async {
    if (latStr.isEmpty || lngStr.isEmpty) return;
    try {
      final lat = double.tryParse(latStr.replaceAll(',', '.'));
      final lng = double.tryParse(lngStr.replaceAll(',', '.'));
      if (lat == null || lng == null) return;
      final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // ignore
    }
  }

  String _formatDateTime(String raw) {
    if (raw.isEmpty || raw == '-') return '-';
    try {
      final dt = DateTime.tryParse(raw);
      if (dt == null) return raw;
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute';
    } catch (_) {
      return raw;
    }
  }

  Widget _buildAddressTileWithMap(IconData icon, String label, String value, {String? lat, String? lng}) {
    const Color defaultRed = Color(0xFFB71C1C);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: defaultRed),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
                    const SizedBox(width: AppSpacing.sm),
                    InkWell(
                      onTap: () {
                        if (lat != null && lng != null) {
                          _openMapsForCoordinates(lat, lng);
                        } else {
                          _openMapsForAddress(value);
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: defaultRed.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.map_outlined, color: defaultRed),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    const Color defaultRed = Color(0xFFB71C1C);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: defaultRed),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.read(authStorageProvider).value?.id;
    const Color defaultRed = Color(0xFFB71C1C);

    if (_isLoading) return const Center(child: CircularProgressIndicator(color: defaultRed));
    if (_error.isNotEmpty) return Center(child: Text(_error, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error)));
    if (_task == null) return const SizedBox.shrink();

    final status = _task?['status']?.toString() ?? '-';
    final type = _task?['type']?.toString() ?? '-';
    final isWasteTask = type == 'waste_delivery';
    final deliveryPerson = _task?['delivery_person'] as Map<String, dynamic>?;
    final order = _task?['order'] as Map<String, dynamic>?;
    final sharingOrder = _task?['sharing_order'] as Map<String, dynamic>?;
    final waste = _task?['waste'] as Map<String, dynamic>?;
    final wastePickup = _task?['waste_pickup'] as Map<String, dynamic>?;

    final recipientUser = isWasteTask
        ? (waste?['farmer'] as Map<String, dynamic>?)
        : order != null
            ? order['user'] as Map<String, dynamic>?
            : sharingOrder != null
                ? (sharingOrder['receiver'] as Map<String, dynamic>?)
                : wastePickup != null
                    ? wastePickup['user'] as Map<String, dynamic>?
                    : null;

    final recipientName = recipientUser?['name']?.toString() ?? '-';
    final recipientPhone = recipientUser?['phone']?.toString() ?? '-';

    final pickupAddress = _task?['pickup_address']?.toString() ?? '-';
    final destinationAddress = isWasteTask
        ? (_task?['destination_address']?.toString().trim().isNotEmpty == true
            ? _task!['destination_address'].toString()
            : _formatAddress(recipientUser))
        : _task?['destination_address']?.toString() ?? '-';
    final pickupLat = _task?['pickup_latitude']?.toString();
    final pickupLng = _task?['pickup_longitude']?.toString();
    final destinationLat = _task?['destination_latitude']?.toString();
    final destinationLng = _task?['destination_longitude']?.toString();
    final scheduledAtRaw = _task?['scheduled_at']?.toString() ?? '-';
    final completedAtRaw = _task?['completed_at']?.toString() ?? '-';
    final scheduledAt = _formatDateTime(scheduledAtRaw);
    final completedAt = _formatDateTime(completedAtRaw);
    final orderItems = (order?['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>();
    final firstOrderItem = orderItems?.isNotEmpty == true ? orderItems!.first : null;
    final orderProductData = order?['product'] as Map<String, dynamic>?;
    final productImage = firstOrderItem != null
        ? firstOrderItem['product_image']?.toString() ?? firstOrderItem['image']?.toString() ?? firstOrderItem['image_url']?.toString()
        : orderProductData is Map<String, dynamic>
            ? orderProductData['image']?.toString() ?? orderProductData['image_url']?.toString()
            : null;
    final deliveryPersonName = deliveryPerson?['name']?.toString() ?? '-';
    final deliveryPersonPhone = deliveryPerson?['phone']?.toString() ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Detail Tugas Pengiriman', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18), onPressed: () => Navigator.pop(context)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1.0), child: Container(color: Colors.black.withValues(alpha: 0.05), height: 1.0)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildSectionCard(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_typeLabel(type), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: AppSpacing.xs),
                        Text('ID Tugas: ${widget.taskId}', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      ]),
                      _buildBadge(status.toUpperCase(), _statusColor(status)),
                    ]),
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoTile(Icons.schedule, 'Jadwal', scheduledAt),
                    if (completedAt != '-' && (status == 'completed' || status == 'delivered')) _buildInfoTile(Icons.check_circle_outline, 'Selesai', completedAt),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  _buildSectionCard(children: [
                    Text(isWasteTask ? 'Informasi Petani Penerima' : 'Informasi Penerima', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoTile(Icons.person_outline_rounded, 'Nama', recipientName),
                    _buildInfoTile(Icons.phone_iphone, 'Nomor HP', recipientPhone),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  _buildSectionCard(children: [
                    Text('Rute Pengiriman', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.md),
                    _buildAddressTileWithMap(Icons.storefront_outlined, isWasteTask ? 'Alamat Pengirim' : 'Alamat Penjemputan', pickupAddress, lat: pickupLat, lng: pickupLng),
                    _buildAddressTileWithMap(Icons.location_on_outlined, 'Alamat Tujuan', destinationAddress, lat: destinationLat, lng: destinationLng),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  _buildSectionCard(children: [
                    Text('Pengantar', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.md),
                    _buildInfoTile(Icons.person, 'Nama', deliveryPersonName != '-' ? deliveryPersonName : 'Belum ditugaskan'),
                    _buildInfoTile(Icons.phone, 'HP', deliveryPersonPhone != '-' ? deliveryPersonPhone : 'Belum tersedia'),
                  ]),
                  if (order != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionCard(children: [
                      Text('Rincian Pesanan', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: AppSpacing.md),
                      if (orderItems != null && orderItems.isNotEmpty)
                        () {
                          final item = firstOrderItem!;
                          final name = item['product_name']?.toString() ?? item['name']?.toString() ?? 'Produk';
                          final subtotal = order['total_amount']?.toString() ?? item['subtotal']?.toString() ?? '0';
                          final quantity = item['quantity']?.toString() ?? item['product_quantity']?.toString() ?? '1';
                          final unit = item['product_unit']?.toString() ?? item['unit']?.toString() ?? '';
                          final extraCount = orderItems.length > 1 ? ' +${orderItems.length - 1} item lain' : '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: defaultRed.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: productImage != null && productImage.isNotEmpty
                                        ? Image.network(
                                            productImage,
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, color: defaultRed, size: 20),
                                          )
                                        : const Icon(Icons.shopping_bag_outlined, color: defaultRed, size: 20),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text('$quantity $unit', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                      if (extraCount.isNotEmpty)
                                        Text(extraCount, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Text('Rp$subtotal', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                          );
                        }()
                      else if (order['product'] is Map)
                        () {
                          final product = order['product'] as Map<String, dynamic>?;
                          final name = product?['name']?.toString() ?? 'Produk';
                          final price = product?['price']?.toString() ?? '0';
                          final subtotal = order['total_amount']?.toString() ?? '0';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: defaultRed.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: productImage != null && productImage.isNotEmpty
                                        ? Image.network(
                                            productImage,
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined, color: defaultRed, size: 20),
                                          )
                                        : const Icon(Icons.shopping_bag_outlined, color: defaultRed, size: 20),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text('Rp$price', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Text('Rp$subtotal', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                              ],
                            ),
                          );
                        }()
                      else
                        Text('Tidak ada rincian pesanan tersedia.', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                    ]),
                  ],
                  const SizedBox(height: AppSpacing.xxxl),
                ]),
              ),
            ),
            if (status == 'pending' || (_task?['delivery_person_id']?.toString() == currentUserId && (status == 'accepted' || status == 'picked_up')))
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
                child: Row(children: [
                  if (status == 'pending')
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _accept,
                        style: ElevatedButton.styleFrom(backgroundColor: defaultRed, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: const Text('Terima Task', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  if (status == 'pending' && _task?['delivery_person_id']?.toString() == currentUserId && (status == 'accepted' || status == 'picked_up'))
                    const SizedBox(width: AppSpacing.md),
                  if (_task?['delivery_person_id']?.toString() == currentUserId && (status == 'accepted' || status == 'picked_up'))
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_isProcessingAction)
                            ? null
                            : () async {
                                final goRouter = GoRouter.of(context);
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Konfirmasi'),
                                    content: const Text('Tandai task ini sebagai selesai?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
                                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Ya')),
                                    ],
                                  ),
                                );
                                if (!mounted || confirm != true) return;
                                final success = await _complete();
                                if (!mounted || !success) return;
                                goRouter.go(AppRoutes.home);
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: defaultRed, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}