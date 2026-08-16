import 'package:flutter/material.dart';

/// Elevation / shadow tokens for the Sintera app (Modern UI V2).
///
/// Soft, premium shadows that follow modern minimalist elevations.
class AppShadow {
  AppShadow._();

  static const List<BoxShadow> none = [];

  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x05141414), // Sangat tipis dan halus
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x08141414),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0C141414), // Bayangan kartu utama yang melayang lembut
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x12141414),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  /// Colored glow used for primary CTAs.
  static List<BoxShadow> glow({required Color color}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.20), // Dikurangi dari 0.28 agar pendarannya lebih elegan
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static const BoxShadow bottomNav = BoxShadow(
    color: Color(0x06141414),
    blurRadius: 20,
    offset: Offset(0, -4),
  );

  static const BoxShadow card = BoxShadow(
    color: Color(0x08141414),
    blurRadius: 20,
    offset: Offset(0, 6),
  );
}