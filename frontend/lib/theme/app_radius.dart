import 'package:flutter/material.dart';

/// Radius tokens for the Sintera app (Modern UI V2).
///
/// Rounded, soft UI components follow this scale.
class AppRadius {
  AppRadius._();

  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 20.0; // Ditingkatkan ke 20.0 agar kelengkungan kartu tampak lebih modern
  static const double xl = 26.0; // Ditingkatkan ke 26.0 untuk bottom sheet yang lebih smooth
  static const double xxl = 36.0;
  static const double round = 999.0;

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(round));
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}