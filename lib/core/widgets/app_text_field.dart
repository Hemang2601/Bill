import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Enterprise-styled text input field with animated focus states and clean validation
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool isPassword;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final int maxLines;
  final int? maxLength;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffix,
    this.isPassword = false,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured;
  late final FocusNode _internalFocusNode;
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _obscured = widget.isPassword;
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    } else {
      _internalFocusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (_isFocused != _internalFocusNode.hasFocus) {
      setState(() => _isFocused = _internalFocusNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.labelMedium.copyWith(
              color: _isFocused ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapVxs,
        ],
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: widget.enabled
                  ? AppColors.surface
                  : AppColors.surfaceSubtle,
              borderRadius: AppRadius.m,
              border: Border.all(
                color: widget.errorText != null
                    ? AppColors.danger
                    : (_isFocused
                          ? AppColors.primary
                          : (_isHovered && widget.enabled
                                ? AppColors.borderHover
                                : AppColors.border)),
                width: _isFocused ? 1.6 : 1.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _internalFocusNode,
              obscureText: _obscured,
              readOnly: widget.readOnly,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              inputFormatters: widget.inputFormatters,
              validator: widget.validator,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onSubmitted,
              onTap: widget.onTap,
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              style: AppTypography.bodyMedium.copyWith(
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                filled: false,
                fillColor: Colors.transparent,
                hintText: widget.hint,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
                counterText: "",
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 14.0,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        size: 20,
                        color: _isFocused
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      )
                    : null,
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          _obscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () => setState(() => _obscured = !_obscured),
                      )
                    : widget.suffix,
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          AppSpacing.gapVxxs,
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              widget.errorText!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.danger,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ] else if (widget.helperText != null) ...[
          AppSpacing.gapVxxs,
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              widget.helperText!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
