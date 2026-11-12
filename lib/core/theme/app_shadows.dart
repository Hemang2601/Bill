import 'package:flutter/material.dart';

/// Centralized shadow system for Shree Shakti Electric
/// Premium White Edition:
/// Subtle ambient shadows and delicate glows tailored for crisp white surfaces.
abstract class AppShadows {
  // Resting card shadow
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color.fromRGBO(17, 24, 39, 0.04),
      blurRadius: 10,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color.fromRGBO(17, 24, 39, 0.02),
      blurRadius: 4,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  // Hover or interactive elevation
  static const List<BoxShadow> hover = [
    BoxShadow(
      color: Color.fromRGBO(17, 24, 39, 0.08),
      blurRadius: 18,
      offset: Offset(0, 6),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color.fromRGBO(37, 99, 235, 0.06),
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // Elevated dialogs and bottom sheets
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color.fromRGBO(17, 24, 39, 0.12),
      blurRadius: 32,
      offset: Offset(0, 12),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color.fromRGBO(37, 99, 235, 0.05),
      blurRadius: 12,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // Primary Electric Blue soft button glow
  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color.fromRGBO(37, 99, 235, 0.25),
      blurRadius: 14,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // Electrical Amber / Gold glow
  static const List<BoxShadow> amberGlow = [
    BoxShadow(
      color: Color.fromRGBO(245, 158, 11, 0.25),
      blurRadius: 14,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // Top bar / bottom bar subtle divider shadows
  static const List<BoxShadow> barBottom = [
    BoxShadow(
      color: Color.fromRGBO(17, 24, 39, 0.04),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> barTop = [
    BoxShadow(
      color: Color.fromRGBO(17, 24, 39, 0.05),
      blurRadius: 12,
      offset: Offset(0, -3),
    ),
  ];
}
