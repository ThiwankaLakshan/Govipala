import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/text_styles.dart';
import '../../widgets/govi_button.dart';
import 'otp_verify_screen.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isValid = false;

  void _onPhoneChanged(String value) {
    final clean = value.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _isValid = clean.length >= 9;
    });
  }

  void _submit() {
    final clean = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    final fullNumber = clean.startsWith('0') ? '+94${clean.substring(1)}' : '+94$clean';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpVerifyScreen(phoneNumber: fullNumber),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GoviColors.background,
      appBar: AppBar(
        title: const Text('ගොවිපල (Govipala)'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(GoviSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: GoviSpacing.xl),
              const Icon(
                Icons.agriculture_rounded,
                size: 56.0,
                color: GoviColors.primary,
              ),
              const SizedBox(height: GoviSpacing.lg),
              const Text(
                'ඔබගේ දුරකථන අංකය ඇතුළත් කරන්න',
                style: GoviTextStyles.screenTitle,
              ),
              const SizedBox(height: GoviSpacing.sm),
              const Text(
                'ගොවිපල සේවාව භාවිතා කිරීමට ඔබගේ ජංගම දුරකථන අංකයට තහවුරු කිරීමේ කෙටි පණිවිඩයක් (OTP) එවනු ලැබේ.',
                style: GoviTextStyles.caption,
              ),
              const SizedBox(height: GoviSpacing.xxl),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: _onPhoneChanged,
                style: GoviTextStyles.bodyBold,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    child: Text(
                      '🇱🇰 +94',
                      style: GoviTextStyles.bodyBold.copyWith(color: GoviColors.primaryDark),
                    ),
                  ),
                  hintText: '77 123 4567',
                ),
              ),
              const Spacer(),
              GoviButton(
                label: 'OTP කේතය ලබාගන්න (Get Code)',
                icon: Icons.arrow_forward_rounded,
                onPressed: _isValid ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
