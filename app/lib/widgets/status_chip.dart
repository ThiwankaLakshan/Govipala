import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';

/// Status Chip (colour + icon + word) (06_UI_UX_GUIDE.md Section 2.2)
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status.toLowerCase());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: config.color.withAlpha(30),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: config.color.withAlpha(100), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14.0, color: config.color),
          const SizedBox(width: GoviSpacing.xs),
          Text(
            config.label,
            style: GoviTextStyles.caption.copyWith(
              color: config.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'requested':
      case 'pending':
        return _StatusConfig(
          label: 'අනුමැතිය බලාපොරොත්තුවෙන් (Requested)',
          icon: Icons.hourglass_top_rounded,
          color: GoviColors.accent,
        );
      case 'confirmed':
        return _StatusConfig(
          label: 'ස්ථිර කළා (Confirmed)',
          icon: Icons.check_circle_outline_rounded,
          color: GoviColors.primary,
        );
      case 'in_progress':
        return _StatusConfig(
          label: 'ක්‍රියාත්මක වෙමින් (In Progress)',
          icon: Icons.play_circle_outline_rounded,
          color: GoviColors.info,
        );
      case 'completed':
        return _StatusConfig(
          label: 'සම්පූර්ණයි (Completed)',
          icon: Icons.done_all_rounded,
          color: GoviColors.textSecondary,
        );
      case 'rejected':
      case 'cancelled':
        return _StatusConfig(
          label: 'අවලංගුයි (Cancelled)',
          icon: Icons.cancel_outlined,
          color: GoviColors.danger,
        );
      default:
        return _StatusConfig(
          label: status,
          icon: Icons.info_outline_rounded,
          color: GoviColors.textSecondary,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final IconData icon;
  final Color color;

  _StatusConfig({required this.label, required this.icon, required this.color});
}
