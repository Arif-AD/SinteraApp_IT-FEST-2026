import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import 'order_chat_page.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  bool _isLoading = true;
  String _error = '';
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadItems());
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final role = ref.read(authStorageProvider).value?.role;
      if (role == UserRole.pengantar) {
        final tasks = await ref.read(laravelAuthServiceProvider).getDeliveryTasks();
        _items = tasks.where((item) => _isProcessedDeliveryTask(item)).toList();
      } else if (role == UserRole.petani) {
        _items = await ref.read(laravelAuthServiceProvider).getFarmerOrders();
      } else {
        _items = await ref.read(laravelAuthServiceProvider).getWargaOrders();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _items = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getRoleColor(UserRole? role) {
    if (role == UserRole.pengantar) {
      return const Color(0xFFB22222); // Merah untuk Pengantar
    } else if (role == UserRole.petani) {
      return const Color(0xFF1B3B6F); // Biru untuk Petani
    }
    return AppColors.primary; // Hijau untuk Default / Warga
  }

  Map<String, dynamic> _resolveOrderData(Map<String, dynamic> item) {
    final sharingOrder = item['sharing_order'] as Map<String, dynamic>? ?? item['sharingOrder'] as Map<String, dynamic>?;
    final order = item['order'] as Map<String, dynamic>?;
    return sharingOrder ?? order ?? item;
  }

  String _resolveOrderType(Map<String, dynamic> item) {
    final sharingOrder = item['sharing_order'] as Map<String, dynamic>? ?? item['sharingOrder'] as Map<String, dynamic>?;
    if (sharingOrder != null || item['sharing_order_id'] != null || item['sharingOrderId'] != null) {
      return 'sharing_order';
    }
    return 'order';
  }

  String _resolveOrderId(Map<String, dynamic> item) {
    final sharingOrder = item['sharing_order'] as Map<String, dynamic>? ?? item['sharingOrder'] as Map<String, dynamic>?;
    final order = item['order'] as Map<String, dynamic>?;
    final orderData = sharingOrder ?? order ?? _resolveOrderData(item);
    return orderData['id']?.toString() ??
        item['order_id']?.toString() ??
        item['sharing_order_id']?.toString() ??
        item['orderId']?.toString() ??
        item['sharingOrderId']?.toString() ??
        '';
  }

  bool _hasWarga(Map<String, dynamic> data) {
    return data['inhabitans_id'] != null ||
        data['receiver_id'] != null ||
        data['receiver'] != null ||
        data['receiver_name'] != null ||
        data['user'] != null ||
        data['customer'] != null ||
        data['inhabitant'] != null;
  }

  bool _hasPetani(Map<String, dynamic> data) {
    return data['farmers_id'] != null ||
        data['farmer'] != null ||
        data['farmer_id'] != null ||
        data['farmer_user'] != null ||
        data['farmerUser'] != null;
  }

  bool _hasPengantar(Map<String, dynamic> data) {
    return data['delivery_id'] != null ||
        data['delivery_person_id'] != null ||
        data['delivery_task'] != null ||
        data['delivery_person'] != null ||
        data['delivery'] != null;
  }

  List<Map<String, String>> _availableChatChannels(UserRole role, Map<String, dynamic> item) {
    final orderData = _resolveOrderData(item);
    final hasWarga = _hasWarga(orderData);
    final hasPetani = _hasPetani(orderData);
    final hasPengantar = _hasPengantar(orderData);
    final channels = <Map<String, String>>[];

    if (role == UserRole.pengantar) {
      if (hasPetani) channels.add({'key': 'petani_pengantar', 'label': 'Chat dengan Petani'});
      if (hasWarga) channels.add({'key': 'warga_pengantar', 'label': 'Chat dengan Warga'});
    } else if (role == UserRole.petani) {
      if (hasWarga) channels.add({'key': 'warga_petani', 'label': 'Chat dengan Warga'});
      if (hasPengantar) channels.add({'key': 'petani_pengantar', 'label': 'Chat dengan Pengantar'});
    } else {
      if (hasPetani) channels.add({'key': 'warga_petani', 'label': 'Chat dengan Petani'});
      if (hasPengantar) channels.add({'key': 'warga_pengantar', 'label': 'Chat dengan Pengantar'});
    }

    return channels;
  }

  List<Map<String, String>> _chatTabsForRole(UserRole role) {
    if (role == UserRole.pengantar) {
      return const [
        {'key': 'petani_pengantar', 'label': 'Chat dengan Petani'},
        {'key': 'warga_pengantar', 'label': 'Chat dengan Warga'},
      ];
    } else if (role == UserRole.petani) {
      return const [
        {'key': 'warga_petani', 'label': 'Chat dengan Warga'},
        {'key': 'petani_pengantar', 'label': 'Chat dengan Pengantar'},
      ];
    }
    return const [
      {'key': 'warga_petani', 'label': 'Chat dengan Petani'},
      {'key': 'warga_pengantar', 'label': 'Chat dengan Pengantar'},
    ];
  }

  bool _isProcessedDeliveryTask(Map<String, dynamic> item) {
    final status = item['status']?.toString().toLowerCase() ?? '';
    final orderData = _resolveOrderData(item);
    final orderStatus = orderData['status']?.toString().toLowerCase() ?? '';
    final deliveryStatus = orderData['delivery_status']?.toString().toLowerCase() ?? '';

    return status == 'accepted' || status == 'picked_up' || status == 'in_transit' ||
        orderStatus == 'accepted' || orderStatus == 'picked_up' || orderStatus == 'in_transit' ||
        deliveryStatus == 'accepted' || deliveryStatus == 'picked_up' || deliveryStatus == 'in_transit';
  }

  bool _isOrderDelivered(Map<String, dynamic> item) {
    final orderData = _resolveOrderData(item);
    final status = orderData['status']?.toString().toLowerCase() ?? '';
    final deliveryStatus = orderData['delivery_status']?.toString().toLowerCase() ?? '';

    return status == 'delivered' ||
        status == 'completed' ||
        status == 'selesai' ||
        status == 'cancelled' ||
        status == 'canceled' ||
        status == 'batal' ||
        deliveryStatus == 'delivered' ||
        deliveryStatus == 'selesai' ||
        deliveryStatus == 'cancelled' ||
        deliveryStatus == 'canceled' ||
        deliveryStatus == 'batal';
  }

  List<Map<String, dynamic>> _chatItemsForChannel(UserRole role, String channel) {
    return _items.where((item) {
      if (_isOrderDelivered(item)) return false;
      if (role == UserRole.pengantar && !_isProcessedDeliveryTask(item)) return false;
      return _availableChatChannels(role, item).any((available) => available['key'] == channel);
    }).toList();
  }

  List<Map<String, dynamic>> _getAllChatEntries(UserRole role) {
    final entries = <Map<String, dynamic>>[];
    final tabs = _chatTabsForRole(role);
    for (final tab in tabs) {
      final channel = tab['key']!;
      final filtered = _chatItemsForChannel(role, channel);
      for (final item in filtered) {
        entries.add({
          'item': item,
          'channel': channel,
        });
      }
    }
    return entries;
  }

  String _chatChannelLabel(String key, UserRole role) {
    if (role == UserRole.pengantar) {
      if (key == 'petani_pengantar') return 'Chat dengan Petani';
      if (key == 'warga_pengantar') return 'Chat dengan Warga';
    }

    switch (key) {
      case 'warga_petani':
        return 'Chat dengan Petani';
      case 'warga_pengantar':
        return 'Chat dengan Pengantar';
      case 'petani_pengantar':
        return 'Chat dengan Pengantar';
      default:
        return 'Chat';
    }
  }

  String _buildTitle(Map<String, dynamic> item, UserRole role) {
    final orderData = _resolveOrderData(item);
    final productName = orderData['product_name']?.toString() ?? orderData['name']?.toString() ?? orderData['product']?['name']?.toString();
    if (productName != null && productName.isNotEmpty) {
      return productName;
    }

    if (item.containsKey('sharing_order')) {
      return 'Pesanan Berbagi';
    }
    if (item.containsKey('order')) {
      return 'Pesanan';
    }
    return 'Chat Pesanan';
  }

  void _openChat(BuildContext context, Map<String, dynamic> item, String chatChannel) {
    final orderType = _resolveOrderType(item);
    final orderId = _resolveOrderId(item);
    final orderData = _resolveOrderData(item);
    if (orderId.isEmpty) return;

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

  Widget _buildChatCard(BuildContext context, UserRole role, Map<String, dynamic> entry) {
    final item = entry['item'] as Map<String, dynamic>;
    final chatChannel = entry['channel'] as String;
    final roleColor = _getRoleColor(role);

    final roomTitle = _buildTitle(item, role);
    final partnerName = _resolveChatPartnerName(item, role, chatChannel);
    final lastMessageText = _resolveLastMessageText(item, chatChannel);
    final channelLabel = _chatChannelLabel(chatChannel, role);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openChat(context, item, chatChannel),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    color: roleColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              partnerName,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: roleColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              channelLabel,
                              style: TextStyle(
                                color: roleColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roomTitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lastMessageText.isNotEmpty ? lastMessageText : 'Ketuk untuk memulai percakapan...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: lastMessageText.isNotEmpty ? AppColors.textPrimary : AppColors.textTertiary,
                              fontSize: 12,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  String _resolveChatPartnerName(Map<String, dynamic> item, UserRole role, String chatChannel) {
    final data = _resolveOrderData(item);
    final farmer = _resolveUserMap(data, ['farmer', 'farmer_user', 'farmerUser']);
    final receiver = _resolveUserMap(data, ['receiver', 'user', 'customer']);
    final deliveryPerson = _resolveUserMap(data, ['delivery_person', 'deliveryPerson', 'delivery']);

    if (role == UserRole.pengantar && chatChannel == 'petani_pengantar') {
      return farmer?['name']?.toString() ?? data['farmer_name']?.toString() ?? 'Petani';
    }
    if (role == UserRole.pengantar && chatChannel == 'warga_pengantar') {
      return 'Warga';
    }
    if (role == UserRole.petani && chatChannel == 'warga_petani') {
      return 'Warga';
    }
    if (role == UserRole.petani && chatChannel == 'petani_pengantar') {
      return deliveryPerson?['name']?.toString() ?? data['delivery_person_name']?.toString() ?? 'Pengantar';
    }
    if (role == UserRole.warga && chatChannel == 'warga_petani') {
      return farmer?['name']?.toString() ?? data['farmer_name']?.toString() ?? 'Petani';
    }
    if (role == UserRole.warga && chatChannel == 'warga_pengantar') {
      return deliveryPerson?['name']?.toString() ?? data['delivery_person_name']?.toString() ?? 'Pengantar';
    }
    return 'Chat';
  }

  String _resolveChatPartnerPhone(Map<String, dynamic> item, UserRole role, String chatChannel) {
    final data = _resolveOrderData(item);
    final farmer = _resolveUserMap(data, ['farmer', 'farmer_user', 'farmerUser']);
    final receiver = _resolveUserMap(data, ['receiver', 'user', 'customer']);
    final deliveryPerson = _resolveUserMap(data, ['delivery_person', 'deliveryPerson', 'delivery']);

    if ((role == UserRole.pengantar && chatChannel == 'petani_pengantar') ||
        (role == UserRole.warga && chatChannel == 'warga_petani')) {
      return _resolvePhoneFromUser(farmer) ?? data['farmer_phone']?.toString() ?? '';
    }
    if ((role == UserRole.pengantar && chatChannel == 'warga_pengantar') ||
        (role == UserRole.petani && chatChannel == 'warga_petani')) {
      return _resolvePhoneFromUser(receiver) ?? data['receiver_phone']?.toString() ?? '';
    }
    if ((role == UserRole.petani && chatChannel == 'petani_pengantar') ||
        (role == UserRole.warga && chatChannel == 'warga_pengantar')) {
      return _resolvePhoneFromUser(deliveryPerson) ?? data['delivery_person_phone']?.toString() ?? '';
    }
    return '';
  }

  Map<String, dynamic>? _resolveUserMap(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }
    return null;
  }

  String? _resolvePhoneFromUser(dynamic userData) {
    if (userData is! Map<String, dynamic>) {
      return null;
    }

    return userData['phone']?.toString() ??
        userData['phone_number']?.toString() ??
        userData['mobile']?.toString() ??
        userData['mobile_phone']?.toString();
  }

  String _resolveLastMessageText(Map<String, dynamic> item, String chatChannel) {
    final lastMessage = item['last_message'];
    if (lastMessage is Map<String, dynamic>) {
      return lastMessage['text']?.toString() ?? '';
    }
    if (item.containsKey('last_message_text')) {
      return item['last_message_text']?.toString() ?? '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = ref.watch(authStorageProvider).value?.role ?? UserRole.warga;
    final roleColor = _getRoleColor(role);
    final allEntries = _getAllChatEntries(role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Pesan & Chat'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0x0D000000), height: 1.0),
        ),
      ),
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: RefreshIndicator(
          color: roleColor,
          onRefresh: _loadItems,
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: roleColor),
                      const SizedBox(height: AppSpacing.md),
                      Text('Memuat daftar chat...', style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : _error.isNotEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 200,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              child: Text(_error, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error)),
                            ),
                          ),
                        ),
                      ],
                    )
                  : allEntries.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height - 200,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.xl),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: roleColor.withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.chat_bubble_outline_rounded, size: 56, color: roleColor),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Text(
                                        'Belum Ada Percakapan',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Semua pesan terkait pesanan dan pengiriman Anda akan muncul di sini.',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          itemCount: allEntries.length,
                          itemBuilder: (context, index) {
                            final entry = allEntries[index];
                            return _buildChatCard(context, role, entry);
                          },
                        ),
        ),
      ),
    );
  }
}