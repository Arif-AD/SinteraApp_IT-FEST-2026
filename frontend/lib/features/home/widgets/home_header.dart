import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../notification/controllers/notification_controller.dart';
import '../../../utils/responsive.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationControllerProvider.select((state) => state.unreadCount));
    final isTablet = Responsive.isTablet(context);
    final logoSize = isTablet ? 104.w : 94.w;
    final iconSize = isTablet ? 28.w : 24.w;

    return Padding(
      // Padding atas tetap, kiri dan kanan diset 0 agar logo dan ikon bisa menyentuh tepi
      padding: EdgeInsets.only(top: 20.h, bottom: 0, left: 15.w, right: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ====== SISI KIRI: LOGO ======
          Image.asset(
            'assets/images/logo_putih.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
          ),
          
          // ====== SISI KANAN: IKON NOTIFIKASI DENGAN BADGE ======
              Transform.translate(
                offset: const Offset(0.0, 0.0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => context.go(AppRoutes.notification),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        child: Image.asset(
                          'assets/images/icon/icon_notif.png',
                          width: iconSize,
                          height: iconSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}