import 'package:flutter/material.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';

class WasteStatCard extends StatelessWidget {
  const WasteStatCard({
    super.key,
    required this.imageName,
    required this.value,
    required this.label,
    required this.activeColor,
  });

  final String imageName;
  final String value;
  final String label;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Image.asset('assets/images/icon/icon_$imageName.png'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: activeColor)),
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}