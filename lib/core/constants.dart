import 'package:flutter/material.dart';

class AppColors {
  // Max Healthcare Palette
  static const Color primary = Color(0xFF001488); // Updated Deep Royal Blue
  static const Color primaryBrand = Color(0xFF001488); // Updated Deep Royal Blue
  static const Color accent = Color(0xFF35B6B4); // Medical Teal (Brand Accent)
  static const Color accentOrange = Color(0xFFF97316); // Keeping for warnings/alerts if needed, or replace
  
  static const Color backgroundLight = Color(0xFFFFFFFF); // Pure White
  static const Color backgroundAlt = Color(0xFFF8FAFC); // Light Blue-Grey for panels
  static const Color backgroundDark = Color(0xFF0F172A); // Dark mode fallback
  
  static const Color textLight = Color(0xFF0F172A); // Almost Black for headings
  static const Color textDim = Color(0xFF64748B); // Slate for secondary text
  static const Color textDark = Color(0xFFF8FAFC); // Off-White for dark mode
  static const Color grey = Color(0xFFE2E8F0); // Borders/Dividers
}

class AppStrings {
  static const String appName = 'Neurowell';
  static const String tagline = 'Modern Clinical Biofeedback';
}
