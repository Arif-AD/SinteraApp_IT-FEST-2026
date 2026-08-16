import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole? _selectedRole;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateRegisterForm() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      return 'Nama lengkap wajib diisi.';
    }

    if (email.isEmpty) {
      return 'Email wajib diisi.';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Format email tidak valid.';
    }

    if (phone.isEmpty) {
      return 'Nomor telepon wajib diisi.';
    }

    if (phone.length < 10) {
      return 'Nomor telepon minimal 10 digit.';
    }

    if (_selectedRole == null) {
      return 'Pilih peran terlebih dahulu.';
    }

    if (password.isEmpty) {
      return 'Password wajib diisi.';
    }

    if (password.length < 8) {
      return 'Password minimal 8 karakter.';
    }

    if (confirmPassword.isEmpty) {
      return 'Konfirmasi password wajib diisi.';
    }

    if (password != confirmPassword) {
      return 'Konfirmasi password tidak cocok.';
    }

    return null;
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;

    final validationMessage = _validateRegisterForm();
    if (validationMessage != null) {
      setState(() => _errorMessage = validationMessage);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(laravelAuthServiceProvider);
      await authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole!,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (mounted) {
        context.go(AppRoutes.home);
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = Responsive.isTablet(context);
    final maxWidth = isTablet ? 420.0 : double.infinity;

    const Color primaryColor = AppColors.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // LOGO
                    Center(
                      child: Image.asset(
                        'assets/images/logo_hitam.png',
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Buat akun baru untuk melanjutkan.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // PESAN ERROR (JIKA ADA)
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.errorTint,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // INPUT FIELDS DENGAN SHADOW GRADASI IJO-BIRU YANG DIKURANGI INTENSITASNYA
                    _buildSoftGlowTextField(
                      controller: _nameController,
                      hint: 'Nama Lengkap',
                      icon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                      onChanged: (_) => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSoftGlowTextField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSoftGlowTextField(
                      controller: _phoneController,
                      hint: 'Nomor Telepon',
                      icon: Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // PILIH PERAN (ROLE)
                    Text(
                      'Pilih Peran',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          _buildRoleSegment(UserRole.warga, 'Warga'),
                          _buildRoleSegment(UserRole.petani, 'Petani'),
                          _buildRoleSegment(UserRole.pengantar, 'Pengantar'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _buildSoftGlowTextField(
                      controller: _passwordController,
                      hint: 'Password (min. 8 karakter)',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onChanged: (_) => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSoftGlowTextField(
                      controller: _confirmPasswordController,
                      hint: 'Konfirmasi Password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onChanged: (_) => setState(() => _errorMessage = null),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // TOMBOL DAFTAR DENGAN SHADOW GRADASI IJO-BIRU YANG DIKURANGI
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                          BoxShadow(
                            color: const Color(0xFF4285F4).withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Daftar',
                                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // LINK KEMBALI KE LOGIN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sudah punya akun? ',
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.login),
                          child: Text(
                            'Masuk',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget Segment Pilihan Peran Modern
  Widget _buildRoleSegment(UserRole role, String label) {
    final isSelected = _selectedRole == role;
    const Color primaryColor = AppColors.primary;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // Widget Textfield dengan Shadow Gradien Ijo-Biru Lembut (Soft Glow)
  Widget _buildSoftGlowTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: const Color(0xFF4285F4).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textTertiary, fontWeight: FontWeight.w400),
          prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
          suffixIcon: suffixIcon,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: onChanged,
        validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
      ),
    );
  }
}