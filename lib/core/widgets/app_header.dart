import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_shadows.dart';

/// Professional, unified Top Application Header for Shree Shakti Electric
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final bool showLeadingLogo;
  final bool showBackButton;
  final VoidCallback? onBack;
  final VoidCallback? onMenuTap;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  const AppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showLeadingLogo = true,
    this.showBackButton = false,
    this.onBack,
    this.onMenuTap,
    this.actions,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(64.0 + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
              tooltip: "Back",
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Row(
        children: [
          if (showLeadingLogo && !showBackButton) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppShadows.primaryGlow,
              ),
              child: const Center(
                child: Icon(
                  Icons.electric_bolt_rounded,
                  color: AppColors.amberLight,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title ?? "SHREE SHAKTI ELECTRIC",
                  style: AppTypography.headingSmall.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle ?? "Commercial Billing & Management",
                  style: AppTypography.labelCaps.copyWith(
                    fontSize: 9,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (actions != null) ...actions!,
        Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.textPrimary,
              size: 24,
            ),
            tooltip: "Open Navigation Menu",
            onPressed: () {
              if (onMenuTap != null) {
                onMenuTap!();
              } else {
                Scaffold.of(ctx).openDrawer();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
      ],
      bottom: bottom,
      shape: const Border(
        bottom: BorderSide(color: AppColors.border, width: 1.0),
      ),
    );
  }
}
