import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';

class ShareFormPage extends StatefulWidget {
  const ShareFormPage({super.key});

  @override
  State<ShareFormPage> createState() => _ShareFormPageState();
}

class _ShareFormPageState extends State<ShareFormPage> {
  final _formKey = GlobalKey<FormState>();

  void _handleBack() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go(AppRoutes.home);
  }
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _donorNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = 'Sayur Segar';
  final List<String> _categories = ['Sayur Segar', 'Buah', 'Bumbu Dapur', 'Organik'];

  @override
  void dispose() {
    _titleController.dispose();
    _donorNameController.dispose();
    _locationController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _handleBack();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Berhasil membagikan hasil kebun ke warga!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const LinearGradient homeGreenGradient = LinearGradient(
      colors: [Color.fromARGB(255, 0, 128, 111), AppColors.primary],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    const Color primaryGreen = AppColors.primary;

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
          'Tambah Berbagi',
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
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // SECTION 1: FOTO PRODUK (Gaya Shopee/E-commerce Square Photo Picker)
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
                            'Foto Produk / Hasil Kebun',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '0/4 Foto',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {},
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
                                    'Tambah Foto',
                                    style: TextStyle(
                                      color: primaryGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // SECTION 2: INFORMASI UTAMA (Nama, Kategori, Jumlah)
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
                      _buildShopeeTextField(
                        label: 'Nama Barang',
                        controller: _titleController,
                        hint: 'Contoh: Kangkung Segar Kebun Sendiri',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Divider(color: Color(0xFFF1F3F5), height: 1),
                      ),
                      
                      // Kategori selector ala pilihan e-commerce
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Kategori',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            DropdownButton<String>(
                              value: _selectedCategory,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
                              items: _categories.map((cat) {
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat, style: const TextStyle(fontSize: 13, color: primaryGreen, fontWeight: FontWeight.bold)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Divider(color: Color(0xFFF1F3F5), height: 1),
                      ),

                      _buildShopeeTextField(
                        label: 'Jumlah / Takaran',
                        controller: _amountController,
                        hint: 'Contoh: 2 Ikat Besar / 1 Kg',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // SECTION 3: DETAIL LOKASI & PEMBERI
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
                      _buildShopeeTextField(
                        label: 'Nama Pemberi & RT',
                        controller: _donorNameController,
                        hint: 'Contoh: Ibu Rini (RT 02)',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Divider(color: Color(0xFFF1F3F5), height: 1),
                      ),
                      _buildShopeeTextField(
                        label: 'Lokasi / Patokan',
                        controller: _locationController,
                        hint: 'Contoh: Jl. Mawar No. 14 (150m)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // SECTION 4: DESKRIPSI
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
                        'Deskripsi Barang',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Jelaskan kondisi barang, alasan dibagikan, atau jadwal pengambilan...',
                          hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Deskripsi wajib diisi' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // TOMBOL SUBMIT BAWAH (Gaya Floating Action / Sticky Button Ala E-Commerce)
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
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.center,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Center(
                      child: Text(
                        'Simpan & Publikasikan',
                        style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold, height: 1.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  // Widget Baris Form Minimalis ala Field E-Commerce Modern
  Widget _buildShopeeTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
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
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              validator: (val) => val == null || val.isEmpty ? 'Wajib diisi' : null,
            ),
          ),
        ],
      ),
    );
  }
}