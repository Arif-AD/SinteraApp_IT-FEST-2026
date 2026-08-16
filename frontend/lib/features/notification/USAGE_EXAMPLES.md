# Contoh Penggunaan Notification Feature

## 1. Navigasi ke Halaman Notifikasi

```dart
context.go('/notifications');
```

## 2. Watch Notification State (Dalam ConsumerWidget)

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationControllerProvider);
    final unreadCount = notificationState.unreadCount;
    
    return Text('Unread: $unreadCount');
  }
}
```

## 3. Perform Actions

```dart
class NotificationActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(notificationControllerProvider.notifier);
    
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => controller.markAsRead('id'),
          child: Text('Mark as Read'),
        ),
        ElevatedButton(
          onPressed: () => controller.deleteNotification('id'),
          child: Text('Delete'),
        ),
        ElevatedButton(
          onPressed: () => controller.markAllAsRead(),
          child: Text('Mark All as Read'),
        ),
        ElevatedButton(
          onPressed: () => controller.clearReadNotifications(),
          child: Text('Clear Read'),
        ),
        ElevatedButton(
          onPressed: () => controller.refresh(),
          child: Text('Refresh'),
        ),
      ],
    );
  }
}
```

## 4. Notification Badge di Home Page

```dart
class HomeTopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(
      notificationControllerProvider.select((state) => state.unreadCount)
    );
    
    return AppBar(
      title: Text('Home'),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () => context.go('/notifications'),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              )
          ],
        ),
      ],
    );
  }
}
```

## 5. Listen to Changes

```dart
class NotificationListener extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      notificationControllerProvider.select((state) => state.unreadCount),
      (previous, next) {
        if (next > (previous ?? 0)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ada $next notifikasi baru')),
          );
        }
      },
    );
    
    return Scaffold(body: NotificationPage());
  }
}
```

## 6. Routing Integration

Di `app_router.dart`:

```dart
GoRoute(
  path: '/notifications',
  name: 'notifications',
  pageBuilder: (context, state) => MaterialPage(
    child: const NotificationPage(),
  ),
),
```

## 7. API Integration

Untuk mengganti mock data dengan API real:

```dart
Future<void> _initialize() async {
  state = state.copyWith(isLoading: true);
  
  try {
    // Fetch dari API
    final response = await notificationService.getNotifications();
    final notifications = response.map(AppNotification.fromJson).toList();
    
    final unreadCount = notifications.where((n) => !n.isRead).length;
    state = NotificationState(
      notifications: notifications,
      isLoading: false,
      unreadCount: unreadCount,
    );
  } catch (e) {
    state = state.copyWith(isLoading: false);
  }
}
```

## 8. Testing

```dart
test('Controller marks notification as read', () async {
  final container = ProviderContainer();
  final controller = container.read(
    notificationControllerProvider.notifier
  );
  
  var state = container.read(notificationControllerProvider);
  expect(state.unreadCount > 0, true);
  
  if (state.notifications.isNotEmpty) {
    controller.markAsRead(state.notifications.first.id);
    state = container.read(notificationControllerProvider);
    // Verify unread count decreased
  }
});
```

## 9. Push Notifications Integration (FCM)

```dart
void setupPushNotifications(WidgetRef ref) {
  final controller = ref.read(notificationControllerProvider.notifier);
  
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final notification = AppNotification(
      id: message.messageId ?? '',
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      type: NotificationType.system,
      timestamp: DateTime.now(),
    );
    // Add to notifications...
  });
}
```

## 10. Generate Mock Data

```dart
List<AppNotification> generateMockNotifications({
  required int count,
  NotificationType? type,
  bool? isRead,
}) {
  final now = DateTime.now();
  final types = NotificationType.values;
  
  return List.generate(count, (i) => AppNotification(
    id: 'mock-$i',
    title: 'Notifikasi $i',
    body: 'Deskripsi notifikasi nomor $i',
    type: type ?? types[i % types.length],
    timestamp: now.subtract(Duration(days: i)),
    isRead: isRead ?? (i % 2 == 0),
  ));
}
```

## 11. Persistence dengan Hive/SharedPreferences

```dart
extension PersistenceHelper on AppNotification {
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.toString(),
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };
  
  static AppNotification fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values.byName(
        (json['type'] as String).split('.').last
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }
}
```

---

Untuk lebih detail, lihat:
- `README.md` - Dokumentasi lengkap
- `IMPLEMENTATION_SUMMARY.md` - Ringkasan implementasi
- Kode source di models/, controllers/, pages/, widgets/
