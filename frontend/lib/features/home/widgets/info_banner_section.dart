import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/widgets/widgets.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';

class InfoBannerSection extends StatelessWidget {
  const InfoBannerSection({super.key});

  // Fungsi untuk menampilkan modern alert dialog saat "Lihat Semua" diklik
  void _showNoInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        backgroundColor: Colors.white,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 340.w),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    size: 36.sp,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Info Terbaru',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Belum ada info terbaru nih, nantikan pembaruan informasi menarik selanjutnya dari kami!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  height: 44.h,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: 16.w), // Ditambahkan padding agar teks tidak terpotong
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text(
                      'Tutup',
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showNoInfoDialog(context),
          child: const SectionHeader(
            title: 'Info Terbaru',
            actionLabel: 'Lihat Semua',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _InfoBannerCarousel(),
      ],
    );
  }
}

class _InfoBannerCarousel extends StatefulWidget {
  const _InfoBannerCarousel();

  @override
  State<_InfoBannerCarousel> createState() => _InfoBannerCarouselState();
}

class _InfoBannerCarouselState extends State<_InfoBannerCarousel> {
  static const Duration _animation = Duration(milliseconds: 450);
  static const Curve _curve = Curves.easeInOut;

  late final PageController _pageController;
  final List<_BannerData> _banners = const [
    _BannerData(
      label: 'Banner Promo 1',
      imagePath: 'assets/images/banner_satu.png',
    ),
    _BannerData(
      label: 'Banner Promo 2',
      imagePath: 'assets/images/banner_dua.png',
    ),
  ];

  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_banners.isEmpty) return;
      
      int nextPage = _currentPage + 1;
      if (nextPage >= _banners.length) {
        nextPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextPage,
          duration: _animation,
          curve: _curve,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);
    final bannerHeight = isTablet ? 160.0 : 140.0;

    return Column(
      children: [
        SizedBox(
          height: bannerHeight,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                _stopAutoScroll();
              } else if (notification is ScrollEndNotification) {
                _startAutoScroll();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                final banner = _banners[index];

                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 0.0;
                    if (_pageController.position.haveDimensions) {
                      value = index.toDouble() - (_pageController.page ?? 0.0);
                    } else {
                      value = index.toDouble() - _pageController.initialPage.toDouble();
                    }

                    double scale = (1 - (value.abs() * 0.08)).clamp(0.92, 1.0);

                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: _InfoBannerItem(
                    label: banner.label,
                    imagePath: banner.imagePath,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            final active = index == _currentPage;
            return AnimatedContainer(
              duration: _animation,
              curve: _curve,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: active ? 24 : 8,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _InfoBannerItem extends StatelessWidget {
  const _InfoBannerItem({
    required this.label,
    required this.imagePath,
  });

  final String label;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    const double reducedRadius = 12.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(reducedRadius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(reducedRadius),
            boxShadow: AppShadow.sm,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(reducedRadius),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.broken_image, size: 36, color: Colors.grey),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerData {
  const _BannerData({required this.label, required this.imagePath});
  final String label;
  final String imagePath;
}