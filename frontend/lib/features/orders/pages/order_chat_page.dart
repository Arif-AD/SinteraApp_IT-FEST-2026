import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';

class OrderChatPage extends ConsumerStatefulWidget {
  const OrderChatPage({
    super.key,
    required this.orderId,
    required this.orderType,
    required this.orderData,
    this.chatChannel,
  });

  final String orderId;
  final String orderType;
  final Map<String, dynamic> orderData;
  final String? chatChannel;

  @override
  ConsumerState<OrderChatPage> createState() => _OrderChatPageState();
}

class _OrderChatPageState extends ConsumerState<OrderChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;
  bool _isLoading = false;
  bool _isSending = false;
  String _error = '';
  String? _selectedChatChannel;
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    if (widget.chatChannel != null && widget.chatChannel!.isNotEmpty) {
      _selectedChatChannel = widget.chatChannel;
    } else {
      final channels = _availableChatChannels;
      if (channels.length == 1) {
        _selectedChatChannel = channels.first['key'];
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_activeChatChannel != null) {
        _loadMessages();
      }
      _startPolling();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_activeChatChannel != null) {
        _loadMessages();
      }
    });
  }

  String? get _activeChatChannel => widget.chatChannel ?? _selectedChatChannel;

  bool get _hasChatChannel => _activeChatChannel != null;

  Color _getRoleColor(UserRole? role) {
    if (role == UserRole.pengantar) {
      return const Color(0xFFB22222); // Merah Pengantar sesuai home
    } else if (role == UserRole.petani) {
      return const Color(0xFF1B3B6F); // Biru Petani sesuai home
    }
    return AppColors.primary; // Hijau Warga / Default sesuai home
  }

  bool _isDeliveredOrder() {
    final status = widget.orderData['status']?.toString().toLowerCase() ?? '';
    final deliveryStatus = widget.orderData['delivery_status']?.toString().toLowerCase() ?? '';

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

  Map<String, dynamic> _resolveOrderData(Map<String, dynamic> data) {
    final sharingOrder = data['sharing_order'] as Map<String, dynamic>? ?? data['sharingOrder'] as Map<String, dynamic>?;
    final order = data['order'] as Map<String, dynamic>?;
    return sharingOrder ?? order ?? data;
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
        data['delivery_person'] != null ||
        data['delivery'] != null;
  }

  List<Map<String, String>> get _availableChatChannels {
    final currentRole = ref.read(authStorageProvider).value?.role;
    final orderData = _resolveOrderData(widget.orderData);
    final hasWarga = _hasWarga(orderData);
    final hasPetani = _hasPetani(orderData);
    final hasPengantar = _hasPengantar(orderData);
    final channels = <Map<String, String>>[];

    if (currentRole == UserRole.pengantar) {
      if (hasPetani) {
        channels.add({'key': 'petani_pengantar', 'label': 'Chat dengan Petani'});
      }
      if (hasWarga) {
        channels.add({'key': 'warga_pengantar', 'label': 'Chat dengan Warga'});
      }
    } else if (currentRole == UserRole.petani) {
      if (hasWarga) {
        channels.add({'key': 'warga_petani', 'label': 'Chat dengan Warga'});
      }
      if (hasPengantar) {
        channels.add({'key': 'petani_pengantar', 'label': 'Chat dengan Pengantar'});
      }
    } else {
      if (hasPetani) {
        channels.add({'key': 'warga_petani', 'label': 'Chat dengan Petani'});
      }
      if (hasPengantar) {
        channels.add({'key': 'warga_pengantar', 'label': 'Chat dengan Pengantar'});
      }
    }

    return channels;
  }

  Future<void> _loadMessages() async {
    if (_isLoading || _activeChatChannel == null) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await ref.read(laravelAuthServiceProvider).getOrderChatMessages(
            widget.orderId,
            orderType: widget.orderType,
            chatChannel: _activeChatChannel,
          );
      if (!mounted) return;
      setState(() {
        _messages = response;
      });
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await ref.read(laravelAuthServiceProvider).sendOrderChatMessage(
            widget.orderId,
            text,
            orderType: widget.orderType,
            chatChannel: _activeChatChannel,
          );
      _messageController.clear();
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.read(authStorageProvider).value;
    final currentUserId = authState?.id;
    final currentRole = authState?.role;
    final roleColor = _getRoleColor(currentRole);

    final orderNumber = widget.orderId;
    final resolvedOrderData = _resolveOrderData(widget.orderData);
    final title = resolvedOrderData['receiver'] != null ? 'Chat Pesanan Berbagi' : 'Chat Pesanan';

    if (!_hasChatChannel) {
      final availableChannels = _availableChatChannels;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pilih Chat'),
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chat_bubble_outline_rounded, size: 36, color: roleColor),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Pilih Tujuan Chat',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pilih salah satu penerima di bawah ini untuk memulai percakapan pesanan #${orderNumber}.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (availableChannels.isEmpty)
                      Text(
                        'Saluran chat tidak tersedia untuk pesanan ini.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      )
                    else ...availableChannels.map(
                      (channel) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedChatChannel = channel['key'];
                              });
                              _loadMessages();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: roleColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(channel['label'] ?? 'Chat', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              'No. Pesanan: #$orderNumber',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
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
        child: Column(
          children: [
            Expanded(
              child: _isLoading && _messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                      ? Center(child: Text(_error, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error)))
                      : _buildMessageList(currentUserId, roleColor),
            ),
            if (_isDeliveredOrder())
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Pesanan telah selesai. Chat ini hanya dapat dilihat sebagai riwayat.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
              color: Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isDeliveredOrder(),
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 4,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: _isDeliveredOrder() ? 'Chat sudah selesai' : 'Tulis pesan...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(
                              color: Colors.black.withValues(alpha: 0.04),
                              width: 0.3,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(
                              color: Colors.black.withValues(alpha: 0.04),
                              width: 0.3,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(
                              color: roleColor,
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Material(
                    color: roleColor,
                    borderRadius: BorderRadius.circular(28),
                    elevation: 2,
                    shadowColor: roleColor.withValues(alpha: 0.3),
                    child: InkWell(
                      onTap: _isSending || _isDeliveredOrder() ? null : _sendMessage,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: _isSending
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(String? currentUserId, Color roleColor) {
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10),
                  ],
                ),
                child: Icon(Icons.chat_bubble_outline_rounded, size: 44, color: Colors.grey.shade400),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Belum ada pesan',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Kirim pesan pertama untuk memulai obrolan dengan rekan terkait.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.md),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final sender = message['sender'] as Map<String, dynamic>?;
        final senderName = sender?['name']?.toString() ?? 'Pengguna';
        final isMe = currentUserId != null && sender?['id']?.toString() == currentUserId;
        final createdAt = message['created_at']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isMe ? roleColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe) ...[
                        Text(
                          senderName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: roleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      IntrinsicWidth(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: 50,
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                message['message']?.toString() ?? '',
                                softWrap: true,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: isMe ? Colors.white : AppColors.textPrimary,
                                      fontSize: 13.5,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  createdAt,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: isMe ? Colors.white70 : AppColors.textTertiary,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}