import 'package:flutter/material.dart';
import '../models/machine.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'govi_card.dart';

class MachineCard extends StatelessWidget {
  final MachineModel machine;
  final VoidCallback? onTap;
  final Widget? trailing;

  const MachineCard({
    super.key,
    required this.machine,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GoviCard(
      onTap: onTap,
      padding: const EdgeInsets.all(GoviSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Machine type visual thumbnail
              Container(
                width: 60.0,
                height: 60.0,
                decoration: BoxDecoration(
                  color: GoviColors.primarySoft,
                  borderRadius: BorderRadius.circular(GoviSpacing.buttonRadius),
                  border: Border.all(color: GoviColors.border),
                ),
                child: Icon(
                  _getMachineIcon(machine.machineType),
                  color: GoviColors.primary,
                  size: 32.0,
                ),
              ),
              const SizedBox(width: GoviSpacing.md),
              // Brand, model, and drive type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            machine.brand,
                            style: GoviTextStyles.bodyBold.copyWith(fontSize: 18.0),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    ),
                    Text(
                      machine.machineType.sinhalaLabel,
                      style: GoviTextStyles.caption.copyWith(color: GoviColors.primaryDark),
                    ),
                    if (machine.modelName != null && machine.modelName!.isNotEmpty)
                      Text(
                        'මෝඩලය (Model): ${machine.modelName}',
                        style: GoviTextStyles.caption,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GoviSpacing.sm),
          const Divider(height: 1.0, color: GoviColors.border),
          const SizedBox(height: GoviSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Drive Type Chip (only for four-wheel tractors)
              if (machine.machineType == MachineType.fourWheelTractor && machine.driveType != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: GoviColors.primarySoft,
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: GoviColors.primary.withAlpha(60)),
                  ),
                  child: Text(
                    machine.driveType!.value.toUpperCase(),
                    style: GoviTextStyles.caption.copyWith(
                      color: GoviColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),

              // Rate display
              Text(
                machine.formattedRate,
                style: GoviTextStyles.bodyBold.copyWith(color: GoviColors.primary),
              ),
            ],
          ),
          if (machine.serviceGnDivisions.isNotEmpty) ...[
            const SizedBox(height: GoviSpacing.xs),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14.0, color: GoviColors.textSecondary),
                const SizedBox(width: 4.0),
                Expanded(
                  child: Text(
                    'සේවා ප්‍රදේශ: ${machine.serviceGnDivisions.take(3).join(', ')}${machine.serviceGnDivisions.length > 3 ? ' තවත්...' : ''}',
                    style: GoviTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getMachineIcon(MachineType type) {
    switch (type) {
      case MachineType.fourWheelTractor:
        return Icons.agriculture_rounded;
      case MachineType.twoWheelTractor:
        return Icons.precision_manufacturing_rounded;
      case MachineType.combineHarvester:
        return Icons.alt_route_rounded;
      case MachineType.waterPump:
        return Icons.water_drop_rounded;
    }
  }
}
