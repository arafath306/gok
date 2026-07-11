import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../services/auth_service.dart';
import 'two_factor_verification_screen.dart';
import '../../utils/app_theme.dart';
import 'forgot_password_screen.dart';
import 'email_verification_pending_screen.dart';

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

  // Login Controllers
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  // Registration Controllers
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureSignUpPassword = true;
  bool _obscureConfirmPassword = true;

  bool _isScanningUsername = false;
  bool? _usernameAvailable;
  String? _usernameError;
  Timer? _debounce;

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
    _emailPhoneController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _signUpPasswordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _debounce?.cancel();
    _cloudController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    _sparkleController.dispose();
    super.dispose();
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
      // If the error specifically mentions email not verified, auto-navigate
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

  void _submitSignup() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final password = _signUpPasswordController.text;
    final email = _emailController.text.trim();

    final success = await authService.handleSignup(
      email: email,
      password: password,
      fullName: _fullNameController.text.trim(),
      phone: '',
      gender: 'Not Specified',
      birthdate: _dobController.text.trim(),
      username: _usernameController.text.trim(),
      division: '',
      city: '',
      village: '',
      zip: '',
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationPendingScreen(
            email: email,
            password: password,
          ),
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    final isDark = context.isDarkMode;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
        content: Text(
          message,
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
    );
  }

  void _checkUsernameAvailability(String username) async {
    if (username.trim().isEmpty) {
      setState(() {
        _usernameAvailable = null;
        _usernameError = null;
      });
      return;
    }

    final reg = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    if (!reg.hasMatch(username)) {
      setState(() {
        _usernameAvailable = false;
        _usernameError = "Username must be 3-20 characters. Letters, numbers or _ only.";
      });
      return;
    }

    setState(() {
      _isScanningUsername = true;
      _usernameError = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final taken = await authService.isUsernameTaken(username);

    if (mounted) {
      setState(() {
        _isScanningUsername = false;
        _usernameAvailable = !taken;
        if (taken) {
          _usernameError = "This username is already taken.";
        } else {
          _usernameError = null;
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final isDark = context.isDarkMode;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF5B7FFF),
                    onPrimary: Colors.white,
                    surface: Color(0xFF090E17),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF5B7FFF),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  // ── Glass card: adapts to light/dark ─────────────────────────────────────
  Widget _buildGlassCard({required Widget child}) {
    final isDark = context.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.55),
                  const Color(0xFF4F46E5).withValues(alpha: 0.25),
                  const Color(0xFF7C3AED).withValues(alpha: 0.35),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  const Color(0xFF5B7FFF).withValues(alpha: 0.18),
                  const Color(0xFF7B5FFF).withValues(alpha: 0.08),
                  const Color(0xFF5B7FFF).withValues(alpha: 0.14),
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
          color: isDark ? const Color(0xFF10132A) : Colors.white,
          borderRadius: BorderRadius.circular(23),
        ),
        child: child,
      ),
    );
  }

  // ── Text field: light or dark styling ─────────────────────────────────────
  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    bool readOnly = false,
    void Function(String)? onChanged,
  }) {
    final isDark = context.isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onTap: onTap,
        readOnly: readOnly,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            size: 20,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: isDark
              ? const Color(0xFF070B13).withValues(alpha: 0.6)
              : const Color(0xFFF8FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF5B7FFF), width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Gradient action button ─────────────────────────────────────────────────
  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B7FFF), Color(0xFF7B5FFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B7FFF).withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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

  Widget _buildGoogleG() {
    return Image.asset(
      'assets/google_logo.png',
      width: 22,
      height: 22,
      fit: BoxFit.contain,
    );
  }

  Widget _buildSocialButtons() {
    final isDark = context.isDarkMode;
    final borderColor =
        isDark ? const Color(0xFF2D3050) : const Color(0xFFE2E8F0);
    final bgColor =
        isDark ? const Color(0xFF0D1021) : const Color(0xFFF8FAFC);
    final textColor =
        isDark ? Colors.white : const Color(0xFF0F172A);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(14),
              color: bgColor,
            ),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/google_logo.png', width: 24, height: 24),
                  const SizedBox(width: 12),
                  Text(
                    "Google",
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(14),
              color: bgColor,
            ),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apple,
                    color: textColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Apple",
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
              color: const Color(0xFF5B7FFF),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5B7FFF).withValues(alpha: opacity * 0.8),
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
    final isDark = context.isDarkMode;
    return Container(
      width: 150,
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildDynamicSegment(1, isDark)),
              const SizedBox(width: 6),
              Expanded(child: _buildDynamicSegment(2, isDark)),
              const SizedBox(width: 6),
              Expanded(child: _buildDynamicSegment(3, isDark)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Step $_signUpStep of 3",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicSegment(int step, bool isDark) {
    bool isCompleted = _signUpStep > step;
    bool isActive = _signUpStep == step;
    
    Color bgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    if (isCompleted || isActive) bgColor = const Color(0xFF5B7FFF);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 6,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
        boxShadow: isActive ? [
           BoxShadow(color: const Color(0xFF5B7FFF).withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))
        ] : [],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          hint: "Full Name",
          controller: _fullNameController,
          prefixIcon: Icons.person_outline,
        ),
        _buildTextField(
          hint: "Username",
          controller: _usernameController,
          prefixIcon: Icons.alternate_email,
          suffixIcon: _isScanningUsername
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF5B7FFF)),
                  ),
                )
              : _usernameAvailable == null
                  ? null
                  : _usernameAvailable == true
                      ? const Icon(Icons.check_circle,
                          color: Colors.green, size: 20)
                      : const Icon(Icons.cancel, color: Colors.red, size: 20),
          onChanged: (val) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              _checkUsernameAvailability(val);
            });
          },
        ),
        if (_usernameError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              _usernameError!,
              style: GoogleFonts.inter(color: Colors.red[400], fontSize: 12),
            ),
          )
        else if (_usernameAvailable == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              "Username is available",
              style:
                  GoogleFonts.inter(color: Colors.green[600], fontSize: 12),
            ),
          ),
        _buildTextField(
          hint: "Email",
          controller: _emailController,
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        _buildGradientButton(
          label: "Next",
          icon: Icons.arrow_forward,
          onPressed: () {
            if (_fullNameController.text.trim().isEmpty) {
              _showSnackBar("Please enter your full name");
              return;
            }
            if (_usernameController.text.trim().isEmpty) {
              _showSnackBar("Please enter a username");
              return;
            }
            if (_usernameAvailable != true) {
              _showSnackBar("Please select a valid and available username");
              return;
            }
            final email = _emailController.text.trim();
            if (email.isEmpty ||
                !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(email)) {
              _showSnackBar("Please enter a valid email address");
              return;
            }
            setState(() => _signUpStep = 2);
          },
        ),
        const SizedBox(height: 16),
        _buildAlreadyHaveAccountLink(),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          hint: "Password",
          controller: _signUpPasswordController,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureSignUpPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureSignUpPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: context.isDarkMode
                  ? Colors.white38
                  : const Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscureSignUpPassword = !_obscureSignUpPassword),
          ),
        ),
        _buildTextField(
          hint: "Confirm Password",
          controller: _confirmPasswordController,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: context.isDarkMode
                  ? Colors.white38
                  : const Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ),
        _buildTextField(
          hint: "Date of Birth",
          controller: _dobController,
          prefixIcon: Icons.calendar_today_outlined,
          readOnly: true,
          onTap: _selectDate,
        ),
        const SizedBox(height: 8),
        _buildGradientButton(
          label: "Next",
          icon: Icons.arrow_forward,
          onPressed: () {
            final pass = _signUpPasswordController.text;
            final conf = _confirmPasswordController.text;
            if (pass.isEmpty || pass.length < 6) {
              _showSnackBar("Password must be at least 6 characters long");
              return;
            }
            if (pass != conf) {
              _showSnackBar("Passwords do not match");
              return;
            }
            final dobText = _dobController.text.trim();
            if (dobText.isEmpty) {
              _showSnackBar("Please enter your date of birth");
              return;
            }
            try {
              final parts = dobText.split('/');
              if (parts.length == 3) {
                final day = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                final year = int.parse(parts[2]);
                final dob = DateTime(year, month, day);
                final today = DateTime.now();
                
                if (dob.isAfter(today)) {
                  _showSnackBar("Date of birth cannot be in the future");
                  return;
                }
                
                int age = today.year - dob.year;
                if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
                  age--;
                }
                
                if (age < 13) {
                  _showSnackBar("You must be at least 13 years old to sign up");
                  return;
                }
              } else {
                _showSnackBar("Invalid date of birth format");
                return;
              }
            } catch (_) {
              _showSnackBar("Invalid date of birth");
              return;
            }
            setState(() => _signUpStep = 3);
          },
        ),
        const SizedBox(height: 16),
        _buildAlreadyHaveAccountLink(),
      ],
    );
  }

  Widget _buildStep3() {
    final isDark = context.isDarkMode;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF070B13).withValues(alpha: 0.6)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              _buildReviewRow(
                  Icons.person_outline, "Full Name", _fullNameController.text),
              Divider(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                  height: 16),
              _buildReviewRow(Icons.alternate_email, "Username",
                  _usernameController.text),
              Divider(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                  height: 16),
              _buildReviewRow(
                  Icons.mail_outline, "Email", _emailController.text),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text.rich(
            TextSpan(
              text: "By creating an account, you agree to our\n",
              style: GoogleFonts.inter(
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  fontSize: 11,
                  height: 1.4),
              children: [
                TextSpan(
                  text: "Terms of Service",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF5B7FFF),
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: " and "),
                TextSpan(
                  text: "Privacy Policy",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF5B7FFF),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        _buildGradientButton(
          label: "Create Account",
          icon: Icons.person_add_alt_1_outlined,
          onPressed: _submitSignup,
        ),
        const SizedBox(height: 16),
        _buildAlreadyHaveAccountLink(),
      ],
    );
  }

  Widget _buildAlreadyHaveAccountLink() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isDark = context.isDarkMode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: GoogleFonts.inter(
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
              fontSize: 13),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _isSignUp = false;
              _signUpStep = 1;
            });
            authService.clearErrors();
          },
          child: Text(
            "Login",
            style: GoogleFonts.inter(
              color: const Color(0xFF5B7FFF),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(IconData icon, String label, String value) {
    final isDark = context.isDarkMode;
    return Row(
      children: [
        Icon(icon,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep7() {
    final isDark = context.isDarkMode;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF141D19)
                  : const Color(0xFFECFDF5),
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
            "Congratulations!",
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF05D782),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your Pigeon account has been created successfully.\nPlease verify your email before logging in.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _buildGradientButton(
            label: "Login Now",
            onPressed: () {
              setState(() {
                _isSignUp = false;
                _signUpStep = 1;
                _fullNameController.clear();
                _usernameController.clear();
                _emailController.clear();
                _signUpPasswordController.clear();
                _confirmPasswordController.clear();
                _dobController.clear();
                _usernameAvailable = null;
                _usernameError = null;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isDark = context.isDarkMode;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    // Theme-aware colors
    final bgColor = isDark ? const Color(0xFF080A18) : const Color(0xFFF4F8FD);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final accentColor = const Color(0xFF5B7FFF);
    final backBtnBg = isDark ? const Color(0xFF10132A) : Colors.white;
    final backBtnBorder = isDark ? const Color(0xFF2D3050) : const Color(0xFFE2E8F0);
    final backBtnIconColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final dividerColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE2E8F0);
    final orTextColor = isDark ? Colors.white38 : const Color(0xFF94A3B8);
    final registerLinkColor = isDark ? Colors.white54 : const Color(0xFF64748B);

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
                      ? const [
                          Color(0xFF0D0F24),
                          Color(0xFF080A18),
                          Color(0xFF060810),
                        ]
                      : const [
                          Color(0xFFF4F8FD),
                          Color(0xFFEEF4FB),
                          Color(0xFFE8F0F8),
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
                  painter: _AtmosphericBackgroundPainter(
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
                                                      const Color(0xFF5B7FFF).withValues(alpha: isDark ? 0.32 : 0.16),
                                                      const Color(0xFF7B5FFF).withValues(alpha: isDark ? 0.14 : 0.06),
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
                                                    color: const Color(0xFF5B7FFF).withValues(alpha: isDark ? 0.2 : 0.12),
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

                            // Back button (top left)
                            if (_isSignUp && _signUpStep < 4)
                              Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
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
                                        if (_signUpStep > 1) {
                                          setState(() => _signUpStep--);
                                        } else {
                                          setState(() => _isSignUp = false);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                        if (!_isSignUp || _signUpStep < 3) ...[
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

                        // Sign-up step info
                        if (_isSignUp && _signUpStep < 4) ...[
                          const SizedBox(height: 6),
                          Text(
                            "Create your account",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _signUpStep == 1
                                ? "Let's get started with some basic info."
                                : _signUpStep == 2
                                    ? "Set a strong password to secure your account."
                                    : "Review your info and create your account.",
                            style: GoogleFonts.inter(
                                fontSize: 13, color: subtitleColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          _buildStepIndicator(),
                        ],

                        // Error message
                        if (authService.errorMessage != null &&
                            _signUpStep < 4)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.red[900]!.withValues(alpha: 0.3)
                                  : Colors.red[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? Colors.red[700]!.withValues(alpha: 0.5)
                                    : Colors.red[200]!,
                              ),
                            ),
                            child: Text(
                              authService.errorMessage!,
                              style: GoogleFonts.inter(
                                color: isDark
                                    ? Colors.red[100]
                                    : Colors.red[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
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
                                _buildGlassCard(
                                  child: _isSignUp
                                      ? (_signUpStep == 1
                                          ? _buildStep1()
                                          : _signUpStep == 2
                                              ? _buildStep2()
                                              : _signUpStep == 3
                                                  ? _buildStep3()
                                                  : _buildStep7())
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                              style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: subtitleColor),
                                            ),
                                            const SizedBox(height: 16),
                                            _buildTextField(
                                              hint: "Email or Username",
                                              controller:
                                                  _emailPhoneController,
                                              prefixIcon:
                                                  Icons.mail_outline_rounded,
                                            ),
                                            _buildTextField(
                                              hint: "Password",
                                              controller: _passwordController,
                                              prefixIcon:
                                                  Icons.lock_outline_rounded,
                                              obscureText:
                                                  _obscureLoginPassword,
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscureLoginPassword
                                                      ? Icons
                                                          .visibility_outlined
                                                      : Icons
                                                          .visibility_off_outlined,
                                                  color: isDark
                                                      ? Colors.white38
                                                      : const Color(
                                                          0xFF94A3B8),
                                                  size: 20,
                                                ),
                                                onPressed: () => setState(() =>
                                                    _obscureLoginPassword =
                                                        !_obscureLoginPassword),
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const ForgotPasswordScreen(),
                                                    ),
                                                  );
                                                },
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize:
                                                      const Size(0, 30),
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
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
                                            _buildGradientButton(
                                              label: "Login",
                                              icon: Icons.arrow_forward,
                                              isLoading:
                                                  authService.isLoading,
                                              onPressed: _submitLogin,
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                    child: Divider(
                                                        color: dividerColor)),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12.0),
                                                  child: Text(
                                                    "or continue with",
                                                    style: GoogleFonts.inter(
                                                        color: orTextColor,
                                                        fontSize: 12),
                                                  ),
                                                ),
                                                Expanded(
                                                    child: Divider(
                                                        color: dividerColor)),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            _buildSocialButtons(),
                                            const SizedBox(height: 14),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "Don't have an account? ",
                                                  style: GoogleFonts.inter(
                                                      color: registerLinkColor,
                                                      fontSize: 13),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _isSignUp = true;
                                                      _signUpStep = 1;
                                                    });
                                                    authService.clearErrors();
                                                  },
                                                  child: Text(
                                                    "Register >",
                                                    style: GoogleFonts.inter(
                                                      color: accentColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
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

// ─────────────────────────────────────────────────────────────────────────────
/// Atmospheric background painter — adapts colors for light/dark mode
// ─────────────────────────────────────────────────────────────────────────────
class _AtmosphericBackgroundPainter extends CustomPainter {
  final double cloudOffset;
  final bool isDark;

  _AtmosphericBackgroundPainter({
    required this.cloudOffset,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final drift = math.sin(cloudOffset * 2 * math.pi);
    final drift2 = math.cos(cloudOffset * 2 * math.pi);

    // Light mode: soft blue/indigo tones; dark: purple nebula
    final c1 = isDark ? const Color(0xFF3D1F8C) : const Color(0xFF5B7FFF);
    final c2 = isDark ? const Color(0xFF1E0F5E) : const Color(0xFF7B5FFF);
    final c3 = isDark ? const Color(0xFF5B21B6) : const Color(0xFF5B7FFF);
    final c4 = isDark ? const Color(0xFF1E3A8A) : const Color(0xFF3B82F6);
    final c5 = isDark ? const Color(0xFF7C3AED) : const Color(0xFF5B7FFF);

    final baseAlpha = isDark ? 0.42 : 0.08;

    // Center glow
    final glowAlpha = baseAlpha + 0.08 * drift;
    final centerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          c1.withValues(alpha: glowAlpha.clamp(0.0, 1.0)),
          c2.withValues(alpha: (glowAlpha * 0.5).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height * 0.1),
        radius: size.width * 0.9,
      ));
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.1),
      size.width * 0.9,
      centerGlow,
    );

    // Left cloud
    final leftX = size.width * 0.08 + 28.0 * drift;
    final leftY = size.height * 0.32 + 14.0 * drift2;
    final leftCloud = Paint()
      ..shader = RadialGradient(
        colors: [
          c3.withValues(
              alpha: (isDark ? 0.20 : 0.07 + 0.03 * drift).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(leftX, leftY),
        radius: size.width * 0.48,
      ));
    canvas.drawCircle(Offset(leftX, leftY), size.width * 0.48, leftCloud);

    // Right cloud
    final rightX = size.width * 0.92 - 22.0 * drift;
    final rightY = size.height * 0.22 - 12.0 * drift2;
    final rightCloud = Paint()
      ..shader = RadialGradient(
        colors: [
          c4.withValues(
              alpha: (isDark ? 0.17 : 0.06 + 0.02 * drift2).clamp(0.0, 1.0)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(rightX, rightY),
        radius: size.width * 0.42,
      ));
    canvas.drawCircle(Offset(rightX, rightY), size.width * 0.42, rightCloud);

    // Bottom accent cloud
    final accentX = size.width * 0.22 + 18.0 * drift2;
    final accentY = size.height * 0.72 + 8.0 * drift;
    final accentCloud = Paint()
      ..shader = RadialGradient(
        colors: [
          c5.withValues(
              alpha: (isDark ? 0.11 : 0.05 + 0.03 * drift.abs())
                  .clamp(0.0, 1.0)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(accentX, accentY),
        radius: size.width * 0.32,
      ));
    canvas.drawCircle(Offset(accentX, accentY), size.width * 0.32, accentCloud);

    // Bottom fade
    final fadeColors = isDark
        ? [Colors.transparent, const Color(0x99080A18), const Color(0xFF080A18)]
        : [Colors.transparent, const Color(0x22EEF4FB), const Color(0xFFE8F0F8)];
    final fadeOut = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: fadeColors,
        stops: const [0.42, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fadeOut);
  }

  @override
  bool shouldRepaint(_AtmosphericBackgroundPainter old) =>
      old.cloudOffset != cloudOffset || old.isDark != isDark;
}
