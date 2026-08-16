import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../providers/environmental_impact_provider.dart';

class ImpactPage extends ConsumerWidget {
  const ImpactPage({super.key});

  void _showStatInfoDialog(
    BuildContext context, {
    required String title,
    required String description,
    required String imageName,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Image.asset('assets/images/icon/icon_$imageName.png', fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        'Mengerti',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final impact = ref.watch(environmentalImpactProvider);
    final progressPercent = impact.totalCO2e == 0 ? 0.0 : (impact.treeProgress / 30.0).clamp(0.0, 1.0);
    const Color primaryGreen = AppColors.primary;

    // Pengecekan nilai 0 untuk menampilkan pesan khusus / penyemangat
    final bool isOrganicZero = impact.totalOrganicKg == 0;
    final bool isInorganicZero = impact.totalInorganicKg == 0;
    final bool isCo2Zero = impact.totalCO2e == 0;
    final bool isTreeZero = impact.sinteraTrees == 0;

    final String organicDesc = isOrganicZero
        ? 'Kamu belum pernah setor limbah organik nih. Yuk, mulai kumpulkan sisa dapur atau daun dan setor sekarang untuk bantu bumi!'
        : 'Yay, kamu hebat! Total limbah organik yang berhasil kamu setor sudah mencapai ${impact.totalOrganicKg.toStringAsFixed(0)} kg. Kontribusi ini sangat berarti untuk mengurangi tumpukan sampah secara alami.';

    final String inorganicDesc = isInorganicZero
        ? 'Belum ada limbah anorganik yang disetor. Yuk, kumpulkan botol atau plastik bekasmu dan mulai langkah kecil hari ini!'
        : 'Keren banget! Kamu telah berhasil menyetor ${impact.totalInorganicKg.toStringAsFixed(0)} kg limbah anorganik. Langkah kecilmu ini mencegah pencemaran lingkungan dalam jangka panjang.';

    final String co2Desc = isCo2Zero
        ? 'Belum ada emisi CO₂e yang dicegah dalam rentang 6 bulan ini. Yuk, mulai setor sampah rutinmu agar angka pengurangan karbonnya makin meningkat!'
        : 'Luar biasa! Total emisi karbon sebesar ${impact.totalCO2e.toStringAsFixed(1)} kg CO₂e berhasil kamu pangkas dan cegah dari lingkungan dalam rentang waktu 6 bulan. Ini adalah bukti nyata kepedulianmu pada bumi.';

    final String treeDesc = isTreeZero
        ? 'Belum ada pohon aktif nih. Yuk, tingkatkan setoran sampahmu untuk capai setara 1 pohon pertama!'
        : 'Yay, kontribusi hebatmu dalam menyetor limbah setara dengan kinerja ${impact.sinteraTrees} pohon dalam 6 bulan loh! Kamu pahlawan lingkungan yang sesungguhnya.';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
          child: CustomScrollView(
            slivers: [
              // HEADER CUSTOM (Tanpa jarak AppBar bawaan)
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (Navigator.canPop(context)) Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back_rounded, color: primaryGreen),
                          ),
                          Text(
                            'Dampak Saya',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 48), // Spacer penyeimbang tombol back agar judul persis di tengah
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // KONTEN BODY UTAMA
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // CARD PROGRESS POHON SINTERA
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.eco_rounded, color: primaryGreen, size: 24),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pohon Sintera',
                                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${impact.sinteraTrees} pohon aktif bertumbuh',
                                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F7F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.trending_up_rounded, size: 18, color: primaryGreen),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress Target Berikutnya',
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              Text(
                                '${(progressPercent * 100).toStringAsFixed(0)}%',
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: primaryGreen),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progressPercent,
                              minHeight: 8,
                              backgroundColor: primaryGreen.withValues(alpha: 0.1),
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 12, color: AppColors.textTertiary),
                              const SizedBox(width: 4),
                              Text(
                                '${impact.treeProgress.toStringAsFixed(1)} kg CO₂e lagi untuk pohon berikutnya',
                                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textTertiary, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 4 CARD STATISTIK
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            imageName: 'organik',
                            value: '${impact.totalOrganicKg.toStringAsFixed(0)} kg',
                            label: 'Limbah Organik',
                            valueOnTop: true,
                            activeColor: primaryGreen,
                            description: organicDesc,
                            onTap: () => _showStatInfoDialog(
                              context,
                              title: 'Limbah Organik',
                              description: organicDesc,
                              imageName: 'organik',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(
                            imageName: 'anorganik',
                            value: '${impact.totalInorganicKg.toStringAsFixed(0)} kg',
                            label: 'Limbah Anorganik',
                            valueOnTop: true,
                            activeColor: primaryGreen,
                            description: inorganicDesc,
                            onTap: () => _showStatInfoDialog(
                              context,
                              title: 'Limbah Anorganik',
                              description: inorganicDesc,
                              imageName: 'anorganik',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            imageName: 'co2',
                            value: '${impact.totalCO2e.toStringAsFixed(1)} kg',
                            label: 'CO₂e\nHilang',
                            valueOnTop: false,
                            activeColor: primaryGreen,
                            description: co2Desc,
                            onTap: () => _showStatInfoDialog(
                              context,
                              title: 'CO₂e Hilang',
                              description: co2Desc,
                              imageName: 'co2',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(
                            imageName: 'pohon',
                            value: '${impact.sinteraTrees} pohon',
                            label: 'Setara Kinerja',
                            valueOnTop: false,
                            activeColor: primaryGreen,
                            description: treeDesc,
                            onTap: () => _showStatInfoDialog(
                              context,
                              title: 'Setara Kinerja',
                              description: treeDesc,
                              imageName: 'pohon',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.imageName,
    required this.value,
    required this.label,
    required this.valueOnTop,
    required this.activeColor,
    required this.description,
    required this.onTap,
  });

  final String imageName;
  final String value;
  final String label;
  final bool valueOnTop;
  final Color activeColor;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: CustomCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06), width: 1.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox(
                width: 28,
                height: 28,
                child: Image.asset('assets/images/icon/icon_$imageName.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: valueOnTop
                    ? [
                        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      ]
                    : [
                        Text(
                          label,
                          maxLines: 2,
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.15),
                        ),
                        const SizedBox(height: 2),
                        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}