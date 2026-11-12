import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// Clean, elevated white card component designed for modern financial software
class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final bool enableHover;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.enableHover = true,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? AppRadius.l;
    final isClickable = widget.onTap != null;

    final cardWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.surface,
        borderRadius: borderRadius,
        border: Border.all(
          color:
              widget.borderColor ??
              (_isHovered && isClickable
                  ? AppColors.primary.withAlpha(120)
                  : AppColors.border),
          width: 1.0,
        ),
        boxShadow: _isHovered && widget.enableHover
            ? AppShadows.hover
            : AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: borderRadius,
          hoverColor: Colors.transparent,
          splashColor: AppColors.primarySoft.withAlpha(100),
          highlightColor: Colors.transparent,
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );

    if (!widget.enableHover && !isClickable) {
      return cardWidget;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: cardWidget,
    );
  }
}
