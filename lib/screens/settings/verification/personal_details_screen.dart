import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../services/database_service.dart';
import '../../../state/verification_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import '../../../widgets/verification/pigeon_text_field.dart';
import '../../../widgets/verification/step_progress_bar.dart';
import 'identity_upload_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dob;

  static const _steps = [
    'Personal',
    'Identity',
    'Face',
    'Review',
    'Payment'
  ];

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<VerificationController>(context, listen: false);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final myProfile = dbService.myProfile;

    _nameController.text = controller.request.fullName.isNotEmpty
        ? controller.request.fullName
        : (myProfile?.fullName ?? '');
    _usernameController.text = controller.request.username.isNotEmpty
        ? controller.request.username
        : (myProfile?.username ?? '');
    _bioController.text = controller.request.bio.isNotEmpty
        ? controller.request.bio
        : (myProfile?.bio ?? '');
    _emailController.text = controller.request.email.isNotEmpty
        ? controller.request.email
        : (myProfile?.email ?? '');
    _phoneController.text = controller.request.phone.isNotEmpty
        ? controller.request.phone
        : (myProfile?.phone ?? '');

    if (controller.request.dateOfBirth != null) {
      _dob = controller.request.dateOfBirth;
    } else if (myProfile?.birthdate != null && myProfile!.birthdate!.isNotEmpty) {
      _dob = DateTime.tryParse(myProfile.birthdate!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: context.primaryAccent,
              primary: context.primaryAccent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth')),
      );
      return;
    }

    context.read<VerificationController>().updatePersonalDetails(
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          dateOfBirth: _dob!,
          bio: _bioController.text.trim(),
        );

    context.read<VerificationController>().updateContactInfo(
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
        );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IdentityUploadScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Apply for Blue Badge',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const StepProgressBar(currentStep: 1, labels: _steps),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Personal details',
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary)),
                      const SizedBox(height: 4),
                      Text(
                        'This should match the name on your ID card.',
                        style: GoogleFonts.inter(
                            color: context.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      PigeonTextField(
                        label: 'Full name',
                        hint: 'e.g. Abdullah Al Mamun',
                        controller: _nameController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Full name is required'
                            : null,
                      ),
                      PigeonTextField(
                        label: 'Pigeon username',
                        hint: 'yourhandle',
                        controller: _usernameController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Username is required'
                            : null,
                      ),
                      PigeonTextField(
                        label: 'Date of birth',
                        hint: 'Tap to select',
                        controller: TextEditingController(
                          text: _dob == null
                              ? ''
                              : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                        ),
                        readOnly: true,
                        onTap: _pickDob,
                        prefixIcon: Icon(Icons.calendar_today_outlined,
                            size: 18, color: context.textMuted),
                      ),
                      PigeonTextField(
                        label: 'Email Address',
                        hint: 'your.email@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Enter a valid email'
                            : null,
                      ),
                      PigeonTextField(
                        label: 'Phone Number',
                        hint: '01XXXXXXXXX',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().length < 11)
                            ? 'Enter a valid phone number'
                            : null,
                      ),
                      PigeonTextField(
                        label: 'Short bio (optional)',
                        hint: 'Tell us a little about yourself',
                        controller: _bioController,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: PigeonPrimaryButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: _onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
