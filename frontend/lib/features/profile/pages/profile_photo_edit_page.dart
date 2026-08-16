import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../../utils/app_navigation.dart';
import '../../../utils/cloudinary_upload.dart';
import '../../../utils/responsive.dart';
import '../../auth/models/user_role.dart';
import '../../auth/providers/auth_provider.dart';

class ProfilePhotoEditPage extends ConsumerStatefulWidget {
  const ProfilePhotoEditPage({super.key});

  @override
  ConsumerState<ProfilePhotoEditPage> createState() => _ProfilePhotoEditPageState();
}

class _ProfilePhotoEditPageState extends ConsumerState<ProfilePhotoEditPage> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isSaving = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 100);
      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Potong Foto Profil',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Potong Foto Profil',
            rotateButtonsHidden: true,
            resetButtonHidden: true,
            aspectRatioPickerButtonHidden: true,
          ),
        ],
      );

      if (croppedFile == null) return;

      if (mounted) {
        setState(() => _selectedImage = File(croppedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuka editor crop foto. Pastikan plugin image_cropper terinstal dan aplikasi di-rebuild.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _savePhoto() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih foto terlebih dahulu.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uploadedUrl = await CloudinaryUpload.uploadImage(XFile(_selectedImage!.path));
      await ref.read(laravelAuthServiceProvider).updateProfile({'profile': uploadedUrl});
      await ref.read(laravelAuthServiceProvider).fetchProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil disimpan.'), behavior: SnackBarBehavior.floating),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.profile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authStorageProvider).value;
    final role = user?.role;
    
    // Warna tema dinamis: Pengantar = Merah, Petani = Biru, Warga = Hijau
    final Color themeColor = role == UserRole.pengantar
        ? const Color(0xFFB22222)
        : role == UserRole.petani
            ? const Color(0xFF1B3B6F)
            : AppColors.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Edit Foto Profil',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => safePopOrGo(context, AppRoutes.profileDetail),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Pilih foto profil baru',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Foto akan otomatis dipotong menjadi bentuk persegi sebelum disimpan.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AspectRatio(
                          aspectRatio: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              color: themeColor.withValues(alpha: 0.08),
                              child: _selectedImage == null
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image_outlined, size: 48, color: themeColor),
                                          const SizedBox(height: 8),
                                          Text(
                                            user?.profile != null && (user!.profile ?? '').isNotEmpty
                                                ? 'Foto profil saat ini'
                                                : 'Belum ada foto profil',
                                            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Image.file(_selectedImage!, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickImage,
                                icon: Icon(Icons.photo_library_outlined, color: themeColor),
                                label: Text('Pilih Foto', style: TextStyle(color: themeColor)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: themeColor.withValues(alpha: 0.4)),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _savePhoto,
                                icon: _isSaving
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.save_outlined),
                                label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}