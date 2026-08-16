import '../models/environmental_impact.dart';

class EnvironmentalImpactService {
  EnvironmentalImpactService({
    double initialOrganicKg = 0,
    double initialInorganicKg = 0,
  })  : _totalOrganicKg = initialOrganicKg,
        _totalInorganicKg = initialInorganicKg;

  static const double organicEmissionFactor = 2.27;
  static const double inorganicEmissionFactor = 3.12;
  static const double co2ePerTree = 30.0;

  double _totalOrganicKg;
  double _totalInorganicKg;

  EnvironmentalImpact get impact {
    final totalCO2e = (_totalOrganicKg * organicEmissionFactor) + (_totalInorganicKg * inorganicEmissionFactor);
    final trees = (totalCO2e / co2ePerTree).floor();
    final progress = totalCO2e == 0 ? 0.0 : totalCO2e % co2ePerTree;

    return EnvironmentalImpact(
      totalOrganicKg: _totalOrganicKg,
      totalInorganicKg: _totalInorganicKg,
      totalCO2e: totalCO2e,
      sinteraTrees: trees,
      treeProgress: progress,
    );
  }

  void addWasteTransaction({required double organicKg, required double inorganicKg}) {
    _totalOrganicKg += organicKg;
    _totalInorganicKg += inorganicKg;
  }

  void reset() {
    _totalOrganicKg = 0;
    _totalInorganicKg = 0;
  }
}
