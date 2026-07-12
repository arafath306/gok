import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../utils/app_theme.dart';
import 'widgets/auth_background_painter.dart';
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

  // ── Animation Controllers ──────────────────────────────────────────────────
  late AnimationController _cloudController;
  late AnimationController _floatController;
  late AnimationController _glowController;
  late AnimationController _sparkleController;

  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;

    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  List<Widget> _buildSparkles(double t) {
    const positions = [
      Offset(108, 6),
      Offset(192, 40),
      Offset(210, 105),
      Offset(188, 172),
      Offset(108, 208),
      Offset(28, 172),
      Offset(6, 105),
      Offset(22, 40),
    ];

    return positions.asMap().entries.map((entry) {
      final i = entry.key;
      final pos = entry.value;
      final scaledX = pos.dx * 125 / 215;
      final scaledY = pos.dy * 125 / 215;
      final phase = ((t + i / positions.length) % 1.0);
      final opacity = math.sin(phase * math.pi).clamp(0.0, 1.0);
      final dotSize = (i % 3 == 0) ? 2.5 : 1.5;

      return Positioned(
        left: scaledX,
        top: scaledY,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.authPrimary,
              boxShadow: [
                BoxShadow(
                  color: context.authPrimary.withValues(alpha: opacity * 0.8),
                  blurRadius: 5,
                  spreadRadius: 1.5,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Theme-aware colors
    final bgColor = context.scaffoldBg;
    final titleColor = context.textPrimary;
    final subtitleColor = context.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Animated atmospheric background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          context.authBgDark1,
                          context.authBgDark2,
                          context.authBgDark3,
                        ]
                      : [
                          context.authBgLight1,
                          context.authBgLight2,
                          context.authBgLight3,
                        ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 2. Animated cloud painter
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _cloudController,
              builder: (context, child) {
                return CustomPaint(
                  painter: AtmosphericBackgroundPainter(
                    cloudOffset: _cloudController.value,
                    isDark: isDark,
                  ),
                );
              },
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
                          // Wrap back button and logo in a Stack to save vertical space
                          SizedBox(
                            height: isKeyboardOpen ? 48 : 125,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // HERO: animated logo + sparkles (centered)
                                if (!isKeyboardOpen)
                                  Align(
                                    alignment: Alignment.center,
                                    child: AnimatedBuilder(
                                      animation: Listenable.merge([
                                        _floatController,
                                        _glowController,
                                        _sparkleController,
                                      ]),
                                      builder: (context, child) {
                                        return Transform.translate(
                                          offset: Offset(0, _floatAnimation.value * 0.4),
                                          child: SizedBox(
                                            height: 125,
                                            width: 125,
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              alignment: Alignment.center,
                                              children: [
                                                // Glow ring
                                                Transform.scale(
                                                  scale: _glowAnimation.value,
                                                  child: Container(
                                                    width: 110,
                                                    height: 110,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      gradient: RadialGradient(
                                                        colors: [
                                                          context.authPrimary.withValues(alpha: isDark ? 0.32 : 0.16),
                                                          context.authSecondary.withValues(alpha: isDark ? 0.14 : 0.06),
                                                          Colors.transparent,
                                                        ],
                                                        stops: const [0.0, 0.5, 1.0],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Ring stroke
                                                Transform.scale(
                                                  scale: _glowAnimation.value * 0.97,
                                                  child: Container(
                                                    width: 104,
                                                    height: 104,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: context.authPrimary.withValues(alpha: isDark ? 0.2 : 0.12),
                                                        width: 1.2,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // App logo
                                                ClipOval(
                                                  child: Image.asset(
                                                    'assets/logo_transparent.png',
                                                    width: 90,
                                                    height: 90,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                // Sparkles
                                                ..._buildSparkles(_sparkleController.value),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

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
                          const SizedBox(height: 16),
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
  }
}
