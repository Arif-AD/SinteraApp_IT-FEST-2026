import 'package:flutter/material.dart';

/// Centralized color palette for the Sintera app (Modern UI V2).
///
/// Every color used across the UI must be referenced from this class.
/// Never hardcode [Color] values in widgets.
class AppColors {
  AppColors._();

  // ----- Brand (Modern Premium Eco-Tech - Updated Color Combination) -----
  // Menggunakan warna pilihan baru: Hijau Kebiruan Deep Emerald & Vibrant Teal
  static const Color primary = Color(0xFF00A892);     // Hasil konversi dari ARGB(255, 0, 168, 146) - Teal Segar
  static const Color primaryDark = Color(0xFF007146); // Hasil konversi dari ARGB(255, 0, 113, 70) - Deep Emerald
  static const Color primaryLight = Color(0xFF33C0AE); // Aksen Mint Light untuk variasi UI
  static const Color secondary = Color(0xFF00A892);    
  static const Color accent = Color(0xFF00A892);       

  // ----- Surfaces -----
  static const Color background = Color(0xFFF8F9FA);  
  static const Color surface = Color(0xFFFFFFFF);     
  static const Color surfaceVariant = Color(0xFFF1F3F5); 
  static const Color scaffold = Color(0xFFF8F9FA);

  // ----- Status (Modern Palette) -----
  static const Color error = Color(0xFFFF4D4F);       
  static const Color success = Color(0xFF007146);     // Mengikuti base primary dark untuk sukses yang kokoh
  static const Color warning = Color(0xFFFFAA00);     
  static const Color info = Color(0xFF1890FF);        

  // ----- Text (High Readability & Sophisticated) -----
  static const Color textPrimary = Color(0xFF141414);   
  static const Color textSecondary = Color(0xFF595959); 
  static const Color textTertiary = Color(0xFF8C8C8C);  
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ----- Borders & dividers -----
  static const Color border = Color(0xFFE8E8E8);
  static const Color divider = Color(0xFFF0F0F0);     

  // ----- Eco accents -----
  static const Color leaf = Color(0xFF007146);
  static const Color sky = Color(0xFFBAE7FF);

  // ----- Neutral -----
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  /// Convenience map for soft tinted backgrounds.
  // Tint disesuaikan menjadi turunan warna baru yang sangat lembut
  static const Color ecoTint = Color(0xFFE6F6F4);      
  static const Color accentTint = Color(0xFFE6FFFA);   
  static const Color warningTint = Color(0xFFFFF7E6);  
  static const Color infoTint = Color(0xFFE6F7FF);     
  static const Color errorTint = Color(0xFFFFF1F0);    
}