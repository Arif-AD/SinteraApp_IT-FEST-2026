import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadow.dart';
import '../../theme/app_spacing.dart';

/// Base surface card used throughout the app.
///
/// Provides the consistent soft-white, rounded, subtly shadowed container.
class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.paddingCard,
    this.color = AppColors.surface,
    this.elevation = AppShadow.md,
    this.onTap,
    this.border,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final List<BoxShadow> elevation;
  final VoidCallback? onTap;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.card,
        border: border ?? const Border.fromBorderSide(BorderSide.none),
        boxShadow: elevation,
      ),
      child: child,
    );

    if (onTap == null) return card;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: card,
      ),
    );
  }
}
