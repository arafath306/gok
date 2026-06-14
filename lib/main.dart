import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/notification_settings_provider.dart';
import 'services/chat_settings_provider.dart';
import 'services/general_settings_provider.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/main_screen.dart';
import 'utils/app_theme.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: "https://lznxtbnqwaryqkyxfwgy.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6bnh0Ym5xd2FyeXFreXhmd2d5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEzNTk1MjIsImV4cCI6MjA5NjkzNTUyMn0.PGQqRFmGjE5GncIs5Eeqf5fvgxQtDMgvggNLzNEGOJk",
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DatabaseService()),
        ChangeNotifierProvider(create: (_) => NotificationSettingsProvider()),
        ChangeNotifierProvider(create: (_) => ChatSettingsProvider()),
        ChangeNotifierProvider(create: (_) => GeneralSettingsProvider()),
      ],
      child: const PigeonApp(),
    ),
  );
}

class PigeonApp extends StatelessWidget {
  const PigeonApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<GeneralSettingsProvider>(context);

    return MaterialApp(
      title: 'Pigeon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsProvider.themeMode,
      builder: (context, child) {
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isWide = screenWidth > 600;
        if (isWide) {
          const double targetWidth = 500;
          return Container(
            color: settingsProvider.isDarkTheme ? const Color(0xFF000000) : const Color(0xFFF4F6F8), // Premium web background
            child: Center(
              child: Container(
                width: targetWidth,
                decoration: BoxDecoration(
                  color: settingsProvider.isDarkTheme ? const Color(0xFF0D0F1A) : Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: Size(targetWidth, MediaQuery.of(context).size.height),
                  ),
                  child: child!,
                ),
              ),
            ),
          );
        }
        return child ?? const SizedBox.shrink();
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _showOnboarding = true;
  bool _startSignUp = false;

  @override
  void initState() {
    super.initState();
    _loadSplash();
  }

  Future<void> _loadSplash() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    final authService = Provider.of<AuthService>(context);
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    // If user is logged in, show MainScreen
    if (authService.isUserSignedIn) {
      return const MainScreen();
    }

    // User signed out — clear DatabaseService cache
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) dbService.clearUser();
    });

    // Otherwise show Onboarding, followed by Auth Screen
    if (_showOnboarding) {
      return OnboardingScreen(
        onFinish: () {
          setState(() {
            _showOnboarding = false;
            _startSignUp = false;
          });
        },
      );
    }

    return AuthScreen(
      initialIsSignUp: _startSignUp,
      onLoginSuccess: () {
        // Upon successful auth, AuthService will trigger state change, causing AuthGate rebuild.
      },
    );
  }
}
