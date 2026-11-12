import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../theme/app_shadows.dart';

enum AppNotificationType { success, error, warning, info }

/// Reusable enterprise notification & toast system for Shree Shakti Electric
abstract class AppNotification {
  /// Displays a floating, styled notification banner
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null) return;

    scaffoldMessenger.hideCurrentSnackBar();

    Color iconBg;
    Color iconFg;
    Color borderColor;
    IconData iconData;

    switch (type) {
      case AppNotificationType.success:
        iconBg = AppColors.successSoft;
        iconFg = AppColors.success;
        borderColor = AppColors.success.withAlpha(70);
        iconData = Icons.check_circle_rounded;
        break;
      case AppNotificationType.error:
        iconBg = AppColors.dangerSoft;
        iconFg = AppColors.danger;
        borderColor = AppColors.danger.withAlpha(70);
        iconData = Icons.error_rounded;
        break;
      case AppNotificationType.warning:
        iconBg = AppColors.warningSoft;
        iconFg = AppColors.warning;
        borderColor = AppColors.warning.withAlpha(70);
        iconData = Icons.warning_amber_rounded;
        break;
      case AppNotificationType.info:
        iconBg = AppColors.primarySoft;
        iconFg = AppColors.primary;
        borderColor = AppColors.primary.withAlpha(70);
        iconData = Icons.info_rounded;
        break;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        duration: type == AppNotificationType.error
            ? const Duration(seconds: 4)
            : duration,
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.symmetric(
          horizontal: isDesktop ? (screenWidth - 480) / 2 : 16.0,
          vertical: 16.0,
        ),
        content: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.m,
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: AppShadows.hover,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Icon(iconData, color: iconFg, size: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null && title.isNotEmpty)
                      Text(
                        title,
                        style: AppTypography.headingSmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    Text(
                      message,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    scaffoldMessenger.hideCurrentSnackBar();
                    onAction();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: iconFg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => scaffoldMessenger.hideCurrentSnackBar(),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Convenience helper for success notifications
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Convenience helper for error notifications
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.error,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// Convenience helper for warning notifications
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Convenience helper for info notifications
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
}
