import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'app_avatar.dart';
import 'notification_badge.dart';

/// Reusable application bar with optional avatar and notification bell.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.elevation = 0,
    this.backgroundColor = AppColors.background,
    this.centerTitle = false,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final double elevation;
  final Color backgroundColor;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
      elevation: elevation,
      backgroundColor: backgroundColor,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Convenience app bar with a notification bell + badge.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.greeting,
    required this.userName,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onAvatarTap,
    this.titleColor = AppColors.textPrimary,
    this.subtitleColor = AppColors.textSecondary,
  });

  final String greeting;
  final String userName;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final Color titleColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        AppAvatar(
          name: userName,
          size: 44,
          onTap: onAvatarTap,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: subtitleColor,
                ),
              ),
              Text(
                userName,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: titleColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        NotificationBadge(
          count: notificationCount,
          onTap: onNotificationTap,
        ),
      ],
    );
  }
}
