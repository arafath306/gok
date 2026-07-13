import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../services/auth_service.dart';
import '../../../utils/app_theme.dart';
import '../email_verification_pending_screen.dart';
import 'auth_text_field.dart';
import 'gradient_action_button.dart';
import 'package:intl/intl.dart';

class SignupForm extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const SignupForm({
    super.key,
    required this.onSwitchToLogin,
  });

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  int _signUpStep = 1;

  // Registration Controllers
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();

  bool _obscureSignUpPassword = true;
  bool _obscureConfirmPassword = true;

  bool _isScanningUsername = false;
  bool? _usernameAvailable;
  String? _usernameError;
  Timer? _debounce;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _signUpPasswordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _debounce?.cancel();
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
                    primary: Color(0xFF05D782),
                    onPrimary: Colors.white,
                    surface: Color(0xFF141D19),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF05D782),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
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
              color: context.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicSegment(int step, bool isDark) {
    bool isCompleted = _signUpStep > step;
    bool isActive = _signUpStep == step;
    
    Color bgColor = context.border;
    if (isCompleted || isActive) bgColor = context.authPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 6,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
        boxShadow: isActive ? [
           BoxShadow(color: context.authPrimary.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))
        ] : [],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTextField(
          hint: "Full Name",
          controller: _fullNameController,
          prefixIcon: Icons.person_outline,
        ),
        AuthTextField(
          hint: "Username",
          controller: _usernameController,
          prefixIcon: Icons.alternate_email,
          suffixIcon: _isScanningUsername
              ? Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: context.authPrimary),
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
        AuthTextField(
          hint: "Email",
          controller: _emailController,
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        GradientActionButton(
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
              _showSnackBar("Please choose a valid and available username");
              return;
            }
            if (_emailController.text.trim().isEmpty ||
                !_emailController.text.contains('@')) {
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
    final isDark = context.isDarkMode;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTextField(
          hint: "Password",
          controller: _signUpPasswordController,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureSignUpPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureSignUpPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: () => setState(
                () => _obscureSignUpPassword = !_obscureSignUpPassword),
          ),
        ),
        AuthTextField(
          hint: "Confirm Password",
          controller: _confirmPasswordController,
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              size: 20,
            ),
            onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
        ),
        AuthTextField(
          hint: "Date of Birth",
          controller: _dobController,
          prefixIcon: Icons.calendar_today_outlined,
          readOnly: true,
          onTap: _selectDate,
        ),
        const SizedBox(height: 8),
        GradientActionButton(
          label: "Next",
          icon: Icons.arrow_forward,
          onPressed: () {
            if (_signUpPasswordController.text.length < 6) {
              _showSnackBar("Password must be at least 6 characters");
              return;
            }
            if (_signUpPasswordController.text !=
                _confirmPasswordController.text) {
              _showSnackBar("Passwords do not match");
              return;
            }
            if (_dobController.text.trim().isEmpty) {
              _showSnackBar("Please select your date of birth");
              return;
            }
            try {
              final dob = DateTime.parse(_dobController.text.trim());
              final today = DateTime.now();
              if (dob.isBefore(today) ||
                  (dob.year == today.year &&
                      dob.month == today.month &&
                      dob.day == today.day)) {
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
            } catch (e) {
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
                  color: context.textSecondary,
                  fontSize: 11,
                  height: 1.4),
              children: [
                TextSpan(
                  text: "Terms of Service",
                  style: GoogleFonts.inter(
                    color: context.authPrimary,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: " and "),
                TextSpan(
                  text: "Privacy Policy",
                  style: GoogleFonts.inter(
                    color: context.authPrimary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        GradientActionButton(
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: GoogleFonts.inter(
              color: context.textSecondary,
              fontSize: 13),
        ),
        GestureDetector(
          onTap: () {
            widget.onSwitchToLogin();
            authService.clearErrors();
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

  Widget _buildReviewRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: context.textMuted, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                    color: context.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                    color: context.textPrimary,
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
              color: context.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          GradientActionButton(
            label: "Login Now",
            onPressed: widget.onSwitchToLogin,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final accentColor = context.authPrimary;
    final subtitleColor = context.textSecondary;

    return Column(
      children: [
        // Sign-up step info header
        if (_signUpStep < 4) ...[
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
          const SizedBox(height: 16),
        ],
        // Error message
        if (authService.errorMessage != null && _signUpStep < 4)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.red[900]!.withValues(alpha: 0.3)
                  : Colors.red[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: context.isDarkMode
                    ? Colors.red[700]!.withValues(alpha: 0.5)
                    : Colors.red[200]!,
              ),
            ),
            child: Text(
              authService.errorMessage!,
              style: GoogleFonts.inter(
                color: context.isDarkMode
                    ? Colors.red[100]
                    : Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
        
        // Render current step
        if (_signUpStep == 1)
          _buildStep1()
        else if (_signUpStep == 2)
          _buildStep2()
        else if (_signUpStep == 3)
          _buildStep3()
        else
          _buildStep7(),
      ],
    );
  }
}
