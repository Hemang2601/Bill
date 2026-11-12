import 'package:flutter/material.dart';

/// Centralized luxury color palette for Shree Shakti Electric
/// Luxury White + Colorful Premium Edition:
/// - Main background: #F7F8FC
/// - Primary surface: #FFFFFF
/// - Primary blue: #2563EB
/// - Deep navy: #172554
/// - Electric blue: #0EA5E9
/// - Premium violet: #7C3AED
/// - Emerald green: #10B981
/// - Warm amber: #F59E0B
/// - Coral: #F97316
/// - Primary text: #111827
/// - Secondary text: #64748B
/// - Border: #E8ECF3
abstract class AppColors {
  // Backgrounds & Surfaces (Luxury White Theme)
  static const Color background = Color(0xFFF7F8FC);
  static const Color backgroundDarker = Color(0xFFEDF2F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF8FAFC);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Primary Blue & Electric Accents
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryHover = Color(0xFF1D4ED8);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF0EA5E9);
  static const Color primarySoft = Color(0xFFEFF6FF);
  static const Color primarySoftHover = Color(0xFFDBEAFE);

  // Deep Navy Branding
  static const Color deepNavy = Color(0xFF172554);
  static const Color deepNavySoft = Color(0xFF1E293B);

  // Electric Blue Accent
  static const Color electricBlue = Color(0xFF0EA5E9);
  static const Color electricSoft = Color(0xFFE0F2FE);
  static const Color electricBorder = Color(0xFFBAE6FD);

  // Premium Violet Accent
  static const Color premiumViolet = Color(0xFF7C3AED);
  static const Color purpleAccent = Color(
    0xFF7C3AED,
  ); // backward-compatible alias
  static const Color violetSoft = Color(0xFFF5F3FF);
  static const Color purpleSoft = Color(0xFFF3E8FF);
  static const Color violetBorder = Color(0xFFDDD6FE);

  // Emerald Green Accent & Positive Indicators
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color emeraldSoft = Color(0xFFECFDF5);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color emeraldBorder = Color(0xFFA7F3D0);
  static const Color successBorder = Color(0xFF86EFAC);

  // Warm Amber / Electrical Accents
  static const Color warmAmber = Color(0xFFF59E0B);
  static const Color amberAccent = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFBBF24);
  static const Color amberSoft = Color(0xFFFFFBEB);
  static const Color amberBorder = Color(0xFFFDE68A);

  // Coral Warning & Attention States
  static const Color coral = Color(0xFFF97316);
  static const Color coralSoft = Color(0xFFFFF7ED);
  static const Color coralBorder = Color(0xFFFED7AA);

  // Semantic Warnings & Errors
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color dangerBorder = Color(0xFFFCA5A5);

  static const Color info = Color(0xFF0EA5E9);
  static const Color infoSoft = Color(0xFFE0F2FE);
  static const Color infoBorder = Color(0xFFBAE6FD);

  // Typography (High-contrast, elegant readability)
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE8ECF3);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color borderHover = Color(0xFFCBD5E1);
  static const Color borderFocus = Color(0xFF2563EB);

  // Neutral Slate Accents
  static const Color slateLight = Color(0xFFE2E8F0);
}
