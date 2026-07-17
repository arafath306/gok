import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with TickerProviderStateMixin {
  int _step = 1;

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _sendResetCode() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text.trim();

    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar("Please enter a valid email address");
      return;
    }

    final success = await authService.sendPasswordReset(email);
    if (success && mounted) {
      _showSnackBar("Reset link/code sent to your email!");
      setState(() => _step = 2);
    }
  }

  void _verifyResetCode() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text.trim();
    final token = _codeController.text.trim();

    if (token.isEmpty || token.length < 6) {
      _showSnackBar("Please enter the 6-digit verification code");
      return;
    }

    final success = await authService.verifyResetOTP(email, token);
    if (success && mounted) {
      setState(() => _step = 3);
    }
  }

  void _resetPassword() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final pass = _passwordController.text;
    final conf = _confirmPasswordController.text;

    if (pass.isEmpty || pass.length < 6) {
      _showSnackBar("Password must be at least 6 characters long");
      return;
    }
    if (pass != conf) {
      _showSnackBar("Passwords do not match");
      return;
    }

    final success = await authService.updatePassword(pass);
    if (success && mounted) {
      setState(() => _step = 4); // Success step
    }
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

  Widget _buildGlassCard({required Widget child}) {
    final isDark = context.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [
                  context.authAccent1.withValues(alpha: 0.55),
                  context.authAccent2.withValues(alpha: 0.25),
                  context.authAccent1.withValues(alpha: 0.35),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  context.authPrimary.withValues(alpha: 0.18),
                  context.authSecondary.withValues(alpha: 0.08),
                  context.authPrimary.withValues(alpha: 0.14),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: context.customCardBg,
          borderRadius: BorderRadius.circular(23),
        ),
        child: child,
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    final isDark = context.isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onTap: onTap,
        readOnly: readOnly,
        style: GoogleFonts.inter(
          color: context.textPrimary,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: context.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            prefixIcon,
            size: 20,
          ),
          prefixIconColor: WidgetStateColor.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return context.authPrimary;
            }
            return context.textMuted;
          }),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: isDark
              ? const Color(0xFF0F172A).withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.90),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isDark
                  ? const Color(0xFF334155).withValues(alpha: 0.7)
                  : const Color(0xFFE2E8F0).withValues(alpha: 0.8),
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: context.authPrimary, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.authPrimary, context.authSecondary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: context.authPrimary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(23),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white, size: 18),
                  ],
                ],
              ),
      ),
    );
  }


  Widget _buildStepIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepCircle(1),
            _buildStepConnector(1),
            _buildStepCircle(2),
            _buildStepConnector(2),
            _buildStepCircle(3),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Step $_step of 3",
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCircle(int step) {
    final isDark = context.isDarkMode;
    bool isCompleted = _step > step;
    bool isActive = _step == step;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive
            ? context.authPrimary
            : isDark
                ? context.border
                : context.border,
        border: isActive
            ? Border.all(
                color: context.textPrimary,
                width: 1.5)
            : Border.all(color: Colors.transparent),
      ),
      alignment: Alignment.center,
      child: isCompleted
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : Text(
              "$step",
              style: GoogleFonts.inter(
                color: isCompleted || isActive
                    ? Colors.white
                    : isDark
                        ? Colors.white38
                        : context.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
    );
  }

  Widget _buildStepConnector(int stepAfter) {
    final isDark = context.isDarkMode;
    bool isPassed = _step > stepAfter;
    return Container(
      width: 40,
      height: 2,
      color: isPassed
          ? context.authPrimary
          : isDark
              ? context.border
              : context.border,
    );
  }

  Widget _buildStep1() {
    final authService = Provider.of<AuthService>(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          hint: "Your Account Email",
          controller: _emailController,
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        _buildGradientButton(
          label: "Send Reset Code",
          icon: Icons.send_rounded,
          isLoading: authService.isLoading,
          onPressed: _sendResetCode,
        ),
        const SizedBox(height: 16),
        _buildBackToLoginLink(),
      ],
    );
  }

  Widget _buildStep2() {
    final authService = Provider.of<AuthService>(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "We sent a 6-digit recovery code to ${_emailController.text}. Please check your email inbox or spam.",
          style: GoogleFonts.inter(
            fontSize: 12,
            color: context.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        _buildTextField(
          hint: "6-Digit Code (OTP)",
          controller: _codeController,
          prefixIcon: Icons.vpn_key_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        _buildGradientButton(
          label: "Verify OTP Code",
          icon: Icons.verified_user_outlined,
          isLoading: authService.isLoading,
          onPressed: _verifyResetCode,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => setState(() => _step = 1),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                "< Edit Email",
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: _sendResetCode,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                "Resend Code",
                style: GoogleFonts.inter(
                  color: context.authPrimary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final authService = Provider.of<AuthService>(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          hint: "New Password",
          controller: _passwordController,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: context.textMuted,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        _buildTextField(
          hint: "Confirm Password",
          controller: _confirmPasswordController,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: context.textMuted,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ),
        const SizedBox(height: 8),
        _buildGradientButton(
          label: "Save & Reset Password",
          icon: Icons.save_outlined,
          isLoading: authService.isLoading,
          onPressed: _resetPassword,
        ),
      ],
    );
  }

  Widget _buildStep4() {
    final isDark = context.isDarkMode;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141D19) : const Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF05D782),
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Success!",
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF05D782),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your password has been reset successfully.\nYou can now login with your new password.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _buildGradientButton(
            label: "Go back to Login",
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Remembered password? ",
          style: GoogleFonts.inter(
            color: context.textSecondary,
            fontSize: 13,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Text(
            "Login",
            style: GoogleFonts.inter(
              color: context.authPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isDark = context.isDarkMode;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Theme-aware colors
    final bgColor = context.scaffoldBg;
    final titleColor = context.textPrimary;
    final subtitleColor = context.textSecondary;
    final backBtnBg = context.customCardBg;
    final backBtnBorder = context.border;
    final backBtnIconColor = context.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Vector background image
          Positioned.fill(
            child: Opacity(
              opacity: 0.85,
              child: Image.asset(
                'assets/auth_bg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: Column(
              children: [
                // ── Top: Back button & Mascot ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: backBtnBg,
                            border: Border.all(color: backBtnBorder),
                            boxShadow: isDark
                                ? []
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: IconButton(
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: const EdgeInsets.all(6),
                            icon: Icon(Icons.arrow_back, color: backBtnIconColor, size: 18),
                            onPressed: () {
                              if (_step > 1 && _step < 4) {
                                setState(() => _step--);
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ),
                      ),

                      // Mascot (hidden if keyboard is visible)
                      if (!isKeyboardOpen) ...[
                        const SizedBox(height: 24),
                        Text(
                          "Pigeon",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Messages. Moments. Together.",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: subtitleColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],

                      // Titles & Progress indicator (hidden on success step)
                      if (_step < 4) ...[
                        const SizedBox(height: 6),
                        Text(
                          "Reset Password",
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: context.authPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _step == 1
                              ? "Enter your email to request a reset"
                              : _step == 2
                                  ? "Enter the code sent to your email"
                                  : "Type your new strong password",
                          style: GoogleFonts.inter(fontSize: 13, color: subtitleColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        _buildStepIndicator(),
                      ],

                      // Error Banner
                      if (authService.errorMessage != null && _step < 4)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: Colors.red[900]!.withValues(alpha: isDark ? 0.3 : 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red[700]!.withValues(alpha: isDark ? 0.5 : 0.35)),
                          ),
                          child: Text(
                            authService.errorMessage!,
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.red[100] : Colors.red[900],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Bottom: Form card ────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    physics: isKeyboardOpen ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                    child: Column(
                      children: [
                        if (!isKeyboardOpen) const SizedBox(height: 16),
                        _buildGlassCard(
                          child: _step == 1
                              ? _buildStep1()
                              : _step == 2
                                  ? _buildStep2()
                                  : _step == 3
                                      ? _buildStep3()
                                      : _buildStep4(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

