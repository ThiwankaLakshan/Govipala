import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'localization/app_localizations.dart';
import 'services/auth_service.dart';
import 'screens/owner/add_machine.dart';
import 'screens/farmer/browse_machines.dart';
import 'screens/auth/phone_entry.dart';
import 'screens/auth/otp_verify.dart';
import 'screens/auth/register_profile_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/owner/availability_calendar.dart';
import 'screens/owner/booking_requests.dart';
import 'screens/farmer/my_bookings.dart';
import 'screens/shared/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (wrap in try-catch to support running mock state without active configs)
  try {
    // In actual app setup, call Firebase.initializeApp() here
    // await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e. Running in offline/mock mode.');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const GovipalaApp(),
    ),
  );
}

class GovipalaApp extends StatefulWidget {
  const GovipalaApp({super.key});

  @override
  State<GovipalaApp> createState() => _GovipalaAppState();
}

class _GovipalaAppState extends State<GovipalaApp> {
  Locale _locale = const Locale('en', '');

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Govipala',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('si', ''),
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const RootScreen(),
        '/login': (context) => const PhoneEntryScreen(),
        '/register': (context) => const PhoneEntryScreen(),
        '/login/otp': (context) => const OtpVerifyScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/owner/add_machine': (context) => const AddMachineScreen(),
        '/farmer/browse_machines': (context) => const BrowseMachinesScreen(),
        '/owner/availability_calendar': (context) => const AvailabilityCalendarScreen(),
        '/owner/booking_requests': (context) => const BookingRequestsScreen(),
        '/farmer/my_bookings': (context) => const MyBookingsScreen(),
      },
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Route redirection based on authentication and registration states
    if (!authService.isAuthenticated) {
      return const InitialLandingScreen();
    }

    if (!authService.isProfileRegistered) {
      return const RegisterProfileScreen();
    }

    return const DashboardScreen();
  }
}

class InitialLandingScreen extends StatelessWidget {
  const InitialLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.agriculture,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                t.translate('app_title'),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Agricultural Machine Reservation System',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(t.translate('login')),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: Colors.green,
                ),
                child: Text(t.translate('register')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String title;

  const PlaceholderWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          '$title under construction.',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
