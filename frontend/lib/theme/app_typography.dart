import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography scale for the Sintera app, built on the Poppins typeface.
class AppTypography {
  AppTypography._();

  /// Base Poppins text theme for Material 3.
  static TextTheme get textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.6, // Disesuaikan sedikit lebih rapat agar kokoh
        color: _textPrimary,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: _textPrimary,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.4,
        color: _textPrimary,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 22.sp,
        fontWeight: FontWeight.w700, // Diubah dari w600 ke w700 untuk ketegasan header
        letterSpacing: -0.2,
        color: _textPrimary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20.sp,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: _textPrimary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: _textPrimary,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: _textPrimary,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        color: _textPrimary,
      ),
    );
  }

  // Diubah agar sejajar dengan AppColors.textPrimary yang baru (Ultra Dark Premium)
  static const Color _textPrimary = Color(0xFF141414); 

  // ----- Semantic helpers (for non-TextTheme contexts) -----

  static TextStyle heading1(BuildContext context) =>
      Theme.of(context).textTheme.displayMedium!;

  static TextStyle heading2(BuildContext context) =>
      Theme.of(context).textTheme.displaySmall!;

  static TextStyle title(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!;

  static TextStyle subtitle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: const Color(0xFF595959), // Disesuaikan ke AppColors.textSecondary baru
          );
}