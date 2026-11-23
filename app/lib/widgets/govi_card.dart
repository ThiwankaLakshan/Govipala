import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// Standard Govipala Card: elevation 0, 1px border, 16px radius (06_UI_UX_GUIDE.md Section 2.4)
class GoviCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const GoviCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(GoviSpacing.lg),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      decoration: BoxDecoration(
        color: GoviColors.surface,
        borderRadius: BorderRadius.circular(GoviSpacing.cardRadius),
        border: Border.all(color: GoviColors.border, width: 1.0),
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GoviSpacing.cardRadius),
        child: cardContent,
      );
    }

    return cardContent;
  }
}
