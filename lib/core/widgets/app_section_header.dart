import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Section header with consistent branding accent bar and optional action link
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  Widget _buildBar() {
    return Container(
      width: 4,
      height: 18,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget? _buildTrailing() {
    if (trailing != null) {
      return trailing;
    }
    if (actionLabel != null && onAction != null) {
      return TextButton(
        onPressed: onAction,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          actionLabel!,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.primaryLight,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.labelCaps.copyWith(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          Text(subtitle!, style: AppTypography.bodySmall),
        ],
      ],
    );

    final trailingWidget = _buildTrailing();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool hasBoundedWidth = constraints.hasBoundedWidth;

          if (hasBoundedWidth) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildBar(),
                AppSpacing.gapHs,
                Expanded(child: titleColumn),
                ?trailingWidget,
              ],
            );
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildBar(),
              AppSpacing.gapHs,
              titleColumn,
              if (trailingWidget != null) ...[AppSpacing.gapHs, trailingWidget],
            ],
          );
        },
      ),
    );
  }
}
