import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../../utils/app_navigation.dart';
import '../../../utils/responsive.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileDetailPage extends ConsumerStatefulWidget {
  const ProfileDetailPage({
    super.key,
    this.editMode = false,
  });

  final bool editMode;

  @override
  ConsumerState<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends ConsumerState<ProfileDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;

    try {
      await ref.read(laravelAuthServiceProvider).fetchProfile();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengambil data profil dari server.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToEdit(String fieldName, String currentValue) async {
    final result = await context.push<bool?>(
      '${AppRoutes.profileEdit}?field=${Uri.encodeComponent(fieldName)}&value=${Uri.encodeComponent(currentValue)}',
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _openPhotoEditor() async {
    await context.push(AppRoutes.profilePhotoEdit);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authStorageProvider).value;
    
    // Warna aksen disesuaikan konsisten: Warga = Hijau, Petani = Biru, Pengantar = Merah
    final primaryColor = switch (user?.role) {
      UserRole.petani => const Color(0xFF1B3B6F),
      UserRole.pengantar => const Color(0xFFB22222),
      _ => AppColors.primary,
    };

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Detail Informasi Akun',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
            onPressed: () => safePopOrGo(context, AppRoutes.profile),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: Colors.black.withValues(alpha: 0.05),
              height: 1.0,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
              child: RefreshIndicator(
                color: primaryColor,
                onRefresh: _loadProfile,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profil',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: primaryColor, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  user?.role.label ?? 'Warga',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: _openPhotoEditor,
                            customBorder: const CircleBorder(),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: primaryColor.withValues(alpha: 0.12),
                                  foregroundImage: user?.profile != null && user!.profile!.isNotEmpty
                                      ? NetworkImage(user.profile!)
                                      : null,
                                  child: user?.profile == null || (user?.profile ?? '').isEmpty
                                      ? Icon(Icons.person_rounded, size: 28, color: primaryColor)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    child: const Icon(Icons.camera_alt_rounded, size: 10, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Informasi Pribadi',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildModernInfoTile(
                            icon: Icons.badge_outlined,
                            label: 'Nama Lengkap',
                            value: user?.name ?? '-',
                            accentColor: primaryColor,
                            onTap: () => _navigateToEdit('Nama Lengkap', user?.name ?? '-'),
                          ),
                          const Divider(height: 1, indent: 50, color: Color(0xFFF1F3F5)),
                          _buildModernInfoTile(
                            icon: Icons.email_outlined,
                            label: 'Alamat Email',
                            value: user?.email ?? '-',
                            accentColor: primaryColor,
                            onTap: () => _navigateToEdit('Alamat Email', user?.email ?? '-'),
                          ),
                          const Divider(height: 1, indent: 50, color: Color(0xFFF1F3F5)),
                          _buildModernInfoTile(
                            icon: Icons.phone_android_outlined,
                            label: 'Nomor Telepon',
                            value: (user?.phone ?? '').trim().isNotEmpty ? user!.phone : 'Belum diatur',
                            accentColor: primaryColor,
                            onTap: () => _navigateToEdit('Nomor Telepon', user?.phone ?? ''),
                          ),
                          const Divider(height: 1, indent: 50, color: Color(0xFFF1F3F5)),
                          _buildModernInfoTile(
                            icon: Icons.location_on_outlined,
                            label: 'Alamat Pengiriman',
                            value: (user?.address ?? '').trim().isNotEmpty ? user!.address : 'Belum diatur',
                            accentColor: primaryColor,
                            onTap: () => _navigateToEdit('Alamat Pengiriman', user?.address ?? ''),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: accentColor, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}