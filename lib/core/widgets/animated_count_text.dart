import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

/// Smooth, native number-counting animation widget for financial statistics
class AnimatedCountText extends ImplicitlyAnimatedWidget {
  final num value;
  final TextStyle? style;
  final bool isCurrency;
  final bool showDecimals;
  final String prefix;
  final String suffix;

  const AnimatedCountText({
    super.key,
    required this.value,
    this.style,
    this.isCurrency = false,
    this.showDecimals = false,
    this.prefix = '',
    this.suffix = '',
    super.duration = const Duration(milliseconds: 600),
    super.curve = Curves.easeOutCubic,
  });

  @override
  AnimatedWidgetBaseState<AnimatedCountText> createState() =>
      _AnimatedCountTextState();
}

class _AnimatedCountTextState
    extends AnimatedWidgetBaseState<AnimatedCountText> {
  Tween<double>? _countTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _countTween =
        visitor(
              _countTween,
              widget.value.toDouble(),
              (dynamic value) =>
                  Tween<double>(begin: (value as num).toDouble()),
            )
            as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final double currentValue =
        _countTween?.evaluate(animation) ?? widget.value.toDouble();

    String formatted;
    if (widget.isCurrency) {
      formatted = CurrencyFormatter.format(
        currentValue,
        showDecimals: widget.showDecimals,
      );
    } else {
      formatted = CurrencyFormatter.formatRaw(
        currentValue,
        showDecimals: widget.showDecimals,
      );
    }

    return Text(
      '${widget.prefix}$formatted${widget.suffix}',
      style: widget.style,
    );
  }
}
