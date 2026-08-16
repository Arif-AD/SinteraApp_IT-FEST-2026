import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/auth/models/user_role.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../models/environmental_impact.dart';
import '../services/environmental_impact_service.dart';

class EnvironmentalImpactNotifier extends StateNotifier<EnvironmentalImpact> {
  EnvironmentalImpactNotifier(this._ref)
      : _service = EnvironmentalImpactService(),
        super(const EnvironmentalImpact(
          totalOrganicKg: 0,
          totalInorganicKg: 0,
          totalCO2e: 0,
          sinteraTrees: 0,
          treeProgress: 0,
        )) {
    _ref.listen<AsyncValue<AuthUser?>>(authStorageProvider, (_, next) async {
      final user = next.value;
      if (user != null) {
        await _load();
      }
    });
    _load();
  }

  final Ref _ref;
  final EnvironmentalImpactService _service;

  static const String _organicKey = 'environmental_impact_total_organic_kg';
  static const String _inorganicKey = 'environmental_impact_total_inorganic_kg';
  static const String _co2eKey = 'environmental_impact_total_co2e';
  static const String _treesKey = 'environmental_impact_sintera_trees';
  static const String _progressKey = 'environmental_impact_tree_progress';

  Future<void> _load() async {
    try {
      final authUser = _ref.read(authStorageProvider).value;
      if (authUser != null) {
        await _loadFromBackend();
        return;
      }

      await _loadFromPreferences();
    } catch (_) {
      state = _service.impact;
    }
  }

  Future<void> _loadFromBackend() async {
    try {
      final authUser = _ref.read(authStorageProvider).value;
      final role = authUser?.role;
      final pickups = role == UserRole.petani
          ? await _ref.read(laravelAuthServiceProvider).getFarmerWastePickups()
          : await _ref.read(laravelAuthServiceProvider).getWargaWastePickups();
      _service.reset();

      for (final item in pickups) {
        final status = item['status']?.toString().toLowerCase() ?? '';
        if (status != 'assigned' && status != 'claimed') {
          continue;
        }

        final wasteTypeValue = item['waste_type']?.toString() ?? 'Organik';
        final normalizedType = wasteTypeValue.toLowerCase();
        final weight = item['weight'] is num ? (item['weight'] as num).toDouble() : 0.0;

        if (normalizedType.contains('anorganik')) {
          _service.addWasteTransaction(organicKg: 0, inorganicKg: weight);
        } else if (normalizedType.contains('organik') || normalizedType.contains('haus')) {
          _service.addWasteTransaction(organicKg: weight, inorganicKg: 0);
        }
      }

      state = _service.impact;
      await _persist();
    } catch (_) {
      await _loadFromPreferences();
    }
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final organicKg = prefs.getDouble(_organicKey) ?? 0.0;
      final inorganicKg = prefs.getDouble(_inorganicKey) ?? 0.0;

      _service.reset();
      if (organicKg > 0 || inorganicKg > 0) {
        _service.addWasteTransaction(organicKg: organicKg, inorganicKg: inorganicKg);
      }

      state = _service.impact;
    } catch (_) {
      state = _service.impact;
    }
  }

  Future<void> addWasteTransaction({required double organicKg, required double inorganicKg}) async {
    _service.addWasteTransaction(organicKg: organicKg, inorganicKg: inorganicKg);
    await _persist();
    state = _service.impact;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final impact = _service.impact;

      await prefs.setDouble(_organicKey, impact.totalOrganicKg);
      await prefs.setDouble(_inorganicKey, impact.totalInorganicKg);
      await prefs.setDouble(_co2eKey, impact.totalCO2e);
      await prefs.setInt(_treesKey, impact.sinteraTrees);
      await prefs.setDouble(_progressKey, impact.treeProgress);
    } catch (_) {
      // Ignore persistence issues so the UI still works offline.
    }
  }
}

final environmentalImpactProvider =
    StateNotifierProvider<EnvironmentalImpactNotifier, EnvironmentalImpact>(
  (ref) => EnvironmentalImpactNotifier(ref),
);
