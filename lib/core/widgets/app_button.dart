import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../theme/app_shadows.dart';

enum AppButtonVariant { primary, secondary, outline, danger, ghost, amber }

enum AppButtonSize { small, medium, large }

/// Modern, accessible interactive button with hover/press/focus states, keyboard support, and loading indicator
/// Premium White Edition: Clean white surfaces, primary blue highlights, subtle shadows
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isIconTrailing;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final String? tooltip;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isIconTrailing = false,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.tooltip,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;

    // Dimensions based on size
    final double height = switch (widget.size) {
      AppButtonSize.small => 38.0,
      AppButtonSize.medium => 48.0,
      AppButtonSize.large => 54.0,
    };

    final EdgeInsets padding = switch (widget.size) {
      AppButtonSize.small => const EdgeInsets.symmetric(horizontal: 14.0),
      AppButtonSize.medium => const EdgeInsets.symmetric(horizontal: 20.0),
      AppButtonSize.large => const EdgeInsets.symmetric(horizontal: 24.0),
    };

    final double iconSize = switch (widget.size) {
      AppButtonSize.small => 16.0,
      AppButtonSize.medium => 18.0,
      AppButtonSize.large => 20.0,
    };

    // Color attributes based on variant
    Color backgroundColor;
    Color foregroundColor;
    Border? border;
    List<BoxShadow>? shadows;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        backgroundColor = isDisabled
            ? AppColors.primary.withAlpha(120)
            : (_isHovered ? AppColors.primaryHover : AppColors.primary);
        foregroundColor = AppColors.textWhite;
        shadows = isDisabled
            ? null
            : (_isFocused
                  ? [
                      ...AppShadows.primaryGlow,
                      const BoxShadow(
                        color: AppColors.borderFocus,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : AppShadows.primaryGlow);
        if (_isFocused) {
          border = Border.all(color: AppColors.primaryDark, width: 2.0);
        }
        break;

      case AppButtonVariant.secondary:
        backgroundColor = isDisabled
            ? AppColors.primarySoft.withAlpha(150)
            : (_isHovered ? AppColors.primarySoftHover : AppColors.primarySoft);
        foregroundColor = AppColors.primary;
        border = Border.all(color: AppColors.border, width: 1.0);
        if (_isFocused) {
          border = Border.all(color: AppColors.borderFocus, width: 2.0);
        }
        break;

      case AppButtonVariant.outline:
        backgroundColor = _isHovered
            ? AppColors.surfaceSubtle
            : AppColors.surface;
        foregroundColor = isDisabled
            ? AppColors.textMuted
            : AppColors.textPrimary;
        border = Border.all(
          color: _isFocused
              ? AppColors.borderFocus
              : (_isHovered ? AppColors.borderHover : AppColors.border),
          width: _isFocused ? 2.0 : 1.2,
        );
        shadows = AppShadows.card;
        break;

      case AppButtonVariant.amber:
        backgroundColor = isDisabled
            ? AppColors.amberAccent.withAlpha(120)
            : (_isHovered ? AppColors.amberLight : AppColors.amberAccent);
        foregroundColor = AppColors.textWhite;
        shadows = isDisabled
            ? null
            : (_isFocused
                  ? [
                      ...AppShadows.amberGlow,
                      const BoxShadow(
                        color: AppColors.amberLight,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : AppShadows.amberGlow);
        if (_isFocused) {
          border = Border.all(color: AppColors.amberLight, width: 2.0);
        }
        break;

      case AppButtonVariant.danger:
        backgroundColor = isDisabled
            ? AppColors.danger.withAlpha(120)
            : (_isHovered ? const Color(0xFFB91C1C) : AppColors.danger);
        foregroundColor = AppColors.textWhite;
        if (_isFocused) {
          border = Border.all(color: AppColors.textWhite, width: 2.0);
        }
        break;

      case AppButtonVariant.ghost:
        backgroundColor = _isHovered
            ? AppColors.surfaceMuted
            : Colors.transparent;
        foregroundColor = isDisabled
            ? AppColors.textMuted
            : AppColors.textPrimary;
        if (_isFocused) {
          border = Border.all(color: AppColors.borderFocus, width: 1.5);
        }
        break;
    }

    Widget content = Row(
      mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.icon != null && !widget.isIconTrailing) ...[
          Icon(widget.icon, size: iconSize, color: foregroundColor),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style:
                (widget.size == AppButtonSize.small
                        ? AppTypography.labelMedium
                        : AppTypography.labelLarge)
                    .copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                    ),
          ),
        ),
        if (!widget.isLoading &&
            widget.icon != null &&
            widget.isIconTrailing) ...[
          const SizedBox(width: 8),
          Icon(widget.icon, size: iconSize, color: foregroundColor),
        ],
      ],
    );

    Widget button = FocusableActionDetector(
      enabled: !isDisabled,
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onPressed?.call(),
        ),
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          scale: _scaleAnimation.value,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: height,
            width:
                widget.width ?? (widget.isFullWidth ? double.infinity : null),
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppRadius.m,
              border: border,
              boxShadow: shadows,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isDisabled ? null : widget.onPressed,
                borderRadius: AppRadius.m,
                hoverColor: Colors.transparent,
                splashColor: Colors.white.withAlpha(30),
                highlightColor: Colors.transparent,
                child: Center(
                  widthFactor: widget.isFullWidth ? null : 1.0,
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}

/// Compact circular or rounded icon-only button with hover feedback
class AppIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;
  final Border? border;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.border,
  });

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;
    final fg = isDisabled
        ? AppColors.textMuted
        : (widget.color ?? AppColors.textPrimary);
    final bg =
        widget.backgroundColor ??
        (_isHovered ? AppColors.surfaceMuted : Colors.transparent);

    Widget btn = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.size / 3.2),
          border: widget.border,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(widget.size / 3.2),
            child: Center(
              child: Icon(widget.icon, size: widget.iconSize, color: fg),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      btn = Tooltip(message: widget.tooltip!, child: btn);
    }

    return btn;
  }
}
