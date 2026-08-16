import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';

/// Bottom navigation model item.
class NavItem {
  const NavItem({
    required this.label,
    this.icon,
    this.activeIcon,
    this.iconAsset,
    this.activeIconAsset,
    required this.route,
  });

  final String label;
  final IconData? icon;
  final IconData? activeIcon;
  final String? iconAsset;
  final String? activeIconAsset;
  final String route;
}

/// Application bottom navigation bar with standard docked styling and sharp outer background.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.items,
    this.currentRoute = '',
    this.currentIndex,
    this.activeColor,
    this.onItemTapped,
  });

  final List<NavItem> items;
  final String currentRoute;
  final int? currentIndex;
  final Color? activeColor;
  final ValueChanged<int>? onItemTapped;

  int get _currentIndex {
    if (currentIndex != null) {
      return currentIndex!.clamp(0, items.length - 1);
    }

    final normalizedCurrentRoute = currentRoute.endsWith('/') && currentRoute.length > 1
        ? currentRoute.substring(0, currentRoute.length - 1)
        : currentRoute;

    final index = items.indexWhere((i) {
      final normalizedRoute = i.route.endsWith('/') && i.route.length > 1
          ? i.route.substring(0, i.route.length - 1)
          : i.route;
      return normalizedRoute == normalizedCurrentRoute;
    });

    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex;
    final effectiveActiveColor = activeColor ?? AppColors.primary;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: effectiveActiveColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: effectiveActiveColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 8.h,
            horizontal: 16.w, // Jarak kanan kiri frame ditambah sedikit
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == index;
              return _NavTile(
                item: item,
                selected: selected,
                activeColor: effectiveActiveColor,
                onTap: () {
                  if (onItemTapped != null) {
                    onItemTapped!(i);
                  } else {
                    context.go(item.route);
                  }
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.activeColor,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final boxColor = selected ? activeColor : Colors.transparent;
    final itemColor = selected ? Colors.white : AppColors.textPrimary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        splashColor: activeColor.withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 8.h,
            horizontal: 4.w,
          ),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(16.r),
            border: selected
                ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1)
                : Border.all(color: Colors.transparent, width: 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 250),
                tween: Tween<double>(begin: 1.0, end: selected ? 1.15 : 1.0),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: item.iconAsset != null
                      ? Image.asset(
                          selected ? (item.activeIconAsset ?? item.iconAsset!) : item.iconAsset!,
                          key: ValueKey<bool>(selected),
                          width: 24.sp,
                          height: 24.sp,
                          fit: BoxFit.contain,
                          color: itemColor,
                        )
                      : Icon(
                          selected ? item.activeIcon : item.icon,
                          key: ValueKey<bool>(selected),
                          color: itemColor,
                          size: 24.sp,
                        ),
                ),
              ),
              SizedBox(height: 4.h),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: theme.textTheme.labelSmall?.copyWith(
                      color: itemColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.sp,
                    ) ??
                    TextStyle(
                      color: itemColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.sp,
                    ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}