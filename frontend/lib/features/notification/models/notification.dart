import 'package:flutter/material.dart';

/// Enum untuk tipe notifikasi di Sintera
enum NotificationType {
  reward,     // Hadiah/poin
  activity,   // Aktivitas/update
  promotion,  // Promosi/penawaran
  warning,    // Peringatan
  system,     // Sistem/umum
}

/// Model untuk notifikasi individual di aplikasi
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.image,
    this.actionLabel,
    this.actionRoute,
    this.orderId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : <String, dynamic>{};
    final typeValue = payload['type']?.toString() ?? 'activity';
    final parsedType = switch (typeValue.toLowerCase()) {
      'reward' => NotificationType.reward,
      'promotion' => NotificationType.promotion,
      'warning' => NotificationType.warning,
      'system' => NotificationType.system,
      _ => NotificationType.activity,
    };

    final orderIdValue = payload['order_id'];
    final parsedOrderId = orderIdValue is int
        ? orderIdValue
        : int.tryParse(orderIdValue?.toString() ?? '');

    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: payload['title']?.toString() ?? 'Notifikasi',
      body: payload['body']?.toString() ?? '',
      type: parsedType,
      timestamp: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      isRead: json['read_at'] != null,
      orderId: parsedOrderId,
    );
  }

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? image;
  final String? actionLabel;
  final String? actionRoute;
  final int? orderId;

  /// CopyWith untuk membuat instance baru dengan beberapa field yang berubah
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? image,
    String? actionLabel,
    String? actionRoute,
    int? orderId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      image: image ?? this.image,
      actionLabel: actionLabel ?? this.actionLabel,
      actionRoute: actionRoute ?? this.actionRoute,
      orderId: orderId ?? this.orderId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Extension untuk NotificationType
extension NotificationTypeExt on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.reward:
        return 'Hadiah';
      case NotificationType.activity:
        return 'Aktivitas';
      case NotificationType.promotion:
        return 'Promosi';
      case NotificationType.warning:
        return 'Peringatan';
      case NotificationType.system:
        return 'Sistem';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.reward:
        return Icons.card_giftcard;
      case NotificationType.activity:
        return Icons.trending_up;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.warning:
        return Icons.warning_amber;
      case NotificationType.system:
        return Icons.info;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.reward:
        return const Color(0xFFFFB800);
      case NotificationType.activity:
        return const Color(0xFF00A892);
      case NotificationType.promotion:
        return const Color(0xFF1890FF);
      case NotificationType.warning:
        return const Color(0xFFFF4D4F);
      case NotificationType.system:
        return const Color(0xFF8C8C8C);
    }
  }
}

/// Enum untuk periode waktu dalam grouping
enum TimePeriod {
  today,    // Hari ini
  yesterday, // Kemarin
  thisWeek,  // Minggu ini
  older,     // Lebih lama
}

extension TimePeriodExt on TimePeriod {
  String get label {
    switch (this) {
      case TimePeriod.today:
        return 'Hari ini';
      case TimePeriod.yesterday:
        return 'Kemarin';
      case TimePeriod.thisWeek:
        return 'Minggu ini';
      case TimePeriod.older:
        return 'Lebih lama';
    }
  }
}

/// Helper function untuk menentukan periode waktu dari notifikasi
TimePeriod getTimePeriod(DateTime timestamp) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  final weekAgo = today.subtract(const Duration(days: 7));
  final date = DateTime(timestamp.year, timestamp.month, timestamp.day);

  if (date == today) {
    return TimePeriod.today;
  } else if (date == yesterday) {
    return TimePeriod.yesterday;
  } else if (date.isAfter(weekAgo)) {
    return TimePeriod.thisWeek;
  } else {
    return TimePeriod.older;
  }
}
