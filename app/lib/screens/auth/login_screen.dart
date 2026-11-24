import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/govi_button.dart';
import '../../widgets/govi_card.dart';
import 'registration_screen.dart';

enum LoginRole { farmer, owner, admin }

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final Function(String roleMode)? onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.authService,
    this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginRole _selectedRole = LoginRole.farmer;
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Role metadata and demo credentials
  static const Map<LoginRole, Map<String, String>> _roleConfigs = {
    LoginRole.farmer: {
      'labelSi': 'ගොවි',
      'labelEn': 'Farmer',
      'icon': '🌾',
      'identifierLabel': 'දුරකථන අංකය (Phone Number)',
      'identifierHint': '077 555 1122',
      'demoIdentifier': '077 555 1122',
      'demoPassword': 'farmer123',
      'demoName': 'අනුර කුමාර (Anura Kumara)',
      'location': 'පදවිය නැගෙනහිර (Padaviya East)',
      'roleKey': 'farmer',
    },
    LoginRole.owner: {
      'labelSi': 'යන්ත්‍ර හිමිකරු',
      'labelEn': 'Owner',
      'icon': '🚜',
      'identifierLabel': 'දුරකථන අංකය (Phone Number)',
      'identifierHint': '077 123 4567',
      'demoIdentifier': '077 123 4567',
      'demoPassword': 'owner123',
      'demoName': 'සුනිල් පෙරේරා (Sunil Perera)',
      'location': 'පදවිය නගරය (Padaviya Town)',
      'roleKey': 'owner',
    },
    LoginRole.admin: {
      'labelSi': 'පරිපාලක',
      'labelEn': 'Admin',
      'icon': '🛡️',
      'identifierLabel': 'විද්‍යුත් තැපෑල (Email Address)',
      'identifierHint': 'admin@govipala.lk',
      'demoIdentifier': 'admin@govipala.lk',
      'demoPassword': 'admin123',
      'demoName': 'පද්ධති පරිපාලක (Govipala Admin)',
      'location': 'ප්‍රධාන පාලන මැදිරිය (Head Office)',
      'roleKey': 'admin',
    },
  };

  @override
  void initState() {
    super.initState();
    _applyDemoCredentialsForRole(LoginRole.farmer);
  }

  void _applyDemoCredentialsForRole(LoginRole role) {
    final config = _roleConfigs[role]!;
    setState(() {
      _selectedRole = role;
      _identifierController.text = config['demoIdentifier']!;
      _passwordController.text = config['demoPassword']!;
      _errorMessage = null;
    });
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty) {
      setState(() => _errorMessage = 'කරුණාකර දුරකථන අංකය හෝ ඊමේල් ලිපිනය ඇතුළත් කරන්න.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'කරුණාකර මුරපදය ඇතුළත් කරන්න.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final roleKey = _roleConfigs[_selectedRole]!['roleKey']!;

    try {
      await widget.authService.login(
        role: roleKey,
        identifier: identifier,
        password: password,
      );

      if (!mounted) return;

      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!(roleKey);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleQuickDemoLogin() async {
    final roleKey = _roleConfigs[_selectedRole]!['roleKey']!;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.authService.loginAsDemoRole(roleKey);

      if (!mounted) return;

      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!(roleKey);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openCreateAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegistrationScreen(
          phoneNumber: '',
          authService: widget.authService,
          onRegisterSuccess: (mode) {
            Navigator.of(context).pop();
            if (widget.onLoginSuccess != null) {
              widget.onLoginSuccess!(mode);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentConfig = _roleConfigs[_selectedRole]!;

    return Scaffold(
      backgroundColor: GoviColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: GoviSpacing.screenPadding,
                vertical: GoviSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. App Header & Brand
                  _buildBrandHeader(),
                  const SizedBox(height: GoviSpacing.lg),

                  // 2. Role Selector Tabs (Farmer, Machine Owner, Admin)
                  _buildRoleSelector(),
                  const SizedBox(height: GoviSpacing.md),

                  // 3. Demo Credentials Card / Badge
                  _buildDemoBadge(currentConfig),
                  const SizedBox(height: GoviSpacing.md),

                  // 4. Input Form
                  GoviCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentConfig['identifierLabel']!,
                          style: GoviTextStyles.bodyBold,
                        ),
                        const SizedBox(height: GoviSpacing.xs),
                        TextField(
                          controller: _identifierController,
                          keyboardType: _selectedRole == LoginRole.admin
                              ? TextInputType.emailAddress
                              : TextInputType.phone,
                          style: GoviTextStyles.bodyBold,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              _selectedRole == LoginRole.admin
                                  ? Icons.email_outlined
                                  : Icons.phone_android_rounded,
                              color: GoviColors.primary,
                            ),
                            hintText: currentConfig['identifierHint'],
                          ),
                        ),
                        const SizedBox(height: GoviSpacing.md),
                        Text(
                          'මුරපදය (Password):',
                          style: GoviTextStyles.bodyBold,
                        ),
                        const SizedBox(height: GoviSpacing.xs),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoviTextStyles.bodyBold,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: GoviColors.primary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: GoviColors.textSecondary,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            hintText: 'මුරපදය ඇතුළත් කරන්න',
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: GoviSpacing.sm),
                          Container(
                            padding: const EdgeInsets.all(GoviSpacing.sm),
                            decoration: BoxDecoration(
                              color: GoviColors.danger.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: GoviColors.danger.withAlpha(76)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: GoviColors.danger, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoviTextStyles.caption.copyWith(
                                      color: GoviColors.danger,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: GoviSpacing.lg),

                        // Login Button
                        GoviButton(
                          label: 'ඇතුල් වන්න (Log In)',
                          icon: Icons.login_rounded,
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: GoviSpacing.sm),

                        // Quick One-Click Demo Button
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleQuickDemoLogin,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            side: const BorderSide(color: GoviColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.bolt_rounded, color: GoviColors.primary),
                          label: Text(
                            '⚡ ක්ෂණික පිවිසුම (${currentConfig['labelSi']})',
                            style: GoviTextStyles.bodyBold.copyWith(color: GoviColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: GoviSpacing.lg),

                  // 5. Create Account Option
                  Container(
                    padding: const EdgeInsets.all(GoviSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GoviColors.border),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'ගොවිපල වෙත අලුත්ද? (New to Govipala?)',
                          style: GoviTextStyles.caption,
                        ),
                        const SizedBox(height: GoviSpacing.xs),
                        TextButton.icon(
                          onPressed: _openCreateAccount,
                          icon: const Icon(Icons.person_add_alt_1_rounded, color: GoviColors.primary),
                          label: Text(
                            'නව ගිණුමක් සාදන්න (Create Account)',
                            style: GoviTextStyles.bodyBold.copyWith(
                              color: GoviColors.primaryDark,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: GoviColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: GoviColors.primary.withAlpha(50),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.agriculture_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: GoviSpacing.sm),
        const Text(
          'ගොවිපල | Govipala',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: GoviColors.primaryDark,
            fontFamily: 'Noto Sans Sinhala',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        const Text(
          'කෘෂි උපකරණ කුලියට ගැනීමේ සහ කළමනාකරණ සේවාව',
          style: GoviTextStyles.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: GoviColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GoviColors.primary.withAlpha(60)),
          ),
          child: Text(
            '🌾 පදවිය නියමු කලාපය (Padaviya Pilot)',
            style: GoviTextStyles.caption.copyWith(
              color: GoviColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ඔබගේ කාණ්ඩය තෝරන්න (Select Your Role):',
          style: GoviTextStyles.bodyBold,
        ),
        const SizedBox(height: GoviSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _buildRoleTab(
                role: LoginRole.farmer,
                icon: '🌾',
                labelSi: 'ගොවි',
                labelEn: 'Farmer',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRoleTab(
                role: LoginRole.owner,
                icon: '🚜',
                labelSi: 'හිමිකරු',
                labelEn: 'Owner',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRoleTab(
                role: LoginRole.admin,
                icon: '🛡️',
                labelSi: 'පරිපාලක',
                labelEn: 'Admin',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleTab({
    required LoginRole role,
    required String icon,
    required String labelSi,
    required String labelEn,
  }) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () => _applyDemoCredentialsForRole(role),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? GoviColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? GoviColors.primaryDark : GoviColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: GoviColors.primary.withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Text(
              labelSi,
              style: TextStyle(
                fontFamily: 'Noto Sans Sinhala',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : GoviColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              labelEn,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white70 : GoviColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoBadge(Map<String, String> config) {
    return Container(
      padding: const EdgeInsets.all(GoviSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // light emerald
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.key_rounded, color: GoviColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'නිරූපණ ගිණුම (${config['labelSi']}): ',
                      style: GoviTextStyles.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: GoviColors.primaryDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: GoviColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Demo: ${config['demoPassword']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '👤 ${config['demoName']} • 📍 ${config['location']}',
                  style: GoviTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
