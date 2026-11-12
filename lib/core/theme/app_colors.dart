import 'package:flutter/material.dart';

/// Luxury White Theme Palette for Shree Shakti Electric
/// Strictly implements the specification:
/// - Page background: #F7F8FC
/// - Surface: #FFFFFF
/// - Hairline border: #E8ECF3
/// - Text: #111827 (primary), #64748B (secondary), #94A3B8 (muted)
/// - Brand: #172554 (navy), #2563EB (blue), #0EA5E9 (sky)
/// - Accents (status & icon chips): violet #7C3AED, emerald #10B981, amber #F59E0B, coral #F97316
/// - Danger: #DC2626
/// - Signature detail: 2px gradient hairline (#172554 to #2563EB to #0EA5E9)
abstract class AppColors {
  // Page Background & Pure White Surfaces
  static const Color background = Color(0xFFF7F8FC);
  static const Color backgroundDarker = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF8FAFC);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Hairline Borders
  static const Color border = Color(0xFFE8ECF3);
  static const Color borderSubtle = Color(0xFFF1F5F9);
  static const Color borderHover = Color(0xFFCBD5E1);
  static const Color borderFocus = Color(0xFF2563EB);

  // Brand Palette: Navy, Electric Blue, Sky
  static const Color brandNavy = Color(0xFF172554);
  static const Color brandBlue = Color(0xFF2563EB);
  static const Color brandSky = Color(0xFF0EA5E9);

  // Primary Action Color (Cobalt / Electric Blue)
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryHover = Color(0xFF1D4ED8);
  static const Color primaryDark = Color(0xFF172554);
  static const Color primaryLight = Color(0xFF0EA5E9);
  static const Color primarySoft = Color(0xFFEFF6FF);
  static const Color primarySoftHover = Color(0xFFDBEAFE);

  // Deep Navy Branding Accents
  static const Color deepNavy = Color(0xFF172554);
  static const Color deepNavySoft = Color(0xFF1E293B);

  // Sky Blue / Electric Accent
  static const Color electricBlue = Color(0xFF0EA5E9);
  static const Color electricSoft = Color(0xFFF0F9FF);
  static const Color electricBorder = Color(0xFFBAE6FD);

  // Status & Icon Accents (Rare, meaningful chips and badges)
  static const Color accentViolet = Color(0xFF7C3AED);
  static const Color violetSoft = Color(0xFFF5F3FF);
  static const Color violetBorder = Color(0xFFDDD6FE);

  static const Color accentEmerald = Color(0xFF10B981);
  static const Color emeraldSoft = Color(0xFFECFDF5);
  static const Color emeraldBorder = Color(0xFFA7F3D0);

  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color amberSoft = Color(0xFFFFFBEB);
  static const Color amberBorder = Color(0xFFFDE68A);

  static const Color accentCoral = Color(0xFFF97316);
  static const Color coralSoft = Color(0xFFFFF7ED);
  static const Color coralBorder = Color(0xFFFED7AA);

  // Semantic Status Aliases
  static const Color paid = Color(0xFF10B981);
  static const Color paidSoft = Color(0xFFECFDF5);
  static const Color paidBorder = Color(0xFFA7F3D0);

  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color successBorder = Color(0xFFA7F3D0);

  static const Color pending = Color(0xFFF59E0B);
  static const Color pendingSoft = Color(0xFFFFFBEB);
  static const Color pendingBorder = Color(0xFFFDE68A);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color warningBorder = Color(0xFFFDE68A);

  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);

  static const Color info = Color(0xFF0EA5E9);
  static const Color infoSoft = Color(0xFFF0F9FF);
  static const Color infoBorder = Color(0xFFBAE6FD);

  // Legacy Non-Purple Aliases (Gracefully mapped to modern accents)
  static const Color premiumViolet = Color(0xFF7C3AED);
  static const Color purpleAccent = Color(0xFF7C3AED);
  static const Color purpleSoft = Color(0xFFF5F3FF);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color warmAmber = Color(0xFFF59E0B);
  static const Color amberAccent = Color(0xFFF59E0B);
  static const Color amberLight = Color(0xFFFBBF24);
  static const Color coral = Color(0xFFF97316);

  // Slate High-Contrast Typography
  static const Color textPrimary = Color(0xFF111827); // #111827
  static const Color textSecondary = Color(0xFF64748B); // #64748B
  static const Color textMuted = Color(0xFF94A3B8); // #94A3B8
  static const Color textWhite = Color(0xFFFFFFFF);

  // Neutral Fill
  static const Color slateLight = Color(0xFFE2E8F0);

  // Signature 2px Gradient Hairline
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF172554), Color(0xFF2563EB), Color(0xFF0EA5E9)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
