import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_machines_screen.dart';
import 'admin_audit_log_screen.dart';

class AdminPanelLayout extends StatefulWidget {
  final VoidCallback? onSwitchToMobileApp;
  final VoidCallback? onLogout;

  const AdminPanelLayout({
    super.key,
    this.onSwitchToMobileApp,
    this.onLogout,
  });

  @override
  State<AdminPanelLayout> createState() => _AdminPanelLayoutState();
}

class _AdminPanelLayoutState extends State<AdminPanelLayout> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      AdminDashboardScreen(onNavigate: (index) => setState(() => _selectedIndex = index)),
      const AdminUsersScreen(),
      const AdminMachinesScreen(),
      const AdminAuditLogScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                const Text('🌾', style: TextStyle(fontSize: 24)),
                const SizedBox(width: GoviSpacing.xs),
                Text(
                  'ගොවිපල පරිපාලක පුවරුව (Govipala Admin)',
                  style: GoviTextStyles.heading2.copyWith(color: Colors.white),
                ),
                const SizedBox(width: GoviSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: GoviColors.accentDark,
                    borderRadius: BorderRadius.circular(GoviSpacing.radiusSm),
                  ),
                  child: const Text(
                    'පදවිය නියමුව (Padaviya Pilot)',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            actions: [
              if (widget.onSwitchToMobileApp != null)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.15),
                  ),
                  icon: const Icon(Icons.phone_android, size: 18),
                  label: const Text('මොබයිල් දැක්ම (Mobile App)'),
                  onPressed: widget.onSwitchToMobileApp,
                ),
              if (widget.onLogout != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red.withOpacity(0.3),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('ඉවත්වන්න (Logout)'),
                  onPressed: widget.onLogout,
                ),
              ],
              const SizedBox(width: GoviSpacing.md),
            ],
          ),
          body: Row(
            children: [
              if (isWide)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  labelType: NavigationRailLabelType.all,
                  selectedLabelTextStyle: GoviTextStyles.caption.copyWith(
                    color: GoviColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelTextStyle: GoviTextStyles.caption.copyWith(
                    color: GoviColors.textSecondary,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard, color: GoviColors.primary),
                      label: Text('පුවරුව (Dashboard)'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people, color: GoviColors.primary),
                      label: Text('පරිශීලකයින් (Users)'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.precision_manufacturing_outlined),
                      selectedIcon: Icon(Icons.precision_manufacturing, color: GoviColors.primary),
                      label: Text('යන්ත්‍ර (Machines)'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history_edu_outlined),
                      selectedIcon: Icon(Icons.history_edu, color: GoviColors.primary),
                      label: Text('විගණනය (Audit)'),
                    ),
                  ],
                ),
              if (isWide) const VerticalDivider(thickness: 1, width: 1),
              Expanded(
                child: _screens[_selectedIndex],
              ),
            ],
          ),
          bottomNavigationBar: isWide
              ? null
              : BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: GoviColors.primary,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard),
                      label: 'පුවරුව',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.people),
                      label: 'පරිශීලකයින්',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.precision_manufacturing),
                      label: 'යන්ත්‍ර',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.history_edu),
                      label: 'විගණනය',
                    ),
                  ],
                ),
        );
      },
    );
  }
}
