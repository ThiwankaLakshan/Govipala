import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Localized values map: English (primary) & Sinhala (to be added)
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Govipala',
      'login': 'Login',
      'register': 'Register',
      'phone_number': 'Phone Number',
      'enter_phone': 'Enter your phone number',
      'verify': 'Verify',
      'enter_otp': 'Enter OTP code',
      'full_name': 'Full Name',
      'enter_name': 'Enter your full name',
      'role': 'Role',
      'gn_division': 'GN Division',
      'select_gn': 'Select your GN Division',
      'language': 'Language',
      'save': 'Save',
      'owner': 'Machine Owner',
      'farmer': 'Farmer',
      'both': 'Both (Owner & Farmer)',
      // Add more English strings here
    },
    'si': {
      // Sinhala translations will be added here
      'app_title': 'ගොවිපල',
      'login': 'ලොගින් වන්න',
      'register': 'ලියාපදිංචි වන්න',
      'phone_number': 'දුරකථන අංකය',
      'enter_phone': 'ඔබගේ දුරකථන අංකය ඇතුලත් කරන්න',
      'verify': 'තහවුරු කරන්න',
      'enter_otp': 'OTP කේතය ඇතුලත් කරන්න',
      'full_name': 'සම්පූර්ණ නම',
      'enter_name': 'ඔබගේ සම්පූර්ණ නම ඇතුලත් කරන්න',
      'role': 'භූමිකාව',
      'gn_division': 'ග්‍රාම නිලධාරී වසම',
      'select_gn': 'ග්‍රාම නිලධාරී වසම තෝරන්න',
      'language': 'භාෂාව',
      'save': 'සුරකින්න',
      'owner': 'යන්ත්‍ර අයිතිකරු',
      'farmer': 'ගොවි මහතා',
      'both': 'අයිතිකරු සහ ගොවි',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? 
           key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'si'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
