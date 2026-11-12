import 'package:flutter/material.dart';

/// Centralized spacing system for Shree Shakti Electric
abstract class AppSpacing {
  // Numeric Constants
  static const double xxxs = 2.0;
  static const double xxs = 4.0;
  static const double xs = 6.0;
  static const double s = 8.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double xxxxl = 40.0;
  static const double huge = 48.0;

  // Vertical Gaps
  static const SizedBox gapVxxs = SizedBox(height: xxs);
  static const SizedBox gapVxs = SizedBox(height: xs);
  static const SizedBox gapVs = SizedBox(height: s);
  static const SizedBox gapVm = SizedBox(height: m);
  static const SizedBox gapVl = SizedBox(height: l);
  static const SizedBox gapVxl = SizedBox(height: xl);
  static const SizedBox gapVxxl = SizedBox(height: xxl);
  static const SizedBox gapVxxxl = SizedBox(height: xxxl);
  static const SizedBox gapVxxxxl = SizedBox(height: xxxxl);

  // Horizontal Gaps
  static const SizedBox gapHxxs = SizedBox(width: xxs);
  static const SizedBox gapHxs = SizedBox(width: xs);
  static const SizedBox gapHs = SizedBox(width: s);
  static const SizedBox gapHm = SizedBox(width: m);
  static const SizedBox gapHl = SizedBox(width: l);
  static const SizedBox gapHxl = SizedBox(width: xl);
  static const SizedBox gapHxxl = SizedBox(width: xxl);
  static const SizedBox gapHxxxl = SizedBox(width: xxxl);

  // Common Padding Presets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 16.0,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(18.0);
  static const EdgeInsets compactCardPadding = EdgeInsets.all(14.0);
  static const EdgeInsets dialogPadding = EdgeInsets.all(24.0);
  static const EdgeInsets modalPadding = EdgeInsets.fromLTRB(
    24.0,
    16.0,
    24.0,
    32.0,
  );
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 15.0,
  );
}
