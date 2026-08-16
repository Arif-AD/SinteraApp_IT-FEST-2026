import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../../auth/services/laravel_auth_service.dart';
import '../../shopping/pages/shopping_page.dart';
import '../widgets/share_category_filter.dart';
import '../widgets/share_search_bar.dart';

class SharePage extends ConsumerStatefulWidget {
  const SharePage({super.key});

  @override
  ConsumerState<SharePage> createState() => _SharePageState();
}

class ShareRecipient {
  const ShareRecipient({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.detailHouse,
  });

  final String id;
  final String name;
  final String phone;
  final String address;
  final String detailHouse;
}

class _SharePageState extends ConsumerState<SharePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRecipientId = '';
  String _selectedCategory = 'Semua';
  bool _isRecipientsLoading = true;
  String? _recipientErrorMessage;
  List<ShareRecipient> _recipients = [];

  final List<String> _categories = ['Semua', 'Terbaru'];

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.go(AppRoutes.home);
  }

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    try {
      final recipients = await ref.read(laravelAuthServiceProvider).getWargaRecipients();
      setState(() {
        _recipients = recipients.map((item) {
          return ShareRecipient(
            id: item['id']?.toString() ?? '',
            name: item['name']?.toString() ?? '-',
            phone: item['phone']?.toString() ?? '',
            address: item['address']?.toString() ?? '',
            detailHouse: item['detail_house']?.toString() ?? '',
          );
        }).where((recipient) => recipient.id.isNotEmpty).toList();
        _isRecipientsLoading = false;
        _recipientErrorMessage = null;
      });
    } catch (_) {
      setState(() {
        _isRecipientsLoading = false;
        _recipientErrorMessage = 'Gagal memuat daftar warga. Silakan coba lagi.';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'W';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var filteredRecipients = _recipients.where((item) {
      final matchesPhone = item.phone.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesName = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return _searchQuery.isEmpty ? true : (matchesPhone || matchesName);
    }).toList();

    if (_selectedCategory == 'Terbaru') {
      filteredRecipients = filteredRecipients.reversed.toList();
    }

    final selectedRecipient = _recipients.firstWhere(
      (recipient) => recipient.id == _selectedRecipientId,
      orElse: () => const ShareRecipient(id: '', name: '', phone: '', address: '', detailHouse: ''),
    );

    const Color customLightBackground = Color(0xFFF7F9FA);
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
        backgroundColor: customLightBackground,
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: RefreshIndicator(
              onRefresh: _loadRecipients,
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShareSearchBar(
                          controller: _searchController,
                          searchQuery: _searchQuery,
                          onChanged: (value) => setState(() => _searchQuery = value),
                          onClear: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                          gradient: homeGreenGradient,
                          primaryColor: primaryGreen,
                        ),
                        const SizedBox(height: 1.0),
                        Divider(
                          height: 0,
                          thickness: 1.2,
                          color: Colors.black.withValues(alpha: 0.08),
                        ),
                        const SizedBox(height: 8.0),
                        ShareCategoryFilter(
                          categories: _categories,
                          selectedCategory: _selectedCategory,
                          onCategorySelected: (cat) => setState(() => _selectedCategory = cat),
                          gradient: homeGreenGradient,
                          primaryColor: primaryGreen,
                          backgroundColor: customLightBackground,
                        ),
                        const SizedBox(height: 8.0),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isRecipientsLoading
                        ? const Center(child: CircularProgressIndicator(color: primaryGreen))
                        : _recipientErrorMessage != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Text(
                                    _recipientErrorMessage!,
                                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : filteredRecipients.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Tidak ada warga penerima yang tersedia.',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    itemCount: filteredRecipients.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final recipient = filteredRecipients[index];
                                      final isSelected = _selectedRecipientId == recipient.id;

                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedRecipientId = isSelected ? '' : recipient.id;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            // Tanpa garis tepi hijau, menggunakan shadow lembut ala Gemini
                                            boxShadow: [
                                              BoxShadow(
                                                color: primaryGreen.withValues(alpha: isSelected ? 0.09 : 0.04),
                                                blurRadius: 12,
                                                offset: const Offset(0, 3),
                                              ),
                                              BoxShadow(
                                                color: const Color(0xFF4285F4).withValues(alpha: isSelected ? 0.07 : 0.03),
                                                blurRadius: 12,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                            border: Border.all(color: Colors.grey.shade100, width: 1),
                                          ),
                                          child: Row(
                                            children: [
                                              // SISI KIRI: Foto Profil / Inisial
                                              CircleAvatar(
                                                radius: 22,
                                                backgroundColor: primaryGreen.withValues(alpha: 0.1),
                                                child: Text(
                                                  _getInitials(recipient.name),
                                                  style: const TextStyle(
                                                    color: primaryGreen,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              // KOLOM TENGAH: Nama, No HP, Alamat
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      recipient.name,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                        color: AppColors.textPrimary,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.phone_outlined, size: 13, color: AppColors.textSecondary),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          recipient.phone,
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            color: AppColors.textSecondary,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            '${recipient.address}${recipient.detailHouse.isNotEmpty ? ', ${recipient.detailHouse}' : ''}',
                                                            style: const TextStyle(
                                                              fontSize: 11.5,
                                                              color: AppColors.textTertiary,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // SISI KANAN: Checkbox Mepet Kanan
                                              Checkbox(
                                                value: isSelected,
                                                activeColor: primaryGreen,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    _selectedRecipientId = (value == true) ? recipient.id : '';
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                  ),
                  if (_selectedRecipientId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ShoppingPage(
                                    receiver: {
                                      'receiver_id': selectedRecipient.id,
                                      'receiver_name': selectedRecipient.name,
                                      'receiver_phone': selectedRecipient.phone,
                                      'receiver_address': selectedRecipient.address,
                                      'receiver_detail_house': selectedRecipient.detailHouse,
                                    },
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Pilih Produk untuk Warga',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
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