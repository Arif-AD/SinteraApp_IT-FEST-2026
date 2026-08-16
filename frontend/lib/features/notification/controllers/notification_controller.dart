import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/notification.dart';

/// State untuk daftar notifikasi dan info lainnya
class NotificationState {
  const NotificationState({
    required this.notifications,
    required this.isLoading,
    this.unreadCount = 0,
  });

  final List<AppNotification> notifications;
  final bool isLoading;
  final int unreadCount;

  /// Copy with method
  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  /// Get grouped notifications by time period
  Map<TimePeriod, List<AppNotification>> get groupedNotifications {
    final grouped = <TimePeriod, List<AppNotification>>{};

    for (final notification in notifications) {
      final period = getTimePeriod(notification.timestamp);
      if (!grouped.containsKey(period)) {
        grouped[period] = [];
      }
      grouped[period]!.add(notification);
    }

    return grouped;
  }
}

/// Provider untuk notification controller
final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationState>((ref) {
  return NotificationController(ref);
});

/// Controller untuk mengelola notifikasi
class NotificationController extends StateNotifier<NotificationState> {
  NotificationController(this._ref) : super(const NotificationState(
    notifications: [],
    isLoading: false,
  )) {
    _ref.listen<AsyncValue<AuthUser?>>(authStorageProvider, (_, next) async {
      final authUser = next.value;
      if (authUser == null) {
        state = const NotificationState(
          notifications: [],
          isLoading: false,
          unreadCount: 0,
        );
        return;
      }

      await _loadFromBackend();
    });

    _initialize();
  }

  final Ref _ref;

  Future<void> _initialize() async {
    final authUser = _ref.read(authStorageProvider).value;
    if (authUser == null) {
      state = const NotificationState(
        notifications: [],
        isLoading: false,
        unreadCount: 0,
      );
      return;
    }

    await _loadFromBackend();
  }

  Future<void> _loadFromBackend() async {
    state = state.copyWith(isLoading: true);

    try {
      final notifications = await _ref.read(laravelAuthServiceProvider).getNotifications();
      final parsedNotifications = notifications
          .map((item) => AppNotification.fromJson(item))
          .toList();

      final unreadCount = parsedNotifications.where((n) => !n.isRead).length;
      state = NotificationState(
        notifications: parsedNotifications,
        isLoading: false,
        unreadCount: unreadCount,
      );
    } catch (_) {
      state = state.copyWith(
        notifications: const [],
        isLoading: false,
        unreadCount: 0,
      );
    }
  }

  /// Refresh notifikasi
  Future<void> refresh() async {
    await _loadFromBackend();
  }

  /// Mark notifikasi sebagai read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _ref.read(laravelAuthServiceProvider).markNotificationAsRead(notificationId);
    } catch (_) {
      // Keep the UI responsive even if the backend read-mark call fails.
    }

    final updated = state.notifications.map((n) {
      if (n.id == notificationId && !n.isRead) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    final unreadCount = updated.where((n) => !n.isRead).length;
    state = NotificationState(
      notifications: updated,
      isLoading: false,
      unreadCount: unreadCount,
    );
  }

  /// Mark notifikasi sebagai unread
  void markAsUnread(String notificationId) {
    final updated = state.notifications.map((n) {
      if (n.id == notificationId && n.isRead) {
        return n.copyWith(isRead: false);
      }
      return n;
    }).toList();

    final unreadCount = updated.where((n) => !n.isRead).length;
    state = NotificationState(
      notifications: updated,
      isLoading: false,
      unreadCount: unreadCount,
    );
  }

  /// Mark semua notifikasi sebagai read
  void markAllAsRead() {
    final updated = state.notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();

    state = NotificationState(
      notifications: updated,
      isLoading: false,
      unreadCount: 0,
    );
  }

  /// Hapus notifikasi
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _ref.read(laravelAuthServiceProvider).deleteNotification(notificationId);
    } catch (_) {
      // Tetap tampilkan hasil lokal jika backend gagal.
    }

    final updated = state.notifications
        .where((n) => n.id != notificationId)
        .toList();

    final unreadCount = updated.where((n) => !n.isRead).length;
    state = NotificationState(
      notifications: updated,
      isLoading: false,
      unreadCount: unreadCount,
    );
  }

  /// Hapus semua notifikasi read
  void clearReadNotifications() {
    final updated =
        state.notifications.where((n) => !n.isRead).toList();

    state = NotificationState(
      notifications: updated,
      isLoading: false,
      unreadCount: updated.length,
    );
  }
}
