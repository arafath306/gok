import 'package:dak/l10n/generated/app_localizations.dart';
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
        title: Text(AppLocalizations.of(context)!.verificationActive,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Glowing outer verification ring
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0095F6).withValues(alpha: 0.06),
                    ),
                  ),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0095F6).withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0095F6), Color(0xFF5B7FFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF0095F6),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Icon(Icons.verified_rounded, color: Colors.white, size: 44),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // User info row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    request.fullName.isEmpty ? 'Pigeon User' : request.fullName,
                    style: GoogleFonts.inter(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                        letterSpacing: -0.4),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.verified_rounded,
                      color: Color(0xFF0095F6), size: 23),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '@${request.username.isEmpty ? 'username' : request.username}',
                style: GoogleFonts.inter(
                  color: context.textSecondary, 
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500
                ),
              ),
              const SizedBox(height: 32),
              
              // Congratulations card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context)!.identityVerified,
                      style: GoogleFonts.inter(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(AppLocalizations.of(context)!.congratulationsYourPigeonBlueBadgeIsNowA,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              PigeonPrimaryButton(
                label: AppLocalizations.of(context)!.goToFeedHome,
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
