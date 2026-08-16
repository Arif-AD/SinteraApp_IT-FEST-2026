import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class ShoppingSearchBar extends StatelessWidget {
  const ShoppingSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.searchQuery,
    required this.gradient,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String searchQuery;
  final LinearGradient gradient;

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
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFB71C1C)),
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
                      hintText: 'Cari produk sayur & buah...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textTertiary, fontSize: 12.5),
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