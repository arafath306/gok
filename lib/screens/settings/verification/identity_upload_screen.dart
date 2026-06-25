import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../state/verification_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/id_upload_card.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import '../../../widgets/verification/pigeon_text_field.dart';
import '../../../widgets/verification/step_progress_bar.dart';
import 'face_verification_screen.dart';

class IdentityUploadScreen extends StatefulWidget {
  const IdentityUploadScreen({super.key});

  @override
  State<IdentityUploadScreen> createState() => _IdentityUploadScreenState();
}

class _IdentityUploadScreenState extends State<IdentityUploadScreen> {
  final _nidController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _front;
  XFile? _back;

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
    _nidController.text = controller.request.nidNumber;
    _front = controller.request.nidFront;
    _back = controller.request.nidBack;
  }

  @override
  void dispose() {
    _nidController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isFront}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        color: context.cardBg,
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt_outlined,
                    color: context.primaryAccent),
                title: Text('Take a photo', style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: context.primaryAccent),
                title: Text('Choose from gallery', style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      if (isFront) {
        _front = picked;
      } else {
        _back = picked;
      }
    });
  }

  void _onContinue() {
    if (_nidController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your NID number')),
      );
      return;
    }
    if (_front == null || _back == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload both sides of your NID card')),
      );
      return;
    }

    context.read<VerificationController>().updateIdentity(
          nidNumber: _nidController.text.trim(),
          front: _front,
          back: _back,
        );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaceVerificationScreen()),
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
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const StepProgressBar(currentStep: 2, labels: _steps),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Confirm Your Identity',
                        style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: context.textPrimary,
                            letterSpacing: -0.4)),
                    const SizedBox(height: 6),
                    Text(
                      'Provide a government-issued photo ID. Make sure the details match your profile and the card is clearly readable.',
                      style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13, height: 1.45),
                    ),
                    const SizedBox(height: 24),
                    
                    PigeonTextField(
                      label: 'National ID (NID) Number',
                      hint: 'Enter your 10 or 17 digit NID number',
                      controller: _nidController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(Icons.badge_outlined,
                          size: 18, color: context.textMuted),
                    ),
                    const SizedBox(height: 20),
                    
                    Text('Upload ID Documents',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: context.textPrimary,
                            letterSpacing: -0.2)),
                    const SizedBox(height: 4),
                    Text('Take clear photos of both the front and back of your NID card.',
                        style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12.5)),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: IdUploadCard(
                            title: 'Front Side',
                            subtitle: 'Tap to upload NID front',
                            file: _front,
                            onTap: () => _pickImage(isFront: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: IdUploadCard(
                            title: 'Back Side',
                            subtitle: 'Tap to upload NID back',
                            file: _back,
                            onTap: () => _pickImage(isFront: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ensure there are no reflections or glares on the NID photos. All text must be perfectly legible for automatic verification checks to succeed.',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: context.textSecondary,
                                height: 1.45,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: PigeonPrimaryButton(
                label: 'Save & Continue',
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
