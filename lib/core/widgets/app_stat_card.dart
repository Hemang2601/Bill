import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';
import 'animated_count_text.dart';

/// Professional metric card with icon badge, animated count, and status badge
class AppStatCard extends StatelessWidget {
  final String title;
  final num value;
  final bool isCurrency;
  final bool showDecimals;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeBgColor;
  final VoidCallback? onTap;

  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    this.isCurrency = false,
    this.showDecimals = false,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    this.badgeText,
    this.badgeColor,
    this.badgeBgColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    final effectiveIconBgColor = iconBgColor ?? AppColors.primarySoft;

    return AppCard(
      onTap: onTap,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: effectiveIconBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: effectiveIconColor.withAlpha(35),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(icon, color: effectiveIconColor, size: 22),
                ),
              ),
              if (badgeText != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBgColor ?? AppColors.successSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (badgeColor ?? AppColors.success).withAlpha(40),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      badgeText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelCaps.copyWith(
                        color: badgeColor ?? AppColors.success,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          AppSpacing.gapVm,
          Text(
            title.toUpperCase(),
            style: AppTypography.labelCaps.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.gapVxs,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedCountText(
              value: value,
              isCurrency: isCurrency,
              showDecimals: showDecimals,
              style: AppTypography.currencyLarge.copyWith(
                color: AppColors.textPrimary,
                fontSize: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
