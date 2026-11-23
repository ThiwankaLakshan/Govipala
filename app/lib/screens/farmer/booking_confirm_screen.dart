import 'package:flutter/material.dart';
import '../../models/machine.dart';
import '../../models/availability_slot.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/govi_button.dart';
import '../../widgets/govi_card.dart';

class BookingConfirmScreen extends StatefulWidget {
  final MachineModel machine;
  final AvailabilitySlotModel slot;

  const BookingConfirmScreen({
    super.key,
    required this.machine,
    required this.slot,
  });

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  final _locationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final isOffline = OfflineCacheService.connectionStatus.value == ConnectionStateStatus.offline;

    if (isOffline) {
      await OfflineCacheService.queueBooking(
        slotId: widget.slot.id,
        landLocation: _locationController.text.trim(),
      );
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GoviSpacing.radiusMd)),
            title: Row(
              children: const [
                Icon(Icons.cloud_queue_rounded, color: GoviColors.accent, size: 28),
                SizedBox(width: GoviSpacing.sm),
                Text('නොබැඳිව සුරැකිණි! (Queued)'),
              ],
            ),
            content: const Text(
              'ඔබ නොබැඳි (Offline) මාදිලියේ සිටියි. ඔබගේ වෙන්කිරීමේ ඉල්ලීම දේශීයව සුරැකිණි. අන්තර්ජාලය සම්බන්ධ වූ වහාම එය ස්වයංක්‍රීයව හිමිකරු වෙත යවනු ලැබේ.',
              style: GoviTextStyles.body,
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: GoviColors.primary, foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(true);
                },
                child: const Text('හරි (Done)'),
              ),
            ],
          ),
        );
      }
      return;
    }

    try {
      await ApiService.createBooking(
        slotId: widget.slot.id,
        landLocation: _locationController.text.trim(),
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GoviSpacing.radiusMd)),
            title: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: GoviColors.success, size: 28),
                SizedBox(width: GoviSpacing.sm),
                Text('ඉල්ලීම සාර්ථකයි!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ඔබගේ වෙන්කිරීමේ ඉල්ලීම යන්ත්‍ර හිමිකරු වෙත යවන ලදී. ඔහු එය තහවුරු කළ වහාම ඔබට කෙටි පණිවිඩයක් ලැබෙනු ඇත.',
                  style: GoviTextStyles.body,
                ),
                const SizedBox(height: GoviSpacing.md),
                Text(
                  'යන්ත්‍රය: ${widget.machine.brand} ${widget.machine.modelName ?? ""}\nදිනය: ${widget.slot.slotDate}\nවේලාව: ${widget.slot.formattedTimeRange}',
                  style: GoviTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GoviColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(true);
                },
                child: const Text('හරි (Done)'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final isConflict = e.toString().contains('slot_no_longer_available') ||
            e.toString().contains('දැනටමත් වෙන්කරවා');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isConflict
                  ? 'කණගාටුයි! මෙම වේලාව වෙනත් අයෙකු විසින් දැනටමත් වෙන්කරවා ගෙන ඇත. කරුණාකර වෙනත් වේලාවක් තෝරන්න.'
                  : 'දෝෂය: ${e.toString()}',
            ),
            backgroundColor: GoviColors.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoviColors.background,
      appBar: AppBar(
        title: const Text('වෙන්කිරීම තහවුරු කිරීම (Confirm)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(GoviSpacing.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Machine Details Summary Card
              GoviCard(
                padding: const EdgeInsets.all(GoviSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.machine.brand} ${widget.machine.modelName ?? ""}',
                      style: GoviTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: GoviSpacing.xxs),
                    Text(
                      widget.machine.machineTypeSinhala,
                      style: GoviTextStyles.caption.copyWith(color: GoviColors.textSecondary),
                    ),
                    const Divider(height: GoviSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('කුලී ගාස්තුව (Rate):', style: GoviTextStyles.body),
                        Text(
                          widget.machine.formattedRate,
                          style: GoviTextStyles.bodyBold.copyWith(color: GoviColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: GoviSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('හිමිකරු (Owner):', style: GoviTextStyles.body),
                        Text(widget.machine.ownerName ?? 'නොදනී', style: GoviTextStyles.bodyBold),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: GoviSpacing.md),

              // Selected Slot Card
              GoviCard(
                padding: const EdgeInsets.all(GoviSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: GoviColors.primarySoft,
                        borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.event_available_rounded, color: GoviColors.primary, size: 28),
                    ),
                    const SizedBox(width: GoviSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('තෝරාගත් දිනය සහ වේලාව', style: GoviTextStyles.caption),
                          const SizedBox(height: 2),
                          Text(widget.slot.slotDate, style: GoviTextStyles.bodyBold),
                          Text(
                            widget.slot.formattedTimeRange,
                            style: GoviTextStyles.caption.copyWith(color: GoviColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: GoviSpacing.lg),

              // Land Location Input
              const Text('වගාබිම පිහිටි ස්ථානය සහ විස්තර (Land Location) *', style: GoviTextStyles.sectionTitle),
              const SizedBox(height: GoviSpacing.xs),
              const Text(
                'යන්ත්‍රය රැගෙන ඒම සඳහා ඔබගේ කුඹුර හෝ ඉඩම පිහිටි ස්ථානය, ප්‍රමාණය සහ ප්‍රවේශ මාර්ගය සඳහන් කරන්න.',
                style: GoviTextStyles.caption,
              ),
              const SizedBox(height: GoviSpacing.sm),
              TextFormField(
                controller: _locationController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'උදා: පදවිය වැව අසල, 03 ඇල පාර, අක්කර 2 කුඹුර...',
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 3) {
                    return 'කරුණාකර වගාබිම පිළිබඳ විස්තරයක් ඇතුළත් කරන්න.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: GoviSpacing.xl),

              // One big "Request booking" button (06_UI_UX_GUIDE.md Section 4)
              GoviButton(
                label: _isSubmitting ? 'ඉල්ලීම යවමින්...' : 'වෙන්කරවා ගැනීම ඉල්ලුම් කරන්න (Request Booking)',
                icon: Icons.send_rounded,
                isLoading: _isSubmitting,
                onPressed: _submitBooking,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
