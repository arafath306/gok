import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase with Web/Android dynamic options
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAxpyiGa7kHXAmTFIiiwet6-84ZBmY-ZpY",
        authDomain: "dak-auth.firebaseapp.com",
        projectId: "dak-auth",
        storageBucket: "dak-auth.firebasestorage.app",
        messagingSenderId: "528559248540",
        appId: "1:528559248540:web:d26d7449c25da722794959",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  // 2. Initialize Supabase
  await Supabase.initialize(
    url: "https://ibesspeysnqikrzovmtm.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImliZXNzcGV5c25xaWtyem92bXRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAzNzA4NDEsImV4cCI6MjA5NTk0Njg0MX0.BNGNubP-fAXEE-VZaFUCZe-jsOdEVR832OCFBj16m9Q",
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DatabaseService()),
      ],
      child: const DakApp(),
    ),
  );
}

class DakApp extends StatelessWidget {
  const DakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E824C),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E824C),
          primary: const Color(0xFF1E824C),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.hindSiliguriTextTheme(
          ThemeData.light().textTheme,
        ),
      ),
      builder: (context, child) {
        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isWide = screenWidth > 600;
        if (isWide) {
          const double targetWidth = 500;
          return Container(
            color: const Color(0xFFF4F6F8), // Premium web background
            child: Center(
              child: Container(
                width: targetWidth,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
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
  bool _showOnboarding = true;
  bool _startSignUp = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    // If user is logged in, push Firebase UID to DatabaseService and show MainScreen
    if (authService.isUserSignedIn) {
      // Pass Firebase UID so DatabaseService can do read-only queries even
      // before a Supabase session is established
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && authService.currentUid.isNotEmpty) {
          dbService.setFirebaseUid(authService.currentUid);
        }
      });
      return const MainScreen();
    }

    // User signed out — clear DatabaseService cache
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) dbService.clearUser();
    });

    // Otherwise show Onboarding, followed by Auth Screen
    if (_showOnboarding) {
      return OnboardingScreen(
        onGetStarted: () {
          setState(() {
            _showOnboarding = false;
            _startSignUp = true;
          });
        },
        onLogin: () {
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
