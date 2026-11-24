import 'package:flutter/material.dart';
import '../../models/machine.dart';
import '../../services/api_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/govi_card.dart';
import '../../widgets/govi_button.dart';
import '../../widgets/machine_card.dart';
import '../../widgets/empty_state.dart';
import 'add_edit_machine_screen.dart';
import 'add_availability_screen.dart';
import 'booking_requests_screen.dart';
import '../notifications_screen.dart';

class OwnerHomeScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const OwnerHomeScreen({super.key, this.onLogout});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  List<MachineModel> _machines = [];
  int _pendingRequestsCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyMachines();
  }

  Future<void> _loadMyMachines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // In dev mode without logged in ownerId, fetch all or current user's machines
      final user = await ApiService.getMe();
      final list = await ApiService.fetchMachines(
        ownerId: user?.id,
        isActive: null, // show both active and inactive to the owner
      );
      int pending = 0;
      try {
        final bookings = await ApiService.fetchMyBookings(asRole: 'owner');
        pending = bookings.where((b) => b.isRequested).length;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _machines = list;
          _pendingRequestsCount = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'යන්ත්‍ර ලැයිස්තුව ලබාගැනීමට නොහැකි විය.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleMachineStatus(MachineModel machine) async {
    try {
      await ApiService.updateMachine(
        id: machine.id,
        isActive: !machine.isActive,
      );
      _loadMyMachines();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('තත්වය වෙනස් කිරීමට නොහැකි විය: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeactivate(MachineModel machine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('යන්ත්‍රය අක්‍රිය කරන්නද?'),
        content: Text('${machine.brand} යන්ත්‍රය තාවකාලිකව අක්‍රිය කිරීමට අවශ්‍ය බව තහවුරු කරන්න.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('නැත (Cancel)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GoviColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('අක්‍රිය කරන්න (Deactivate)'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.deleteMachine(machine.id);
      _loadMyMachines();
    }
  }

  void _openAddMachine() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddEditMachineScreen()),
    );
    if (result == true) {
      _loadMyMachines();
    }
  }

  void _openEditMachine(MachineModel machine) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddEditMachineScreen(machineToEdit: machine)),
    );
    if (result == true) {
      _loadMyMachines();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoviColors.background,
      appBar: AppBar(
        title: const Text('යන්ත්‍ර හිමිකරු (Owner)'),
        actions: [
          IconButton(
            tooltip: 'දැනුම්දීම් (Notifications)',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'වෙන්කිරීම් ඉල්ලීම් (Requests)',
            icon: Badge(
              isLabelVisible: _pendingRequestsCount > 0,
              label: Text(_pendingRequestsCount.toString()),
              child: const Icon(Icons.notifications_active_outlined),
            ),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookingRequestsScreen()),
              );
              _loadMyMachines();
            },
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
          onRefresh: _loadMyMachines,
          color: GoviColors.primary,
          child: ListView(
            padding: const EdgeInsets.all(GoviSpacing.screenPadding),
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BookingRequestsScreen()),
                        );
                        _loadMyMachines();
                      },
                      borderRadius: BorderRadius.circular(GoviSpacing.cardRadius),
                      child: GoviCard(
                        padding: const EdgeInsets.all(GoviSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.hourglass_bottom_rounded, color: GoviColors.accent, size: 20.0),
                                SizedBox(width: GoviSpacing.xs),
                                Text('ඉල්ලීම් (Requests)', style: GoviTextStyles.caption),
                              ],
                            ),
                            const SizedBox(height: GoviSpacing.xs),
                            Text(
                              _pendingRequestsCount.toString(),
                              style: GoviTextStyles.screenTitle.copyWith(color: GoviColors.accent),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: GoviSpacing.md),
                  Expanded(
                    child: GoviCard(
                      padding: const EdgeInsets.all(GoviSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.agriculture_rounded, color: GoviColors.primary, size: 20.0),
                              SizedBox(width: GoviSpacing.xs),
                              Text('යන්ත්‍ර (Machines)', style: GoviTextStyles.caption),
                            ],
                          ),
                          const SizedBox(height: GoviSpacing.xs),
                          Text(
                            _machines.length.toString(),
                            style: GoviTextStyles.screenTitle.copyWith(color: GoviColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GoviSpacing.lg),

              // Big "Add availability" Button
              GoviButton(
                label: 'නව වේලාවක් එක්කරන්න (Add Availability)',
                icon: Icons.calendar_month_rounded,
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const AddAvailabilityScreen()),
                  );
                  if (result == true) {
                    _loadMyMachines();
                  }
                },
              ),
              const SizedBox(height: GoviSpacing.xl),

              // Machine List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('මගේ යන්ත්‍ර (My Machines)', style: GoviTextStyles.sectionTitle),
                  TextButton.icon(
                    onPressed: _openAddMachine,
                    icon: const Icon(Icons.add, color: GoviColors.primary),
                    label: const Text('එක්කරන්න (Add)', style: GoviTextStyles.bodyBold),
                  ),
                ],
              ),
              const SizedBox(height: GoviSpacing.sm),

              // Machines list content
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: GoviColors.primary),
                  ),
                )
              else if (_errorMessage != null)
                Center(
                  child: Text(_errorMessage!, style: GoviTextStyles.caption.copyWith(color: GoviColors.danger)),
                )
              else if (_machines.isEmpty)
                EmptyState(
                  icon: Icons.agriculture_rounded,
                  title: 'තවමත් කිසිදු යන්ත්‍රයක් ඇතුළත් කර නැත',
                  subtitle: 'ඔබ සතු ට්‍රැක්ටර්, අස්වනු නෙලන යන්ත්‍ර හෝ ජල පොම්ප පහසුවෙන් ලැයිස්තුගත කරන්න.',
                  actionLabel: 'පළමු යන්ත්‍රය එක්කරන්න (Add Machine)',
                  onAction: _openAddMachine,
                )
              else
                ..._machines.map((machine) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: GoviSpacing.md),
                    child: MachineCard(
                      machine: machine,
                      onTap: () => _openEditMachine(machine),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              machine.isActive ? Icons.check_circle : Icons.pause_circle_outline,
                              color: machine.isActive ? GoviColors.primary : GoviColors.textSecondary,
                            ),
                            tooltip: machine.isActive ? 'සක්‍රියයි (Active)' : 'අක්‍රියයි (Inactive)',
                            onPressed: () => _toggleMachineStatus(machine),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: GoviColors.primaryDark),
                            onPressed: () => _openEditMachine(machine),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: GoviColors.danger),
                            onPressed: () => _confirmDeactivate(machine),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Machines tab active
        selectedItemColor: GoviColors.primary,
        unselectedItemColor: GoviColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'මුල් පිටුව (Home)',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'ඉල්ලීම් (Requests)',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture_rounded),
            label: 'යන්ත්‍ර (Machines)',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'පැතිකඩ (Profile)',
          ),
        ],
      ),
    );
  }
}
