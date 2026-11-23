import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/empty_state.dart';
import 'leave_review_dialog.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ApiService.fetchMyBookings(asRole: 'farmer');
      if (mounted) {
        setState(() {
          _bookings = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GoviSpacing.radiusMd)),
        title: const Text('වෙන්කිරීම අවලංගු කරන්නද?'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ඔබට මෙම වෙන්කිරීම අවලංගු කිරීමට අවශ්‍ය හේතුව සටහන් කරන්න:'),
              const SizedBox(height: GoviSpacing.sm),
              TextFormField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'උදා: වැසි සහිත කාලගුණය, මුදල් අපහසුතාව...',
                ),
                validator: (v) => (v == null || v.trim().length < 3) ? 'හේතුවක් ඇතුළත් කරන්න' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('නැත (Back)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GoviColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('අවලංගු කරන්න (Cancel)'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.updateBookingStatus(
          booking.id,
          status: 'cancelled',
          reason: reasonController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('වෙන්කිරීම සාර්ථකව අවලංගු කරන ලදී.'),
              backgroundColor: GoviColors.success,
            ),
          );
          _loadBookings();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('දෝෂය: ${e.toString()}'), backgroundColor: GoviColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBookings = _bookings.filter((b) => b.isRequested || b.isConfirmed || b.isInProgress);
    final completedBookings = _bookings.filter((b) => b.isCompleted);
    final allBookings = _bookings;

    return Scaffold(
      backgroundColor: GoviColors.background,
      appBar: AppBar(
        title: const Text('මගේ වෙන්කිරීම් (My Bookings)'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: GoviColors.accent,
          tabs: [
            Tab(text: 'ක්‍රියාකාරී (${activeBookings.length})'),
            Tab(text: 'අවසන් වූ (${completedBookings.length})'),
            Tab(text: 'සියල්ල (${allBookings.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: GoviTextStyles.caption))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(
                      activeBookings,
                      emptyTitle: 'ක්‍රියාකාරී වෙන්කිරීම් නැත',
                      emptySubtitle: 'ඔබට ඉදිරියට නියමිත යන්ත්‍ර වෙන්කිරීම් නොමැත.',
                    ),
                    _buildList(
                      completedBookings,
                      emptyTitle: 'අවසන් වූ වෙන්කිරීම් නැත',
                      emptySubtitle: 'ඔබ මෙතෙක් සම්පූර්ණ කළ වෙන්කිරීම් නොමැත.',
                    ),
                    _buildList(
                      allBookings,
                      emptyTitle: 'වෙන්කිරීම් වාර්තා නැත',
                      emptySubtitle: 'ඔබගේ සියලුම වෙන්කිරීම් මෙහි දැකගත හැක.',
                    ),
                  ],
                ),
    );
  }

  Widget _buildList(
    List<BookingModel> items, {
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.event_note_rounded,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.separated(
        padding: const EdgeInsets.all(GoviSpacing.screenPadding),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: GoviSpacing.md),
        itemBuilder: (context, index) {
          final booking = items[index];
          return BookingCard(
            booking: booking,
            isOwnerView: false,
            onCancel: () => _cancelBooking(booking),
            onLeaveReview: booking.isCompleted
                ? () async {
                    final reviewed = await LeaveReviewDialog.show(
                      context,
                      bookingId: booking.id,
                      machineTitle: '${booking.machineBrand ?? "යන්ත්‍රය"} ${booking.machineModel ?? ""}',
                    );
                    if (reviewed == true) _loadBookings();
                  }
                : null,
          );
        },
      ),
    );
  }
}

extension on List<BookingModel> {
  List<BookingModel> filter(bool Function(BookingModel) predicate) {
    return where(predicate).toList();
  }
}
