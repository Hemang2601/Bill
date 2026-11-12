import 'package:flutter/material.dart';

/// Centralized border radius system for Shree Shakti Electric
/// Uses clean, moderate curvatures avoiding overly bulky or cartoonish rounded cards.
abstract class AppRadius {
  // Numeric Radius values
  static const double xsVal = 6.0;
  static const double sVal = 8.0;
  static const double mVal = 12.0;
  static const double lVal = 16.0;
  static const double xlVal = 20.0;
  static const double xxlVal = 24.0;
  static const double modalVal = 28.0;
  static const double fullVal = 999.0;

  // BorderRadius objects
  static const BorderRadius xs = BorderRadius.all(Radius.circular(xsVal));
  static const BorderRadius s = BorderRadius.all(Radius.circular(sVal));
  static const BorderRadius m = BorderRadius.all(Radius.circular(mVal));
  static const BorderRadius l = BorderRadius.all(Radius.circular(lVal));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(xlVal));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(xxlVal));
  static const BorderRadius full = BorderRadius.all(Radius.circular(fullVal));

  // Top/Modal specific
  static const BorderRadius modalTop = BorderRadius.vertical(
    top: Radius.circular(modalVal),
  );
  static const BorderRadius cardTop = BorderRadius.vertical(
    top: Radius.circular(lVal),
  );
  static const BorderRadius cardBottom = BorderRadius.vertical(
    bottom: Radius.circular(lVal),
  );
}
