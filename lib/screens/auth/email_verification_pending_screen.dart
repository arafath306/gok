import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import 'auth_screen.dart';

class EmailVerificationPendingScreen extends StatefulWidget {
  final String? email;
  final String? password;

  const EmailVerificationPendingScreen({
    super.key,
    this.email,
    this.password,
  });

  @override
  State<EmailVerificationPendingScreen> createState() => _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState extends State<EmailVerificationPendingScreen> {
  int _cooldownSeconds = 0;
  Timer? _timer;
  bool _isResending = false;
  String? _statusMessage;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _resendEmail(AuthService authService) async {
    if (_cooldownSeconds > 0 || _isResending) return;
    
    final email = widget.email ?? authService.currentUser?.email;
    if (email == null) return;

    setState(() {
      _isResending = true;
      _statusMessage = null;
    });

    final success = await authService.resendVerificationEmail(email);

    if (mounted) {
      setState(() {
        _isResending = false;
        if (success) {
          _statusMessage = "Verification email resent successfully!";
          _startCooldown();
        } else {
          _statusMessage = authService.errorMessage ?? "Failed to resend. Try again later.";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isDark = context.isDarkMode;
    final email = widget.email ?? authService.currentUser?.email ?? 'your email';

    final bgColor = isDark ? context.authBgDark2 : context.authBgLight1;
    final accentColor = context.authPendingAccent;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background image — 85% opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.85,
              child: Image.asset(
                'assets/auth_bg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Warning / Notice Banner ──────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.50),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: Colors.amber, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Email verification service is currently off. '
                              'Please click "Back to Login" to sign in to your account.',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                height: 1.45,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Verification pending icon
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(22),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        color: accentColor,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Title
                    Text(
                      "Verify your email",
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    Text(
                      "We have sent a verification link to:",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Please check your inbox (and spam folder) and click the link to confirm your account.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.4,
                        color: const Color(0xFF64748B),
                      ),
                    ),

                    const SizedBox(height: 28),

                    if (_statusMessage != null) ...[
                      Text(
                        _statusMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _statusMessage!.contains("resend") ||
                                  _statusMessage!.contains("Failed")
                              ? Colors.red[400]
                              : const Color(0xFF05D782),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Resend email button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_cooldownSeconds > 0 || _isResending)
                            ? null
                            : () => _resendEmail(authService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: accentColor.withAlpha(76),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isResending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _cooldownSeconds > 0
                                    ? "Resend email (${_cooldownSeconds}s)"
                                    : "Resend verification email",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Back to Login button
                    TextButton(
                      onPressed: () async {
                        await authService.handleSignout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AuthScreen(
                                onLoginSuccess: () {},
                              ),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                      ),
                      child: Text(
                        "Back to Login",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
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
