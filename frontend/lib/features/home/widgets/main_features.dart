import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/models/user_role.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/waste/pages/waste_product_page.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';

class MainFeatures extends StatelessWidget {
  const MainFeatures({super.key, required this.role});

  final UserRole? role;

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.petani) {
      return const _PetaniFeatures();
    }

    if (role == UserRole.pengantar) {
      return const _PengantarFeatures();
    }

    return const _WargaFeatures();
  }
}

class _WargaFeatures extends StatelessWidget {
  const _WargaFeatures();

  static const List<_MainFeature> _items = [
    _MainFeature(title: 'Belanja', iconName: 'belanja', route: AppRoutes.sayurku),
    _MainFeature(title: 'Berbagi', iconName: 'berbagi', route: AppRoutes.sampahku),
    _MainFeature(title: 'Limbah', iconName: 'limbah', route: AppRoutes.komposku),
    _MainFeature(title: 'Poin', iconName: 'poin', route: AppRoutes.poinWarga),
  ];

  @override
  Widget build(BuildContext context) {
    const gap = 20.0;

    return Transform.translate(
      offset: const Offset(0, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              Expanded(child: _MainFeatureTile(item: _items[i], iconPadding: 6.0)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PetaniFeatures extends StatelessWidget {
  const _PetaniFeatures();

  // Tombol 'Limbah' untuk petani menggunakan route kustom atau langsung membuka WasteProductPage
  static final List<_MainFeature> _items = [
    const _MainFeature(title: 'Jual', iconName: 'belanja', route: AppRoutes.jualSayur),
    const _MainFeature(
      title: 'Limbah', 
      iconName: 'limbah', 
      route: '', // Menggunakan navigasi langsung ke WasteProductPage
      isCustomAction: true,
    ),
    const _MainFeature(title: 'Keuangan', iconName: 'uang', route: AppRoutes.keuangan),
  ];

  @override
  Widget build(BuildContext context) {
    const gap = 40.0;

    return Transform.translate(
      offset: const Offset(0, 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox(
                width: 58,
                child: _MainFeatureTile(
                  item: _items[i],
                  iconPadding: 6.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PengantarFeatures extends StatelessWidget {
  const _PengantarFeatures();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _MainFeatureTile extends ConsumerWidget {
  const _MainFeatureTile({
    required this.item,
    this.iconPadding = 6.0,
  });

  final _MainFeature item;
  final double iconPadding;

  bool _hasAddress(AuthUser? user) {
    return user != null && user.address.trim().isNotEmpty;
  }

  Future<void> _showAddressRequiredDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Alamat Dibutuhkan', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'Silakan isi alamat pengiriman di profil terlebih dahulu sebelum mengakses fitur ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(
                  '${AppRoutes.profileEdit}?field=${Uri.encodeComponent('Alamat Pengiriman')}&value=${Uri.encodeComponent('')}',
                );
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Isi Alamat'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStorageProvider);
    final user = authState.value;

    return GestureDetector(
      onTap: () async {
        if (!_hasAddress(user)) {
          await _showAddressRequiredDialog(context);
          return;
        }

        if (item.isCustomAction && item.title == 'Limbah') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WasteProductPage()),
          );
        } else {
          context.push(item.route);
        }
      },
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.10),
                  width: 0.5,
                ),
              ),
              child: Image.asset(
                'assets/images/icon/icon_${item.iconName}.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.title,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w300,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MainFeature {
  const _MainFeature({
    required this.title,
    required this.iconName,
    required this.route,
    this.isCustomAction = false,
  });

  final String title;
  final String iconName;
  final String route;
  final bool isCustomAction;
}