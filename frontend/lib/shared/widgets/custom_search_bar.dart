import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

/// Reusable search bar with trailing filter icon.
class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({
    super.key,
    this.hint = 'Cari di Sintera...',
    this.onTap,
    this.onChanged,
    this.controller,
  });

  final String hint;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.button,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1A1F24),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onTap: onTap,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune, color: AppColors.primary),
            onPressed: onTap,
          ),
          border: InputBorder.none,
          hintStyle: theme.textTheme.bodyMedium
              ?.copyWith(color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
