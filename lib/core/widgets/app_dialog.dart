import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../utils/app_responsive.dart';
import '../utils/currency_formatter.dart';
import 'app_button.dart';

enum DialogIconType { info, success, warning, danger, logout }

/// Professional modal dialog and bottom-sheet helpers with smooth entrance transitions and keyboard accessibility
abstract class AppDialog {
  /// Displays a customized, animated confirmation dialog with keyboard shortcuts (Escape = Cancel, Enter = Confirm)
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = "CONFIRM",
    String cancelLabel = "CANCEL",
    DialogIconType iconType = DialogIconType.warning,
    bool isDestructive = false,
    String? highlightPill,
    IconData? confirmIcon,
    IconData? cancelIcon,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dialog",
      barrierColor: Colors.black.withAlpha(120),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curvedValue = Curves.easeOutBack.transform(anim1.value);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5 * anim1.value,
            sigmaY: 5 * anim1.value,
          ),
          child: Transform.scale(
            scale: 0.9 + (0.1 * curvedValue),
            child: Opacity(
              opacity: anim1.value.clamp(0.0, 1.0),
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape): () {
                    if (Navigator.of(ctx).canPop()) {
                      Navigator.of(ctx).pop(false);
                    }
                  },
                },
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppResponsive.maxDialogWidth,
                    ),
                    child: Dialog(
                      backgroundColor: AppColors.surface,
                      surfaceTintColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.xxl,
                      ),
                      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildIconBadge(iconType),
                                AppSpacing.gapVl,
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.headingLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                if (highlightPill != null) ...[
                                  AppSpacing.gapVs,
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPillBg(iconType),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _getPillFg(
                                          iconType,
                                        ).withAlpha(50),
                                      ),
                                    ),
                                    child: Text(
                                      highlightPill,
                                      style: AppTypography.labelCaps.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: _getPillFg(iconType),
                                      ),
                                    ),
                                  ),
                                ],
                                AppSpacing.gapVs,
                                Text(
                                  message,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                                AppSpacing.gapVxxl,
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppButton(
                                        label: cancelLabel,
                                        icon: cancelIcon,
                                        variant: AppButtonVariant.outline,
                                        size: AppButtonSize.medium,
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                      ),
                                    ),
                                    AppSpacing.gapHm,
                                    Expanded(
                                      child: AppButton(
                                        label: confirmLabel,
                                        icon: confirmIcon,
                                        variant: isDestructive
                                            ? AppButtonVariant.danger
                                            : AppButtonVariant.primary,
                                        size: AppButtonSize.medium,
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: AppColors.textMuted,
                              ),
                              tooltip: "Close",
                              splashRadius: 18,
                              onPressed: () => Navigator.of(ctx).pop(false),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Specialized helper for confirming invoice deletion
  static Future<bool?> showDeleteInvoiceConfirmation({
    required BuildContext context,
    required String billNumber,
    String? customerName,
  }) {
    final customerPart =
        (customerName != null &&
            customerName.isNotEmpty &&
            customerName != "CASH CUSTOMER")
        ? " for $customerName"
        : "";
    return showConfirmation(
      context: context,
      title: "Delete Invoice?",
      highlightPill: "Permanent Deletion",
      message:
          "Are you sure you want to permanently delete invoice #$billNumber$customerPart? This will erase the SQLite record and associated PDF file.",
      confirmLabel: "DELETE INVOICE",
      cancelLabel: "CANCEL",
      iconType: DialogIconType.danger,
      confirmIcon: Icons.delete_forever_rounded,
      cancelIcon: Icons.close_rounded,
      isDestructive: true,
    );
  }

  /// Specialized helper for discarding unsaved changes
  static Future<bool?> showDiscardChangesConfirmation({
    required BuildContext context,
    String title = "Discard Invoice?",
    String? message,
    String confirmLabel = "DISCARD",
    String cancelLabel = "KEEP EDITING",
  }) {
    return showConfirmation(
      context: context,
      title: title,
      highlightPill: "Unsaved Changes",
      message:
          message ??
          "You have unsaved changes. Leaving now will discard all modifications and preserve the original records.",
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      iconType: DialogIconType.warning,
      confirmIcon: Icons.delete_sweep_rounded,
      cancelIcon: Icons.edit_rounded,
      isDestructive: true,
    );
  }

  /// Specialized helper for logging out
  static Future<bool?> showLogoutConfirmation({
    required BuildContext context,
    String? userName,
    String cancelLabel = "CANCEL",
  }) {
    final namePart = userName != null && userName.isNotEmpty
        ? " ($userName)"
        : "";
    return showConfirmation(
      context: context,
      title: "Sign Out",
      highlightPill: "Manager Session",
      message:
          "Are you sure you want to sign out of your manager session$namePart?",
      confirmLabel: "SIGN OUT",
      cancelLabel: cancelLabel,
      iconType: DialogIconType.logout,
      confirmIcon: Icons.logout_rounded,
      cancelIcon: Icons.close_rounded,
      isDestructive: true,
    );
  }

  /// Specialized helper for notifying of missing PDF file
  static Future<bool?> showMissingPdfDialog({
    required BuildContext context,
    required String billNumber,
    VoidCallback? onRegenerate,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "MissingPdf",
      barrierColor: Colors.black.withAlpha(100),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 4 * anim1.value,
            sigmaY: 4 * anim1.value,
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppResponsive.maxDialogWidth,
                ),
                child: Dialog(
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.xxl,
                  ),
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Padding(
                    padding: AppSpacing.dialogPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIconBadge(DialogIconType.warning),
                        AppSpacing.gapVl,
                        Text(
                          "PDF File Missing",
                          style: AppTypography.headingLarge,
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.gapVs,
                        Text(
                          "The PDF document for Invoice #$billNumber was moved, deleted, or cannot be accessed on this device.",
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.gapVxxl,
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: "CLOSE",
                                variant: AppButtonVariant.outline,
                                onPressed: () => Navigator.of(ctx).pop(false),
                              ),
                            ),
                            if (onRegenerate != null) ...[
                              AppSpacing.gapHm,
                              Expanded(
                                child: AppButton(
                                  label: "REGENERATE",
                                  variant: AppButtonVariant.primary,
                                  onPressed: () {
                                    Navigator.of(ctx).pop(true);
                                    onRegenerate();
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Unified, enterprise modal dialog for invoice generation & update success
  static Future<void> showInvoiceSuccessDialog({
    required BuildContext context,
    required String billNumber,
    required double totalAmount,
    required File pdfFile,
    required Uint8List pdfBytes,
    required bool isNewInvoice,
    VoidCallback? onCreateAnother,
    required VoidCallback onFinish,
  }) {
    return showCustomDialog(
      context: context,
      barrierDismissible: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.success.withAlpha(50),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 36,
              ),
            ),
            AppSpacing.gapVl,
            Text(
              isNewInvoice
                  ? "Invoice Generated Successfully!"
                  : "Invoice Updated Successfully!",
              style: AppTypography.headingMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapVs,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                billNumber,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            AppSpacing.gapVm,
            Text(
              isNewInvoice
                  ? "PDF saved and SQLite database record created.\nTotal Amount: ${CurrencyFormatter.format(totalAmount)}"
                  : "PDF and SQLite records updated.\nNew Total: ${CurrencyFormatter.format(totalAmount)}",
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapVxl,
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: "SHARE PDF",
                    icon: Icons.share_rounded,
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.medium,
                    onPressed: () {
                      Share.shareXFiles(
                        [XFile(pdfFile.path)],
                        text: 'Invoice $billNumber from Shree Shakti Electric',
                      );
                    },
                  ),
                ),
                AppSpacing.gapHm,
                Expanded(
                  child: AppButton(
                    label: "VIEW / PRINT",
                    icon: Icons.print_rounded,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.medium,
                    onPressed: () async {
                      await Printing.layoutPdf(
                        onLayout: (format) async => pdfBytes,
                        name: "Invoice_$billNumber",
                      );
                    },
                  ),
                ),
              ],
            ),
            AppSpacing.gapVm,
            AppButton(
              label: "FINISH & EXIT",
              icon: Icons.dashboard_rounded,
              variant: AppButtonVariant.primary,
              isFullWidth: true,
              onPressed: onFinish,
            ),
            if (onCreateAnother != null) ...[
              AppSpacing.gapVs,
              AppButton(
                label: "CREATE ANOTHER BILL",
                icon: Icons.add_rounded,
                variant: AppButtonVariant.ghost,
                isFullWidth: true,
                size: AppButtonSize.small,
                onPressed: onCreateAnother,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Displays an informative modal sheet or dialog with custom content
  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: "CustomDialog",
      barrierColor: Colors.black.withAlpha(100),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox(),
      transitionBuilder: (ctx, anim1, anim2, _) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 4 * anim1.value,
            sigmaY: 4 * anim1.value,
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: FadeTransition(
              opacity: anim1,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppResponsive.maxDialogWidth,
                  ),
                  child: Dialog(
                    backgroundColor: AppColors.surface,
                    surfaceTintColor: Colors.transparent,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.xxl,
                    ),
                    insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Displays a modern bottom sheet with drag handle and backdrop blur
  static Future<T?> showAppBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.modalTop,
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(25, 17, 24, 39),
                blurRadius: 30,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSpacing.gapVm,
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.slateLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                AppSpacing.gapVs,
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildIconBadge(DialogIconType type) {
    Color bg;
    Color fg;
    IconData icon;

    switch (type) {
      case DialogIconType.info:
        bg = AppColors.primarySoft;
        fg = AppColors.primary;
        icon = Icons.info_outline_rounded;
        break;
      case DialogIconType.logout:
        bg = AppColors.primarySoft;
        fg = AppColors.primary;
        icon = Icons.logout_rounded;
        break;
      case DialogIconType.success:
        bg = AppColors.successSoft;
        fg = AppColors.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case DialogIconType.warning:
        bg = AppColors.warningSoft;
        fg = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case DialogIconType.danger:
        bg = AppColors.dangerSoft;
        fg = AppColors.danger;
        icon = Icons.delete_forever_rounded;
        break;
    }

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: fg.withAlpha(50), width: 2),
        boxShadow: [
          BoxShadow(
            color: fg.withAlpha(25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: Icon(icon, color: fg, size: 34)),
    );
  }

  static Color _getPillBg(DialogIconType type) {
    switch (type) {
      case DialogIconType.info:
      case DialogIconType.logout:
        return AppColors.primarySoft;
      case DialogIconType.success:
        return AppColors.successSoft;
      case DialogIconType.warning:
        return AppColors.warningSoft;
      case DialogIconType.danger:
        return AppColors.dangerSoft;
    }
  }

  static Color _getPillFg(DialogIconType type) {
    switch (type) {
      case DialogIconType.info:
      case DialogIconType.logout:
        return AppColors.primary;
      case DialogIconType.success:
        return AppColors.success;
      case DialogIconType.warning:
        return AppColors.warning;
      case DialogIconType.danger:
        return AppColors.danger;
    }
  }
}
