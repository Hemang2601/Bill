import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Luxury White Typography System for Shree Shakti Electric
/// Strictly implements the specification:
/// - Display: 32/40 w700 (letter-spacing -0.5)
/// - H1: 24/32 w700 (letter-spacing -0.4)
/// - H2: 20/28 w600 (letter-spacing -0.3)
/// - Title: 16/24 w600 (letter-spacing -0.2)
/// - Body: 14/22 w400 (line height 1.57)
/// - Caption: 12/16 w500 (line height 1.33)
/// - Overline: 11/16 w600 uppercase (+0.8 tracking)
/// Tabular figures (FontFeature.tabularFigures()) for all money, quantities, and bill numbers.
abstract class AppTypography {
  // Display 32/40 w700 (letter-spacing -0.5)
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 40 / 32,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayLarge = display;

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 36 / 28,
    color: AppColors.textPrimary,
  );

  // H1 24/32 w700
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    height: 32 / 24,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingLarge = h1;

  // H2 20/28 w600
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 28 / 20,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 26 / 18,
    color: AppColors.textPrimary,
  );

  // Title 16/24 w600
  static const TextStyle title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 24 / 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingSmall = title;

  // Body 14/22 w400
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 22 / 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 24 / 15,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = body;

  // Caption 12/16 w500
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = caption;

  // Overline 11/16 w600 uppercase (+0.8 tracking)
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 16 / 11,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelCaps = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
    color: AppColors.textSecondary,
  );

  // Tabular Figures for Money, Quantities, and Bill Numbers
  static const TextStyle currencyDisplay = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 40 / 32,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle currencyLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.primary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle currencyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.primary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle currencySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle tabularQuantity = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle tabularBillNumber = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: AppColors.primary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    color: AppColors.textWhite,
  );
}
