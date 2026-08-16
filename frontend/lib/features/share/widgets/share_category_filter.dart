import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class ShareCategoryFilter extends StatelessWidget {
  const ShareCategoryFilter({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.gradient,
    required this.primaryColor,
    required this.backgroundColor,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final LinearGradient gradient;
  final Color primaryColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 6.0),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = selectedCategory == cat;

            return InkWell(
              onTap: () => onCategorySelected(cat),
              borderRadius: BorderRadius.circular(10.0),
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  gradient: isSelected ? gradient : null,
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSelected ? 1.2 : 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : backgroundColor,
                      borderRadius: BorderRadius.circular(isSelected ? 8.8 : 10.0),
                      border: !isSelected
                          ? Border.all(color: Colors.black.withValues(alpha: 0.15), width: 0.8)
                          : null,
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? primaryColor : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
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