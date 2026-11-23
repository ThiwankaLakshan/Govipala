import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/govi_button.dart';

class LeaveReviewDialog extends StatefulWidget {
  final String bookingId;
  final String machineTitle;

  const LeaveReviewDialog({
    super.key,
    required this.bookingId,
    required this.machineTitle,
  });

  static Future<bool?> show(BuildContext context, {required String bookingId, required String machineTitle}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => LeaveReviewDialog(bookingId: bookingId, machineTitle: machineTitle),
    );
  }

  @override
  State<LeaveReviewDialog> createState() => _LeaveReviewDialogState();
}

class _LeaveReviewDialogState extends State<LeaveReviewDialog> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'ඉතා දුර්වලයි (Very Poor)';
      case 2:
        return 'දුර්වලයි (Poor)';
      case 3:
        return 'සාමාන්‍යයි (Average)';
      case 4:
        return 'හොඳයි (Good)';
      case 5:
        return 'විශිෂ්ටයි! (Excellent)';
      default:
        return '';
    }
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);
    try {
      await ApiService.createBookingReview(
        widget.bookingId,
        rating: _rating,
        comment: _commentController.text,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ඔබගේ ඇගයීම සාර්ථකව සටහන් විය! (Review submitted successfully)'),
            backgroundColor: GoviColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final errStr = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errStr),
            backgroundColor: GoviColors.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GoviSpacing.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(GoviSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Header
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: GoviColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, size: 36, color: Colors.amber),
              ),
              const SizedBox(height: GoviSpacing.md),

              const Text(
                'සේවාව ඇගයීම (Review Service)',
                style: GoviTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: GoviSpacing.xs),
              Text(
                widget.machineTitle,
                style: GoviTextStyles.caption.copyWith(color: GoviColors.primaryDark, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: GoviSpacing.lg),

              // Star selection row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  return IconButton(
                    iconSize: 40,
                    padding: const EdgeInsets.all(4),
                    icon: Icon(
                      starVal <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: starVal <= _rating ? Colors.amber : GoviColors.textMuted,
                    ),
                    onPressed: _isSubmitting ? null : () => setState(() => _rating = starVal),
                  );
                }),
              ),
              const SizedBox(height: GoviSpacing.xs),
              Text(
                _ratingLabel,
                style: GoviTextStyles.bodyBold.copyWith(color: GoviColors.primaryDark),
              ),
              const SizedBox(height: GoviSpacing.lg),

              // Comment text area
              TextField(
                controller: _commentController,
                maxLines: 3,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText: 'ඔබගේ අත්දැකීම පිළිබඳ විස්තරයක් ඇතුළත් කරන්න (විකල්ප)...',
                  hintStyle: GoviTextStyles.caption,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GoviSpacing.radiusMd),
                  ),
                ),
              ),
              const SizedBox(height: GoviSpacing.lg),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                      child: const Text('පසුවට (Later)'),
                    ),
                  ),
                  const SizedBox(width: GoviSpacing.sm),
                  Expanded(
                    child: GoviButton(
                      label: 'ඉදිරිපත් කරන්න',
                      isLoading: _isSubmitting,
                      onPressed: _submitReview,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
