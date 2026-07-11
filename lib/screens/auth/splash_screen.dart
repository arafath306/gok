import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/dak_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Perfectly centered logo to match native splash screen
          const Center(
            child: DakLogo(size: 160),
          ),
          
          // App Name below the logo
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 240), // 160/2 + spacing
              child: Text(
                'Pigeon',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: const Color(0xFF1E824C),
                ),
              ),
            ),
          ),
          
          // Loading indicator at bottom
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 48.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E824C)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
