import 'package:flutter/material.dart';
import '../../models/machine.dart';
import '../../models/availability_slot.dart';
import '../../models/review.dart';
import '../../services/api_service.dart';
import '../../services/offline_cache_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/govi_button.dart';
import '../../widgets/govi_card.dart';
import '../../widgets/slot_chip.dart';
import 'booking_confirm_screen.dart';

class MachineDetailScreen extends StatefulWidget {
  final String machineId;

  const MachineDetailScreen({super.key, required this.machineId});

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  MachineModel? _machine;
  List<AvailabilitySlotModel> _slots = [];
  List<ReviewModel> _reviews = [];
  double _averageRating = 0.0;
  int _reviewCount = 0;
  DateTime _selectedDate = DateTime.now();
  AvailabilitySlotModel? _selectedSlot;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final m = await ApiService.fetchMachineById(widget.machineId);
      final slots = await ApiService.fetchMachineSlots(widget.machineId);
      await OfflineCacheService.cacheSlots(widget.machineId, slots);
      ReviewsListResponse? reviewsResp;
      try {
        reviewsResp = await ApiService.fetchMachineReviews(widget.machineId);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _machine = m;
          _slots = slots;
          if (reviewsResp != null) {
            _reviews = reviewsResp.reviews;
            _averageRating = reviewsResp.averageRating;
            _reviewCount = reviewsResp.reviewCount;
          } else {
            _averageRating = m.averageRating;
            _reviewCount = m.reviewCount;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      final cachedSlots = await OfflineCacheService.getCachedSlots(widget.machineId);
      if (mounted && cachedSlots.isNotEmpty) {
        setState(() {
          _slots = cachedSlots;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = 'යන්ත්‍ර තොරතුරු ලබාගැනීමට නොහැකි විය.';
          _isLoading = false;
        });
      }
    }
  }

  void _onSlotPicked(AvailabilitySlotModel slot) {
    setState(() {
      _selectedSlot = slot;
    });
  }

  void _proceedToBooking() async {
    if (_machine == null || _selectedSlot == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BookingConfirmScreen(
          machine: _machine!,
          slot: _selectedSlot!,
        ),
      ),
    );

    if (result == true) {
      _selectedSlot = null;
      _loadDetail();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: GoviColors.background,
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: GoviColors.primary),
        ),
      );
    }

    if (_errorMessage != null || _machine == null) {
      return Scaffold(
        backgroundColor: GoviColors.background,
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage ?? 'දත්ත නොමැත', style: GoviTextStyles.bodyBold),
              const SizedBox(height: GoviSpacing.md),
              ElevatedButton(
                onPressed: _loadDetail,
                child: const Text('නැවත උත්සාහ කරන්න'),
              ),
            ],
          ),
        ),
      );
    }

    final m = _machine!;
    final dateStr = _selectedDate.toISOString().split('T')[0];
    final daySlots = _slots.where((s) => s.slotDate == dateStr).toList();

    return Scaffold(
      backgroundColor: GoviColors.background,
      appBar: AppBar(
        title: Text('${m.brand} ${m.modelName ?? ""}'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(GoviSpacing.screenPadding),
                children: [
                  // Photo / Category Thumbnail Card
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: GoviColors.primarySoft,
                      borderRadius: BorderRadius.circular(GoviSpacing.cardRadius),
                      border: Border.all(color: GoviColors.border),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            m.machineType == MachineType.fourWheelTractor
                                ? Icons.agriculture_rounded
                                : (m.machineType == MachineType.combineHarvester
                                    ? Icons.alt_route_rounded
                                    : (m.machineType == MachineType.twoWheelTractor
                                        ? Icons.precision_manufacturing_rounded
                                        : Icons.water_drop_rounded)),
                            size: 64.0,
                            color: GoviColors.primary,
                          ),
                          const SizedBox(height: GoviSpacing.xs),
                          Text(
                            m.machineTypeSinhala,
                            style: GoviTextStyles.sectionTitle.copyWith(color: GoviColors.primaryDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: GoviSpacing.md),

                  // Machine Brand, Drive Type, Rate Card
                  GoviCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${m.brand} ${m.modelName ?? ""}',
                                style: GoviTextStyles.screenTitle,
                              ),
                            ),
                            if (m.driveType != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: GoviColors.accent.withAlpha(50),
                                  borderRadius: BorderRadius.circular(GoviSpacing.buttonRadius),
                                  border: Border.all(color: GoviColors.accent),
                                ),
                                child: Text(
                                  m.driveType == DriveType.fourWheel ? '4WD' : '2WD',
                                  style: GoviTextStyles.caption.copyWith(
                                    color: GoviColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: GoviSpacing.xs),
                        Text(
                          m.formattedRate,
                          style: GoviTextStyles.screenTitle.copyWith(
                            color: GoviColors.primary,
                            fontSize: 22.0,
                          ),
                        ),
                        const Divider(height: GoviSpacing.lg),
                        const Text('සේවාව සපයන ග්‍රාම නිලධාරී වසම්:', style: GoviTextStyles.caption),
                        const SizedBox(height: GoviSpacing.xs),
                        Wrap(
                          spacing: GoviSpacing.xs,
                          runSpacing: GoviSpacing.xs,
                          children: m.serviceGnDivisions.map((gn) {
                            return Chip(
                              label: Text(gn, style: GoviTextStyles.caption.copyWith(fontSize: 12.0)),
                              backgroundColor: GoviColors.background,
                              side: const BorderSide(color: GoviColors.border),
                              padding: EdgeInsets.zero,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: GoviSpacing.md),

                  // Owner Information Card
                  GoviCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(GoviSpacing.md),
                          decoration: const BoxDecoration(
                            color: GoviColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_outline_rounded, color: GoviColors.primary, size: 28.0),
                        ),
                        const SizedBox(width: GoviSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.ownerName ?? 'යන්ත්‍ර හිමිකරු (Owner)', style: GoviTextStyles.bodyBold),
                              if (m.ownerGnDivision != null)
                                Text('වසම: ${m.ownerGnDivision}', style: GoviTextStyles.caption),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: GoviColors.accent, size: 18.0),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    '${m.averageRating > 0 ? m.averageRating.toStringAsFixed(1) : 'නව'} (${m.reviewCount} සමාලෝචන)',
                                    style: GoviTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: GoviSpacing.lg),

                  // Section: Slot Picker (06_UI_UX_GUIDE.md Section 4)
                  const Text('වෙන්කරගත හැකි වේලාවන් (Available Slots)', style: GoviTextStyles.sectionTitle),
                  const SizedBox(height: GoviSpacing.xs),
                  const Text(
                    'දිනයක් තෝරා එම දිනයේ විවෘත වේලා වාරයක් තෝරන්න.',
                    style: GoviTextStyles.caption,
                  ),
                  const SizedBox(height: GoviSpacing.md),

                  // 14-Day Horizontal Strip (with green dot for days with open slots)
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      itemBuilder: (context, index) {
                        final date = DateTime.now().add(Duration(days: index));
                        final dStr = date.toISOString().split('T')[0];
                        final isSelected = date.day == _selectedDate.day &&
                            date.month == _selectedDate.month &&
                            date.year == _selectedDate.year;

                        final hasOpenSlot = _slots.any((s) => s.slotDate == dStr && s.isOpen);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDate = date;
                                _selectedSlot = null; // reset picked slot
                              });
                            },
                            borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                            child: Container(
                              width: 60,
                              decoration: BoxDecoration(
                                color: isSelected ? GoviColors.primary : GoviColors.surface,
                                borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                                border: Border.all(
                                  color: isSelected ? GoviColors.primary : GoviColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getDayName(date.weekday),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white70 : GoviColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    date.day.toString(),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : GoviColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: hasOpenSlot
                                          ? (isSelected ? Colors.white : GoviColors.primary)
                                          : Colors.transparent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: GoviSpacing.lg),

                  // Time block chips for the chosen date
                  Text(
                    '${_selectedDate.toISOString().split('T')[0]} දින වේලා වාර:',
                    style: GoviTextStyles.bodyBold,
                  ),
                  const SizedBox(height: GoviSpacing.sm),

                  if (daySlots.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(GoviSpacing.md),
                      decoration: BoxDecoration(
                        color: GoviColors.surface,
                        borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                        border: Border.all(color: GoviColors.border),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, color: GoviColors.textSecondary, size: 20),
                          SizedBox(width: GoviSpacing.sm),
                          Expanded(
                            child: Text(
                              'මෙම දිනය සඳහා යන්ත්‍ර හිමිකරු විසින් වේලාවන් සටහන් කර නොමැත.',
                              style: GoviTextStyles.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Wrap(
                      spacing: GoviSpacing.sm,
                      runSpacing: GoviSpacing.sm,
                      children: daySlots.map((slot) {
                        final isPicked = _selectedSlot?.id == slot.id;
                        return SlotChip(
                          timeRange: slot.formattedTimeRange,
                          isSelected: isPicked,
                          isAvailable: slot.isOpen,
                          onSelected: () => _onSlotPicked(slot),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: GoviSpacing.lg),

                  // Customer Reviews & Ratings section (Phase 5: FR-7.2)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'පාරිභෝගික ඇගයීම් (Reviews)',
                        style: GoviTextStyles.heading2,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            _averageRating.toStringAsFixed(1),
                            style: GoviTextStyles.bodyBold.copyWith(fontSize: 16),
                          ),
                          Text(
                            ' ($_reviewCount)',
                            style: GoviTextStyles.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: GoviSpacing.sm),

                  if (_reviews.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(GoviSpacing.md),
                      decoration: BoxDecoration(
                        color: GoviColors.surface,
                        borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                        border: Border.all(color: GoviColors.border),
                      ),
                      child: const Text(
                        'මෙම යන්ත්‍රය සඳහා තවමත් ඇගයීම් සටහන් කර නොමැත.',
                        style: GoviTextStyles.caption,
                      ),
                    )
                  else
                    ..._reviews.map((r) => Container(
                          margin: const EdgeInsets.only(bottom: GoviSpacing.sm),
                          padding: const EdgeInsets.all(GoviSpacing.md),
                          decoration: BoxDecoration(
                            color: GoviColors.surface,
                            borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                            border: Border.all(color: GoviColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    r.reviewerName ?? 'ගොවි මහතා (Farmer)',
                                    style: GoviTextStyles.bodyBold.copyWith(fontSize: 13),
                                  ),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        i < r.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                        size: 16,
                                        color: i < r.rating ? Colors.amber : GoviColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (r.comment != null && r.comment!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  r.comment!,
                                  style: GoviTextStyles.caption.copyWith(color: GoviColors.textPrimary),
                                ),
                              ],
                            ],
                          ),
                        )),

                  const SizedBox(height: GoviSpacing.xl),
                ],
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(GoviSpacing.screenPadding),
              decoration: const BoxDecoration(
                color: GoviColors.surface,
                border: Border(top: BorderSide(color: GoviColors.border)),
              ),
              child: GoviButton(
                label: _selectedSlot != null
                    ? 'වෙන්කිරීමට ඉදිරියට යන්න (${_selectedSlot!.formattedTimeRange})'
                    : 'ඉදිරියට යාමට වේලාවක් තෝරන්න',
                icon: Icons.arrow_forward_rounded,
                onPressed: _selectedSlot != null ? _proceedToBooking : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'සඳුදා';
      case DateTime.tuesday:
        return 'අඟහ';
      case DateTime.wednesday:
        return 'බදාදා';
      case DateTime.thursday:
        return 'බ්‍රහස්';
      case DateTime.friday:
        return 'සිකු';
      case DateTime.saturday:
        return 'සෙන';
      case DateTime.sunday:
        return 'ඉරිදා';
      default:
        return '';
    }
  }
}

extension on DateTime {
  String toISOString() => toIso8601String();
}
