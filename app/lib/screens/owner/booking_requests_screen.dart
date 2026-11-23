import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../services/api_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/empty_state.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> with SingleTickerProviderStateMixin {
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
      final list = await ApiService.fetchMyBookings(asRole: 'owner');
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

  Future<void> _respond(BookingModel booking, String action) async {
    try {
      await ApiService.respondToBooking(booking.id, action: action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'confirm'
                  ? 'වෙන්කිරීම තහවුරු කරන ලදී (Booking Confirmed).'
                  : 'වෙන්කිරීම ප්‍රතික්ෂේප විය (Booking Declined).',
            ),
            backgroundColor: action == 'confirm' ? GoviColors.success : GoviColors.danger,
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

  Future<void> _updateStatus(BookingModel booking, String status) async {
    try {
      await ApiService.updateBookingStatus(booking.id, status: status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'in_progress'
                  ? 'කාර්යය ආරම්භ කරන ලදී (Job Started).'
                  : 'කාර්යය සාර්ථකව අවසන් විය (Job Completed).',
            ),
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

  @override
  Widget build(BuildContext context) {
    final pendingRequests = _bookings.filter((b) => b.isRequested);
    final confirmedJobs = _bookings.filter((b) => b.isConfirmed || b.isInProgress);
    final completedJobs = _bookings.filter((b) => b.isCompleted || b.isCancelled || b.isRejected);

    return Scaffold(
      backgroundColor: GoviColors.background,
      appBar: AppBar(
        title: const Text('වෙන්කිරීම් ඉල්ලීම් (Bookings)'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: GoviColors.accent,
          tabs: [
            Tab(text: 'ඉල්ලීම් (${pendingRequests.length})'),
            Tab(text: 'ක්‍රියාත්මක (${confirmedJobs.length})'),
            Tab(text: 'අවසන් වූ (${completedJobs.length})'),
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
                      pendingRequests,
                      emptyTitle: 'නව ඉල්ලීම් නොමැත',
                      emptySubtitle: 'මේ මොහොතේ තහවුරු කිරීමට නව ඉල්ලීම් නොමැත.',
                    ),
                    _buildList(
                      confirmedJobs,
                      emptyTitle: 'ක්‍රියාකාරී වෙන්කිරීම් නොමැත',
                      emptySubtitle: 'තහවුරු කළ හෝ ක්‍රියාත්මක වන වැඩ නොමැත.',
                    ),
                    _buildList(
                      completedJobs,
                      emptyTitle: 'අවසන් වූ වෙන්කිරීම් නොමැත',
                      emptySubtitle: 'පසුගිය වැඩ වාර්තා නොමැත.',
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
        icon: Icons.event_busy_rounded,
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
            isOwnerView: true,
            onAccept: () => _respond(booking, 'confirm'),
            onDecline: () => _respond(booking, 'reject'),
            onStartJob: () => _updateStatus(booking, 'in_progress'),
            onCompleteJob: () => _updateStatus(booking, 'completed'),
            onCancel: () => _updateStatus(booking, 'cancelled'),
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
