import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';

class AboutAppPage extends ConsumerStatefulWidget {
  const AboutAppPage({super.key});

  @override
  ConsumerState<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends ConsumerState<AboutAppPage> {
  bool _isLoading = true;
  int _wargaCount = 0;
  int _petaniCount = 0;
  int _pengantarCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final stats = await ref.read(laravelAuthServiceProvider).getAboutAppStats();
      if (!mounted) return;
      setState(() {
        _wargaCount = stats['warga'] ?? 0;
        _petaniCount = stats['petani'] ?? 0;
        _pengantarCount = stats['pengantar'] ?? 0;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authStorageProvider).value;
    final accentColor = switch (user?.role) {
      UserRole.petani => const Color(0xFF1B3B6F),
      UserRole.pengantar => const Color(0xFFB22222),
      _ => AppColors.primary,
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
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
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                // Header / Branding Section dengan jarak samping diperbesar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Sintera',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Versi Beta',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Sintera adalah aplikasi yang menghubungkan petani, warga, dan pengantar dalam satu ekosistem transaksi hasil pertanian yang lebih mudah, cepat, dan aman.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),

                // Stats Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(theme, accentColor, _isLoading ? '...' : '$_wargaCount', 'Warga Aktif'),
                      _buildVerticalDivider(),
                      _buildStatItem(theme, accentColor, _isLoading ? '...' : '$_petaniCount', 'Petani Aktif'),
                      _buildVerticalDivider(),
                      _buildStatItem(theme, accentColor, _isLoading ? '...' : '$_pengantarCount', 'Pengantar Aktif'),
                    ],
                  ),
                ),

                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),

                // Section Title: Fitur Utama
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
                  child: Text(
                    'EKOSISTEM & LAYANAN',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                _buildFeatureTile(
                  icon: Icons.storefront_rounded,
                  title: 'Marketplace Hasil Panen',
                  subtitle: 'Jual beli produk pertanian langsung dari sumbernya',
                  accentColor: accentColor,
                ),
                _buildFeatureTile(
                  icon: Icons.local_shipping_rounded,
                  title: 'Logistik Terintegrasi',
                  subtitle: 'Pantau pengantar dan status pengiriman secara real-time',
                  accentColor: accentColor,
                ),
                _buildFeatureTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Pesan Langsung (Chat)',
                  subtitle: 'Komunikasi transparan antara pembeli, petani, dan kurir',
                  accentColor: accentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, Color accentColor, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.black.withValues(alpha: 0.08),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
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