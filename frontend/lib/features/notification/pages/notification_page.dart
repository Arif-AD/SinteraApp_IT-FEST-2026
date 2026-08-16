import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/services/laravel_auth_service.dart';
import '../../../features/orders/pages/order_detail_page.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../utils/responsive.dart';
import '../controllers/notification_controller.dart';
import '../models/notification.dart';
import '../widgets/widgets.dart';

/// Halaman notifikasi dengan desain modern dan user-friendly
class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationControllerProvider);
    final controller =
        ref.read(notificationControllerProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go(AppRoutes.home);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context, state, controller),
        body: state.notifications.isEmpty
            ? const NotificationEmptyState()
            : _buildNotificationList(context, ref, state, controller),
      ),
    );
  }

  /// Build custom app bar dengan title, unread count, dan action buttons
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    NotificationState state,
    NotificationController controller,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifikasi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (state.unreadCount > 0)
              Text(
                '${state.unreadCount} belum dibaca',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
          ],
        ),
        actions: [
          if (state.unreadCount > 0)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                color: AppColors.surface,
                onSelected: (String result) {
                  if (result == 'mark_all_read') {
                    controller.markAllAsRead();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Semua notifikasi ditandai sebagai dibaca'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else if (result == 'clear_read') {
                    controller.clearReadNotifications();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifikasi yang sudah dibaca dihapus'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 18),
                        SizedBox(width: 8),
                        Text('Tandai Semua Dibaca'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'clear_read',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, size: 18),
                        SizedBox(width: 8),
                        Text('Hapus yang Dibaca'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build daftar notifikasi dengan grouping berdasarkan waktu
  Widget _buildNotificationList(
    BuildContext context,
    WidgetRef ref,
    NotificationState state,
    NotificationController controller,
  ) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => controller.refresh(),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          child: CustomScrollView(
            slivers: [
              // Sorted time periods untuk grouping yang konsisten
              ..._buildGroupedNotifications(
                context,
                ref,
                state,
                controller,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build notification groups dengan headers
  List<Widget> _buildGroupedNotifications(
    BuildContext context,
    WidgetRef ref,
    NotificationState state,
    NotificationController controller,
  ) {
    final grouped = state.groupedNotifications;
    final sortedPeriods = [
      TimePeriod.today,
      TimePeriod.yesterday,
      TimePeriod.thisWeek,
      TimePeriod.older,
    ];

    final widgets = <Widget>[];

    for (final period in sortedPeriods) {
      if (grouped.containsKey(period) && grouped[period]!.isNotEmpty) {
        final notifications = grouped[period]!;

        // Section Header
        widgets.add(
          SliverToBoxAdapter(
            child: NotificationSectionHeader(
              period: period,
              count: notifications.length,
            ),
          ),
        );

        // Notification Items
        widgets.add(
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final notification = notifications[index];
                return NotificationListItem(
                  notification: notification,
                  onTap: () {
                    unawaited(_handleNotificationTap(context, ref, notification));
                  },
                  onDismiss: () {
                    unawaited(controller.deleteNotification(notification.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifikasi dihapus'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  onMarkAsRead: () {
                    controller.markAsRead(notification.id);
                  },
                  onAction: () {
                    if (notification.actionRoute != null) {
                      context.go(notification.actionRoute!);
                      return;
                    }
                    _handleNotificationTap(context, ref, notification);
                  },
                );
              },
              childCount: notifications.length,
            ),
          ),
        );

        // Spacing between sections
        if (sortedPeriods.indexOf(period) <
            sortedPeriods.where((p) => grouped.containsKey(p)).length - 1) {
          widgets.add(
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.md),
            ),
          );
        }
      }
    }

    // Padding at the bottom
    widgets.add(
      const SliverToBoxAdapter(
        child: SizedBox(height: AppSpacing.xl),
      ),
    );

    return widgets;
  }

  /// Handle ketika notifikasi di-tap
  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    final orderId = notification.orderId?.toString();
    if (orderId != null && orderId.isNotEmpty) {
      try {
        final orderData = await ref.read(laravelAuthServiceProvider).getOrderDetailById(orderId);
        if (!context.mounted) return;
        if (orderData != null) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OrderDetailPage(
                orderId: orderId,
                orderData: orderData,
              ),
            ),
          );
          return;
        }
      } catch (_) {
        // Fallback ke snackbar jika data pesanan tidak ditemukan.
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${notification.title}: ${notification.body}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
