import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../services/offline_cache_service.dart';
import '../services/auth_service.dart';
import '../widgets/offline_banner.dart';
import 'farmer/home_screen.dart';
import 'owner/home_screen.dart';
import 'admin/admin_panel_layout.dart';
import 'auth/login_screen.dart';

enum AppViewMode { auth, farmer, owner, admin }

class AppShell extends StatefulWidget {
  final AppViewMode? initialMode;

  const AppShell({super.key, this.initialMode});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late AppViewMode _currentMode;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Default to login page on first entrance as requested
    _currentMode = widget.initialMode ?? AppViewMode.auth;
    _authService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Active view screen with top offline banner
        Positioned.fill(
          child: Column(
            children: [
              ValueListenableBuilder<ConnectionStateStatus>(
                valueListenable: OfflineCacheService.connectionStatus,
                builder: (context, status, _) {
                  return OfflineBanner(
                    isOffline: status == ConnectionStateStatus.offline,
                    isSyncing: status == ConnectionStateStatus.syncing,
                  );
                },
              ),
              Expanded(child: _buildCurrentView()),
            ],
          ),
        ),

        // Floating dev mode switcher pill
        Positioned(
          top: 8,
          right: 12,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeButton(
                      mode: AppViewMode.auth,
                      label: '🔒 පිවිසුම (Login)',
                      tooltip: 'මුල් පිවිසුම් පිටුව (Login & Account Creation)',
                    ),
                    const SizedBox(width: 3),
                    _buildModeButton(
                      mode: AppViewMode.admin,
                      label: '🛡️ පරිපාලක (Admin)',
                      tooltip: 'පරිපාලක පුවරුව (Admin Web Panel)',
                    ),
                    const SizedBox(width: 3),
                    _buildModeButton(
                      mode: AppViewMode.farmer,
                      label: '🌾 ගොවි (Farmer)',
                      tooltip: 'ගොවි දැක්ම (Farmer View)',
                    ),
                    const SizedBox(width: 3),
                    _buildModeButton(
                      mode: AppViewMode.owner,
                      label: '🚜 හිමිකරු (Owner)',
                      tooltip: 'හිමිකරු දැක්ම (Owner View)',
                    ),
                    const SizedBox(width: 6),
                    // Offline simulator toggle
                    ValueListenableBuilder<ConnectionStateStatus>(
                      valueListenable: OfflineCacheService.connectionStatus,
                      builder: (context, status, _) {
                        final isOff = status == ConnectionStateStatus.offline;
                        return InkWell(
                          onTap: () {
                            OfflineCacheService.setConnectionStatus(
                              isOff ? ConnectionStateStatus.online : ConnectionStateStatus.offline,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: isOff ? GoviColors.danger.withAlpha(180) : Colors.white12,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isOff ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isOff ? 'Offline' : 'Online',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentView() {
    switch (_currentMode) {
      case AppViewMode.auth:
        return LoginScreen(
          authService: _authService,
          onLoginSuccess: (roleKey) {
            setState(() {
              if (roleKey == 'admin') {
                _currentMode = AppViewMode.admin;
              } else if (roleKey == 'owner' || roleKey == 'machine_owner') {
                _currentMode = AppViewMode.owner;
              } else {
                _currentMode = AppViewMode.farmer;
              }
            });
          },
        );
      case AppViewMode.farmer:
        return FarmerHomeScreen(
          onLogout: () async {
            await _authService.logout();
            setState(() => _currentMode = AppViewMode.auth);
          },
        );
      case AppViewMode.owner:
        return OwnerHomeScreen(
          onLogout: () async {
            await _authService.logout();
            setState(() => _currentMode = AppViewMode.auth);
          },
        );
      case AppViewMode.admin:
        return AdminPanelLayout(
          onSwitchToMobileApp: () => setState(() => _currentMode = AppViewMode.farmer),
          onLogout: () async {
            await _authService.logout();
            setState(() => _currentMode = AppViewMode.auth);
          },
        );
    }
  }

  Widget _buildModeButton({
    required AppViewMode mode,
    required String label,
    required String tooltip,
  }) {
    final isSelected = _currentMode == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _currentMode = mode),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? GoviColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
