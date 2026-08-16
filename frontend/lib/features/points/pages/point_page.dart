import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../providers/points_provider.dart';

class PointPage extends ConsumerStatefulWidget {
  const PointPage({super.key});

  @override
  ConsumerState<PointPage> createState() => _PointPageState();
}

class _PointPageState extends ConsumerState<PointPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedPeriod = 'Bulan Ini';
  final List<String> _periods = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Semua'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesPeriod(DateTime date) {
    final now = DateTime.now();
    if (_selectedPeriod == 'Semua') return true;
    if (_selectedPeriod == 'Bulan Ini') {
      return date.year == now.year && date.month == now.month;
    }
    if (_selectedPeriod == 'Minggu Ini') {
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      return date.isAfter(oneWeekAgo) || date.isAtSameMomentAs(oneWeekAgo);
    }
    if (_selectedPeriod == 'Hari Ini') {
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }
    return true;
  }

  String _formatActivityTitle(String description) {
    final match = RegExp(r'Waste sale -\s*([0-9]+(?:[.,][0-9]+)?)\s*kg', caseSensitive: false).firstMatch(description);
    if (match != null) {
      final weight = match.group(1)?.replaceAll(',', '.');
      return 'Limbah ${weight ?? '0'} Kg';
    }

    return description;
  }

  String _formatActivityDate(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) return rawDate;

    return DateFormat('dd-MM-yyyy', 'id_ID').format(parsed);
  }

  List<_PointHistoryItem> _filteredHistory(List<_PointHistoryItem> historyItems) {
    return historyItems.where((item) {
      final queryMatch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final date = DateTime.tryParse(item.rawDate) ?? DateTime(1970);
      final periodMatch = _matchesPeriod(date);
      return queryMatch && periodMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color primaryGreen = AppColors.primary;
    final pointsAsync = ref.watch(wargaPointsProvider);
    final pointsValue = pointsAsync.maybeWhen(data: (value) => value, orElse: () => 0);
    final pointsText = pointsValue.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+\b)'),
      (match) => '${match[1]}.',
    );
    final historyAsync = ref.watch(wargaPointTransactionsProvider);

    final List<_PointHistoryItem> historyItems = historyAsync.maybeWhen(
      data: (transactions) {
        return transactions.map((transaction) {
          final int amount = int.tryParse(transaction['amount']?.toString() ?? '0') ?? 0;
          final _PointEventType eventType = amount >= 0 ? _PointEventType.earn : _PointEventType.redeem;
          final String description = transaction['description']?.toString() ?? 'Transaksi poin';
          final String rawDate = transaction['created_at']?.toString() ?? '';
          final String formattedDate = _formatActivityDate(rawDate);

          return _PointHistoryItem(
            id: transaction['id']?.toString() ?? UniqueKey().toString(),
            title: _formatActivityTitle(description),
            category: eventType == _PointEventType.earn ? 'Poin Diterima' : 'Poin Digunakan',
            date: formattedDate,
            rawDate: rawDate,
            points: amount.abs(),
            type: eventType,
          );
        }).toList();
      },
      orElse: () => <_PointHistoryItem>[],
    );

    final filteredHistory = _filteredHistory(historyItems);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.contentMaxWidth(context)),
          child: RefreshIndicator(
            color: primaryGreen,
            onRefresh: () async {
              ref.refresh(wargaPointsProvider.future);
              ref.refresh(wargaPointTransactionsProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header Clean White Minimalis
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    if (Navigator.canPop(context)) Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.arrow_back_rounded, color: primaryGreen),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Poin Warga',
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Kelola dan pantau saldo poin hijau kamu',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            // Kartu Saldo Poin Modern UI dengan Angka Tebal Terpisah
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: primaryGreen.withValues(alpha: 0.15), width: 1.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryGreen.withValues(alpha: 0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: primaryGreen.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Image.asset(
                                          'assets/images/icon/icon_koin.png',
                                          width: 26,
                                          height: 26,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Poin Warga',
                                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                            textBaseline: TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                pointsText,
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Poin',
                                                style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: primaryGreen.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '100 Poin = Rp1.000',
                                      style: TextStyle(color: primaryGreen, fontSize: 10, fontWeight: FontWeight.bold),
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
                ),
                // Bagian Pencarian & Filter Periode
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Cari riwayat aktivitas...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                            prefixIcon: const Icon(Icons.search_rounded, color: primaryGreen, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _periods.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final period = _periods[index];
                              final isSelected = _selectedPeriod == period;
                              return InkWell(
                                onTap: () => setState(() => _selectedPeriod = period),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected ? primaryGreen : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? primaryGreen : Colors.black.withValues(alpha: 0.08),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    period,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Riwayat Aktivitas',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${filteredHistory.length} transaksi',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ),
                  ),
                ),
                if (pointsAsync.isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (pointsAsync.hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: Text(
                          'Gagal memuat data. Tarik ke bawah untuk mencoba lagi.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else if (filteredHistory.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: Text(
                          'Tidak ada aktivitas poin untuk periode ini.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return _PointHistoryCard(item: filteredHistory[index]);
                      },
                      childCount: filteredHistory.length,
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PointEventType { earn, redeem }

class _PointHistoryItem {
  const _PointHistoryItem({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.rawDate,
    required this.points,
    required this.type,
  });

  final String id;
  final String title;
  final String category;
  final String date;
  final String rawDate;
  final int points;
  final _PointEventType type;
}

class _PointHistoryCard extends StatelessWidget {
  const _PointHistoryCard({required this.item});

  final _PointHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEarn = item.type == _PointEventType.earn;
    final color = isEarn ? AppColors.success : AppColors.warning;
    final amountText = '${isEarn ? '+' : '-'}${item.points} Poin';

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                'assets/images/icon/icon_koin.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.category} • ${item.date}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              amountText,
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}