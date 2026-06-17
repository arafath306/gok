import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../services/auth_service.dart';

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

  // ── Animation Controllers ──────────────────────────────────────────────────
  late AnimationController _cloudController;   // drifting clouds
  late AnimationController _floatController;   // pigeon bobbing
  late AnimationController _glowController;    // glow ring pulse
  late AnimationController _sparkleController; // star twinkle

  late Animation<double> _floatAnimation;
  late Animation<double> _glowAnimation;
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Drifting clouds (10s cycle)
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Mascot float (3s, up-down)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Glow ring pulse (2.2s)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Sparkle twinkling (1.8s)
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cloudController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _sparkleController.dispose();
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
        backgroundColor: const Color(0xFF1E293B),
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED).withValues(alpha: 0.55),
            const Color(0xFF4F46E5).withValues(alpha: 0.25),
            const Color(0xFF7C3AED).withValues(alpha: 0.35),
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
          color: const Color(0xFF10132A),
          borderRadius: BorderRadius.circular(23),
        ),
        child: child,
      ),
    );
  }

  Widget _buildDarkTextField({
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onTap: onTap,
        readOnly: readOnly,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
          prefixIcon: Icon(prefixIcon, color: Colors.white38, size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFF070B13).withValues(alpha: 0.6),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E293B)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E293B)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
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
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B3A), Color(0xFFFF3A5C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5E36).withValues(alpha: 0.35),
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
      final scaledX = pos.dx * 85 / 215;
      final scaledY = pos.dy * 85 / 215;
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
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA78BFA).withValues(alpha: opacity * 0.85),
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
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCircle(int step) {
    bool isCompleted = _step > step;
    bool isActive = _step == step;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive ? const Color(0xFF8B5CF6) : const Color(0xFF1E293B),
        border: isActive ? Border.all(color: Colors.white, width: 1.5) : Border.all(color: Colors.transparent),
      ),
      alignment: Alignment.center,
      child: isCompleted
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : Text(
              "$step",
              style: GoogleFonts.inter(
                color: isCompleted || isActive ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
    );
  }

  Widget _buildStepConnector(int stepAfter) {
    bool isPassed = _step > stepAfter;
    return Container(
      width: 40,
      height: 2,
      color: isPassed ? const Color(0xFF8B5CF6) : const Color(0xFF1E293B),
    );
  }

  Widget _buildStep1() {
    final authService = Provider.of<AuthService>(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDarkTextField(
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
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: 14),
        _buildDarkTextField(
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
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _sendResetCode,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                "Resend Code",
                style: GoogleFonts.inter(color: const Color(0xFF9B79FF), fontSize: 13),
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
        _buildDarkTextField(
          hint: "New Password",
          controller: _passwordController,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.white38,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        _buildDarkTextField(
          hint: "Confirm Password",
          controller: _confirmPasswordController,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.white38,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF141D19),
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
              color: Colors.white70,
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
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Text(
            "Login",
            style: GoogleFonts.inter(
              color: const Color(0xFF9B79FF),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF080A18),
      body: Stack(
        children: [
          // 1. Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0D0F24),
                    Color(0xFF080A18),
                    Color(0xFF060810),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 2. Animated cloud background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.50,
            child: AnimatedBuilder(
              animation: _cloudController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _AtmosphericBackgroundPainter(
                    cloudOffset: _cloudController.value,
                  ),
                );
              },
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
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10132A),
                            border: Border.all(color: const Color(0xFF2D3050)),
                          ),
                          child: IconButton(
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: const EdgeInsets.all(6),
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
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
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _floatController,
                            _glowController,
                            _sparkleController,
                          ]),
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatAnimation.value * 0.4),
                              child: Center(
                                child: SizedBox(
                                  height: 85,
                                  width: 85,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.center,
                                    children: [
                                      Transform.scale(
                                        scale: _glowAnimation.value,
                                        child: Container(
                                          width: 76,
                                          height: 76,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: [
                                                const Color(0xFF7C3AED).withValues(alpha: 0.32),
                                                const Color(0xFF4F46E5).withValues(alpha: 0.14),
                                                Colors.transparent,
                                              ],
                                              stops: const [0.0, 0.5, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Transform.scale(
                                        scale: _glowAnimation.value * 0.97,
                                        child: Container(
                                          width: 72,
                                          height: 72,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF9B79FF).withValues(alpha: 0.2),
                                              width: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Image.asset(
                                        "assets/pigeon_logo.png",
                                        height: 68,
                                        width: 76,
                                        fit: BoxFit.contain,
                                      ),
                                      ..._buildSparkles(_sparkleController.value),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Pigeon",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Messages. Moments. Together.",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white60,
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
                            color: const Color(0xFF8B5CF6),
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
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
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
                            color: Colors.red[900]!.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red[700]!.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            authService.errorMessage!,
                            style: GoogleFonts.inter(color: Colors.red[100], fontSize: 12),
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

// Re-use atmospheric painter class
class _AtmosphericBackgroundPainter extends CustomPainter {
  final double cloudOffset;
  _AtmosphericBackgroundPainter({required this.cloudOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final drift = math.sin(cloudOffset * 2 * math.pi);
    final drift2 = math.cos(cloudOffset * 2 * math.pi);

    final glowAlpha = 0.42 + 0.13 * drift;
    final centerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          Color(0xFF3D1F8C).withValues(alpha: glowAlpha.clamp(0.0, 1.0)),
          Color(0xFF1E0F5E).withValues(alpha: (glowAlpha * 0.5).clamp(0.0, 1.0)),
          Color(0xFF0D0F24).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.1),
        radius: size.width * 0.9,
      ));
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.1), size.width * 0.9, centerGlow);

    final leftX = size.width * 0.08 + 28.0 * drift;
    final leftY = size.height * 0.32 + 14.0 * drift2;
    final leftCloud = Paint()
      ..shader = RadialGradient(
        colors: [
          Color(0xFF5B21B6).withValues(alpha: (0.20 + 0.09 * drift).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(leftX, leftY),
        radius: size.width * 0.48,
      ));
    canvas.drawCircle(Offset(leftX, leftY), size.width * 0.48, leftCloud);

    final rightX = size.width * 0.92 - 22.0 * drift;
    final rightY = size.height * 0.22 - 12.0 * drift2;
    final rightCloud = Paint()
      ..shader = RadialGradient(
        colors: [
          Color(0xFF1E3A8A).withValues(alpha: (0.17 + 0.08 * drift2).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(rightX, rightY),
        radius: size.width * 0.42,
      ));
    canvas.drawCircle(Offset(rightX, rightY), size.width * 0.42, rightCloud);

    final fadeOut = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Color(0x99080A18),
          Color(0xFF080A18),
        ],
        stops: [0.42, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fadeOut);
  }

  @override
  bool shouldRepaint(_AtmosphericBackgroundPainter old) => old.cloudOffset != cloudOffset;
}
