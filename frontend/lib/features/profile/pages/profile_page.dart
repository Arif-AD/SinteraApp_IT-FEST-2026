import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/profile_header_card.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(laravelAuthServiceProvider).fetchProfile();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengambil data profil dari server.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStorageProvider);
    final user = authState.value;

    // Warna aksen disesuaikan persis dengan Home & Profile Detail (Warga = Hijau, Petani = Biru, Pengantar = Merah)[cite: 10]
    final accentColor = switch (user?.role) {
      UserRole.petani => const Color(0xFF1B3B6F),
      UserRole.pengantar => const Color(0xFFB22222),
      _ => AppColors.primary,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                const SizedBox(height: AppSpacing.sm),
                
                // HEADER PROFIL
                ProfileHeaderCard(
                  userName: user?.name ?? 'Pengguna Sintera',
                  roleLabel: user?.role.label ?? 'Warga',
                  email: user?.email ?? '-',
                  profileImageUrl: user?.profile,
                  accentColor: accentColor,
                  isLoading: _isLoading,
                  onTap: () => context.push(AppRoutes.profileDetail),
                ),
                const SizedBox(height: AppSpacing.lg),

                // GRUP MENU 1: AKUN & PENGATURAN
                Text(
                  'Akun & Keamanan',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
                      _buildProfileTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Edit Informasi Profil',
                        accentColor: accentColor,
                        onTap: () => context.push('${AppRoutes.profileDetail}?edit=true'),
                      ),
                      const Divider(height: 1, indent: 56, color: Color(0xFFF1F3F5)),
                      _buildProfileTile(
                        icon: Icons.location_on_outlined,
                        title: 'Alamat Pengiriman',
                        accentColor: accentColor,
                        onTap: () {
                          final user = ref.read(authStorageProvider).value;
                          context.push(
                            '${AppRoutes.profileEdit}?field=${Uri.encodeComponent('Alamat Pengiriman')}&value=${Uri.encodeComponent(user?.address ?? '')}',
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 56, color: Color(0xFFF1F3F5)),
                      _buildProfileTile(
                        icon: Icons.lock_outline_rounded,
                        title: 'Keamanan',
                        accentColor: accentColor,
                        onTap: () => context.push(AppRoutes.passwordChange),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // GRUP MENU 2: APLIKASI & BANTUAN
                Text(
                  'Lainnya',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
                      _buildProfileTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifikasi',
                        accentColor: accentColor,
                        onTap: () => context.push(AppRoutes.notification),
                      ),
                      const Divider(height: 1, indent: 56, color: Color(0xFFF1F3F5)),
                      _buildProfileTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Pusat Bantuan Sintera',
                        accentColor: accentColor,
                        onTap: () => context.push(AppRoutes.helpCenter),
                      ),
                      const Divider(height: 1, indent: 56, color: Color(0xFFF1F3F5)),
                      _buildProfileTile(
                        icon: Icons.info_outline_rounded,
                        title: 'Tentang Aplikasi',
                        accentColor: accentColor,
                        onTap: () => context.push(AppRoutes.aboutApp),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // TOMBOL KELUAR (LOGOUT)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: const Text('Apakah kamu yakin ingin keluar dari aplikasi Sintera?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        await ref.read(laravelAuthServiceProvider).logout();
                        if (context.mounted) {
                          context.go(AppRoutes.login);
                        }
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
                    label: const Text(
                      'Keluar dari Akun',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFCDD2)),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
        child: Row(
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
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
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