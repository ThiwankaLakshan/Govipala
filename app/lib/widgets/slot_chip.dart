import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Slot Chip for selecting availability time blocks (06_UI_UX_GUIDE.md Section 4)
class SlotChip extends StatelessWidget {
  final String timeRange;
  final bool isSelected;
  final bool isAvailable;
  final VoidCallback? onSelected;

  const SlotChip({
    super.key,
    required this.timeRange,
    required this.isSelected,
    this.isAvailable = true,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = !isAvailable
        ? GoviColors.border.withAlpha(128)
        : isSelected
            ? GoviColors.primary
            : GoviColors.surface;

    final Color textColor = !isAvailable
        ? GoviColors.textSecondary
        : isSelected
            ? Colors.white
            : GoviColors.textPrimary;

    final Color borderColor = isSelected
        ? GoviColors.primary
        : GoviColors.border;

    return InkWell(
      onTap: isAvailable ? onSelected : null,
      borderRadius: BorderRadius.circular(GoviSpacing.buttonRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(GoviSpacing.buttonRadius),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 16.0,
              color: textColor,
            ),
            const SizedBox(width: GoviSpacing.xs),
            Text(
              timeRange,
              style: GoviTextStyles.bodyBold.copyWith(color: textColor, fontSize: 14.0),
            ),
          ],
        ),
      ),
    );
  }
}
