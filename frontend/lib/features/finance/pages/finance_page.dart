import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../../../utils/responsive.dart';
import '../../auth/models/user_role.dart';
import '../../auth/services/laravel_auth_service.dart';
import '../../auth/services/mock_auth_service.dart';

class FinancePage extends ConsumerStatefulWidget {
  const FinancePage({super.key});

  @override
  ConsumerState<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends ConsumerState<FinancePage> {
  String _selectedPeriod = 'Bulan Ini';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _periods = ['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Semua'];

  List<_FinanceTransaction> _transactions = [];
  bool _isLoading = true;
  String _error = '';
  int _backendBalance = 0;
  bool _hasBackendBalance = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTransactions());
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      _backendBalance = await ref.read(laravelAuthServiceProvider).getNetBalance();
      _hasBackendBalance = _backendBalance > 0;
    } catch (_) {
      _backendBalance = 0;
      _hasBackendBalance = false;
    }

    try {
      final role = ref.read(authStorageProvider).value?.role;
      if (role == UserRole.pengantar) {
        final tasks = await ref.read(laravelAuthServiceProvider).getDeliveryTasks();
        if (!mounted) return;

        final deliveredTasks = (tasks as List).where((t) {
          final status = (t['status'] ?? '').toString().toLowerCase();
          return status == 'completed' || status == 'selesai' || status == 'delivered';
        }).toList();

        _transactions = deliveredTasks.map((t) {
          final order = t['order'] as Map<String, dynamic>?;
          final product = order?['product'] as Map<String, dynamic>?;
          final name = product?['name']?.toString() ?? 'Produk';
          final createdAt = order?['created_at']?.toString() ?? '';

          num distanceFee = 0;
          try {
            final distanceValue = order?['distance_fee'];
            distanceFee = distanceValue is num ? distanceValue : num.parse(distanceValue?.toString() ?? '0');
          } catch (_) {
            distanceFee = 0;
          }
          num baseFee = 0;
          try {
            final baseValue = order?['base_fee'];
            baseFee = baseValue is num ? baseValue : num.parse(baseValue?.toString() ?? '0');
          } catch (_) {
            baseFee = 0;
          }

          final incomeValue = (distanceFee + (baseFee / 2)).round();

          String formattedAmount(int val) {
            return 'Rp${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
          }

          return _FinanceTransaction(
            id: t['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: name,
            category: 'Pengiriman',
            amount: formattedAmount(incomeValue),
            date: DateTime.tryParse(createdAt)?.toLocal().toString().split(' ').first ?? createdAt,
            icon: Icons.local_shipping_rounded,
          );
        }).toList();
      } else {
        final orders = await ref.read(laravelAuthServiceProvider).getFarmerOrders();
        if (!mounted) return;

        final delivered = (orders as List).where((o) {
          final s = (o['status'] ?? '').toString().toLowerCase();
          final d = (o['delivery_status'] ?? '').toString().toLowerCase();
          return s == 'completed' || s == 'selesai' || d == 'delivered' || d == 'selesai';
        }).toList();

        _transactions = delivered.map((o) {
          final product = o['product'] as Map<String, dynamic>?;
          final name = product?['name']?.toString() ?? 'Produk';
          final createdAt = o['created_at']?.toString() ?? '';

          num total = 0;
          try {
            final totalValue = o['total_amount'];
            total = totalValue is num ? totalValue : num.parse(totalValue?.toString() ?? '0');
          } catch (_) {
            total = 0;
          }
          num baseFee = 0;
          try {
            final baseValue = o['base_fee'];
            baseFee = baseValue is num ? baseValue : num.parse(baseValue?.toString() ?? '0');
          } catch (_) {
            baseFee = 0;
          }
          num farmerSubsidy = 0;
          try {
            final subsidyValue = o['farmer_subsidy'];
            farmerSubsidy = subsidyValue is num ? subsidyValue : num.parse(subsidyValue?.toString() ?? '0');
          } catch (_) {
            farmerSubsidy = 0;
          }

          final incomeValue = (total + (baseFee / 2) - farmerSubsidy).round();

          String formattedAmount(int val) {
            return 'Rp${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
          }

          return _FinanceTransaction(
            id: o['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            title: name,
            category: 'Penjualan',
            amount: formattedAmount(incomeValue),
            date: DateTime.tryParse(createdAt)?.toLocal().toString().split(' ').first ?? createdAt,
            icon: Icons.shopping_cart_checkout_rounded,
          );
        }).toList();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _transactions = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = ref.watch(authStorageProvider).value?.role;
    
    final Color themeColor = role == UserRole.pengantar ? const Color(0xFFB22222) : const Color(0xFF1B3B6F);

    final List<Color> cardGradientColors = role == UserRole.pengantar
        ? const [Color(0xFF8B0000), Color(0xFFB22222)]
        : role == UserRole.petani
            ? const [Color(0xFF1B3B6F), Color(0xFF0C2340)]
            : [AppColors.primaryDark, AppColors.primary];

    final totalIncome = _transactions
        .fold<int>(0, (sum, t) {
      final value = int.tryParse(t.amount.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return sum + value;
    });

    final balance = _hasBackendBalance ? _backendBalance : totalIncome;

    String formatRupiah(int value) {
      return 'Rp${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
    }

    final filteredTransactions = _transactions.where((t) {
      final queryMatch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.category.toLowerCase().contains(_searchQuery.toLowerCase());
      final date = DateTime.tryParse(t.date) ?? DateTime(1970);
      final periodMatch = _matchesPeriod(date);
      return queryMatch && periodMatch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
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
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Keuangan Usaha',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pantau pendapatan secara real-time',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          // Kartu Total Pendapatan dengan Padding Kiri-Kanan Diperlebar & Jarak Teks-Angka Diperdekat
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: cardGradientColors,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: cardGradientColors.first.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
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
                                      'Total Pendapatanmu',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Real-Time',
                                        style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2), // Jarak teks dan angka diperdekat
                                Text(
                                  formatRupiah(balance < 0 ? 0 : balance),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                    letterSpacing: -0.5,
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
                          hintText: 'Cari transaksi atau kategori...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                          prefixIcon: Icon(Icons.search_rounded, color: themeColor, size: 20),
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
                            borderSide: BorderSide(color: themeColor, width: 1.5),
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
                                  color: isSelected ? themeColor : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? themeColor : Colors.black.withValues(alpha: 0.08),
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
                            'Riwayat Transaksi',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${filteredTransactions.length} transaksi',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error.isNotEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                          const SizedBox(height: AppSpacing.sm),
                          Text(_error, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                )
              else if (filteredTransactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: AppSpacing.sm),
                          const Text('Transaksi tidak ditemukan', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final transaction = filteredTransactions[index];
                        return _TransactionCard(transaction: transaction, themeColor: themeColor);
                      },
                      childCount: filteredTransactions.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction, required this.themeColor});

  final _FinanceTransaction transaction;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const amountColor = AppColors.success;
    final amountText = '+${transaction.amount}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(transaction.icon, color: themeColor, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${transaction.category} • ${transaction.date}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              amountText,
              style: theme.textTheme.titleSmall?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceTransaction {
  const _FinanceTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.icon,
  });

  final String id;
  final String title;
  final String category;
  final String amount;
  final String date;
  final IconData icon;
}