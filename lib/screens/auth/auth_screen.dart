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
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Theme(
      data: AppTheme.lightTheme,
      child: Builder(
        builder: (context) {
          final bgColor = context.scaffoldBg;
          final titleColor = context.textPrimary;
          final subtitleColor = context.textSecondary;

          return Scaffold(
            backgroundColor: bgColor,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.85,
                    child: Image.asset(
                      'assets/auth_bg.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

          // 3. Main content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SafeArea(
                child: Column(
                  children: [
                    // ── Top hero section ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          if (!isKeyboardOpen) const SizedBox(height: 28),
                          if (!isKeyboardOpen) const SizedBox(height: 36),

                          _buildHeader(titleColor, subtitleColor),
                        ],
                      ),
                    ),

                    // ── Bottom: auth card ────────────────────────────────────
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: isKeyboardOpen
                                ? const ClampingScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 4.0),
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(minHeight: constraints.maxHeight),
                              child: IntrinsicHeight(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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

  Widget _buildHeader(Color titleColor, Color subtitleColor) {
    if (!_isSignUp) {
      return Column(
        children: [
          Text(
            "Pigeon",
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: titleColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Messages. Moments. Together.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: subtitleColor,
              letterSpacing: 0.4,
            ),
          ),
        ],
      );
    }

    String titlePart1 = "";
    String titlePart2 = "";
    String subtitle = "";

    switch (_signUpStep) {
      case 1:
        titlePart1 = "Connect\n";
        titlePart2 = "Beyond Borders";
        subtitle = "Meet new people and share\nevery moment that matters.";
        break;
      case 2:
        titlePart1 = "Your Privacy\n";
        titlePart2 = "Comes First";
        subtitle = "Secure your account with\nstrong protection.";
        break;
      case 3:
      default:
        titlePart1 = "Ready to\n";
        titlePart2 = "Join Pigeon?";
        subtitle = "One last step and you're\nall set to go.";
        break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: titlePart1,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                      height: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: titlePart2,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: context.authPrimary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: subtitleColor,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
