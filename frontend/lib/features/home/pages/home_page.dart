import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../controllers/home_controller.dart';
import '../providers/home_provider.dart';
import '../widgets/home_header.dart';
import '../widgets/wallet_card.dart';
import '../widgets/main_features.dart';
import '../widgets/impact_summary_card.dart';
import '../widgets/vegetable_deals.dart';
import '../../orders/pages/delivery_orders_page.dart';
import '../widgets/info_banner_section.dart';
import '../../../features/auth/models/user_role.dart';
import '../../../features/auth/providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncState = ref.watch(homeStateProvider);
    final role = ref.watch(authStorageProvider).value?.role;
    final state = asyncState.maybeWhen(
      data: (value) => value,
      orElse: () => ref.watch(homeControllerProvider),
    );

    final isPetani = role == UserRole.petani;
    final isPengantar = role == UserRole.pengantar;
    final isWarga = role == UserRole.warga;

    final gradientColors = isPengantar
        ? const [Color(0xFF8B0000), Color(0xFFB22222)]
        : isPetani
            ? const [Color(0xFF1B3B6F), Color(0xFF0C2340)]
            : const [AppColors.primaryDark, AppColors.primary];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          child: RefreshIndicator(
            color: isPengantar
                ? const Color(0xFFB22222)
                : isPetani
                    ? const Color(0xFF1B3B6F)
                    : AppColors.primary,
            onRefresh: () async {
              await ref.refresh(homeStateProvider.future);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HomeHeaderArea(
                    theme: theme,
                    isPetani: isPetani,
                    isPengantar: isPengantar,
                    gradientColors: gradientColors,
                    state: state,
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: 24.w,
                    right: 24.w,
                    top: 26.h,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (!isPengantar) ...[
                        MainFeatures(role: role),
                        const SizedBox(height: 20),
                        if (isWarga) ...[
                          const InfoBannerSection(),
                          SizedBox(height: 20.h),
                        ],
                      ],
                      if (isPengantar) ...[
                        const DeliveryOrdersPage(embedded: true),
                        const SizedBox(height: AppSpacing.xxxl),
                      ] else ...[
                        ImpactSummaryCard(
                          organicKg: state.organicKg,
                          inorganicKg: state.inorganicKg,
                          co2e: state.co2e,
                          trees: state.trees,
                          organicRatio: state.organicRatio,
                          isPetani: isPetani,
                        ),
                        SizedBox(height: 24.h),
                        if (isWarga) ...[ 
                          SectionHeader(
                            title: 'Produk Terbaru',
                            actionLabel: 'Lihat Semua',
                            onActionTap: () => context.push(AppRoutes.sayurku),
                          ),
                          SizedBox(height: 16.h),
                          const VegetableDeals(),
                          SizedBox(height: 32.h),
                        ],
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeaderArea extends StatelessWidget {
  const _HomeHeaderArea({
    required this.theme,
    required this.isPetani,
    required this.isPengantar,
    required this.gradientColors,
    required this.state,
  });

  final ThemeData theme;
  final bool isPetani;
  final bool isPengantar;
  final List<Color> gradientColors;
  final HomeState state;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(bottom: 110.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Theme(
                  data: theme.copyWith(
                    inputDecorationTheme: theme.inputDecorationTheme.copyWith(
                      fillColor: Colors.white.withValues(alpha: 0.15),
                    ),
                    textTheme: theme.textTheme.copyWith(
                      titleLarge: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                      bodyMedium: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ),
                  child: const HomeHeader(),
                ),
                FractionallySizedBox(
                  widthFactor: 0.65,
                  child: Transform.translate(
                    offset: Offset(0, -16.h),
                    child: Padding(
                      padding: EdgeInsets.only(left: 15.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPengantar ? 'Pengantar Sintera' : (isPetani ? 'Kelola Pertanian' : 'Tukar Limbah'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            isPengantar ? 'Pickup & Pengiriman' : (isPetani ? 'Hasil Panen & Keuangan' : 'Jadi Sayur dan Buah'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
        Positioned(
          top: 185.0,
          left: 0,
          right: 0,
          bottom: -10.0,
          child: CustomPaint(
            painter: LandaiClipPainter(backgroundColor: AppColors.background),
          ),
        ),
        Positioned(
          left: -130,
          top: -60,
          child: IgnorePointer(
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: -100,
          top: -30,
          child: IgnorePointer(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: -70,
          top: 0,
          child: IgnorePointer(
            child: Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: -40,
          top: 10,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 5,
          top: 50,
          child: IgnorePointer(
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.13),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 42,
          top: 80,
          child: IgnorePointer(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 152.0, left: 24.0, right: 24.0),
          child: WalletCard(
            greeting: state.greeting,
            userName: state.userName,
            avatarImageUrl: state.profileImageUrl,
            pointsLabel: state.pointsLabel,
            currentPoints: state.currentPointsLabel,
            incomeLabel: (isPetani || isPengantar) ? state.incomeLabel : null,
            isPengantar: isPengantar,
            onPointsTap: () => context.push(AppRoutes.poinWarga),
            onIncomeTap: () => context.push(AppRoutes.pengantarIncome),
          ),
        ),
        Positioned(
          right: isPengantar ? 5 : isPetani ? 5 : 30,
          top: isPengantar ? 62 : isPetani ? 62 : 65,
          child: IgnorePointer(
            child: Image.asset(
              isPengantar
                  ? 'assets/images/pengantar.png'
                  : isPetani
                      ? 'assets/images/petani.png'
                      : 'assets/images/sayur_buah.png',
              height: isPengantar ? 155 : isPetani ? 155 : 140,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

class LandaiClipPainter extends CustomPainter {
  final Color backgroundColor;
  const LandaiClipPainter({required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 48);
    path.quadraticBezierTo(size.width / 2, 8, size.width, 48);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}