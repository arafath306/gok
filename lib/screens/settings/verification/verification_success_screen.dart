import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../state/verification_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import '../../main_screen.dart';

class VerificationSuccessScreen extends StatelessWidget {
  const VerificationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final request = context.watch<VerificationController>().request;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          'Verification Active',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.primaryAccent, context.primaryAccent.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    request.fullName.isEmpty ? 'Pigeon User' : request.fullName,
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.verified,
                      color: context.primaryAccent, size: 22),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '@${request.username.isEmpty ? 'username' : request.username}',
                style: GoogleFonts.inter(color: context.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.greenAccent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.greenAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: context.greenAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Congratulations! Your Pigeon Blue Badge is active.",
                        style: GoogleFonts.inter(
                            color: context.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PigeonPrimaryButton(
                label: 'Go to Main Screen',
                icon: Icons.home_rounded,
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
