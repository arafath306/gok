import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/logo_d_icon_v2.jpg',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dak",
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1E824C),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            "— সংযোগ থাকুক হৃদয়ের —",
                            style: GoogleFonts.hindSiliguri(
                              color: Colors.grey[700],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: widget.onFinish,
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
              const SizedBox(height: 24),

              // Image Slider with Navigation Arrows
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(color: Colors.black12, width: 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        children: [
                          Image.asset(
                            'assets/onboarding_1.jpg',
                            fit: BoxFit.contain,
                          ),
                          Image.asset(
                            'assets/onboarding_2.jpg',
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                    // Left Arrow Button
                    if (_currentPage > 0)
                      Positioned(
                        left: 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: InkWell(
                            onTap: () {
                              _pageController.jumpToPage(_currentPage - 1);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(255, 255, 255, 0.9),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.chevron_left,
                                color: Color(0xFF1E824C),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Right Arrow Button
                    if (_currentPage < 1)
                      Positioned(
                        right: 12,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: InkWell(
                            onTap: () {
                              _pageController.jumpToPage(_currentPage + 1);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(255, 255, 255, 0.9),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              child: const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF1E824C),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Indicators (Dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? const Color(0xFF1E824C)
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

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
              const SizedBox(height: 8),
              Text(
                "আপনার মনের কথা শেয়ার করুন সবার সাথে।",
                textAlign: TextAlign.center,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              Text(
                "Share your thoughts with the community.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),

              // Next Button
              ElevatedButton(
                onPressed: () {
                  if (_currentPage < 1) {
                    // Slide without animation (jumpToPage) as requested
                    _pageController.jumpToPage(_currentPage + 1);
                  } else {
                    widget.onFinish();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E824C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: Text(
                  _currentPage < 1 ? "পরবর্তী (Next)" : "শুরু করুন (Get Started)",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                "বাংলা ও English সাপোর্ট করে",
                textAlign: TextAlign.center,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 11,
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
