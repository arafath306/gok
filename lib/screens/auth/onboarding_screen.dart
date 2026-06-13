import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({Key? key, required this.onFinish}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E824C),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "ডাক",
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1E824C),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: onFinish,
                    child: Text(
                      "Skip",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1E824C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Image
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: Image.network(
                    "https://images.unsplash.com/photo-1544787219-7f47ccb76574",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Welcome text
              Text(
                "সবাইকে ডাকুন",
                textAlign: TextAlign.center,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Connect with Everyone",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "আপনার মনের কথা শেয়ার করুন সবার সাথে।",
                textAlign: TextAlign.center,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Text(
                "Share your thoughts with the community.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),

              // Next Button
              ElevatedButton(
                onPressed: onFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E824C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: Text(
                  "পরবর্তী (Next)",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                "বাংলা ও English সাপোর্ট করে",
                textAlign: TextAlign.center,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
