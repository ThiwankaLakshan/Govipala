import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOwnerMode = true;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    // Initialize modes based on user roles
    _isOwnerMode = authService.userRole == 'owner' || authService.userRole == 'both';
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bool canToggleRole = authService.userRole == 'both';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isOwnerMode ? 'Equipment Owner Dashboard' : 'Farmer Reservation Board'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authService.logout();
            },
            tooltip: 'Logout',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Greeting Card
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome to Govipala!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text('Logged in role: ${authService.userRole.toUpperCase()}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Role toggle switch for users who listed as 'both'
            if (canToggleRole) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Switch Role Dashboard',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  Switch(
                    value: _isOwnerMode,
                    activeColor: Colors.green,
                    onChanged: (val) {
                      setState(() {
                        _isOwnerMode = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Option lists based on mode selection
            Expanded(
              child: ListView(
                children: _isOwnerMode ? _buildOwnerOptions() : _buildFarmerOptions(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOwnerOptions() {
    return [
      _buildOptionCard(
        title: 'Register Equipment Listing',
        subtitle: 'Add a new tractor or harvester with rental rates and GN division scopes',
        icon: Icons.add_circle,
        color: Colors.green,
        onTap: () => Navigator.pushNamed(context, '/owner/add_machine'),
      ),
      _buildOptionCard(
        title: 'Set Slot Availability Calendar',
        subtitle: 'Configure and publish date/time blocks for your listings',
        icon: Icons.calendar_month,
        color: Colors.orange,
        onTap: () => Navigator.pushNamed(context, '/owner/availability_calendar'),
      ),
      _buildOptionCard(
        title: 'Incoming Booking Requests',
        subtitle: 'Review, confirm, or decline booking reservations made by farmers',
        icon: Icons.assignment,
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/owner/booking_requests'),
      ),
    ];
  }

  List<Widget> _buildFarmerOptions() {
    return [
      _buildOptionCard(
        title: 'Search & Browse Listings',
        subtitle: 'Discover available machines by type, GN service area, and schedule',
        icon: Icons.search,
        color: Colors.green,
        onTap: () => Navigator.pushNamed(context, '/farmer/browse_machines'),
      ),
      _buildOptionCard(
        title: 'My Active Bookings',
        subtitle: 'Track your requested, confirmed, and ongoing reservations',
        icon: Icons.history_edu,
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/farmer/my_bookings'),
      ),
    ];
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Icon(icon, size: 40, color: color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
