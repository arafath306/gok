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
    final email = authService.currentUser?.email ?? 'your email';

    final bgColor = isDark ? const Color(0xFF080A18) : const Color(0xFFF4F8FD);
    final cardBg = isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(5);
    final cardBorder = isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(12);
    final accentColor = const Color(0xFF5B7FFF);

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
              ? [const Color(0xFF080A18), const Color(0xFF0F172A)] 
              : [const Color(0xFFF4F8FD), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: cardBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 76 : 12),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Verification pending icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      color: accentColor,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Title
                  Text(
                    "Verify your email",
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    "We have sent a verification link to:\n",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Please check your inbox (and spam folder) and click the link to confirm your account.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  if (_statusMessage != null) ...[
                    Text(
                      _statusMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _statusMessage!.contains("resend") || _statusMessage!.contains("Failed")
                            ? Colors.red[400] 
                            : const Color(0xFF05D782),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Resend email button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
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
                          borderRadius: BorderRadius.circular(16),
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
                  const SizedBox(height: 16),
                  
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
                      foregroundColor: isDark ? Colors.white70 : const Color(0xFF64748B),
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
      ),
    );
  }
}
