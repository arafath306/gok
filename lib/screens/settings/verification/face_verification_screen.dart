import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../state/verification_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/id_upload_card.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import '../../../widgets/verification/step_progress_bar.dart';
import 'review_screen.dart';

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  final _picker = ImagePicker();
  XFile? _faceImage;

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
    _faceImage = controller.request.faceImage;
  }

  Future<void> _pickImage() async {
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
                leading: Icon(Icons.camera_alt_outlined, color: context.primaryAccent),
                title: Text('Take a selfie', style: GoogleFonts.inter(color: context.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: context.primaryAccent),
                title: Text('Choose from gallery', style: GoogleFonts.inter(color: context.textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    
    // We prefer the front camera for selfies if using the camera
    final picked = await _picker.pickImage(
      source: source, 
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked == null) return;

    setState(() {
      _faceImage = picked;
    });
  }

  void _onContinue() {
    if (_faceImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a clear photo of your face')),
      );
      return;
    }

    context.read<VerificationController>().updateFaceImage(_faceImage);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReviewScreen()),
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
            const StepProgressBar(currentStep: 3, labels: _steps),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Face Verification',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      'Please provide a clear photo of your face to match with your NID. This prevents impersonation.',
                      style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 250,
                        child: IdUploadCard(
                          title: 'Your Face',
                          subtitle: 'Tap to take a selfie',
                          file: _faceImage,
                          onTap: _pickImage,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.primaryAccent.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.primaryAccent.withOpacity(0.1)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline, color: context.primaryAccent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tips for a good photo:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary)),
                                const SizedBox(height: 8),
                                Text('• Ensure good lighting\n• Look straight at the camera\n• Do not wear sunglasses or hats\n• Face should be clearly visible', 
                                style: GoogleFonts.inter(color: context.textSecondary, fontSize: 12.5, height: 1.5)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
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
