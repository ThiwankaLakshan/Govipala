import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/text_styles.dart';
import 'status_chip.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isOwnerView;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onStartJob;
  final VoidCallback? onCompleteJob;
  final VoidCallback? onCancel;
  final VoidCallback? onLeaveReview;

  const BookingCard({
    super.key,
    required this.booking,
    this.isOwnerView = false,
    this.onAccept,
    this.onDecline,
    this.onStartJob,
    this.onCompleteJob,
    this.onCancel,
    this.onLeaveReview,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GoviSpacing.cardRadius),
        side: const BorderSide(color: GoviColors.border, width: 1.0),
      ),
      color: GoviColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(GoviSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Machine title + status chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${booking.machineBrand ?? "යන්ත්‍රය"} ${booking.machineModel ?? ""}',
                        style: GoviTextStyles.heading2.copyWith(fontSize: 16),
                      ),
                      if (booking.driveType != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: GoviColors.accent.withAlpha(50),
                            borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                          ),
                          child: Text(
                            booking.driveType!.toUpperCase(),
                            style: GoviTextStyles.caption.copyWith(
                              color: GoviColors.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                StatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: GoviSpacing.sm),

            // Date and time
            Row(
              children: [
                const Icon(Icons.event_rounded, size: 16, color: GoviColors.primary),
                const SizedBox(width: GoviSpacing.xs),
                Text(
                  booking.slotDate ?? 'දින වකවානුව',
                  style: GoviTextStyles.bodyBold.copyWith(fontSize: 14),
                ),
                const SizedBox(width: GoviSpacing.md),
                const Icon(Icons.schedule_rounded, size: 16, color: GoviColors.primary),
                const SizedBox(width: GoviSpacing.xs),
                Text(
                  booking.formattedTimeRange.isNotEmpty ? booking.formattedTimeRange : 'වේලාව',
                  style: GoviTextStyles.caption.copyWith(color: GoviColors.textPrimary),
                ),
              ],
            ),

            // Land location
            if (booking.landLocation != null && booking.landLocation!.isNotEmpty) ...[
              const SizedBox(height: GoviSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: GoviColors.textSecondary),
                  const SizedBox(width: GoviSpacing.xs),
                  Expanded(
                    child: Text(
                      booking.landLocation!,
                      style: GoviTextStyles.caption.copyWith(color: GoviColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],

            // Person contact row
            const SizedBox(height: GoviSpacing.xs),
            Row(
              children: [
                Icon(
                  isOwnerView ? Icons.person_rounded : Icons.precision_manufacturing_rounded,
                  size: 16,
                  color: GoviColors.textSecondary,
                ),
                const SizedBox(width: GoviSpacing.xs),
                Expanded(
                  child: Text(
                    isOwnerView
                        ? 'ගොවි මහතා: ${booking.farmerName ?? "N/A"} (${booking.farmerPhone ?? ""})'
                        : 'හිමිකරු: ${booking.ownerName ?? "N/A"} (${booking.ownerPhone ?? ""})',
                    style: GoviTextStyles.caption.copyWith(color: GoviColors.textSecondary),
                  ),
                ),
              ],
            ),

            if (booking.cancellationReason != null && booking.cancellationReason!.isNotEmpty) ...[
              const SizedBox(height: GoviSpacing.xs),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: GoviColors.danger.withAlpha(20),
                  borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                  border: Border.all(color: GoviColors.danger.withAlpha(50)),
                ),
                child: Text(
                  'අවලංගු වීමට හේතුව: ${booking.cancellationReason}',
                  style: GoviTextStyles.caption.copyWith(color: GoviColors.danger, fontSize: 12),
                ),
              ),
            ],

            // Action buttons row
            if (isOwnerView && booking.isRequested) ...[
              const SizedBox(height: GoviSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GoviColors.danger,
                        side: const BorderSide(color: GoviColors.danger),
                      ),
                      onPressed: onDecline,
                      child: const Text('ප්‍රතික්ෂේප (Decline)'),
                    ),
                  ),
                  const SizedBox(width: GoviSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GoviColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onAccept,
                      child: const Text('පිළිගන්න (Accept)'),
                    ),
                  ),
                ],
              ),
            ] else if (isOwnerView && booking.isConfirmed) ...[
              const SizedBox(height: GoviSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GoviColors.danger,
                        side: const BorderSide(color: GoviColors.danger),
                      ),
                      onPressed: onCancel,
                      child: const Text('අවලංගු කරන්න'),
                    ),
                  ),
                  const SizedBox(width: GoviSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GoviColors.info,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onStartJob,
                      child: const Text('ආරම්භ කරන්න (Start)'),
                    ),
                  ),
                ],
              ),
            ] else if (isOwnerView && booking.isInProgress) ...[
              const SizedBox(height: GoviSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GoviColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('වැඩ අවසන් (Mark Completed)'),
                  onPressed: onCompleteJob,
                ),
              ),
            ] else if (!isOwnerView && (booking.isRequested || booking.isConfirmed)) ...[
              const SizedBox(height: GoviSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: GoviColors.danger),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text('වෙන්කිරීම අවලංගු කරන්න (Cancel)'),
                  onPressed: onCancel,
                ),
              ),
            ] else if (booking.isCompleted && onLeaveReview != null) ...[
              const SizedBox(height: GoviSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GoviColors.primary,
                    side: const BorderSide(color: GoviColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(GoviSpacing.radiusMd),
                    ),
                  ),
                  icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  label: const Text(
                    'ඇගයීමක් ලබා දෙන්න (Leave Review)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: onLeaveReview,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
