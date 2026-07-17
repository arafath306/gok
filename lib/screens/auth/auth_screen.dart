import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import 'widgets/auth_glass_card.dart';
import 'widgets/login_form.dart';
import 'widgets/signup_form.dart';

class AuthScreen extends StatefulWidget {
  final bool initialIsSignUp;
  final VoidCallback onLoginSuccess;

  const AuthScreen({
    super.key,
    this.initialIsSignUp = false,
    required this.onLoginSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late bool _isSignUp;
  int _signUpStep = 1;

  late AnimationController _cloudController;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
    _signUpStep = 1;

    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Builder(
        builder: (context) {
          final bgColor = context.scaffoldBg;
          final titleColor = context.textPrimary;
          final subtitleColor = context.textSecondary;

          return Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: bgColor,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.70,
                    child: Image.asset(
                      'assets/auth_bg.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Main content
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Top hero section ──────────────────────────────────────
                            const SizedBox(height: 24),
                            _buildHeader(titleColor, subtitleColor),

                            // ── Auth card fills remaining space naturally ────────────
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  child: _buildCardContent(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuthGlassCard(
          child: _isSignUp
              ? SignupForm(
                  onSwitchToLogin: () {
                    setState(() {
                      _isSignUp = false;
                      _signUpStep = 1;
                    });
                  },
                  onStepChanged: (step) {
                    setState(() => _signUpStep = step);
                  },
                )
              : LoginForm(
                  onLoginSuccess: widget.onLoginSuccess,
                  onSwitchToSignUp: () {
                    setState(() {
                      _isSignUp = true;
                      _signUpStep = 1;
                    });
                  },
                ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeader(Color titleColor, Color subtitleColor) {
    if (!_isSignUp) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(left: 4.0, right: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Pigeon",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.authPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "Connect the world\n",
                      style: GoogleFonts.poppins(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w500,
                        color: titleColor,
                        height: 1.25,
                      ),
                    ),
                    TextSpan(
                      text: "One message",
                      style: GoogleFonts.poppins(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                        color: context.authPrimary,
                        height: 1.25,
                      ),
                    ),
                    TextSpan(
                      text: " at a time.",
                      style: GoogleFonts.poppins(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w500,
                        color: titleColor,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "A safe, fast and meaningful way to share moments.",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF1E293B),
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildFeaturesRow(false),
            ],
          ),
        ),
      );
    }

    String titlePart1 = "";
    String titlePart2 = "";
    String subtitle = "";

    switch (_signUpStep) {
      case 1:
        titlePart1 = "Connect\n";
        titlePart2 = "Beyond Borders";
        subtitle = "Meet new people and share every moment.";
        break;
      case 2:
        titlePart1 = "Your Privacy\n";
        titlePart2 = "Comes First";
        subtitle = "Secure your account with strong protection.";
        break;
      case 3:
      default:
        titlePart1 = "Ready to\n";
        titlePart2 = "Join Pigeon?";
        subtitle = "One last step and you're all set to go.";
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0, right: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Pigeon",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: context.authPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: titlePart1,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                      height: 1.25,
                    ),
                  ),
                  TextSpan(
                    text: titlePart2,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.authPrimary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: subtitleColor,
                height: 1.3,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),
            _buildFeaturesRow(true),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesRow(bool isSignUp) {
    final isDark = context.isDarkMode;
    final List<Map<String, dynamic>> features = isSignUp
        ? [
            {
              "icon": Icons.shield_outlined,
              "text": "Private &\nSecure",
            },
            {
              "icon": Icons.language,
              "text": "Connect\nGlobally",
            },
            {
              "icon": Icons.flash_on_outlined,
              "text": "Super\nFast",
            },
          ]
        : [
            {
              "icon": Icons.shield_outlined,
              "text": "Private by\nDesign",
            },
            {
              "icon": Icons.language,
              "text": "Connect\nGlobally",
            },
            {
              "icon": Icons.flash_on_outlined,
              "text": "Built for\nSpeed",
            },
          ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: features.map((f) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.authPrimary.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Icon(
                f["icon"] as IconData,
                color: context.authPrimary,
                size: 14,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              f["text"] as String,
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
                height: 1.15,
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.9),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
