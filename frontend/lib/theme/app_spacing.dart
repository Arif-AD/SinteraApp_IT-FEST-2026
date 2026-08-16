import 'package:flutter/material.dart';

/// Spacing scale for the Sintera app.
///
/// Use these tokens to keep vertical rhythm and consistent gaps.
/// Never hardcode raw padding/margin numbers in widgets.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;
  static const double massive = 48.0;

  // ----- Edge insets helpers -----
  static const EdgeInsets paddingScreen =
      EdgeInsets.symmetric(horizontal: lg, vertical: xl);

  static const EdgeInsets paddingCard = EdgeInsets.all(lg);

  static const EdgeInsets horizontalMd =
      EdgeInsets.symmetric(horizontal: md);

  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);

  // ----- Common SizedBox gaps -----
  static const Widget gapXs = SizedBox(width: xs, height: xs);
  static const Widget gapSm = SizedBox(width: sm, height: sm);
  static const Widget gapMd = SizedBox(width: md, height: md);
  static const Widget gapLg = SizedBox(width: lg, height: lg);
  static const Widget gapXl = SizedBox(width: xl, height: xl);
  static const Widget gapXxl = SizedBox(width: xxl, height: xxl);
}
