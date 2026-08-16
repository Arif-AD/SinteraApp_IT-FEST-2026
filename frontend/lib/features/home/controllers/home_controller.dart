import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/models/user_role.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/environmental_impact/providers/environmental_impact_provider.dart';

class HomeState {
  const HomeState({
    required this.userName,
    required this.greeting,
    required this.pointsBalance,
    required this.impactPoints,
    required this.impactProgress,
    required this.impactRank,
    required this.organicKg,
    required this.inorganicKg,
    required this.co2e,
    required this.trees,
    this.profileImageUrl,
    this.income = 0,
  });

  final String userName;
  final String greeting;
  final int pointsBalance;
  final int impactPoints;
  final double impactProgress;
  final String impactRank;
  final int organicKg;
  final int inorganicKg;
  final int co2e;
  final int trees;
  final String? profileImageUrl;
  final int income;

  double get organicRatio {
    final total = organicKg + inorganicKg;
    if (total == 0) return 0.5;
    return organicKg / total;
  }

  String get pointsLabel {
    final grouped = pointsBalance
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return grouped;
  }

  String get currentPointsLabel => pointsLabel;

  String get incomeLabel {
    if (income == 0) return '0';
    final formatted = income
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp $formatted';
  }
}

String _greetingForNow() {
  final hour = DateTime.now().hour;
  if (hour < 11) return 'Selamat pagi';
  if (hour < 15) return 'Selamat siang';
  if (hour < 19) return 'Selamat sore';
  return 'Selamat malam';
}

final homeControllerProvider = Provider<HomeState>((ref) {
  final role = ref.watch(authStorageProvider).value?.role;
  final impact = ref.watch(environmentalImpactProvider);

  if (role == UserRole.petani || role == UserRole.pengantar) {
    return HomeState(
      userName: role == UserRole.petani ? 'Pak Tani' : 'Pak Pengantar',
      greeting: _greetingForNow(),
      pointsBalance: 0,
      impactPoints: impact.totalCO2e.toInt(),
      impactProgress: impact.treeProgress / 10.0,
      impactRank: impact.sinteraTrees > 0 ? 'Aktif ${impact.sinteraTrees} pohon' : 'Mulai aksi dampak',
      organicKg: impact.totalOrganicKg.toInt(),
      inorganicKg: impact.totalInorganicKg.toInt(),
      co2e: impact.totalCO2e.toInt(),
      trees: impact.sinteraTrees,
      income: 0,
    );
  }

  return HomeState(
    userName: 'Budi Santoso',
    greeting: _greetingForNow(),
    pointsBalance: 12450,
    impactPoints: impact.totalCO2e.toInt(),
    impactProgress: impact.treeProgress / 10.0,
    impactRank: impact.sinteraTrees > 0 ? 'Aktif ${impact.sinteraTrees} pohon' : 'Mulai aksi dampak',
    organicKg: impact.totalOrganicKg.toInt(),
    inorganicKg: impact.totalInorganicKg.toInt(),
    co2e: impact.totalCO2e.toInt(),
    trees: impact.sinteraTrees,
  );
});
