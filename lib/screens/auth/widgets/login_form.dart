import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_theme.dart';
import '../two_factor_verification_screen.dart';
import '../email_verification_pending_screen.dart';
import '../forgot_password_screen.dart';
import 'auth_text_field.dart';
import 'gradient_action_button.dart';
import 'social_login_buttons.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onSwitchToSignUp;

  const LoginForm({
    super.key,
    required this.onLoginSuccess,
    required this.onSwitchToSignUp,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureLoginPassword = true;

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: context.buttonBg,
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
    );
  }

  void _submitLogin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final identifier = _emailPhoneController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter your email and password');
      return;
    }

    final result = await authService.handleLogin(identifier, password);
    if (!mounted) return;

    if (result == LoginResult.success) {
      widget.onLoginSuccess();
    } else if (result == LoginResult.requires2FA) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TwoFactorVerificationScreen(
            onVerificationSuccess: widget.onLoginSuccess,
          ),
        ),
      );
    } else {
      if (authService.errorMessage != null &&
          authService.errorMessage!.contains('not been verified')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerificationPendingScreen(
              email: identifier.contains('@') ? identifier : null,
              password: password,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isDark = context.isDarkMode;
    
    final accentColor = context.authPrimary;
    final subtitleColor = context.textSecondary;
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE2E8F0);
    final orTextColor = context.textMuted;
    final registerLinkColor = context.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back!",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Login to continue your journey",
          style: GoogleFonts.inter(fontSize: 13, color: subtitleColor),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          hint: "Email or Username",
          controller: _emailPhoneController,
          prefixIcon: Icons.mail_outline_rounded,
        ),
        AuthTextField(
          hint: "Password",
          controller: _passwordController,
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscureLoginPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureLoginPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: () => setState(
                () => _obscureLoginPassword = !_obscureLoginPassword),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ForgotPasswordScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              "Forgot password?",
              style: GoogleFonts.inter(
                color: accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GradientActionButton(
          label: "Login",
          icon: Icons.arrow_forward,
          isLoading: authService.isLoading,
          onPressed: _submitLogin,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Divider(color: dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                "or continue with",
                style: GoogleFonts.inter(color: orTextColor, fontSize: 12),
              ),
            ),
            Expanded(child: Divider(color: dividerColor)),
          ],
        ),
        const SizedBox(height: 12),
        const SocialLoginButtons(),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: GoogleFonts.inter(
                  color: registerLinkColor, fontSize: 13),
            ),
            GestureDetector(
              onTap: widget.onSwitchToSignUp,
              child: Text(
                "Register >",
                style: GoogleFonts.inter(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
