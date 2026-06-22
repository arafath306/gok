import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../state/verification_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import '../../../widgets/verification/step_progress_bar.dart';
import 'payment_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _confirmed = false;

  static const _steps = [
    'Personal',
    'Identity',
    'Face',
    'Review',
    'Payment'
  ];

  @override
  Widget build(BuildContext context) {
    final request = context.watch<VerificationController>().request;

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
            const StepProgressBar(currentStep: 4, labels: _steps),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Review your application',
                        style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      'Double check everything before you proceed to payment.',
                      style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: context.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(context, 'Personal & Contact'),
                          _buildDetailRow(context, 'Full name', request.fullName),
                          _buildDetailRow(context, 'Username', '@${request.username}'),
                          _buildDetailRow(context, 'Date of birth', request.dateOfBirth == null ? '-' : '${request.dateOfBirth!.day}/${request.dateOfBirth!.month}/${request.dateOfBirth!.year}'),
                          _buildDetailRow(context, 'Phone', request.phone),
                          _buildDetailRow(context, 'Email', request.email),
                          
                          const Divider(height: 1),
                          
                          _buildSectionHeader(context, 'Identity & Face'),
                          _buildDetailRow(context, 'NID number', request.nidNumber),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(child: _buildImageThumb(context, 'Front', request.nidFront?.path)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildImageThumb(context, 'Back', request.nidBack?.path)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildImageThumb(context, 'Face', request.faceImage?.path)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () => setState(() => _confirmed = !_confirmed),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _confirmed,
                                activeColor: context.primaryAccent,
                                onChanged: (v) =>
                                    setState(() => _confirmed = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'I confirm this information is accurate and the provided NID and photo belong to me.',
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: context.textPrimary, height: 1.4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: PigeonPrimaryButton(
                label: 'Continue to Payment',
                icon: Icons.arrow_forward_rounded,
                onPressed: _confirmed
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PaymentScreen()),
                        );
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.primaryAccent.withOpacity(0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
          color: context.primaryAccent,
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: context.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: GoogleFonts.inter(
                color: context.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImageThumb(BuildContext context, String label, String? path) {
    return Column(
      children: [
        Container(
          height: 60,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.border),
          ),
          child: path != null 
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(path), fit: BoxFit.cover),
                )
              : Center(child: Icon(Icons.broken_image_outlined, size: 20, color: context.textMuted)),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
