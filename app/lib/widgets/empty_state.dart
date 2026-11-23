import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'govi_button.dart';

/// Friendly Empty State (06_UI_UX_GUIDE.md Section 2.5)
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GoviSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(GoviSpacing.lg),
              decoration: BoxDecoration(
                color: GoviColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48.0, color: GoviColors.primary),
            ),
            const SizedBox(height: GoviSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoviTextStyles.sectionTitle,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: GoviSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: GoviTextStyles.caption,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: GoviSpacing.xl),
              GoviButton(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
