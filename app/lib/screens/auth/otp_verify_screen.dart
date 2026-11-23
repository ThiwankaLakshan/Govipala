import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/govi_button.dart';
import 'registration_screen.dart';
import '../farmer/home_screen.dart';
import '../owner/home_screen.dart';
import '../../models/user.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerifyScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length < 4) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isExistingUser = await _authService.verifyOtp(widget.phoneNumber, code);
      if (!mounted) return;

      if (isExistingUser && _authService.currentUser != null) {
        // Direct to appropriate home screen
        final role = _authService.currentUser!.role;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => role == UserRole.owner
                ? const OwnerHomeScreen()
                : const FarmerHomeScreen(),
          ),
          (route) => false,
        );
      } else {
        // Need to complete registration
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RegistrationScreen(
              phoneNumber: widget.phoneNumber,
              authService: _authService,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'OTP කේතය වැරදියි. කරුණාකර නැවත උත්සාහ කරන්න.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoviColors.background,
      appBar: AppBar(
        title: const Text('තහවුරු කිරීම (Verification)'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(GoviSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: GoviSpacing.lg),
              Text(
                '${widget.phoneNumber} වෙත එවන ලද OTP කේතය ඇතුළත් කරන්න',
                style: GoviTextStyles.screenTitle,
              ),
              const SizedBox(height: GoviSpacing.sm),
              const Text(
                'කරුණාකර කෙටි පණිවුඩ මඟින් ලැබුණු අංක 6 කේතය ඇතුළත් කරන්න.',
                style: GoviTextStyles.caption,
              ),
              const SizedBox(height: GoviSpacing.xxl),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: GoviTextStyles.screenTitle.copyWith(letterSpacing: 8.0),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '• • • • • •',
                ),
                onChanged: (val) {
                  if (val.length >= 6) _verify();
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: GoviSpacing.md),
                Text(
                  _errorMessage!,
                  style: GoviTextStyles.caption.copyWith(color: GoviColors.danger),
                ),
              ],
              const Spacer(),
              GoviButton(
                label: 'තහවුරු කරන්න (Verify)',
                icon: Icons.check_circle_rounded,
                isLoading: _isLoading,
                onPressed: _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
