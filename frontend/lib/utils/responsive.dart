import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Responsive breakpoint helpers.
///
/// Supports phones, large phones, and tablets with a single source of truth
/// for layout decisions.
class Responsive {
  Responsive._();

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  static bool isLargePhone(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 480 && width < 600;
  }

  static bool isPhone(BuildContext context) =>
      MediaQuery.of(context).size.width < 480;

  /// Constrains content width on large screens for a centered layout.
  static double contentMaxWidth(BuildContext context) =>
      isTablet(context) ? 720.w : double.infinity;

  /// Grid column count that adapts to the available width.
  static int gridColumns(BuildContext context) =>
      isTablet(context) ? 4 : (isLargePhone(context) ? 3 : 2);

  /// Keeps text sizing stable across devices without shrinking the UI too much.
  static double textScale(BuildContext context, {double factor = 1.0}) {
    final mediaQuery = MediaQuery.of(context);
    final scale = mediaQuery.textScaler.clamp(maxScaleFactor: 1.0).scale(1.0);
    return (scale * factor).clamp(0.96, 1.0);
  }
}
