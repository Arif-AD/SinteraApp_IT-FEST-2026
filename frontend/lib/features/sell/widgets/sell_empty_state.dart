import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class SellEmptyState extends StatelessWidget {
  const SellEmptyState({super.key, required this.onAdd, this.isFiltered = false});

  final VoidCallback onAdd;
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF1B3B6F).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isFiltered ? Icons.search_off_rounded : Icons.storefront_outlined,
              size: 35,
              color: const Color(0xFF1B3B6F),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isFiltered ? 'Produk Tidak Ditemukan' : 'Belum Ada Produk Jualan',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFiltered
                ? 'Coba gunakan kata kunci atau kategori filter yang lain.'
                : 'Mulai tawarkan hasil panen atau produk segar Anda kepada warga sekitar dengan mudah.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (!isFiltered) ...[
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah Produk Pertama'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B3B6F),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}