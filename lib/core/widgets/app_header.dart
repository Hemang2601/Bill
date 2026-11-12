import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_shadows.dart';

/// Professional, unified Top Application Header for Shree Shakti Electric Service
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final bool showLeadingLogo;
  final bool showBackButton;
  final bool showDrawerButton;
  final String? backTooltip;
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
    this.showDrawerButton = false,
    this.backTooltip,
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
    Widget? leadingWidget;
    if (showBackButton) {
      leadingWidget = IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textPrimary,
        ),
        tooltip: backTooltip ?? "Back",
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      );
    } else if (showDrawerButton) {
      leadingWidget = Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
          tooltip: "Menu",
          onPressed: onMenuTap ?? () => Scaffold.of(ctx).openDrawer(),
        ),
      );
    }

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      leading: leadingWidget,
      title: Row(
        children: [
          if (showLeadingLogo && !showBackButton && !showDrawerButton) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF0284C7)],
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
                  size: 20,
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
                if (title != null)
                  Text(
                    title!,
                    style: AppTypography.headingSmall.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: AppTypography.labelCaps.copyWith(
                      fontSize: 9.5,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: bottom != null
          ? PreferredSize(
              preferredSize: bottom!.preferredSize,
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1.0),
                  ),
                ),
                child: bottom!,
              ),
            )
          : null,
    );
  }
}
