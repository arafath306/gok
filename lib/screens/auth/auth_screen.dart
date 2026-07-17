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

  late AnimationController _cloudController;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;

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

                          if (!_isSignUp) ...[
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
                          const SizedBox(height: 28),
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
                                                setState(() => _isSignUp = false);
                                              },
                                            )
                                          : LoginForm(
                                              onLoginSuccess: widget.onLoginSuccess,
                                              onSwitchToSignUp: () {
                                                setState(() => _isSignUp = true);
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
}
