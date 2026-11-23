import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/text_styles.dart';

class CountCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;

  const CountCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? GoviColors.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GoviSpacing.radiusMd),
        side: BorderSide(color: GoviColors.divider),
      ),
      color: GoviColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(GoviSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoviTextStyles.caption.copyWith(
                      color: GoviColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(GoviSpacing.xs),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                  ),
                  child: Icon(icon, color: themeColor, size: 20),
                ),
              ],
            ),
            const SizedBox(height: GoviSpacing.xs),
            Text(
              value,
              style: GoviTextStyles.heading1.copyWith(
                color: themeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: GoviSpacing.xxs),
              Text(
                subtitle!,
                style: GoviTextStyles.caption.copyWith(color: GoviColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
