import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Reusable placeholder screen with a modern empty state.
///
/// Used by not-yet-implemented modules. Provides an [AppBar], page [title],
/// an illustrative [icon], a "Coming Soon" badge, and a friendly [message].
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor,
    this.message,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? AppColors.primary;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return Center(
              child: SingleChildScrollView(
                padding: AppSpacing.paddingScreen,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          isWide ? AppSpacing.xl : AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: isWide ? 64 : 52,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        title,
                        style: theme.textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: AppRadius.chip,
                        ),
                        child: Text(
                          'Coming Soon',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        message ??
                            'Modul ini sedang dalam pengembangan.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
