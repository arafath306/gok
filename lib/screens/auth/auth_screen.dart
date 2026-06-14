import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/auth_service.dart';

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

class _AuthScreenState extends State<AuthScreen> {
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

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
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

    final success = await authService.handleLogin(identifier, password);
    if (success && mounted) {
      widget.onLoginSuccess();
    }
  }

  void _submitSignup() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final password = _signUpPasswordController.text;

    final success = await authService.handleSignup(
      email: _emailController.text.trim(),
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
      setState(() => _signUpStep = 4); // Step 4 will be Success View
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E293B),
        content: Text(
          message,
          style: GoogleFonts.outfit(color: Colors.white),
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
        _usernameError = "At least 3 characters. Letters, numbers or _ only.";
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF8B5CF6),
              onPrimary: Colors.white,
              surface: Color(0xFF090E17),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF090E17),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  // Helper Custom Widget: Gradient Border Glassmorphic Container
  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED).withOpacity(0.55),
            const Color(0xFF4F46E5).withOpacity(0.25),
            const Color(0xFF7C3AED).withOpacity(0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.2),
        padding: const EdgeInsets.all(24),
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
    void Function(String)? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onTap: onTap,
        readOnly: readOnly,
        onChanged: onChanged,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
          prefixIcon: Icon(prefixIcon, color: Colors.white38, size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFF070B13).withOpacity(0.6),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B3A), Color(0xFFFF3A5C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5E36).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
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
                    style: GoogleFonts.outfit(
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
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFFEA4335), Color(0xFFFBBC05), Color(0xFF34A853)],
          stops: [0.0, 0.33, 0.66, 1.0],
        ).createShader(bounds);
      },
      child: Text(
        "G",
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w900,
          fontSize: 22,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2D3050)),
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF0D1021),
            ),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGoogleG(),
                  const SizedBox(width: 8),
                  Text(
                    "Google",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
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
              border: Border.all(color: const Color(0xFF2D3050)),
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF0D1021),
            ),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.apple, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "Apple",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
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
        const SizedBox(height: 8),
        Text(
          "Step $_signUpStep of 3",
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCircle(int step) {
    bool isCompleted = _signUpStep > step;
    bool isActive = _signUpStep == step;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive ? const Color(0xFF8B5CF6) : const Color(0xFF1E293B),
        border: isActive
            ? Border.all(color: Colors.white, width: 1.5)
            : Border.all(color: Colors.transparent),
      ),
      alignment: Alignment.center,
      child: isCompleted
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : Text(
              "$step",
              style: GoogleFonts.outfit(
                color: isCompleted || isActive ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
    );
  }

  Widget _buildStepConnector(int stepAfter) {
    bool isPassed = _signUpStep > stepAfter;
    return Container(
      width: 40,
      height: 2,
      color: isPassed ? const Color(0xFF8B5CF6) : const Color(0xFF1E293B),
    );
  }

  // Registration step views
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Create your account",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Let's get started with some basic info.",
          style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
        ),
        const SizedBox(height: 24),
        _buildDarkTextField(
          hint: "Full Name",
          controller: _fullNameController,
          prefixIcon: Icons.person_outline,
        ),
        _buildDarkTextField(
          hint: "Username",
          controller: _usernameController,
          prefixIcon: Icons.alternate_email,
          suffixIcon: _isScanningUsername
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6)),
                  ),
                )
              : _usernameAvailable == null
                  ? null
                  : _usernameAvailable == true
                      ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
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
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              _usernameError!,
              style: GoogleFonts.outfit(color: Colors.red[400], fontSize: 12),
            ),
          )
        else if (_usernameAvailable == true)
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              "Username is available",
              style: GoogleFonts.outfit(color: Colors.green[400], fontSize: 12),
            ),
          ),
        _buildDarkTextField(
          hint: "Email",
          controller: _emailController,
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
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
            if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
              _showSnackBar("Please enter a valid email address");
              return;
            }
            setState(() => _signUpStep = 2);
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Create your account",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Set a strong password to secure your account.",
          style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
        ),
        const SizedBox(height: 24),
        _buildDarkTextField(
          hint: "Password",
          controller: _signUpPasswordController,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureSignUpPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureSignUpPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.white38,
              size: 20,
            ),
            onPressed: () => setState(() => _obscureSignUpPassword = !_obscureSignUpPassword),
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
        _buildDarkTextField(
          hint: "Date of Birth",
          controller: _dobController,
          prefixIcon: Icons.calendar_today_outlined,
          readOnly: true,
          onTap: _selectDate,
        ),
        const SizedBox(height: 16),
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
            if (_dobController.text.trim().isEmpty) {
              _showSnackBar("Please enter your date of birth");
              return;
            }
            setState(() => _signUpStep = 3);
          },
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Create your account",
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF8B5CF6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Review your info and create your account.",
          style: GoogleFonts.outfit(fontSize: 13, color: Colors.white54),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF070B13).withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            children: [
              _buildReviewRow(Icons.person_outline, "Full Name", _fullNameController.text),
              const Divider(color: Color(0xFF1E293B), height: 24),
              _buildReviewRow(Icons.alternate_email, "Username", _usernameController.text),
              const Divider(color: Color(0xFF1E293B), height: 24),
              _buildReviewRow(Icons.mail_outline, "Email", _emailController.text),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text.rich(
            TextSpan(
              text: "By creating an account, you agree to our\n",
              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 11, height: 1.4),
              children: [
                TextSpan(
                  text: "Terms of Service",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8B5CF6),
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: " and "),
                TextSpan(
                  text: "Privacy Policy",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8B5CF6),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        _buildGradientButton(
          label: "Create Account",
          icon: Icons.person_add_alt_1_outlined,
          onPressed: _submitSignup,
        ),
      ],
    );
  }

  Widget _buildReviewRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep7() {
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
            "Congratulations!",
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF05D782),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your Dak account has been created successfully.\nPlease verify your email before logging in.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white70,
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF080A18),
      body: Stack(
        children: [
          // 1. Full atmospheric dark background
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

          // 2. Atmospheric decorative top section (programmatic - no image dependency)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.55,
            child: CustomPaint(
              painter: _AtmosphericBackgroundPainter(),
            ),
          ),

          // 3. Main scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Back button for signup steps > 1
                  if (_isSignUp && _signUpStep > 1 && _signUpStep < 4)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10132A),
                          border: Border.all(color: const Color(0xFF2D3050)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          onPressed: () => setState(() => _signUpStep--),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 8),

                  const SizedBox(height: 8),

                  // HERO: Pigeon mascot — large, prominent, centered
                  Center(
                    child: SizedBox(
                      height: 215,
                      width: 215,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Programmatic glow ring (no image asset needed)
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF7C3AED).withValues(alpha: 0.4),
                                  const Color(0xFF4F46E5).withValues(alpha: 0.2),
                                  const Color(0xFF7C3AED).withValues(alpha: 0.05),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.4, 0.7, 1.0],
                              ),
                            ),
                          ),
                          // Outer ring stroke
                          Container(
                            width: 195,
                            height: 195,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                          ),
                          // Main mascot
                          Image.asset(
                            "assets/pigeon_logo.png",
                            height: 185,
                            width: 210,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // App name
                  Text(
                    "Piagoan",
                    style: GoogleFonts.outfit(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Messages. Moments. Together.",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white60,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Error Message
                  if (authService.errorMessage != null && _signUpStep < 4)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[900]!.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[700]!.withOpacity(0.5)),
                      ),
                      child: Text(
                        authService.errorMessage!,
                        style: GoogleFonts.outfit(color: Colors.red[100], fontSize: 13),
                      ),
                    ),

                  // Step Indicator (sign-up only)
                  if (_isSignUp && _signUpStep < 4) ...[
                    _buildStepIndicator(),
                    const SizedBox(height: 20),
                  ],

                  // Glassmorphic Auth Card
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome back! 👋",
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF9B79FF),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Login to continue your journey",
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.white54,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildDarkTextField(
                                hint: "Email or Username",
                                controller: _emailPhoneController,
                                prefixIcon: Icons.mail_outline_rounded,
                              ),
                              _buildDarkTextField(
                                hint: "Password",
                                controller: _passwordController,
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: _obscureLoginPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureLoginPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.white38,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscureLoginPassword = !_obscureLoginPassword),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    "Forgot password?",
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF9B79FF),
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
                                isLoading: authService.isLoading,
                                onPressed: _submitLogin,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                        color: Colors.white.withOpacity(0.1)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0),
                                    child: Text(
                                      "or continue with",
                                      style: GoogleFonts.outfit(
                                          color: Colors.white38, fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                        color: Colors.white.withOpacity(0.1)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildSocialButtons(),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: GoogleFonts.outfit(
                                        color: Colors.white54, fontSize: 13),
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
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF9B79FF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),

                  // Already have account? link (sign-up flow)
                  if (_isSignUp && _signUpStep < 4) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style:
                              GoogleFonts.outfit(color: Colors.white54, fontSize: 13),
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
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF9B79FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the atmospheric cloud/nebula background at the top of the auth screen.
/// Draws dark purple glowing arcs and radial gradients to simulate the dark atmospheric effect
/// from the Piagoan design — no image assets required.
class _AtmosphericBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Main top radial glow (large purple nebula)
    final centerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF3D1F8C).withValues(alpha: 0.55),
          const Color(0xFF1E0F5E).withValues(alpha: 0.3),
          const Color(0xFF0D0F24).withValues(alpha: 0.0),
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

    // Left side purple cloud blob
    final leftCloud = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF5B21B6).withValues(alpha: 0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.1, size.height * 0.35),
        radius: size.width * 0.45,
      ));

    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.35),
      size.width * 0.45,
      leftCloud,
    );

    // Right side teal accent cloud
    final rightCloud = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1E3A8A).withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.9, size.height * 0.25),
        radius: size.width * 0.4,
      ));

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.25),
      size.width * 0.4,
      rightCloud,
    );

    // Bottom fade-out gradient to merge with background
    final fadeOut = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF080A18).withValues(alpha: 0.6),
          const Color(0xFF080A18),
        ],
        stops: const [0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      fadeOut,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
