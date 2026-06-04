import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Login & Session states
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _isSignUp = false;
  bool _showVerification = false;

  // Multi-step SignUp state controllers
  int _signupStep = 1; // 1 to 4
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _gender = "অন্যান্য";
  String? _selectedDay;
  String? _selectedMonth;
  String? _selectedYear;

  final List<String> _days = List.generate(31, (i) => (i + 1).toString());
  final List<String> _months = [
    "জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন",
    "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর"
  ];
  final List<String> _years = List.generate(70, (i) => (2020 - i).toString());

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("অনুগ্রহ করে ইমেইল ও পাসওয়ার্ড দিন")),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.handleLogin(email, password);

    if (success) {
      widget.onLoginSuccess();
    } else {
      if (mounted && authService.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authService.errorMessage!)),
        );
      }
    }
  }

  void _submitSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final birthdate = "${_selectedDay ?? '1'} ${_selectedMonth ?? 'জানুয়ারি'} ${_selectedYear ?? '2000'}";

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("অনুগ্রহ করে একটি পাসওয়ার্ড তৈরি করুন")),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.handleSignup(
      email: email,
      password: password,
      fullName: "$firstName $lastName",
      phone: phone,
      gender: _gender,
      birthdate: birthdate,
    );

    if (success) {
      setState(() {
        _showVerification = true;
      });
    } else {
      if (mounted && authService.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authService.errorMessage!)),
        );
      }
    }
  }

  void _nextStep() {
    if (_signupStep == 1) {
      if (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("অনুগ্রহ করে আপনার নাম লিখুন")),
        );
        return;
      }
    } else if (_signupStep == 2) {
      if (_selectedDay == null || _selectedMonth == null || _selectedYear == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("অনুগ্রহ করে জন্মতারিখ সম্পূর্ণ করুন")),
        );
        return;
      }
    } else if (_signupStep == 3) {
      if (_emailController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("অনুগ্রহ করে ইমেইল ও মোবাইল নম্বর দিন")),
        );
        return;
      }
    }

    setState(() {
      _signupStep++;
    });
  }

  void _prevStep() {
    setState(() {
      _signupStep--;
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.hindSiliguri(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1E824C)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginView(AuthService authService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _loginEmailController,
          label: "ইমেইল",
          hint: "email@example.com",
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _loginPasswordController,
          label: "পাসওয়ার্ড",
          hint: "••••••••",
          obscureText: true,
        ),
        const SizedBox(height: 24),
        if (authService.isLoading)
          const Center(child: CircularProgressIndicator(color: Color(0xFF1E824C)))
        else
          ElevatedButton(
            onPressed: _submitLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E824C),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: Text(
              "লগইন করুন",
              style: GoogleFonts.hindSiliguri(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "অ্যাকাউন্ট নেই? ",
              style: GoogleFonts.hindSiliguri(color: Colors.black54),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSignUp = true;
                  _signupStep = 1;
                });
                authService.clearErrors();
              },
              child: Text(
                "নতুন ডাক তৈরি করুন",
                style: GoogleFonts.hindSiliguri(
                  color: const Color(0xFF1E824C),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            authService.bypassLogin();
            widget.onLoginSuccess();
          },
          child: Text(
            "ডেমো মোডে প্রবেশ করুন (Bypass Login)",
            style: GoogleFonts.hindSiliguri(
              color: const Color(0xFF1E824C),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupView(AuthService authService) {
    switch (_signupStep) {
      case 1:
        // Step 1: Name Input
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "ধাপ ১: আপনার নাম",
              style: GoogleFonts.hindSiliguri(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E824C),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _firstNameController,
              label: "প্রথম নাম (First Name)",
              hint: "যেমন: আব্দুর",
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _lastNameController,
              label: "শেষ নাম (Last Name)",
              hint: "যেমন: রহমান",
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E824C),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text(
                "পরবর্তী (Next)",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _isSignUp = false;
                });
                authService.clearErrors();
              },
              child: Text(
                "লগইনে ফিরে যান",
                style: GoogleFonts.hindSiliguri(
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );

      case 2:
        // Step 2: Birthday & Gender
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "ধাপ ২: জন্মতারিখ ও জেন্ডার",
              style: GoogleFonts.hindSiliguri(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E824C),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "জন্মতারিখ (Birthday)",
              style: GoogleFonts.hindSiliguri(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedDay,
                    hint: Text("দিন", style: GoogleFonts.hindSiliguri(fontSize: 13)),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (val) => setState(() => _selectedDay = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedMonth,
                    hint: Text("মাস", style: GoogleFonts.hindSiliguri(fontSize: 13)),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (val) => setState(() => _selectedMonth = val),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedYear,
                    hint: Text("বছর", style: GoogleFonts.hindSiliguri(fontSize: 13)),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
                    onChanged: (val) => setState(() => _selectedYear = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              "জেন্ডার (Gender)",
              style: GoogleFonts.hindSiliguri(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
            RadioGroup<String>(
              groupValue: _gender,
              onChanged: (val) => setState(() => _gender = val!),
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text("পুরুষ", style: GoogleFonts.hindSiliguri(fontSize: 14)),
                      value: "পুরুষ",
                      activeColor: const Color(0xFF1E824C),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text("মহিলা", style: GoogleFonts.hindSiliguri(fontSize: 14)),
                      value: "মহিলা",
                      activeColor: const Color(0xFF1E824C),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text("অন্যান্য", style: GoogleFonts.hindSiliguri(fontSize: 13)),
                      value: "অন্যান্য",
                      activeColor: const Color(0xFF1E824C),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _prevStep,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text("পূর্ববর্তী", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E824C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    child: Text("পরবর্তী", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        );

      case 3:
        // Step 3: Contact Details
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "ধাপ ৩: ইমেইল ও ফোন নম্বর",
              style: GoogleFonts.hindSiliguri(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E824C),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: "ইমেইল (Email)",
              hint: "example@mail.com",
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: "মোবাইল নম্বর (Phone Number)",
              hint: "+8801XXXXXXXXX",
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _prevStep,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text("পূর্ববর্তী", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E824C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    child: Text("পরবর্তী", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        );

      case 4:
        // Step 4: Password & Submit
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "ধাপ ৪: অ্যাকাউন্ট পাসওয়ার্ড",
              style: GoogleFonts.hindSiliguri(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E824C),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: "পাসওয়ার্ড তৈরি করুন (Password)",
              hint: "কমপক্ষে ৬ অক্ষরের পাসওয়ার্ড",
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (authService.isLoading)
              const Center(child: CircularProgressIndicator(color: Color(0xFF1E824C)))
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: Text("পূর্ববর্তী", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E824C),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      child: Text(
                        "অ্যাকাউন্ট তৈরি করুন",
                        style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              )
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildVerificationView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.mark_email_unread_outlined,
          color: Color(0xFF1E824C),
          size: 80,
        ),
        const SizedBox(height: 24),
        Text(
          "ইমেইল ভেরিফাই করুন",
          textAlign: TextAlign.center,
          style: GoogleFonts.hindSiliguri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "আমরা আপনার ইমেইল অ্যাড্রেসে একটি ভেরিফিকেশন লিঙ্ক পাঠিয়েছি। অনুগ্রহ করে আপনার ইমেইল চেক করুন এবং অ্যাকাউন্ট অ্যাক্টিভেট করুন।",
          textAlign: TextAlign.center,
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _showVerification = false;
              _isSignUp = false;
              _loginEmailController.text = _emailController.text;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E824C),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 0,
          ),
          child: Text(
            "লগইন পেজে যান (Back to Login)",
            style: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!_showVerification) ...[
                    // Logo Box (Full D logo representation)
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/logo_d_icon_v2.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Dak",
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E824C),
                      ),
                    ),
                    Text(
                      "— সংযোগ থাকুক হৃদয়ের —",
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isSignUp ? "নতুন ডাক অ্যাকাউন্ট তৈরি করুন" : "আপনার আড্ডা শুরু হোক এখানেই",
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 15,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _isSignUp ? _buildSignupView(authService) : _buildLoginView(authService),
                  ] else
                    _buildVerificationView(),

                  const SizedBox(height: 40),
                  // Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "বাংলা (বাংলাদেশ)",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "মেড ইন বাংলাদেশ by NGST",
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 11,
                      color: Colors.black38,
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
