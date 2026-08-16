class EnvironmentalImpact {
  const EnvironmentalImpact({
    required this.totalOrganicKg,
    required this.totalInorganicKg,
    required this.totalCO2e,
    required this.sinteraTrees,
    required this.treeProgress,
  });

  final double totalOrganicKg;
  final double totalInorganicKg;
  final double totalCO2e;
  final int sinteraTrees;
  final double treeProgress;

  double get organicRatio {
    final total = totalOrganicKg + totalInorganicKg;
    if (total == 0) return 0.5;
    return totalOrganicKg / total;
  }

  EnvironmentalImpact copyWith({
    double? totalOrganicKg,
    double? totalInorganicKg,
    double? totalCO2e,
    int? sinteraTrees,
    double? treeProgress,
  }) {
    return EnvironmentalImpact(
      totalOrganicKg: totalOrganicKg ?? this.totalOrganicKg,
      totalInorganicKg: totalInorganicKg ?? this.totalInorganicKg,
      totalCO2e: totalCO2e ?? this.totalCO2e,
      sinteraTrees: sinteraTrees ?? this.sinteraTrees,
      treeProgress: treeProgress ?? this.treeProgress,
    );
  }
}
