import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class ShareSearchBar extends StatelessWidget {
  const ShareSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
    required this.gradient,
    required this.primaryColor,
  });

  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final LinearGradient gradient;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 48.0, AppSpacing.lg, 2.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            icon: Icon(Icons.arrow_back_rounded, color: primaryColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          const SizedBox(width: 2.0),
          Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                gradient: gradient,
              ),
              child: Padding(
                padding: const EdgeInsets.all(1.2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.8),
                  ),
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary, fontSize: 13),
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Cari warga berdasarkan nama atau nomor HP',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary, fontSize: 12),
                      isDense: true,
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 18),
                      prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 18),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: onClear,
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 0.8),
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.swap_vert_rounded, color: AppColors.textPrimary, size: 18),
              padding: EdgeInsets.zero,
              tooltip: 'Urutkan Terbaru',
            ),
          ),
        ],
      ),
    );
  }
}