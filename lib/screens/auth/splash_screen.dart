import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/dak_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Animated Fade-in Pigeon Logo
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: child,
                  ),
                );
              },
              child: const DakLogo(size: 160),
            ),
            const SizedBox(height: 16),
            // App Name
            Text(
              'Pigeon',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: const Color(0xFF7C4DFF),
              ),
            ),
            const Spacer(),
            // Loading indicator at bottom
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E824C)),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
