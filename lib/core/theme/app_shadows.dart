import 'package:flutter/material.dart';

/// Luxury White shadow system for Shree Shakti Electric
/// All shadows are navy-tinted (0x172554) with low opacity:
/// - sm: 0 1px 2px rgba(23,37,84,.04)
/// - md: 0 4px 12px rgba(23,37,84,.06)
/// - lg: 0 12px 32px rgba(23,37,84,.10)
abstract class AppShadows {
  static const Color _navy = Color(0xFF172554);

  // sm: 0 1px 2px rgba(23,37,84,.04)
  static final List<BoxShadow> sm = [
    BoxShadow(
      color: _navy.withValues(alpha: 0.04),
      blurRadius: 2,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  // md: 0 4px 12px rgba(23,37,84,.06)
  static final List<BoxShadow> md = [
    BoxShadow(
      color: _navy.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // lg: 0 12px 32px rgba(23,37,84,.10)
  static final List<BoxShadow> lg = [
    BoxShadow(
      color: _navy.withValues(alpha: 0.10),
      blurRadius: 32,
      offset: const Offset(0, 12),
      spreadRadius: 0,
    ),
  ];

  // Aliases for backward compatibility
  static List<BoxShadow> get card => sm;
  static List<BoxShadow> get hover => md;
  static List<BoxShadow> get elevated => lg;

  // Primary brand subtle glow for key CTAs
  static final List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: const Color(0xFF2563EB).withValues(alpha: 0.18),
      blurRadius: 14,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // Amber accent subtle glow
  static final List<BoxShadow> amberGlow = [
    BoxShadow(
      color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
      blurRadius: 14,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // Subtle border hairline shadows for bars
  static final List<BoxShadow> barBottom = [
    BoxShadow(
      color: _navy.withValues(alpha: 0.03),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> barTop = [
    BoxShadow(
      color: _navy.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, -3),
    ),
  ];
}
