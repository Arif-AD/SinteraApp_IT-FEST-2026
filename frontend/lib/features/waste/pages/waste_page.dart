import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/waste_model.dart';
import '../widgets/waste_transaction_tile.dart';
import 'waste_form_page.dart';

class WastePage extends ConsumerStatefulWidget {
  const WastePage({super.key});

  @override
  ConsumerState<WastePage> createState() => _WastePageState();
}

class _WastePageState extends ConsumerState<WastePage> {
  bool _isLoading = true;
  List<WasteSellRecord> _transactionRecords = [];
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Organik', 'Anorganik', 'Menunggu', 'Diklaim'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final pickups = await ref.read(laravelAuthServiceProvider).getWargaWastePickups();
      if (!mounted) return;
      setState(() {
        _transactionRecords = pickups.map((item) {
          final weight = item['weight'] is num ? (item['weight'] as num).toStringAsFixed(1) : '0';
          final wasteTypeValue = item['waste_type']?.toString() ?? 'Organik';
          final normalizedType = wasteTypeValue.toLowerCase();
          final wasteType = normalizedType.contains('anorganik')
              ? 'Anorganik'
              : 'Organik';
          final wasteCategory = wasteType == 'Anorganik'
              ? 'Limbah Anorganik'
              : 'Limbah Organik';
          final status = item['status']?.toString() ?? 'requested';
          final displayStatus = status == 'assigned' ? 'Diklaim' : 'Menunggu';
          final pickupId = item['id']?.toString();
          final address = item['address']?.toString() ?? '';
          final note = item['note']?.toString() ?? '';
          final latitude = item['latitude'] is num ? (item['latitude'] as num).toDouble() : null;
          final longitude = item['longitude'] is num ? (item['longitude'] as num).toDouble() : null;
          final weightValue = item['weight'] is num ? (item['weight'] as num).toDouble() : 0.0;
          final imageUrl = item['image_url']?.toString();
          final pointRate = wasteType == 'Anorganik' ? 300 : 150;
          final totalPointsEarned = (weightValue * pointRate).round();

          return WasteSellRecord(
            date: DateTime.tryParse(item['created_at']?.toString() ?? '')?.toLocal().toString().split(' ').first ?? '-',
            title: wasteCategory,
            unitInfo: '$weight kg',
            totalPoints: '+${totalPointsEarned.toString()}',
            status: displayStatus,
            statusColor: status == 'assigned' ? AppColors.warning : AppColors.success,
            imageName: wasteType.toLowerCase().contains('anorganik') ? 'anorganik' : 'organik',
            id: pickupId,
            wasteType: wasteType,
            weight: weightValue,
            note: note,
            address: address,
            latitude: latitude,
            longitude: longitude,
            imageUrl: imageUrl,
          );
        }).toList();
      });
    } catch (_) {
      if (mounted) {
        setState(() => _transactionRecords = const []);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openEditForm(WasteSellRecord record) async {
    final shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => WasteFormPage(
          initialPickupId: record.id,
          initialWasteType: record.wasteType,
          initialWeight: record.weight,
          initialNote: record.note,
          initialAddress: record.address,
          initialImageUrl: record.imageUrl,
        ),
      ),
    );

    if (shouldRefresh == true && mounted) {
      await _loadData();
    }
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color primaryGreen = AppColors.primary;

    final filteredRecords = _transactionRecords.where((record) {
      if (_selectedFilter == 'Semua') return true;
      if (_selectedFilter == 'Organik' || _selectedFilter == 'Anorganik') {
        return (record.wasteType ?? '').toLowerCase() == _selectedFilter.toLowerCase();
      }
      if (_selectedFilter == 'Menunggu' || _selectedFilter == 'Diklaim') {
        return record.status == _selectedFilter;
      }
      return true;
    }).toList();

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
            child: RefreshIndicator(
              color: primaryGreen,
              onRefresh: _loadData,
              child: Column(
                children: [
                  // Bagian Header Sticky (Model Layout mirip WasteProductPage)
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
                                  'Limbah Warga',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: -12,
                                child: IconButton(
                                  onPressed: _handleBack,
                                  icon: const Icon(Icons.arrow_back_rounded, color: primaryGreen),
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
                                    color: isSelected ? primaryGreen : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? primaryGreen : Colors.black.withValues(alpha: 0.12),
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

                  // Daftar Riwayat Penjualan
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredRecords.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inbox_outlined, size: 50, color: Colors.grey.shade400),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'Belum ada penjualan limbah.',
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
                                itemCount: filteredRecords.length,
                                itemBuilder: (context, index) {
                                  final record = filteredRecords[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                    child: WasteTransactionTile(
                                      record: record,
                                      onTap: () => _openEditForm(record),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: Colors.white,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WasteFormPage()),
                ).then((shouldRefresh) {
                  if (shouldRefresh == true) {
                    _loadData();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text(
                'Setor Limbah Sekarang',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}