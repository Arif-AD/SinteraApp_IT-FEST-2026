import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

import '../features/finance/pages/finance_page.dart';
import '../features/sell/pages/sell_page.dart';
import '../features/notification/pages/notification_page.dart';
import '../features/environmental_impact/pages/impact_page.dart';
import '../features/home/pages/home_page.dart';
import '../features/orders/pages/orders_page.dart';
import '../features/profile/pages/profile_detail_page.dart';
import '../features/profile/pages/profile_edit_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/profile/pages/profile_photo_edit_page.dart';
import '../features/profile/pages/password_change_page.dart';
import '../features/profile/pages/help_center_page.dart';
import '../features/profile/pages/about_app_page.dart';
import '../features/shopping/pages/shopping_page.dart';
import '../features/shopping/pages/seller_profile_page.dart';
import '../features/share/pages/share_page.dart';
import '../features/waste/pages/waste_page.dart';
import '../features/points/pages/point_page.dart';
import '../features/orders/pages/chat_list_page.dart';
import '../features/orders/pages/delivery_orders_page.dart';
import '../features/auth/models/user_role.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/auth/providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../shared/pages/coming_soon_page.dart';
import '../shared/widgets/widgets.dart';
import '../theme/app_colors.dart';

Color _activeColorForRole(UserRole role) {
  switch (role) {
    case UserRole.warga:
      return AppColors.primary;
    case UserRole.petani:
      return const Color(0xFF1B3B6F);
    case UserRole.pengantar:
      return const Color(0xFF8B0000);
  }
}

/// Bottom navigation items per role.
const Map<UserRole, List<NavItem>> navItemsByRole = {
  UserRole.warga: [
    NavItem(
      label: 'Home',
      iconAsset: 'assets/images/icon/home.png',
      activeIconAsset: 'assets/images/icon/home.png',
      route: AppRoutes.home,
    ),
    NavItem(
      label: 'Chat',
      iconAsset: 'assets/images/icon/chat.png',
      activeIconAsset: 'assets/images/icon/chat.png',
      route: AppRoutes.chat,
    ),
    NavItem(
      label: 'Pesanan',
      iconAsset: 'assets/images/icon/keranjang.png',
      activeIconAsset: 'assets/images/icon/keranjang.png',
      route: AppRoutes.orders,
    ),
    NavItem(
      label: 'Dampak',
      iconAsset: 'assets/images/icon/dampak.png',
      activeIconAsset: 'assets/images/icon/dampak.png',
      route: AppRoutes.dampak,
    ),
    NavItem(
      label: 'Profil',
      iconAsset: 'assets/images/icon/profile.png',
      activeIconAsset: 'assets/images/icon/profile.png',
      route: AppRoutes.profile,
    ),
  ],
  UserRole.petani: [
    NavItem(
      label: 'Home',
      iconAsset: 'assets/images/icon/home.png',
      activeIconAsset: 'assets/images/icon/home.png',
      route: AppRoutes.home,
    ),
    NavItem(
      label: 'Chat',
      iconAsset: 'assets/images/icon/chat.png',
      activeIconAsset: 'assets/images/icon/chat.png',
      route: AppRoutes.chat,
    ),
    NavItem(
      label: 'Pesanan',
      iconAsset: 'assets/images/icon/keranjang.png',
      activeIconAsset: 'assets/images/icon/keranjang.png',
      route: AppRoutes.orders,
    ),
    NavItem(
      label: 'Dompet',
      iconAsset: 'assets/images/icon/keuangan.png',
      activeIconAsset: 'assets/images/icon/keuangan.png',
      route: AppRoutes.keuangan,
    ),
    NavItem(
      label: 'Profil',
      iconAsset: 'assets/images/icon/profile.png',
      activeIconAsset: 'assets/images/icon/profile.png',
      route: AppRoutes.profile,
    ),
  ],
  UserRole.pengantar: [
    NavItem(
      label: 'Home',
      iconAsset: 'assets/images/icon/home.png',
      activeIconAsset: 'assets/images/icon/home.png',
      route: AppRoutes.home,
    ),
    NavItem(
      label: 'Chat',
      iconAsset: 'assets/images/icon/chat.png',
      activeIconAsset: 'assets/images/icon/chat.png',
      route: AppRoutes.chat,
    ),
    NavItem(
      label: 'Pesanan',
      iconAsset: 'assets/images/icon/keranjang.png',
      activeIconAsset: 'assets/images/icon/keranjang.png',
      route: AppRoutes.pengantarTasks,
    ),
    NavItem(
      label: 'Dompet',
      iconAsset: 'assets/images/icon/keuangan.png',
      activeIconAsset: 'assets/images/icon/keuangan.png',
      route: AppRoutes.pengantarIncome,
    ),
    NavItem(
      label: 'Profil',
      iconAsset: 'assets/images/icon/profile.png',
      activeIconAsset: 'assets/images/icon/profile.png',
      route: AppRoutes.profile,
    ),
  ],
};

class _RoleAwareShell extends StatefulWidget {
  const _RoleAwareShell({
    required this.navigationShell,
    required this.role,
  });

  final StatefulNavigationShell navigationShell;
  final UserRole role;

  @override
  State<_RoleAwareShell> createState() => _RoleAwareShellState();
}

class _RoleAwareShellState extends State<_RoleAwareShell> {
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final items = navItemsByRole[widget.role] ?? navItemsByRole[UserRole.warga]!;
    final activeColor = _activeColorForRole(widget.role);
    final isHomeLocation = location == AppRoutes.home || location == '/';

    return PopScope(
      canPop: false,
      // Avoid automatic navigation to home here; PopScope implementations in other pages
      // already navigate when appropriate. Keeping this empty prevents unexpected jumps.
      onPopInvokedWithResult: (_, __) {},
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: AppBottomNavigation(
          items: items,
          currentRoute: location,
          currentIndex: widget.navigationShell.currentIndex,
          activeColor: activeColor,
          onItemTapped: (index) {
            if (index != widget.navigationShell.currentIndex) {
              widget.navigationShell.goBranch(index);
            }
          },
        ),
      ),
    );
  }
}

class _RoleAwareOrdersPage extends ConsumerWidget {
  const _RoleAwareOrdersPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authStorageProvider.select((s) => s.value?.role));
    if (role == UserRole.pengantar) {
      return const DeliveryOrdersPage();
    }
    // For warga and petani, show OrdersPage
    return const OrdersPage();
  }
}

class _RoleAwareFinancePage extends ConsumerWidget {
  const _RoleAwareFinancePage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authStorageProvider.select((s) => s.value?.role));
    if (role == UserRole.warga) {
      return const ImpactPage();
    }
    // For petani and pengantar show FinancePage
    return const FinancePage();
  }
}

Page<dynamic> _buildSlidePage({required LocalKey key, required Widget child}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;
      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  // Do not watch `authStorageProvider` here — watching would recreate the
  // GoRouter whenever auth changes which can lead to navigation flashes.
  return GoRouter(
    // Use home as initial location so recreating the router doesn't force-login
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final authState = ref.read(authStorageProvider);
      final loggedIn = authState.value != null;
      final isLoading = authState.isLoading;
      final isAuthPage = state.matchedLocation == AppRoutes.login || state.matchedLocation == AppRoutes.register;
      final isProfileRoute = state.matchedLocation.startsWith(AppRoutes.profile);

      if (kDebugMode) {
        debugPrint('[Router] redirect check: location=${state.matchedLocation}, loggedIn=$loggedIn, isLoading=$isLoading, isAuthPage=$isAuthPage, isProfileRoute=$isProfileRoute');
      }

      if (isLoading) return null;
      if (!loggedIn && !isAuthPage) return AppRoutes.login;
      if (loggedIn && isAuthPage) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _RoleAwareShell(
              navigationShell: navigationShell,
              role: ref.read(authStorageProvider).value?.role ?? UserRole.warga,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                builder: (context, state) => const ChatListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
                  GoRoute(
                    path: AppRoutes.orders,
                    builder: (context, state) => const _RoleAwareOrdersPage(),
                  ),
            ],
          ),
          StatefulShellBranch(
            routes: [
                  GoRoute(
                    path: AppRoutes.dampak,
                    builder: (context, state) => const _RoleAwareFinancePage(),
                  ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      // Orders is now part of the shell branches (bottom navigation)
      GoRoute(
        path: '/coming-soon/keuangan',
        builder: (context, state) => const ComingSoonPage(title: 'Keuangan'),
      ),
      GoRoute(
        path: AppRoutes.pengantarTasks,
        builder: (context, state) => const ComingSoonPage(title: 'Pesanan'),
      ),
      GoRoute(
        path: AppRoutes.pengantarIncome,
        builder: (context, state) => const FinancePage(),
      ),
      GoRoute(
        path: AppRoutes.sayurku,
        builder: (context, state) => const ShoppingPage(),
      ),
      GoRoute(
        path: AppRoutes.sampahku,
        builder: (context, state) => const SharePage(),
      ),
      GoRoute(
        path: AppRoutes.komposku,
        builder: (context, state) => const WastePage(),
      ),
      GoRoute(
        path: AppRoutes.poinWarga,
        builder: (context, state) => const PointPage(),
      ),
      GoRoute(
        path: AppRoutes.jualSayur,
        builder: (context, state) => const SellPage(),
      ),
      GoRoute(
        path: AppRoutes.keuangan,
        builder: (context, state) => const FinancePage(),
      ),
      GoRoute(
        path: AppRoutes.dampak,
        builder: (context, state) => const ImpactPage(),
      ),
      GoRoute(
        path: AppRoutes.profileDetail,
        pageBuilder: (context, state) {
          final isEdit = state.uri.queryParameters['edit'] == 'true';
          return _buildSlidePage(
            key: state.pageKey,
            child: ProfileDetailPage(editMode: isEdit),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        pageBuilder: (context, state) {
          final fieldName = state.uri.queryParameters['field'] ?? 'Nama Lengkap';
          final initialValue = Uri.decodeComponent(state.uri.queryParameters['value'] ?? '');
          return _buildSlidePage(
            key: state.pageKey,
            child: ProfileEditPage(
              fieldName: fieldName,
              initialValue: initialValue,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profilePhotoEdit,
        pageBuilder: (context, state) => _buildSlidePage(
          key: state.pageKey,
          child: const ProfilePhotoEditPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.passwordChange,
        pageBuilder: (context, state) => _buildSlidePage(
          key: state.pageKey,
          child: const PasswordChangePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.sellerProfile,
        builder: (context, state) {
          final sellerName = state.uri.queryParameters['sellerName'] ?? 'Penjual Lokal';
          final sellerId = state.uri.queryParameters['sellerId'];
          return SellerProfilePage(sellerName: sellerName, sellerId: sellerId);
        },
      ),
      GoRoute(
        path: AppRoutes.notification,
        builder: (context, state) => const NotificationPage(),
      ),
      GoRoute(
        path: AppRoutes.helpCenter,
        builder: (context, state) => const HelpCenterPage(),
      ),
      GoRoute(
        path: AppRoutes.aboutApp,
        builder: (context, state) => const AboutAppPage(),
      ),
    ],
  );
});
