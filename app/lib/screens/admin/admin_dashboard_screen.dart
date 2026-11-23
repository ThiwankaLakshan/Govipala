import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../models/admin_stats.dart';
import '../../services/admin_api_service.dart';
import 'widgets/count_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Function(int) onNavigate;

  const AdminDashboardScreen({super.key, required this.onNavigate});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminDashboardStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await AdminApiService.fetchStats();
      if (mounted) {
        setState(() {
          _stats = stats;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(GoviSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: GoviColors.error),
              const SizedBox(height: GoviSpacing.md),
              Text('දත්ත ලබා ගැනීමට නොහැකි විය', style: GoviTextStyles.heading2),
              const SizedBox(height: GoviSpacing.xs),
              Text(_errorMessage!, style: GoviTextStyles.caption),
              const SizedBox(height: GoviSpacing.md),
              ElevatedButton.icon(
                onPressed: _loadStats,
                icon: const Icon(Icons.refresh),
                label: const Text('නැවත උත්සාහ කරන්න (Retry)'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _stats!;

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(GoviSpacing.lg),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'පරිපාලක පාලක පුවරුව (Admin Dashboard)',
                      style: GoviTextStyles.heading1,
                    ),
                    const SizedBox(height: GoviSpacing.xxs),
                    Text(
                      'පදවිය ප්‍රාදේශීය ලේකම් කොට්ඨාස නියමු ව්‍යාපෘතිය (Padaviya Pilot)',
                      style: GoviTextStyles.caption.copyWith(color: GoviColors.textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'නැවුම් කරන්න (Refresh)',
                  icon: const Icon(Icons.refresh, color: GoviColors.primary),
                  onPressed: _loadStats,
                ),
              ],
            ),
            const SizedBox(height: GoviSpacing.lg),

            // Section 1: Users Overview
            Text('පරිශීලක සංඛ්‍යාලේඛන (Users Overview)', style: GoviTextStyles.heading2),
            const SizedBox(height: GoviSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: GoviSpacing.md,
                  mainAxisSpacing: GoviSpacing.md,
                  childAspectRatio: 2.2,
                  children: [
                    CountCard(
                      title: 'මුළු පරිශීලකයින් (Total Users)',
                      value: stats.users.totalUsers.toString(),
                      icon: Icons.people_outline,
                      color: GoviColors.primary,
                      subtitle: '${stats.users.activeUsers} සක්‍රීය (Active)',
                    ),
                    CountCard(
                      title: 'ගොවීන් (Farmers)',
                      value: stats.users.farmers.toString(),
                      icon: Icons.agriculture_outlined,
                      color: GoviColors.accent,
                    ),
                    CountCard(
                      title: 'යන්ත්‍ර හිමිකරුවන් (Owners)',
                      value: stats.users.owners.toString(),
                      icon: Icons.precision_manufacturing_outlined,
                      color: GoviColors.accentDark,
                      subtitle: '${stats.users.bothRoles} දෙපාර්ශවයම (Both)',
                    ),
                    CountCard(
                      title: 'අත්හිටවූ ගිණුම් (Suspended)',
                      value: stats.users.suspendedUsers.toString(),
                      icon: Icons.block_outlined,
                      color: stats.users.suspendedUsers > 0 ? GoviColors.error : GoviColors.textSecondary,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: GoviSpacing.xl),

            // Section 2: Machines Overview
            Text('යන්ත්‍ර සංඛ්‍යාලේඛන (Machines Overview)', style: GoviTextStyles.heading2),
            const SizedBox(height: GoviSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: GoviSpacing.md,
                  mainAxisSpacing: GoviSpacing.md,
                  childAspectRatio: 2.2,
                  children: [
                    CountCard(
                      title: 'ලියාපදිංචි යන්ත්‍ර (Total Machines)',
                      value: stats.machines.totalMachines.toString(),
                      icon: Icons.build_circle_outlined,
                      color: GoviColors.primary,
                    ),
                    CountCard(
                      title: 'වෙන්කරවාගත හැකි යන්ත්‍ර (Active)',
                      value: stats.machines.activeMachines.toString(),
                      icon: Icons.check_circle_outline,
                      color: GoviColors.success,
                    ),
                    CountCard(
                      title: 'අක්‍රීය යන්ත්‍ර (Inactive)',
                      value: stats.machines.inactiveMachines.toString(),
                      icon: Icons.pause_circle_outline,
                      color: GoviColors.textSecondary,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: GoviSpacing.xl),

            // Section 3: Bookings & Activity
            Text('වෙන්කිරීම් සහ ක්‍රියාකාරකම් (Bookings & Activity)', style: GoviTextStyles.heading2),
            const SizedBox(height: GoviSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: GoviSpacing.md,
                  mainAxisSpacing: GoviSpacing.md,
                  childAspectRatio: 2.2,
                  children: [
                    CountCard(
                      title: 'අද දින වෙන්කිරීම් (Today)',
                      value: stats.bookings.bookingsToday.toString(),
                      icon: Icons.today_outlined,
                      color: GoviColors.primary,
                    ),
                    CountCard(
                      title: 'තහවුරු කිරීමට ඇති (Pending)',
                      value: stats.bookings.pendingBookings.toString(),
                      icon: Icons.pending_actions_outlined,
                      color: GoviColors.warning,
                    ),
                    CountCard(
                      title: 'තහවුරු කළ (Confirmed)',
                      value: stats.bookings.confirmedBookings.toString(),
                      icon: Icons.event_available_outlined,
                      color: GoviColors.success,
                    ),
                    CountCard(
                      title: 'සම්පූර්ණ වූ (Completed)',
                      value: stats.bookings.completedBookings.toString(),
                      icon: Icons.task_alt_outlined,
                      color: GoviColors.accentDark,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: GoviSpacing.xl),

            // Quick Actions shortcuts
            Text('ක්‍රියාකාරකම් වෙත සෘජු ප්‍රවේශය (Quick Actions)', style: GoviTextStyles.heading2),
            const SizedBox(height: GoviSpacing.sm),
            Wrap(
              spacing: GoviSpacing.md,
              runSpacing: GoviSpacing.md,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.people_alt, size: 18, color: GoviColors.primary),
                  label: const Text('පරිශීලකයින් කළමනාකරණය (Manage Users)'),
                  onPressed: () => widget.onNavigate(1),
                ),
                ActionChip(
                  avatar: const Icon(Icons.precision_manufacturing, size: 18, color: GoviColors.primary),
                  label: const Text('යන්ත්‍ර ලැයිස්තුව (Manage Machines)'),
                  onPressed: () => widget.onNavigate(2),
                ),
                ActionChip(
                  avatar: const Icon(Icons.history_edu, size: 18, color: GoviColors.primary),
                  label: const Text('විගණන සටහන් (View Audit Log)'),
                  onPressed: () => widget.onNavigate(3),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
