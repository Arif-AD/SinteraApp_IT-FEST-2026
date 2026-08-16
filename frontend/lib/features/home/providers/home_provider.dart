import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/models/user_role.dart';
import '../../../features/environmental_impact/providers/environmental_impact_provider.dart';
import '../controllers/home_controller.dart';

String greetingForNow() {
  final hour = DateTime.now().hour;
  if (hour < 11) return 'Selamat pagi';
  if (hour < 15) return 'Selamat siang';
  if (hour < 19) return 'Selamat sore';
  return 'Selamat malam';
}

final homeStateProvider = FutureProvider<HomeState>((ref) async {
  final authUser = ref.watch(authStorageProvider).value;
  final role = authUser?.role;
  final userName = authUser?.name ?? 'Warga';
  final profileImageUrl = authUser?.profile;
  final impact = ref.watch(environmentalImpactProvider);

  if (role == UserRole.petani || role == UserRole.pengantar) {
    final authService = ref.read(laravelAuthServiceProvider);
    int netBalance = 0;

    try {
      netBalance = await authService.getNetBalanceWithFallback();
    } catch (_) {
      netBalance = 0;
    }

    return HomeState(
      userName: userName,
      greeting: greetingForNow(),
      pointsBalance: 0,
      impactPoints: impact.totalCO2e.toInt(),
      impactProgress: impact.treeProgress / 10.0,
      impactRank: impact.sinteraTrees > 0 ? 'Aktif ${impact.sinteraTrees} pohon' : 'Mulai aksi dampak',
      organicKg: impact.totalOrganicKg.toInt(),
      inorganicKg: impact.totalInorganicKg.toInt(),
      co2e: impact.totalCO2e.toInt(),
      trees: impact.sinteraTrees,
      profileImageUrl: profileImageUrl,
      income: netBalance,
    );
  }

  try {
    final authService = ref.read(laravelAuthServiceProvider);
    final response = await authService.getWargaPoints();
    final points = response['points'] is int
        ? response['points'] as int
        : (int.tryParse(response['points']?.toString() ?? '0') ?? 0);

    return HomeState(
      userName: userName,
      greeting: greetingForNow(),
      pointsBalance: points,
      impactPoints: impact.totalCO2e.toInt(),
      impactProgress: impact.treeProgress / 10.0,
      impactRank: impact.sinteraTrees > 0 ? 'Aktif ${impact.sinteraTrees} pohon' : 'Mulai aksi dampak',
      organicKg: impact.totalOrganicKg.toInt(),
      inorganicKg: impact.totalInorganicKg.toInt(),
      co2e: impact.totalCO2e.toInt(),
      trees: impact.sinteraTrees,
      profileImageUrl: profileImageUrl,
    );
  } catch (_) {
    return HomeState(
      userName: userName,
      greeting: greetingForNow(),
      pointsBalance: 0,
      impactPoints: impact.totalCO2e.toInt(),
      impactProgress: impact.treeProgress / 10.0,
      impactRank: impact.sinteraTrees > 0 ? 'Aktif ${impact.sinteraTrees} pohon' : 'Mulai aksi dampak',
      organicKg: impact.totalOrganicKg.toInt(),
      inorganicKg: impact.totalInorganicKg.toInt(),
      co2e: impact.totalCO2e.toInt(),
      trees: impact.sinteraTrees,
      profileImageUrl: profileImageUrl,
    );
  }
});