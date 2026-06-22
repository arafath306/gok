import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/verification_request.dart';
import '../../../services/database_service.dart';
import '../../../state/verification_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import '../../main_screen.dart';
import 'personal_details_screen.dart';
import 'verification_success_screen.dart';

class PendingScreen extends StatefulWidget {
  const PendingScreen({super.key});

  @override
  State<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends State<PendingScreen> {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Refresh status automatically on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh(silent: true);
    });
  }

  Future<void> _refresh({bool silent = false}) async {
    if (!silent) setState(() => _checking = true);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final controller = context.read<VerificationController>();
    final status = await controller.checkStatus(dbService);
    if (!silent) setState(() => _checking = false);

    if (!mounted) return;

    if (status == VerificationStatus.approved) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerificationSuccessScreen()),
      );
    } else if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == VerificationStatus.rejected
                ? 'Your request has been rejected. Please review details.'
                : 'Still under review — check back later.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = context.watch<VerificationController>().request;
    final isRejected = request.status == VerificationStatus.rejected;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
            );
          },
        ),
        title: Text(
          'Application Status',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: (isRejected ? Colors.red : context.primaryAccent)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRejected
                        ? Icons.error_outline
                        : Icons.hourglass_top_rounded,
                    size: 44,
                    color: isRejected ? Colors.red : context.primaryAccent,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isRejected
                      ? 'Application needs attention'
                      : "You're in the queue",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  isRejected
                      ? (request.rejectionReason ??
                          'There was an issue with your documents or payment. '
                              'Please check the details and try again.')
                      : 'Our team is verifying your documents and bKash payment. '
                          'This usually takes 24–48 hours. We\'ll enable the Blue '
                          'Badge on your profile as soon as it is approved.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 13.5, color: context.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.border),
                  ),
                  child: Column(
                    children: [
                      _StatusRow(label: 'Username', value: '@${request.username}'),
                      _StatusRow(
                          label: 'TrxID', value: request.bkashTrxId.isEmpty ? '-' : request.bkashTrxId),
                      _StatusRow(
                        label: 'Status',
                        value: isRejected ? 'Rejected' : 'Pending review',
                        valueColor: isRejected ? Colors.red : context.primaryAccent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (isRejected)
                  PigeonPrimaryButton(
                    label: 'Re-apply for Blue Badge',
                    icon: Icons.refresh_rounded,
                    onPressed: () {
                      final controller = context.read<VerificationController>();
                      controller.resetApplication();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PersonalDetailsScreen()),
                      );
                    },
                  )
                else
                  PigeonPrimaryButton(
                    label: 'Refresh Status',
                    icon: Icons.refresh_rounded,
                    isLoading: _checking,
                    onPressed: () => _refresh(silent: false),
                  ),
                const SizedBox(height: 12),
                PigeonPrimaryButton(
                  label: 'Back to Home',
                  outlined: true,
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
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatusRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13)),
          Text(value,
              style: GoogleFonts.inter(
                  color: valueColor ?? context.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
