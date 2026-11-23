import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

enum GoviButtonVariant { primary, outlined, danger }

/// Big thumb-friendly button with icon and Sinhala label (06_UI_UX_GUIDE.md Section 1 & 2.4)
class GoviButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final GoviButtonVariant variant;

  const GoviButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.variant = GoviButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == GoviButtonVariant.outlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: _buildChild(GoviColors.primary),
      );
    }

    final Color bgColor = variant == GoviButtonVariant.danger
        ? GoviColors.danger
        : GoviColors.primary;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
      ),
      onPressed: isLoading ? null : onPressed,
      child: _buildChild(Colors.white),
    );
  }

  Widget _buildChild(Color textColor) {
    if (isLoading) {
      return const SizedBox(
        width: 24.0,
        height: 24.0,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20.0, color: textColor),
          const SizedBox(width: GoviSpacing.sm),
          Text(label, style: GoviTextStyles.buttonText.copyWith(color: textColor)),
        ],
      );
    }

    return Text(label, style: GoviTextStyles.buttonText.copyWith(color: textColor));
  }
}
