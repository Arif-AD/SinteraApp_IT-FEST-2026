import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../models/waste_product_model.dart';
import '../../auth/services/laravel_auth_service.dart';

class WasteDetailPage extends StatefulWidget {
  const WasteDetailPage({
    super.key,
    required this.wasteItem,
    required this.onClaim,
  });

  final WasteProductModel wasteItem;
  final VoidCallback onClaim;

  @override
  State<WasteDetailPage> createState() => _WasteDetailPageState();
}

class _WasteDetailPageState extends State<WasteDetailPage> {
  String? _imageUrl;
  String? _residentName;
  String? _note;
  @override
  void initState() {
    super.initState();
    _imageUrl = widget.wasteItem.imageUrl;
    _residentName = widget.wasteItem.residentName;
    _note = widget.wasteItem.note;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
  }

  Future<void> _loadDetail() async {
    try {
      final container = ProviderScope.containerOf(context);
      final laravel = container.read(laravelAuthServiceProvider);
      final data = await laravel.getWargaWastePickup(widget.wasteItem.id);
      if (!mounted) return;
      setState(() {
        _imageUrl = data['image_url']?.toString() ?? _imageUrl;
        // Prefer 'resident' returned by API (inhabitans_id) then fallback to 'user'
        if (data['resident'] is Map<String, dynamic>) {
          _residentName = (data['resident'] as Map<String, dynamic>)['name']?.toString() ?? _residentName;
        } else if (data['user'] is Map<String, dynamic>) {
          _residentName = (data['user'] as Map<String, dynamic>)['name']?.toString() ?? _residentName;
        }
        _note = data['note']?.toString() ?? _note;
      });
    } catch (_) {
      // ignore errors and keep fallback values from passed model
    }
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
    const Color primaryBlue = Color(0xFF1B3B6F);
    final bool isAvailable = widget.wasteItem.status == 'Tersedia';
    final displayImage = _imageUrl ?? widget.wasteItem.imageUrl;
    final displayResident = _residentName ?? widget.wasteItem.residentName;
    final displayNote = _note ?? widget.wasteItem.note;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          child: Column(
            children: [
              // Header / App Bar Sticky
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 10.0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _handleBack,
                            icon: const Icon(Icons.arrow_back_rounded, color: primaryBlue),
                          ),
                          Expanded(
                            child: Text(
                              'Detail Setoran Limbah',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48), // Seimbang dengan lebar IconButton back
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Area Gambar / Foto Limbah (Persegi, Full Frame Kanan-Kiri, Tanpa Rounded)
                      AspectRatio(
                        aspectRatio: 1.2,
                        child: Container(
                          color: Colors.white,
                          child: displayImage != null && displayImage.isNotEmpty
                              ? Image.network(
                                  displayImage,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) => Image.asset(
                                    widget.wasteItem.wasteType == 'Organik'
                                        ? 'assets/images/icon/icon_organik.png'
                                        : 'assets/images/icon/icon_anorganik.png',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                )
                              : Image.asset(
                                  widget.wasteItem.wasteType == 'Organik'
                                      ? 'assets/images/icon/icon_organik.png'
                                      : 'assets/images/icon/icon_anorganik.png',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Informasi Berat & Status
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      widget.wasteItem.weight,
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'estimasi berat',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? primaryBlue.withValues(alpha: 0.1)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.wasteItem.status,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isAvailable ? primaryBlue : Colors.grey.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Limbah ${widget.wasteItem.wasteType} Warga',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.orange),
                                const SizedBox(width: 6),
                                Text(
                                  'Tanggal Disetorkan: ${widget.wasteItem.date}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Informasi Pengirim (Warga)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: primaryBlue.withValues(alpha: 0.1),
                              child: const Icon(Icons.person_outline_rounded, color: primaryBlue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayResident,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Penyetor Limbah Terverifikasi',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Catatan & Deskripsi Kondisi Limbah
                      Container(
                        color: Colors.white,
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catatan & Kondisi Limbah',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              (displayNote != null && displayNote.isNotEmpty)
                                  ? displayNote
                                  : 'Tidak ada catatan khusus yang diberikan oleh warga terkait kondisi limbah ini.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Bottom Bar Aksi (Kembali & Klaim / Ambil)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Kembali',
                          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isAvailable
                            ? () {
                                widget.onClaim();
                                Navigator.pop(context);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          isAvailable ? 'Klaim / Ambil' : 'Sudah Diklaim',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}