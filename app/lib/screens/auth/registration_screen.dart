import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/govi_button.dart';
import '../../widgets/govi_card.dart';
import '../farmer/home_screen.dart';
import '../owner/home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String phoneNumber;
  final AuthService authService;

  const RegistrationScreen({
    super.key,
    required this.phoneNumber,
    required this.authService,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  UserRole _selectedRole = UserRole.farmer;
  String? _selectedGnDivision;
  List<String> _gnDivisions = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGnDivisions();
  }

  Future<void> _loadGnDivisions() async {
    final list = await ApiService.asyncFetchGnDivisions();
    if (mounted) {
      setState(() {
        _gnDivisions = list;
        _selectedGnDivision = list.isNotEmpty ? list.first : 'Padaviya Town';
      });
    }
  }

  Future<void> _completeRegistration() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'කරුණාකර ඔබගේ සම්පූර්ණ නම ඇතුළත් කරන්න.');
      return;
    }

    if (_selectedGnDivision == null) {
      setState(() => _errorMessage = 'කරුණාකර ඔබගේ වසම (GN Division) තෝරන්න.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.register(
        fullName: name,
        role: _selectedRole,
        gnDivision: _selectedGnDivision!,
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => _selectedRole == UserRole.owner
              ? const OwnerHomeScreen()
              : const FarmerHomeScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoviColors.background,
      appBar: AppBar(
        title: const Text('ගිණුම සකසන්න (Profile Setup)'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GoviSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ඔබගේ තොරතුරු ඇතුළත් කරන්න', style: GoviTextStyles.screenTitle),
              const SizedBox(height: GoviSpacing.sm),
              const Text(
                'යන්ත්‍ර වෙන්කරවා ගැනීමට හෝ සේවා සැපයීමට ඔබගේ නිවැරදි තොරතුරු ඇතුළත් කරන්න.',
                style: GoviTextStyles.caption,
              ),
              const SizedBox(height: GoviSpacing.xl),
              const Text('සම්පූර්ණ නම (Full Name):', style: GoviTextStyles.bodyBold),
              const SizedBox(height: GoviSpacing.xs),
              TextField(
                controller: _nameController,
                style: GoviTextStyles.body,
                decoration: const InputDecoration(
                  hintText: 'උදා: සුනිල් පෙරේරා',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: GoviSpacing.lg),
              const Text('ඔබගේ භූමිකාව (Your Role):', style: GoviTextStyles.bodyBold),
              const SizedBox(height: GoviSpacing.sm),
              _buildRoleSelector(),
              const SizedBox(height: GoviSpacing.lg),
              const Text('ප්‍රාදේශීය වසම (GN Division - Padaviya):', style: GoviTextStyles.bodyBold),
              const SizedBox(height: GoviSpacing.xs),
              DropdownButtonFormField<String>(
                initialValue: _selectedGnDivision,
                items: _gnDivisions.map((division) {
                  return DropdownMenuItem(
                    value: division,
                    child: Text(division, style: GoviTextStyles.body),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedGnDivision = val),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: GoviSpacing.md),
                Text(
                  _errorMessage!,
                  style: GoviTextStyles.caption.copyWith(color: GoviColors.danger),
                ),
              ],
              const SizedBox(height: GoviSpacing.xxl),
              GoviButton(
                label: 'ලියාපදිංචිය සම්පූර්ණ කරන්න (Finish)',
                icon: Icons.check_rounded,
                isLoading: _isLoading,
                onPressed: _completeRegistration,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      children: [
        _buildRoleTile(
          role: UserRole.farmer,
          title: 'ගොවි මහතා (Farmer)',
          desc: 'යන්ත්‍ර කුලියට ගැනීමට අවශ්‍යයි',
          icon: Icons.grass_rounded,
        ),
        const SizedBox(height: GoviSpacing.sm),
        _buildRoleTile(
          role: UserRole.owner,
          title: 'යන්ත්‍ර හිමිකරු (Machine Owner)',
          desc: 'යන්ත්‍ර කුලියට දීමට බලාපොරොත්තු වෙයි',
          icon: Icons.agriculture_rounded,
        ),
        const SizedBox(height: GoviSpacing.sm),
        _buildRoleTile(
          role: UserRole.both,
          title: 'දෙකම (Both)',
          desc: 'යන්ත්‍ර හිමියෙක් මෙන්ම ගොවිතැන් ද කරයි',
          icon: Icons.handshake_outlined,
        ),
      ],
    );
  }

  Widget _buildRoleTile({
    required UserRole role,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;

    return GoviCard(
      onTap: () => setState(() => _selectedRole = role),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(GoviSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected ? GoviColors.primarySoft : GoviColors.border.withAlpha(76),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? GoviColors.primary : GoviColors.textSecondary,
              size: 24.0,
            ),
          ),
          const SizedBox(width: GoviSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoviTextStyles.bodyBold.copyWith(
                    color: isSelected ? GoviColors.primaryDark : GoviColors.textPrimary,
                  ),
                ),
                Text(desc, style: GoviTextStyles.caption),
              ],
            ),
          ),
          Radio<UserRole>(
            value: role,
            groupValue: _selectedRole,
            activeColor: GoviColors.primary,
            onChanged: (val) {
              if (val != null) setState(() => _selectedRole = val);
            },
          ),
        ],
      ),
    );
  }
}
