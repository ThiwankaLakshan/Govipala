import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GovipalaApp());
}

class GovipalaApp extends StatelessWidget {
  const GovipalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Govipala',
      theme: GoviTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      locale: const Locale('si'), // Sinhala-first UI per PRD
      supportedLocales: const [
        Locale('si'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppShell(),
    );
  }
}
