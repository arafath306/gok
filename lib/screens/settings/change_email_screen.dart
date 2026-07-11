import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/app_theme.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateEmail() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _isSuccess = false;
    });

    try {
      final newEmail = _emailController.text.trim();
      
      // Update email in Supabase Auth
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(email: newEmail),
        emailRedirectTo: 'io.supabase.dak://login-callback',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
          _statusMessage = "A confirmation link has been sent to $newEmail. Please click the link in your email to complete the change.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _statusMessage = e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bgColor = context.scaffoldBg;
    final cardBg = isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(5);
    final cardBorder = isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(10);
    final textPrimary = context.textPrimary;
    final textSecondary = context.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Change Email",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: textPrimary,
            fontSize: 17,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Update your email address",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your new email address below. A confirmation link will be sent to confirm this update.",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder, width: 1),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.inter(color: textPrimary),
                      decoration: InputDecoration(
                        labelText: 'New Email Address',
                        labelStyle: GoogleFonts.inter(color: textSecondary),
                        hintText: 'enter new email',
                        hintStyle: GoogleFonts.inter(color: textSecondary.withAlpha(100)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF0085FF)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an email address';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    if (_statusMessage != null) ...[
                      Text(
                        _statusMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: _isSuccess ? const Color(0xFF05D782) : Colors.red[400],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0085FF),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF0085FF).withAlpha(100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                "Send Confirmation",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
