import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';

class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.greeting,
    required this.userName,
    this.pointsLabel,
    this.currentPoints,
    this.incomeLabel,
    this.onPointsTap,
    this.onIncomeTap,
    this.isPengantar = false,
    this.avatarImageUrl,
  });

  final String greeting;
  final String userName;
  final String? pointsLabel;
  final String? currentPoints;
  final String? incomeLabel;
  final VoidCallback? onPointsTap;
  final VoidCallback? onIncomeTap;
  final bool isPengantar;
  final String? avatarImageUrl;

  bool get hasIncome => incomeLabel != null;

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final cardPadding = isTablet ? 20.h : 12.w;

    final mainBorderRadius = BorderRadius.circular(12.0);
    final internalBorderRadius = BorderRadius.circular(8.0);

    // Pemisahan warna yang tegas: Pengantar = Merah Tua, Petani = Biru Gelap, Warga = Hijau
    final activeThemeColor = hasIncome 
        ? (isPengantar ? const Color(0xFFB22222) : const Color(0xFF1B3B6F)) 
        : AppColors.primary;
        
    final activeThemeTint = hasIncome 
        ? (isPengantar ? const Color(0xFFFFF1F0) : const Color(0xFFE8EEF5)) 
        : AppColors.primary.withValues(alpha: 0.1);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: mainBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                children: [
                  AppAvatar(name: userName, size: 40, imageUrl: avatarImageUrl),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        Text(userName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // PENDAPATAN / POIN
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: activeThemeTint,
                        borderRadius: internalBorderRadius,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(hasIncome ? 'Pendapatan' : 'Poin Warga', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(hasIncome ? 'Total pendapatan kamu' : 'Poin kamu saat ini', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black.withValues(alpha: 0.6), fontSize: 11)),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              if (!hasIncome)
                                Image.asset('assets/images/icon/icon_koin.png', width: 20, height: 20),
                              if (!hasIncome) const SizedBox(width: AppSpacing.sm),
                              ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: hasIncome 
                                      ? (isPengantar 
                                          ? [const Color(0xFF5A0000), const Color(0xFFB22222)] 
                                          : [const Color(0xFF0C2340), const Color(0xFF1B3B6F)])
                                      : [const Color(0xFF2C3E50), const Color(0xFF007146)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ).createShader(bounds),
                                child: Text(
                                  hasIncome ? (incomeLabel ?? 'Rp 0') : (pointsLabel ?? '0'),
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20.sp,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  // TOMBOL AKSI
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: activeThemeTint,
                        borderRadius: internalBorderRadius,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            hasIncome ? 'Lihat Pendapatan?' : 'Tukar Sekarang?',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: activeThemeColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14.sp,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: activeThemeColor,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              elevation: 2,
                              shadowColor: activeThemeColor.withValues(alpha: 0.4),
                              child: InkWell(
                                onTap: hasIncome ? onIncomeTap : onPointsTap,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                                  alignment: Alignment.center,
                                  child: Text(
                                    hasIncome ? 'Lihat' : 'Tukar',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}