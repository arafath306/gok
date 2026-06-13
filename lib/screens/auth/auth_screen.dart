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

  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Sign up step controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _villageController = TextEditingController();
  final _zipController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedGender;
  String? _selectedDay;
  String? _selectedMonth;
  String? _selectedYear;
  String? _selectedDivision;

  bool _isScanningUsername = false;
  bool? _usernameAvailable;
  String? _usernameError;
  Timer? _debounce;

  final List<String> _divisions = [
    "ঢাকা (Dhaka)",
    "চট্টগ্রাম (Chattogram)",
    "রাজশাহী (Rajshahi)",
    "খুলনা (Khulna)",
    "বরিশাল (Barishal)",
    "সিলেট (Sylhet)",
    "রংপুর (Rangpur)",
    "ময়মনসিংহ (Mymensingh)"
  ];

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    _villageController.dispose();
    _zipController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _signUpPasswordController.dispose();
    _confirmPasswordController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _submit() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final identifier = _emailPhoneController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      _showSnackBar('অনুগ্রহ করে ইমেইল ও পাসওয়ার্ড দিন');
      return;
    }

    final success = await authService.handleLogin(identifier, password);
    if (success && mounted) {
      widget.onLoginSuccess();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.hindSiliguri())),
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
        _usernameError = "ইউজারনেম কমপক্ষে ৩ অক্ষরের হতে হবে এবং বর্ণ, সংখ্যা বা underscore (_) থাকতে পারে।";
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
          _usernameError = "এই ইউজারনেমটি ইতিমধ্যে ব্যবহৃত হয়েছে। অন্য একটি চেষ্টা করুন।";
        } else {
          _usernameError = null;
        }
      });
    }
  }

  Widget _buildStepTextField({
    required String label,
    required TextEditingController controller,
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
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStepHeader() {
    return Row(
      children: [
        if (_signUpStep < 7)
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
            onPressed: () {
              if (_signUpStep > 1) {
                setState(() => _signUpStep--);
              } else {
                setState(() {
                  _isSignUp = false;
                });
              }
            },
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _signUpStep == 7 ? "অ্যাকাউন্ট তৈরি সম্পন্ন" : "ধাপ $_signUpStep / ৬",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: _signUpStep / 6.0,
                backgroundColor: Colors.grey[200],
                color: const Color(0xFF1E824C),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton({required VoidCallback onPressed, String label = "পরবর্তী ধাপ"}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E824C),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.hindSiliguri(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 18),
        ],
      ),
    );
  }

  Widget _buildActiveStep(AuthService authService) {
    switch (_signUpStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep5();
      case 6:
        return _buildStep6(authService);
      case 7:
        return _buildStep7();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "আপনার নাম কী?",
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E824C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "আপনার আসল নাম ব্যবহার করুন যা আপনার বন্ধুরা চেনে।",
          style: GoogleFonts.hindSiliguri(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        _buildStepTextField(
          label: "প্রথম নাম (First Name)",
          controller: _firstNameController,
          hint: "যেমন: তানজীর",
        ),
        _buildStepTextField(
          label: "পদবী (Last Name)",
          controller: _lastNameController,
          hint: "যেমন: আহমেদ",
        ),
        const SizedBox(height: 24),
        _buildNextButton(onPressed: () {
          if (_firstNameController.text.trim().isEmpty) {
            _showSnackBar("অনুগ্রহ করে আপনার প্রথম নাম লিখুন");
            return;
          }
          if (_lastNameController.text.trim().isEmpty) {
            _showSnackBar("অনুগ্রহ করে আপনার পদবী লিখুন");
            return;
          }
          setState(() => _signUpStep = 2);
        }),
      ],
    );
  }

  Widget _buildStep2() {
    final days = List.generate(31, (index) => (index + 1).toString());
    final months = ["জানুয়ারী", "ফেব্রুয়ারী", "মার্চ", "এপ্রিল", "মে", "জুন", "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর"];
    final currentYear = DateTime.now().year;
    final years = List.generate(100, (index) => (currentYear - index).toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "জন্মতারিখ ও লিঙ্গ",
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E824C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "আপনার অ্যাকাউন্ট ভেরিফিকেশন ও সুরক্ষার জন্য এটি প্রয়োজনীয়।",
          style: GoogleFonts.hindSiliguri(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        Text(
          "জন্মতারিখ",
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                hint: const Text("দিন"),
                value: _selectedDay,
                items: days.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                onChanged: (val) => setState(() => _selectedDay = val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                hint: const Text("মাস"),
                value: _selectedMonth,
                items: months.map((month) => DropdownMenuItem(value: month, child: Text(month))).toList(),
                onChanged: (val) => setState(() => _selectedMonth = val),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                hint: const Text("বছর"),
                value: _selectedYear,
                items: years.map((year) => DropdownMenuItem(value: year, child: Text(year))).toList(),
                onChanged: (val) => setState(() => _selectedYear = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          "লিঙ্গ",
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedGender == "Female" ? const Color(0xFF1E824C) : Colors.black12,
                    width: _selectedGender == "Female" ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _selectedGender == "Female" ? const Color(0xFF1E824C).withOpacity(0.05) : Colors.transparent,
                ),
                child: RadioListTile<String>(
                  title: Text("নারী", style: GoogleFonts.hindSiliguri(fontSize: 14, fontWeight: FontWeight.bold)),
                  value: "Female",
                  groupValue: _selectedGender,
                  onChanged: (val) => setState(() => _selectedGender = val),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: const Color(0xFF1E824C),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedGender == "Male" ? const Color(0xFF1E824C) : Colors.black12,
                    width: _selectedGender == "Male" ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _selectedGender == "Male" ? const Color(0xFF1E824C).withOpacity(0.05) : Colors.transparent,
                ),
                child: RadioListTile<String>(
                  title: Text("পুরুষ", style: GoogleFonts.hindSiliguri(fontSize: 14, fontWeight: FontWeight.bold)),
                  value: "Male",
                  groupValue: _selectedGender,
                  onChanged: (val) => setState(() => _selectedGender = val),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: const Color(0xFF1E824C),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildNextButton(onPressed: () {
          if (_selectedDay == null || _selectedMonth == null || _selectedYear == null) {
            _showSnackBar("অনুগ্রহ করে আপনার জন্মতারিখ নির্বাচন করুন");
            return;
          }
          if (_selectedGender == null) {
            _showSnackBar("অনুগ্রহ করে লিঙ্গ নির্বাচন করুন");
            return;
          }
          setState(() => _signUpStep = 3);
        }),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "আপনার বর্তমান ঠিকানা",
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E824C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "আপনার বর্তমান বাসস্থান এবং ডাকযোগের ঠিকানা প্রদান করুন।",
          style: GoogleFonts.hindSiliguri(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        Text(
          "বিভাগ (Division)",
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black12),
            ),
          ),
          hint: Text("বিভাগ নির্বাচন করুন", style: GoogleFonts.hindSiliguri(color: Colors.black26)),
          value: _selectedDivision,
          items: _divisions.map((div) => DropdownMenuItem(value: div, child: Text(div, style: GoogleFonts.hindSiliguri()))).toList(),
          onChanged: (val) => setState(() => _selectedDivision = val),
        ),
        const SizedBox(height: 16),
        _buildStepTextField(
          label: "শহর / উপজেলা (City / Town)",
          controller: _cityController,
          hint: "যেমন: মিরপুর, ঢাকা",
        ),
        _buildStepTextField(
          label: "গ্রাম / এলাকা / সড়ক (Village / Street / House)",
          controller: _villageController,
          hint: "যেমন: ব্লক ডি, রোড ৫, বাড়ি ১২",
        ),
        _buildStepTextField(
          label: "জিপ কোড (ZIP Code)",
          controller: _zipController,
          hint: "যেমন: ১২১৬",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        _buildNextButton(onPressed: () {
          if (_selectedDivision == null) {
            _showSnackBar("অনুগ্রহ করে আপনার বিভাগ নির্বাচন করুন");
            return;
          }
          if (_cityController.text.trim().isEmpty) {
            _showSnackBar("অনুগ্রহ করে আপনার শহর বা উপজেলা লিখুন");
            return;
          }
          if (_villageController.text.trim().isEmpty) {
            _showSnackBar("অনুগ্রহ করে আপনার গ্রাম বা এলাকার নাম লিখুন");
            return;
          }
          if (_zipController.text.trim().isEmpty) {
            _showSnackBar("অনুগ্রহ করে জিপ কোড লিখুন");
            return;
          }
          setState(() => _signUpStep = 4);
        }),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "ইউজারনেম নির্ধারণ করুন",
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E824C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "আপনার বন্ধুদের সাথে যুক্ত হওয়ার জন্য একটি অনন্য ইউজারনেম পছন্দ করুন।",
          style: GoogleFonts.hindSiliguri(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        Text(
          "ইউজারনেম (Username)",
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _usernameController,
          onChanged: (val) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              _checkUsernameAvailability(val);
            });
          },
          decoration: InputDecoration(
            hintText: "যেমন: tanzir_ahmed",
            hintStyle: const TextStyle(color: Colors.black26),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixText: "@ ",
            prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
            suffixIcon: _isScanningUsername
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E824C)),
                    ),
                  )
                : _usernameAvailable == null
                    ? null
                    : _usernameAvailable == true
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.cancel, color: Colors.red),
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
              borderSide: BorderSide(
                color: _usernameAvailable == true
                    ? Colors.green
                    : _usernameAvailable == false
                        ? Colors.red
                        : const Color(0xFF1E824C),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_usernameError != null)
          Text(
            _usernameError!,
            style: GoogleFonts.hindSiliguri(color: Colors.red[800], fontSize: 13),
          )
        else if (_usernameAvailable == true)
          Text(
            "অভিনন্দন! এই ইউজারনেমটি খালি আছে।",
            style: GoogleFonts.hindSiliguri(color: Colors.green[800], fontSize: 13, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 28),
        _buildNextButton(onPressed: () {
          if (_usernameController.text.trim().isEmpty) {
            _showSnackBar("অনুগ্রহ করে একটি ইউজারনেম লিখুন");
            return;
          }
          if (_usernameAvailable != true) {
            _showSnackBar("দয়া করে একটি সঠিক ও অব্যবহৃত ইউজারনেম নির্বাচন করুন");
            return;
          }
          setState(() => _signUpStep = 5);
        }),
      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "যোগাযোগের তথ্য",
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E824C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "আপনার অ্যাকাউন্ট নিরাপদ রাখতে এবং নোটিফিকেশন পেতে সঠিক ইমেইল ও মোবাইল নম্বর দিন।",
          style: GoogleFonts.hindSiliguri(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        _buildStepTextField(
          label: "ইমেইল অ্যাড্রেস (Email Address)",
          controller: _emailController,
          hint: "example@gmail.com",
          keyboardType: TextInputType.emailAddress,
        ),
        _buildStepTextField(
          label: "মোবাইল নম্বর (Phone Number)",
          controller: _phoneController,
          hint: "যেমন: ০১৭XXXXXXXX",
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        _buildNextButton(onPressed: () {
          final email = _emailController.text.trim();
          final phone = _phoneController.text.trim();
          
          if (email.isEmpty) {
            _showSnackBar("অনুগ্রহ করে আপনার ইমেইল লিখুন");
            return;
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
            _showSnackBar("অনুগ্রহ করে একটি সঠিক ইমেইল দিন");
            return;
          }
          if (phone.isEmpty) {
            _showSnackBar("অনুগ্রহ করে মোবাইল নম্বর লিখুন");
            return;
          }
          setState(() => _signUpStep = 6);
        }),
      ],
    );
  }

  Widget _buildStep6(AuthService authService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "নিরাপদ পাসওয়ার্ড তৈরি করুন",
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E824C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "অন্যরা যেন সহজে অনুমান করতে না পারে এমন শক্তিশালী পাসওয়ার্ড তৈরি করুন।",
          style: GoogleFonts.hindSiliguri(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        _buildStepTextField(
          label: "পাসওয়ার্ড (Password)",
          controller: _signUpPasswordController,
          hint: "••••••••",
          obscureText: true,
        ),
        _buildStepTextField(
          label: "পাসওয়ার্ড নিশ্চিত করুন (Confirm Password)",
          controller: _confirmPasswordController,
          hint: "••••••••",
          obscureText: true,
        ),
        const SizedBox(height: 24),
        if (authService.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(color: Color(0xFF1E824C)),
            ),
          )
        else
          _buildNextButton(
            label: "অ্যাকাউন্ট তৈরি করুন",
            onPressed: () async {
              final password = _signUpPasswordController.text;
              final confirm = _confirmPasswordController.text;
              
              if (password.isEmpty || password.length < 6) {
                _showSnackBar("পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে");
                return;
              }
              if (password != confirm) {
                _showSnackBar("পাসওয়ার্ড দুটি মেলেনি, আবার চেক করুন");
                return;
              }
              
              final fullName = "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";
              final birthdate = "$_selectedDay/$_selectedMonth/$_selectedYear";
              
              final success = await authService.handleSignup(
                email: _emailController.text.trim(),
                password: password,
                fullName: fullName,
                phone: _phoneController.text.trim(),
                gender: _selectedGender!,
                birthdate: birthdate,
                username: _usernameController.text.trim(),
                division: _selectedDivision,
                city: _cityController.text.trim(),
                village: _villageController.text.trim(),
                zip: _zipController.text.trim(),
              );
              
              if (success && mounted) {
                setState(() => _signUpStep = 7);
              }
            },
          ),
      ],
    );
  }

  Widget _buildStep7() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "অভিনন্দন!",
            style: GoogleFonts.hindSiliguri(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E824C),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "আপনার ডাক অ্যাকাউন্ট সফলভাবে তৈরি হয়েছে। ইমেল ভেরিফাই করার পর লগইন করুন।",
            textAlign: TextAlign.center,
            style: GoogleFonts.hindSiliguri(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isSignUp = false;
                _signUpStep = 1;
                
                // Clear all controllers
                _firstNameController.clear();
                _lastNameController.clear();
                _selectedDay = null;
                _selectedMonth = null;
                _selectedYear = null;
                _selectedGender = null;
                _selectedDivision = null;
                _cityController.clear();
                _villageController.clear();
                _zipController.clear();
                _usernameController.clear();
                _usernameAvailable = null;
                _usernameError = null;
                _emailController.clear();
                _phoneController.clear();
                _signUpPasswordController.clear();
                _confirmPasswordController.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E824C),
              foregroundColor: Colors.white,
              minimumSize: const Size(200, 48),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _isSignUp
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildStepHeader(),
                      const SizedBox(height: 24),
                      if (authService.errorMessage != null && _signUpStep < 7)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            authService.errorMessage!,
                            style: GoogleFonts.hindSiliguri(color: Colors.red[800]),
                          ),
                        ),
                      _buildActiveStep(authService),
                      const SizedBox(height: 40),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),
                      Center(
                        child: Image.asset(
                          "assets/logo_transparent.png",
                          height: 85,
                          width: 85,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "স্বাগতম!",
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E824C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Welcome Back",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (authService.errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            authService.errorMessage!,
                            style: GoogleFonts.hindSiliguri(color: Colors.red[800]),
                          ),
                        ),

                      _buildStepTextField(
                        label: "ইমেইল বা মোবাইল নম্বর",
                        controller: _emailPhoneController,
                        hint: "example@gmail.com",
                      ),
                      _buildStepTextField(
                        label: "পাসওয়ার্ড",
                        controller: _passwordController,
                        hint: "••••••••",
                        obscureText: true,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            "পাসওয়ার্ড ভুলে গেছেন?",
                            style: GoogleFonts.hindSiliguri(
                              color: const Color(0xFF1E824C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (authService.isLoading)
                        const Center(
                          child: CircularProgressIndicator(color: Color(0xFF1E824C)),
                        )
                      else
                        ElevatedButton(
                          onPressed: _submit,
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
                                _signUpStep = 1;
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

                      const SizedBox(height: 40),

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
                      Center(
                        child: Text(
                          "মেড ইন বাংলাদেশ by NGST",
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 11,
                            color: Colors.black38,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
