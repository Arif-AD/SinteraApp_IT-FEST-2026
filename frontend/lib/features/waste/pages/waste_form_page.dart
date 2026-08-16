import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../../utils/cloudinary_upload.dart';
import '../../../utils/responsive.dart';
import '../../auth/providers/auth_provider.dart';

class WasteFormPage extends ConsumerStatefulWidget {
  const WasteFormPage({
    super.key,
    this.initialPickupId,
    this.initialWasteType,
    this.initialWeight,
    this.initialNote,
    this.initialAddress,
    this.initialImageUrl,
  });

  final String? initialPickupId;
  final String? initialWasteType;
  final double? initialWeight;
  final String? initialNote;
  final String? initialAddress;
  final String? initialImageUrl;

  @override
  ConsumerState<WasteFormPage> createState() => _WasteFormPageState();
}

class _WasteFormPageState extends ConsumerState<WasteFormPage> {
  String _selectedWasteType = 'Organik';
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  String? _selectedImageUrl;

  final Map<String, int> _pointsPerKg = {
    'Organik': 150,
    'Anorganik': 300,
  };

  @override
  void initState() {
    super.initState();
    final currentUser = ref.read(authStorageProvider).value;
    _selectedWasteType = ['Organik', 'Anorganik'].contains(widget.initialWasteType)
        ? widget.initialWasteType!
        : 'Organik';
    _weightController.text = widget.initialWeight?.toString() ?? '';
    _noteController.text = widget.initialNote ?? '';
    _addressController.text = widget.initialAddress ?? _buildDefaultAddress(currentUser);
    _selectedImageUrl = widget.initialImageUrl;
    _loadCurrentUserAddress();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color primaryGreen = AppColors.primary;

    const LinearGradient homeGreenGradient = LinearGradient(
      colors: [Color.fromARGB(255, 0, 128, 111), AppColors.primary],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_rounded, color: primaryGreen),
          ),
          title: Text(
            widget.initialPickupId == null ? 'Form Setor Limbah' : 'Perbarui Setor Limbah',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: Colors.black.withValues(alpha: 0.06),
              height: 1.0,
            ),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // SECTION 1: FOTO LIMBAH
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Foto Limbah (Opsional)',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_isUploadingImage)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          InkWell(
                            onTap: _isUploadingImage ? null : _pickWasteImage,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 85,
                              height: 85,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: primaryGreen.withValues(alpha: 0.3),
                                  style: BorderStyle.solid,
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_alt_rounded, color: primaryGreen, size: 24),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedImageUrl != null && _selectedImageUrl!.isNotEmpty
                                        ? 'Ganti Foto'
                                        : 'Tambah Foto',
                                    style: const TextStyle(
                                      color: primaryGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_selectedImageUrl != null && _selectedImageUrl!.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 85,
                              height: 85,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _selectedImageUrl!,
                                      height: 85,
                                      width: 85,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 85,
                                        width: 85,
                                        color: Colors.grey.shade100,
                                        alignment: Alignment.center,
                                        child: const Text('Gagal', style: TextStyle(fontSize: 10)),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedImageUrl = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // SECTION 2: PILIH JENIS LIMBAH & ESTIMASI BERAT
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jenis Limbah',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCategoryCard(
                              title: 'Organik',
                              subtitle: '150 Poin/kg',
                              imageName: 'organik',
                              isSelected: _selectedWasteType == 'Organik',
                              onTap: () => setState(() => _selectedWasteType = 'Organik'),
                              primaryColor: primaryGreen,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCategoryCard(
                              title: 'Anorganik',
                              subtitle: '300 Poin/kg',
                              imageName: 'anorganik',
                              isSelected: _selectedWasteType == 'Anorganik',
                              onTap: () => setState(() => _selectedWasteType = 'Anorganik'),
                              primaryColor: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Color(0xFFF1F3F5), height: 1),
                      ),
                      _buildShopeeTextField(
                        label: 'Estimasi Berat (Kg)',
                        controller: _weightController,
                        hint: 'Contoh: 3',
                        isNumber: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // SECTION 3: ALAMAT
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      context.push(
                        '${AppRoutes.profileEdit}?field=${Uri.encodeComponent('Alamat Pengiriman')}&value=${Uri.encodeComponent(_addressController.text)}',
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Alamat',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _addressController.text.trim().isEmpty ? 'Alamat belum diatur' : _addressController.text,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // SECTION 4: CATATAN TAMBAHAN
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catatan Tambahan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Tambahkan detail kondisi limbah...',
                          hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estimasi Poin Diperoleh:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '+${_calculatePoints()}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Image.asset('assets/images/icon/icon_koin.png', fit: BoxFit.contain),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: homeGreenGradient,
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitWaste,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.center,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              widget.initialPickupId == null ? 'Ajukan Setor Limbah' : 'Perbarui Penjualan',
                              style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold, height: 1.0),
                            ),
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

  Widget _buildShopeeTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: isNumber ? TextInputType.number : TextInputType.text,
              readOnly: readOnly,
              onTap: readOnly ? onTap : null,
              onChanged: isNumber && !readOnly ? (val) => setState(() {}) : null,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                suffixText: isNumber ? 'Kg' : null,
                suffixIcon: suffixIcon != null ? Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: suffixIcon,
                ) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required String imageName,
    required bool isSelected,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.black.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? primaryColor.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 4 : 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SizedBox(
                width: 20,
                height: 20,
                child: Image.asset('assets/images/icon/icon_$imageName.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primaryColor : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 14, color: primaryColor)
            else
              Icon(Icons.radio_button_unchecked_rounded, size: 14, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Future<void> _submitWaste() async {
    final weightText = _weightController.text.trim();
    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan berat limbah yang valid.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'waste_type': _selectedWasteType,
        'weight': weight,
        'note': _noteController.text.trim(),
        'address': _addressController.text.trim(),
        if (_selectedImageUrl != null && _selectedImageUrl!.isNotEmpty) 'image_url': _selectedImageUrl,
      };

      if (widget.initialPickupId == null) {
        await ref.read(laravelAuthServiceProvider).createWargaWastePickup(payload);
      } else {
        await ref.read(laravelAuthServiceProvider).updateWargaWastePickup(widget.initialPickupId!, payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Penjualan limbah berhasil disimpan.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickWasteImage() async {
    final imageSource = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Ambil Foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (imageSource == null) return;

    try {
      setState(() => _isUploadingImage = true);
      final pickedFile = await _imagePicker.pickImage(source: imageSource, imageQuality: 80, maxWidth: 1200);
      if (pickedFile == null) return;

      final uploadedUrl = await CloudinaryUpload.uploadImage(pickedFile);
      if (!mounted) return;
      setState(() => _selectedImageUrl = uploadedUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _loadCurrentUserAddress() async {
    try {
      final profile = await ref.read(laravelAuthServiceProvider).fetchProfile();
      if (!mounted) return;
      setState(() {
        _addressController.text = widget.initialAddress ?? _buildDefaultAddress(profile);
      });
    } catch (_) {
      if (!mounted) return;
      final currentUser = ref.read(authStorageProvider).value;
      if ((widget.initialAddress ?? '').isEmpty) {
        setState(() {
          _addressController.text = _buildDefaultAddress(currentUser);
        });
      }
    }
  }

  String _buildDefaultAddress(AuthUser? currentUser) {
    if (currentUser == null) {
      return '';
    }

    final address = currentUser.address.trim();
    final detail = currentUser.detailHouse.trim();

    if (address.isEmpty && detail.isEmpty) {
      return '';
    }

    return [address, detail].where((value) => value.isNotEmpty).join(', ');
  }

  int _calculatePoints() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final rate = _pointsPerKg[_selectedWasteType] ?? 0;
    return (weight * rate).toInt();
  }
}