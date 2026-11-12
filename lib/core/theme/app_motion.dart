import 'package:flutter/material.dart';

/// Centralized motion tokens and animation helpers for Shree Shakti Electric
/// Strictly implements the Luxury White Motion System:
/// - Fast (150ms), Base (250ms), Slow (400ms), Hero (600ms)
/// - easeOutCubic (entrances), easeInOutCubic (state changes), easeOutBack (small pops)
/// - Automatic support for reduced motion (MediaQuery.disableAnimations)
abstract class AppMotion {
  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration hero = Duration(milliseconds: 600);

  // Curves
  static const Curve curveEntrance = Curves.easeOutCubic;
  static const Curve curveState = Curves.easeInOutCubic;
  static const Curve curvePop = Curves.easeOutBack;

  /// Checks if reduced motion is preferred by the operating system or accessibility settings
  static bool isReduceMotion(BuildContext context) {
    try {
      return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Returns Duration.zero if reduced motion is requested, else returns the target duration
  static Duration duration(BuildContext context, Duration target) {
    return isReduceMotion(context) ? Duration.zero : target;
  }
}

/// A lightweight, performance-focused entrance widget that fades and slides up 16px.
class AppMotionEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slideOffset;

  const AppMotionEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.slow,
    this.slideOffset = 16.0,
  });

  @override
  State<AppMotionEntrance> createState() => _AppMotionEntranceState();
}

class _AppMotionEntranceState extends State<AppMotionEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.curveEntrance,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: Offset(0, widget.slideOffset / 100),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _controller, curve: AppMotion.curveEntrance),
        );

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReduceMotion(context)) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
