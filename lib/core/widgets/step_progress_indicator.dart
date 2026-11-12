import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Professional, animated 3-step progress indicator for the Invoice Wizard
class StepProgressIndicator extends StatelessWidget {
  final int currentStep; // 0, 1, 2
  final ValueChanged<int>? onStepTapped;

  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    this.onStepTapped,
  });

  static const List<String> _stepTitles = ["Customer", "Items", "Review"];
  static const List<IconData> _stepIcons = [
    Icons.person_rounded,
    Icons.inventory_2_rounded,
    Icons.check_circle_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 400;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 12 : 16,
            vertical: 10,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              for (int i = 0; i < 3; i++) ...[
                _buildStepItem(context, i, isNarrow),
                if (i < 2) _buildConnectingLine(i),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepItem(BuildContext context, int stepIndex, bool isNarrow) {
    final bool isCompleted = stepIndex < currentStep;
    final bool isCurrent = stepIndex == currentStep;

    Color circleColor;
    Color iconColor;
    Color textColor;
    Border? border;

    if (isCompleted) {
      circleColor = AppColors.success;
      iconColor = Colors.white;
      textColor = AppColors.textPrimary;
      border = null;
    } else if (isCurrent) {
      circleColor = AppColors.primary;
      iconColor = Colors.white;
      textColor = AppColors.primary;
      border = Border.all(
        color: AppColors.primaryLight.withAlpha(120),
        width: 2.5,
      );
    } else {
      circleColor = AppColors.surfaceSubtle;
      iconColor = AppColors.textMuted;
      textColor = AppColors.textMuted;
      border = Border.all(color: AppColors.border, width: 1.5);
    }

    final bool isTappable = isCompleted && onStepTapped != null;
    final double circleSize = isNarrow ? 24.0 : 28.0;

    return InkWell(
      onTap: isTappable ? () => onStepTapped!(stepIndex) : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                border: border,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(40),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: isNarrow ? 13 : 15,
                      )
                    : isCurrent
                    ? Icon(
                        _stepIcons[stepIndex],
                        color: iconColor,
                        size: isNarrow ? 12 : 14,
                      )
                    : Text(
                        "${stepIndex + 1}",
                        style: TextStyle(
                          color: iconColor,
                          fontSize: isNarrow ? 10.5 : 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _stepTitles[stepIndex],
              style: AppTypography.labelCaps.copyWith(
                fontSize: isNarrow ? 10 : 11,
                color: textColor,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectingLine(int stepIndex) {
    final bool isCompleted = stepIndex < currentStep;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.success : AppColors.border,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
