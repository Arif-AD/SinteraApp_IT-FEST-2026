import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../../auth/providers/auth_provider.dart';
import '../../environmental_impact/providers/environmental_impact_provider.dart';
import '../models/waste_product_model.dart';
import '../widgets/waste_product_card.dart';
import 'waste_detail_page.dart';

class WasteProductPage extends ConsumerStatefulWidget {
  const WasteProductPage({super.key});

  @override
  ConsumerState<WasteProductPage> createState() => _WasteProductPageState();
}

class _WasteProductPageState extends ConsumerState<WasteProductPage> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Organik', 'Anorganik', 'Tersedia'];
  bool _isLoading = true;
  final List<WasteProductModel> _wasteList = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final pickups = await ref.read(laravelAuthServiceProvider).getFarmerWastePickups();
      if (!mounted) return;
      setState(() {
        _wasteList.clear();
        _wasteList.addAll(pickups.map((item) {
          final wasteTypeValue = item['waste_type']?.toString() ?? 'Organik';
          final normalizedType = wasteTypeValue.toLowerCase();
          final wasteType = normalizedType.contains('anorganik')
              ? 'Anorganik'
              : 'Organik';
          final weight = item['weight'] is num ? (item['weight'] as num).toStringAsFixed(1) : '0';
          final status = item['status']?.toString() == 'assigned' ? 'Diklaim' : 'Tersedia';
          return WasteProductModel(
            id: item['id']?.toString() ?? '',
            residentName: item['user'] is Map<String, dynamic>
                ? ((item['user'] as Map<String, dynamic>)['name']?.toString() ?? 'Warga')
                : 'Warga',
            wasteType: wasteType,
            weight: '$weight kg',
            date: DateTime.tryParse(item['created_at']?.toString() ?? '')?.toLocal().toString().split(' ').first ?? '-',
            note: item['note']?.toString() ?? 'Limbah dari warga',
            status: status,
            imageUrl: item['image_url']?.toString(),
          );
        }));
      });
    } catch (_) {
      if (mounted) {
        setState(() => _wasteList.clear());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _claimWaste(String id) async {
    try {
      await ref.read(laravelAuthServiceProvider).claimFarmerWastePickup(id);

      final item = _wasteList.firstWhere((entry) => entry.id == id);
      final normalizedType = item.wasteType.toLowerCase();
      final weightValue = double.tryParse(item.weight.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      final organicKg = normalizedType.contains('organik') ? weightValue : 0.0;
      final inorganicKg = normalizedType.contains('anorganik') ? weightValue : 0.0;

      await ref.read(environmentalImpactProvider.notifier).addWasteTransaction(
        organicKg: organicKg,
        inorganicKg: inorganicKg,
      );

      if (!mounted) return;
      setState(() {
        final index = _wasteList.indexWhere((item) => item.id == id);
        if (index != -1) {
          final item = _wasteList[index];
          _wasteList[index] = WasteProductModel(
            id: item.id,
            residentName: item.residentName,
            wasteType: item.wasteType,
            weight: item.weight,
            date: item.date,
            note: item.note,
            status: 'Diklaim',
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Limbah berhasil diklaim! Silakan ambil ke lokasi warga.'), duration: Duration(seconds: 2)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    }
  }

  void _viewWasteDetails(WasteProductModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WasteDetailPage(
          wasteItem: item,
          onClaim: () => _claimWaste(item.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color primaryBlue = Color(0xFF1B3B6F);

    final filteredList = _wasteList.where((item) {
      if (_selectedFilter == 'Semua') return true;
      if (_selectedFilter == 'Tersedia') return item.status == 'Tersedia';
      return item.wasteType == _selectedFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          child: Column(
            children: [
              // Header Sticky
              Container(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 48.0, AppSpacing.lg, AppSpacing.md),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Text(
                              'Kelola & Klaim Limbah Warga',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Positioned(
                            left: -12,
                            child: IconButton(
                              onPressed: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              },
                              icon: const Icon(Icons.arrow_back_rounded, color: primaryBlue),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Filter Chips Horizontal
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _filters.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = _filters[index];
                          final isSelected = _selectedFilter == filter;
                          return InkWell(
                            onTap: () => setState(() => _selectedFilter = filter),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? primaryBlue : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? primaryBlue : Colors.black.withValues(alpha: 0.12),
                                  width: isSelected ? 1.5 : 0.8,
                                ),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Daftar Limbah
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 50, color: Colors.grey.shade400),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Tidak ada data limbah',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final item = filteredList[index];
                              return WasteProductCard(
                                item: item,
                                onView: () => _viewWasteDetails(item),
                                onClaim: () => _claimWaste(item.id),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}