import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../services/database_service.dart';
import '../../../state/verification_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import '../../../widgets/verification/pigeon_text_field.dart';
import '../../../widgets/verification/step_progress_bar.dart';
import 'pending_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senderController = TextEditingController();
  final _trxController = TextEditingController();

  static const _steps = ['Personal', 'Identity', 'Face', 'Review', 'Payment'];

  static const _merchantNumber = '01313961899';

  @override
  void dispose() {
    _senderController.dispose();
    _trxController.dispose();
    super.dispose();
  }

  void _copyNumber() {
    Clipboard.setData(const ClipboardData(text: _merchantNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'bKash number copied',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        backgroundColor: context.greenAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final controller = context.read<VerificationController>();
    controller.updatePaymentInfo(
      bkashSenderNumber: _senderController.text.trim(),
      bkashTrxId: _trxController.text.trim().toUpperCase(),
    );

    try {
      await controller.submitApplication(dbService);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PendingScreen()),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Submission failed: $e',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final controller = context.watch<VerificationController>();
    final isSubmitting = controller.isSubmitting;
    final selectedPlanId = controller.request.selectedPlanId;

    final plan = dbService.verificationPlans.firstWhere(
      (p) => p['id'] == selectedPlanId,
      orElse: () => {
        'id': 'monthly',
        'name': 'Monthly Plan',
        'price': 199.0,
        'interval_unit': 'month',
      },
    );

    final planName = plan['name'] ?? 'Monthly Plan';
    final price = plan['price'] is num
        ? (plan['price'] as num).toDouble()
        : double.tryParse(plan['price'].toString()) ?? 199.0;
    final discountPrice = plan['discount_price'] != null
        ? (plan['discount_price'] is num
              ? (plan['discount_price'] as num).toDouble()
              : double.tryParse(plan['discount_price'].toString()))
        : null;

    final finalPriceVal = discountPrice ?? price;
    final feeAmountStr = '৳${finalPriceVal.toStringAsFixed(0)}';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.textPrimary,
            size: 20,
          ),
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
            const StepProgressBar(currentStep: 5, labels: _steps),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pay the verification fee',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A membership fee to verify and maintain your Blue Badge ($planName).',
                        style: GoogleFonts.inter(
                          color: context.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // bKash card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2136E),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE2136E).withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'bKash · Send Money',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _merchantNumber,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _copyNumber,
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white24,
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Amount: $feeAmountStr',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'How to pay',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _StepLine(number: 1, text: 'Open your bKash app'),
                      const _StepLine(
                        number: 2,
                        text: "Tap 'Send Money' and enter the number above",
                      ),
                      _StepLine(
                        number: 3,
                        text: 'Enter the amount: $feeAmountStr',
                      ),
                      const _StepLine(
                        number: 4,
                        text: 'Use your Pigeon username as reference',
                      ),
                      const _StepLine(
                        number: 5,
                        text:
                            'Confirm with your PIN and copy the TrxID '
                            'from the confirmation screen/SMS',
                      ),
                      const SizedBox(height: 24),

                      PigeonTextField(
                        label: 'Your bKash number',
                        hint: '01XXXXXXXXX',
                        controller: _senderController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icon(
                          Icons.phone_iphone,
                          size: 18,
                          color: context.textMuted,
                        ),
                        validator: (v) => (v == null || v.trim().length < 11)
                            ? 'Enter the number you paid from'
                            : null,
                      ),
                      PigeonTextField(
                        label: 'Transaction ID (TrxID)',
                        hint: 'e.g. 9F7K2L1A0B',
                        controller: _trxController,
                        prefixIcon: Icon(
                          Icons.confirmation_number_outlined,
                          size: 18,
                          color: context.textMuted,
                        ),
                        validator: (v) => (v == null || v.trim().length < 6)
                            ? 'Enter the TrxID from your bKash SMS'
                            : null,
                      ),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.primaryAccent.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.primaryAccent.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: context.primaryAccent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'We verify every transaction ID against our '
                                'bKash statement before approving a badge. '
                                'False TrxIDs will be rejected.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: context.textSecondary,
                                  height: 1.4,
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: PigeonPrimaryButton(
                label: 'Submit Application',
                icon: Icons.check_circle_outline,
                isLoading: isSubmitting,
                onPressed: _onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final int number;
  final String text;

  const _StepLine({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: context.primaryAccent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
