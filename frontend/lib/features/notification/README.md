# Notification Feature

Halaman notifikasi modern dan user-friendly untuk aplikasi Sintera dengan desain yang clean, responsif, dan mengikuti standar Flutter best practices.

## 📋 Daftar Isi

- [Fitur](#fitur)
- [Struktur Kode](#struktur-kode)
- [Komponen Utama](#komponen-utama)
- [Cara Penggunaan](#cara-penggunaan)
- [State Management](#state-management)
- [Best Practices](#best-practices)

## ✨ Fitur

### 1. **Grouping Notifikasi Berdasarkan Waktu**
   - **Hari ini** - Notifikasi dari hari saat ini
   - **Kemarin** - Notifikasi dari hari kemarin
   - **Minggu ini** - Notifikasi dari 7 hari terakhir
   - **Lebih lama** - Notifikasi lebih dari seminggu lalu

### 2. **Tipe Notifikasi (5 Kategori)**
   - 🎁 **Reward** - Hadiah/poin/achievement (Warna: Orange)
   - 📈 **Activity** - Update aktivitas/status (Warna: Teal)
   - 🎯 **Promotion** - Promosi/penawaran spesial (Warna: Blue)
   - ⚠️ **Warning** - Peringatan/alert (Warna: Red)
   - ℹ️ **System** - Info sistem/umum (Warna: Gray)

### 3. **Interaksi Pengguna**
   - ✅ **Tap Notifikasi** - Tandai sebagai dibaca + lihat detail
   - 🗑️ **Swipe to Delete** - Hapus notifikasi dengan swipe ke kanan
   - 🔔 **Popup Menu** - Mark all as read, Clear read notifications
   - 🔄 **Pull to Refresh** - Refresh daftar notifikasi
   - 🎯 **Action Button** - Tombol aksi untuk navigasi/action tertentu

### 4. **Empty State**
   - Tampilan yang menarik ketika tidak ada notifikasi
   - Pesan informatif untuk pengguna

## 🏗️ Struktur Kode

```
features/notification/
│
├── models/
│   └── notification.dart
│       ├── AppNotification (class)
│       ├── NotificationType (enum) - 5 tipe notifikasi
│       ├── TimePeriod (enum) - Grouping waktu
│       ├── NotificationTypeExt (extension)
│       ├── TimePeriodExt (extension)
│       └── getTimePeriod() - Helper function
│
├── controllers/
│   └── notification_controller.dart
│       ├── NotificationState (state holder)
│       ├── NotificationController (StateNotifier)
│       └── notificationControllerProvider (Riverpod)
│
├── pages/
│   └── notification_page.dart
│       └── NotificationPage (ConsumerWidget)
│
├── widgets/
│   ├── notification_list_item.dart
│   │   └── NotificationListItem - Item dengan animasi & dismiss
│   │
│   ├── notification_section_header.dart
│   │   └── NotificationSectionHeader - Header dengan count badge
│   │
│   ├── notification_empty_state.dart
│   │   └── NotificationEmptyState - Empty state UI
│   │
│   └── widgets.dart
│       └── Barrel file untuk export semua widgets
```

## 🧩 Komponen Utama

### 1. **AppNotification Model**
```dart
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? image;
  final String? actionLabel;
  final String? actionRoute;
  
  AppNotification copyWith({...}); // Immutable pattern
}
```

### 2. **NotificationState**
```dart
class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final int unreadCount;
  
  Map<TimePeriod, List<AppNotification>> get groupedNotifications;
}
```

### 3. **NotificationController**
```dart
class NotificationController extends StateNotifier<NotificationState> {
  Future<void> refresh(); // Refresh notifikasi
  void markAsRead(String notificationId); // Tandai dibaca
  void markAsUnread(String notificationId); // Tandai belum dibaca
  void markAllAsRead(); // Tandai semua dibaca
  void deleteNotification(String notificationId); // Hapus notifikasi
  void clearReadNotifications(); // Hapus semua notifikasi yang dibaca
}
```

## 🚀 Cara Penggunaan

### Setup
Pastikan Riverpod sudah tersedia dalam project:
```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^2.6.0
```

### Implementasi dalam Widget
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/notification/pages/notification_page.dart';

// Navigasi ke halaman notifikasi
context.go('/notifications');
```

### Akses Data Notifikasi
```dart
// Di mana saja dalam konsumer widget
final notificationState = ref.watch(notificationControllerProvider);
final unreadCount = notificationState.unreadCount;
final notifications = notificationState.notifications;
```

### Perform Action
```dart
// Mark notifikasi sebagai read
ref.read(notificationControllerProvider.notifier)
    .markAsRead('notification-id');

// Delete notifikasi
ref.read(notificationControllerProvider.notifier)
    .deleteNotification('notification-id');

// Mark all as read
ref.read(notificationControllerProvider.notifier)
    .markAllAsRead();
```

## 🧠 State Management

### Riverpod Architecture
- **Provider Pattern** - Clean dependency injection
- **StateNotifier** - Immutable state management
- **ConsumerWidget** - Reactive UI updates

### Data Flow
```
UI Interaction (tap, swipe, etc.)
        ↓
NotificationListItem/NotificationPage
        ↓
NotificationController.markAsRead/deleteNotification()
        ↓
NotificationState diupdate
        ↓
ConsumerWidget rebuild dengan state baru
```

### Mock Data
Controller menggunakan mock data untuk testing:
- 9 notifikasi sample dengan berbagai tipe
- Distribusi waktu (hari ini, kemarin, minggu lalu)
- Beberapa unread untuk menunjukkan badge

## 📐 Design Principles

### 1. **Atomic Design**
- Small, reusable components
- NotificationListItem, NotificationSectionHeader, dll

### 2. **Immutability**
- AppNotification menggunakan `copyWith()`
- NotificationState tidak berubah, selalu replace

### 3. **Responsive Design**
- ConstrainedBox untuk max width
- Flexible spacing dengan AppSpacing tokens
- Mobile-first approach

### 4. **Color Consistency**
- Menggunakan AppColors dari theme
- Type-specific colors via `NotificationType.color`
- Opacity menggunakan `.withValues(alpha: x)` (bukan `.withOpacity()`)

### 5. **Animation & Transitions**
- Slide animation saat notifikasi muncul
- Smooth dismiss dengan Dismissible widget
- Fade effects untuk better UX

## 🎨 UI/UX Features

### Visual Hierarchy
- **Title** - Berat (FontWeight.w700 jika unread, w500 jika read)
- **Body** - Normal weight, secondary text color
- **Timestamp** - Small, tertiary text color
- **Icon** - Warna sesuai tipe, background color semi-transparent

### Unread Indicator
- Background color: eco tint (light teal)
- Blue dot di sebelah title
- Border warna sesuai tipe notifikasi

### Interactive Elements
- **Tap area** - Full row, 48px min height
- **Swipe to delete** - Red background dengan icon delete
- **Action button** - Solid color dengan white text
- **Popup menu** - Akses via more_vert icon

## ✅ Best Practices Implemented

### Code Quality
- ✅ Const constructors di mana possible
- ✅ Documentation comments (///, ///)
- ✅ Type-safe code (no dynamic, proper generics)
- ✅ Null safety (null coalescing, optional chaining)
- ✅ Clean imports (barrel files untuk widgets)

### Architecture
- ✅ Clear separation of concerns
- ✅ Controller → State → UI
- ✅ Model tidak tahu tentang UI
- ✅ Widgets tidak tahu tentang business logic

### Performance
- ✅ Efficient list building dengan SliverList
- ✅ Animations dengan SingleTickerProviderStateMixin
- ✅ Lazy loading via Riverpod
- ✅ RefreshIndicator dengan const constructors

### Accessibility
- ✅ Proper semantic elements
- ✅ Color + icon untuk type indication
- ✅ Touch targets min 48x48 dp
- ✅ Clear text hierarchy

## 🔗 Integration Points

### Routing
- Notifikasi dengan `actionRoute` bisa navigate via GoRouter
- Contoh: `/shopping`, `/points`, `/profile`

### API Integration
- Replace mock data di `NotificationController._initialize()`
- Gunakan proper repository pattern
- Handle loading, error states

### Push Notifications
- Integrate dengan Firebase Cloud Messaging (FCM)
- Update state saat notification diterima
- Play sound/vibration jika diperlukan

## 📝 Future Enhancements

1. **Real API Integration**
   - Fetch dari backend API
   - Implement pagination
   - Handle error states

2. **Advanced Features**
   - Notification preferences/settings
   - Notification history/archive
   - Search functionality
   - Multi-language support

3. **Performance**
   - Infinite scroll dengan pagination
   - Caching strategy
   - Background sync

4. **Analytics**
   - Track notification opens
   - CTR (Click-Through Rate)
   - User engagement metrics
