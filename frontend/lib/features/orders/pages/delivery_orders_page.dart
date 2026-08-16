import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import 'delivery_task_detail_page.dart';
import 'order_chat_page.dart';

class DeliveryOrdersPage extends ConsumerStatefulWidget {
  final bool embedded;

  const DeliveryOrdersPage({super.key, this.embedded = false});

  @override
  ConsumerState<DeliveryOrdersPage> createState() => _DeliveryOrdersPageState();
}

class _DeliveryOrdersPageState extends ConsumerState<DeliveryOrdersPage> {
  bool _isLoading = true;
  bool _isActioning = false;
  String _error = '';
  String _selectedDeliveryTab = 'baru';
  List<Map<String, dynamic>> _tasks = [];

  static const Map<String, String> _deliveryTabs = {
    'baru': 'Baru',
    'proses': 'Diproses',
    'selesai': 'Selesai',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTasks());
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final tasks = await ref.read(laravelAuthServiceProvider).getDeliveryTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        if (_tasks.where((task) => _getDeliveryTabKey(task) == _selectedDeliveryTab).isEmpty) {
          _selectedDeliveryTab = _firstAvailableDeliveryTab(tasks);
        }
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _accept(String id) async {
    if (_isActioning) return;
    setState(() => _isActioning = true);
    try {
      await ref.read(laravelAuthServiceProvider).acceptDeliveryTask(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task diterima'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadTasks();
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
      if (mounted) setState(() => _isActioning = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'assigned':
        return AppColors.warning;
      case 'accepted':
      case 'picked_up':
      case 'in_transit':
        return AppColors.primary;
      case 'delivered':
      case 'completed':
      case 'selesai':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  bool _hasWargaForTask(Map<String, dynamic> task) {
    final order = task['order'] as Map<String, dynamic>?;
    final sharingOrder = task['sharing_order'] as Map<String, dynamic>?;
    final data = order ?? sharingOrder ?? task;
    return data['receiver_id'] != null || data['receiver'] != null || data['inhabitans_id'] != null || data['receiver_name'] != null;
  }

  bool _hasPetaniForTask(Map<String, dynamic> task) {
    final order = task['order'] as Map<String, dynamic>?;
    final sharingOrder = task['sharing_order'] as Map<String, dynamic>?;
    final data = order ?? sharingOrder ?? task;
    return data['farmers_id'] != null || data['farmer'] != null || data['farmer_id'] != null || data['product'] != null || data['product_name'] != null;
  }

  bool _hasPengantarForTask(Map<String, dynamic> task) {
    return task['delivery_id'] != null || task['delivery_person_id'] != null || task['delivery_task'] != null || task['delivery_person'] != null;
  }

  List<Map<String, String>> _chatChannelsForTask(Map<String, dynamic> task) {
    final role = ref.read(authStorageProvider).value?.role;
    final hasWarga = _hasWargaForTask(task);
    final hasPetani = _hasPetaniForTask(task);
    final hasPengantar = _hasPengantarForTask(task);
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

  void _openTaskChat(BuildContext context, String orderId, String orderType, Map<String, dynamic> orderData, String chatChannel) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => OrderChatPage(
          orderId: orderId,
          orderType: orderType,
          orderData: orderData,
          chatChannel: chatChannel,
        ),
      ),
    );
  }

  String _getDeliveryTabKey(Map<String, dynamic> task) {
    final status = task['status']?.toString().toLowerCase() ?? '';
    switch (status) {
      case 'pending':
      case 'assigned':
        return 'baru';
      case 'accepted':
      case 'picked_up':
      case 'in_transit':
        return 'proses';
      case 'delivered':
      case 'completed':
      case 'selesai':
        return 'selesai';
      default:
        return 'baru';
    }
  }

  String _firstAvailableDeliveryTab(List<Map<String, dynamic>> tasks) {
    const tabOrder = ['baru', 'proses', 'selesai'];
    for (final tab in tabOrder) {
      if (tasks.any((task) => _getDeliveryTabKey(task) == tab)) {
        return tab;
      }
    }
    return 'selesai';
  }

  List<Map<String, dynamic>> _getFilteredTasks(String selectedTab) {
    return _tasks.where((task) => _getDeliveryTabKey(task) == selectedTab).toList();
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

  Widget _buildStatusTabs(Color themeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: _deliveryTabs.entries.map((entry) {
          final isSelected = entry.key == _selectedDeliveryTab;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedDeliveryTab = entry.key),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? themeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  entry.value,
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

  Widget _buildChatGrid(List<Widget> chatButtons) {
    if (chatButtons.isEmpty) return const SizedBox.shrink();
    
    final rows = <Widget>[];
    for (int i = 0; i < chatButtons.length; i += 2) {
      final first = chatButtons[i];
      final second = (i + 1 < chatButtons.length) ? chatButtons[i + 1] : null;

      rows.add(
        Row(
          children: [
            Expanded(child: first),
            if (second != null) ...[
              const SizedBox(width: 8),
              Expanded(child: second),
            ] else ...[
              const SizedBox(width: 8),
              const Expanded(child: SizedBox.shrink()),
            ],
          ],
        ),
      );
      if (i + 2 < chatButtons.length) {
        rows.add(const SizedBox(height: 8));
      }
    }
    return Column(children: rows);
  }

  Widget _buildTaskTile(BuildContext context, ThemeData theme, Map<String, dynamic> task, Color themeColor) {
    final status = task['status']?.toString() ?? 'Pending';
    final type = task['type']?.toString() ?? '-';
    final isWasteTask = type == 'waste_delivery';
    final order = task['order'] as Map<String, dynamic>?;
    final sharingOrder = task['sharing_order'] as Map<String, dynamic>?;
    final waste = task['waste'] as Map<String, dynamic>?;
    final wastePickup = task['waste_pickup'] as Map<String, dynamic>?;

    final farmer = waste?['farmer'] as Map<String, dynamic>?;
    final title = _typeLabel(type);
    
    final destinationAddress = isWasteTask
        ? (task['destination_address']?.toString().trim().isNotEmpty == true
            ? task['destination_address'].toString()
            : _formatAddress(farmer))
        : task['destination_address']?.toString() ?? '-';

    final itemDescription = order != null && order['product'] is Map
        ? '${order['product']?['name'] ?? 'Produk'}'
        : sharingOrder != null
            ? '${sharingOrder['product_name'] ?? 'Produk'}'
            : (isWasteTask ? 'Pengiriman Limbah ke Petani' : (wastePickup != null ? 'Pickup Limbah' : 'Pengiriman Pesanan'));

    final orderType = sharingOrder != null || task['sharing_order_id'] != null ? 'sharing_order' : 'order';
    final orderId = sharingOrder != null
        ? sharingOrder['id']?.toString() ?? task['sharing_order_id']?.toString() ?? ''
        : order != null
            ? order['id']?.toString() ?? task['order_id']?.toString() ?? ''
            : task['order_id']?.toString() ?? '';
    final orderData = sharingOrder ?? order ?? <String, dynamic>{'id': orderId};
    final chatChannels = _chatChannelsForTask(task);
    
    final statusLower = status.toLowerCase();
    final isCompleted = statusLower == 'delivered' || statusLower == 'completed' || statusLower == 'selesai';

    final chatButtons = <Widget>[];
    for (final channel in chatChannels) {
      chatButtons.add(
        OutlinedButton.icon(
          onPressed: orderId.isEmpty
              ? null
              : () => _openTaskChat(context, orderId, orderType, orderData, channel['key']!),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
          label: Text(channel['label']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
          style: OutlinedButton.styleFrom(
            foregroundColor: themeColor,
            side: BorderSide(color: themeColor.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }

    Widget? acceptButtonWidget;
    if (statusLower == 'pending' || statusLower == 'assigned') {
      acceptButtonWidget = SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _accept(task['id'].toString()),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Terima Tugas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey.shade50 : Colors.white,
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
        onTap: () async {
          await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(builder: (_) => DeliveryTaskDetailPage(taskId: task['id'].toString())),
          );
          await _loadTasks();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isCompleted ? Colors.grey.shade600 : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      itemDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tujuan: $destinationAddress',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (chatButtons.isNotEmpty || acceptButtonWidget != null) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: Color(0xFFF1F3F5)),
                const SizedBox(height: AppSpacing.sm),
                if (chatButtons.isNotEmpty) _buildChatGrid(chatButtons),
                if (chatButtons.isNotEmpty && acceptButtonWidget != null) const SizedBox(height: 8),
                if (acceptButtonWidget != null) acceptButtonWidget,
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = ref.watch(authStorageProvider).value?.role;

    final Color themeColor = role == UserRole.pengantar ? const Color(0xFFB22222) : const Color(0xFF1B3B6F);
    final bool showTabs = !widget.embedded;

    final visibleTasks = widget.embedded
        ? _tasks.where((task) => _getDeliveryTabKey(task) == 'baru').toList()
        : _getFilteredTasks(_selectedDeliveryTab);

    final badgeLabel = widget.embedded ? 'Pending' : (_deliveryTabs[_selectedDeliveryTab] ?? 'Tugas');

    final headerRow = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Daftar Tugas Pengiriman',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${visibleTasks.length} $badgeLabel',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: themeColor),
            ),
          ),
        ],
      ),
    );

    Widget bodyWidget;
    if (_isLoading) {
      bodyWidget = const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_error.isNotEmpty) {
      bodyWidget = Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(_error, style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
        ),
      );
    } else if (visibleTasks.isEmpty) {
      bodyWidget = Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.embedded
                    ? 'Belum ada tugas pengiriman pending.'
                    : _selectedDeliveryTab == 'selesai'
                        ? 'Belum ada tugas yang selesai.'
                        : _selectedDeliveryTab == 'proses'
                            ? 'Belum ada tugas yang sedang diproses.'
                            : 'Belum ada tugas pengiriman baru.',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      bodyWidget = ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: visibleTasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          return _buildTaskTile(context, theme, visibleTasks[index], themeColor);
        },
      );
    }

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerRow,
          const SizedBox(height: AppSpacing.md),
          if (showTabs) ...[
            _buildStatusTabs(themeColor),
            const SizedBox(height: AppSpacing.md),
          ],
          bodyWidget,
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Menghilangkan icon kembali secara otomatis
        title: Text(
          'Daftar Tugas Pengiriman',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadTasks,
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
            child: RefreshIndicator(
              color: themeColor,
              onRefresh: _loadTasks,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [content],
              ),
            ),
          ),
        ),
      ),
    );
  }
}