import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Professional branded loading indicator and modal loader
class AppLoading extends StatelessWidget {
  final String? message;
  final double size;

  const AppLoading({super.key, this.message, this.size = 32.0});

  /// Displays a non-dismissible modal loading dialog
  static void show(BuildContext context, {String message = "Processing..."}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(80),
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Dialog(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.l),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28.0,
                vertical: 24.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.8,
                      color: AppColors.primary,
                    ),
                  ),
                  AppSpacing.gapHl,
                  Flexible(
                    child: Text(
                      message,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Closes the modal loading dialog
  static void hide(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 2.8,
              color: AppColors.primary,
            ),
          ),
          if (message != null) ...[
            AppSpacing.gapVm,
            Text(
              message!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
