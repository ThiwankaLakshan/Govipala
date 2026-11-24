import 'package:flutter/material.dart';
import '../../models/machine.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/govi_card.dart';
import '../../widgets/status_chip.dart';
import 'browse_machines_screen.dart';
import 'my_bookings_screen.dart';
import '../notifications_screen.dart';

/// Farmer Home Screen (06_UI_UX_GUIDE.md Section 4)
class FarmerHomeScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const FarmerHomeScreen({super.key, this.onLogout});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  BookingModel? _upcomingBooking;
  bool _isLoadingBooking = false;

  @override
  void initState() {
    super.initState();
    _loadUpcomingBooking();
  }

  Future<void> _loadUpcomingBooking() async {
    setState(() => _isLoadingBooking = true);
    try {
      final list = await ApiService.fetchMyBookings(asRole: 'farmer');
      final active = list.where((b) => b.isRequested || b.isConfirmed || b.isInProgress).toList();
      if (mounted) {
        setState(() {
          _upcomingBooking = active.isNotEmpty ? active.first : null;
          _isLoadingBooking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBooking = false);
    }
  }

  void _openBrowse([MachineType? type]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrowseMachinesScreen(initialType: type),
      ),
    );
  }

  void _openMyBookings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
    );
    _loadUpcomingBooking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoviColors.background,
      appBar: AppBar(
        title: const Text('ගොවිපල (Govipala)'),
        actions: [
          IconButton(
            tooltip: 'දැනුම්දීම් (Notifications)',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'මගේ වෙන්කිරීම් (My Bookings)',
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: _openMyBookings,
          ),
          IconButton(
            tooltip: 'යන්ත්‍ර සොයන්න (Search)',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _openBrowse(),
          ),
          if (widget.onLogout != null)
            IconButton(
              tooltip: 'ඉවත්වන්න (Logout)',
              icon: const Icon(Icons.logout_rounded),
              onPressed: widget.onLogout,
            ),
          const SizedBox(width: GoviSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUpcomingBooking,
          child: ListView(
            padding: const EdgeInsets.all(GoviSpacing.screenPadding),
            children: [
              // Greeting Header
              const Text('ආයුබෝවන්! 🌾', style: GoviTextStyles.screenTitle),
              const SizedBox(height: GoviSpacing.xs),
              const Text(
                'අද ඔබගේ වගාබිමට අවශ්‍ය යන්ත්‍රය තෝරන්න',
                style: GoviTextStyles.caption,
              ),
              const SizedBox(height: GoviSpacing.lg),

              // Upcoming booking card if one exists (06_UI_UX_GUIDE.md Section 4)
              if (_isLoadingBooking) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: GoviSpacing.sm),
                  child: LinearProgressIndicator(minHeight: 2, color: GoviColors.primary),
                ),
                const SizedBox(height: GoviSpacing.md),
              ] else if (_upcomingBooking != null) ...[
                InkWell(
                  onTap: _openMyBookings,
                  borderRadius: BorderRadius.circular(GoviSpacing.cardRadius),
                  child: Container(
                    padding: const EdgeInsets.all(GoviSpacing.md),
                    decoration: BoxDecoration(
                      color: GoviColors.primarySoft,
                      borderRadius: BorderRadius.circular(GoviSpacing.cardRadius),
                      border: Border.all(color: GoviColors.primary.withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.event_available_rounded, color: GoviColors.primary, size: 20),
                                SizedBox(width: GoviSpacing.xs),
                                Text(
                                  'මීළඟ වෙන්කිරීම (Upcoming Booking)',
                                  style: TextStyle(
                                    color: GoviColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            StatusChip(status: _upcomingBooking!.status),
                          ],
                        ),
                        const SizedBox(height: GoviSpacing.sm),
                        Text(
                          '${_upcomingBooking!.machineBrand ?? "යන්ත්‍රය"} ${_upcomingBooking!.machineModel ?? ""}',
                          style: GoviTextStyles.bodyBold,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_upcomingBooking!.slotDate ?? ""} (${_upcomingBooking!.formattedTimeRange})',
                          style: GoviTextStyles.caption.copyWith(color: GoviColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: GoviSpacing.lg),
              ],

              // 2x2 Machine Types Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: GoviSpacing.md,
                crossAxisSpacing: GoviSpacing.md,
                children: [
                  _buildMachineTypeTile(
                    type: MachineType.fourWheelTractor,
                    icon: Icons.agriculture_rounded,
                    titleSinhala: 'හතර රෝද ට්‍රැක්ටර්',
                    titleEnglish: '4-Wheel Tractor',
                    color: GoviColors.primary,
                  ),
                  _buildMachineTypeTile(
                    type: MachineType.twoWheelTractor,
                    icon: Icons.precision_manufacturing_rounded,
                    titleSinhala: 'අත් ට්‍රැක්ටර්',
                    titleEnglish: '2-Wheel Tractor',
                    color: GoviColors.primaryDark,
                  ),
                  _buildMachineTypeTile(
                    type: MachineType.combineHarvester,
                    icon: Icons.alt_route_rounded,
                    titleSinhala: 'අස්වනු නෙලන යන්ත්‍ර',
                    titleEnglish: 'Harvester',
                    color: GoviColors.accentDark,
                  ),
                  _buildMachineTypeTile(
                    type: MachineType.waterPump,
                    icon: Icons.water_drop_rounded,
                    titleSinhala: 'ජල පොම්ප',
                    titleEnglish: 'Water Pump',
                    color: GoviColors.info,
                  ),
                ],
              ),
              const SizedBox(height: GoviSpacing.xl),

              // Bottom Banner: Pilot Scope info
              GoviCard(
                padding: const EdgeInsets.all(GoviSpacing.md),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      color: GoviColors.primary,
                      size: 28.0,
                    ),
                    const SizedBox(width: GoviSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('පදවිය නියමු ව්‍යාපෘතිය', style: GoviTextStyles.bodyBold),
                          Text(
                            'පදවිය ප්‍රාදේශීය ලේකම් කොට්ඨාසයේ සියලුම ග්‍රාම නිලධාරී වසම් සඳහා වලංගු වේ.',
                            style: GoviTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMachineTypeTile({
    required MachineType type,
    required IconData icon,
    required String titleSinhala,
    required String titleEnglish,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _openBrowse(type),
      borderRadius: BorderRadius.circular(GoviSpacing.cardRadius),
      child: Container(
        decoration: BoxDecoration(
          color: GoviColors.surface,
          borderRadius: BorderRadius.circular(GoviSpacing.cardRadius),
          border: Border.all(color: GoviColors.border, width: 1.5),
        ),
        padding: const EdgeInsets.all(GoviSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(GoviSpacing.md),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36.0, color: color),
            ),
            const SizedBox(height: GoviSpacing.sm),
            Text(
              titleSinhala,
              style: GoviTextStyles.bodyBold.copyWith(fontSize: 14.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GoviSpacing.xxs),
            Text(
              titleEnglish,
              style: GoviTextStyles.caption.copyWith(fontSize: 11.0),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
