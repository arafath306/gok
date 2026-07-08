import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../services/database_service.dart';
import '../../state/monetization_controller.dart';
import '../../utils/app_theme.dart';

class SubscriptionPaymentScreen extends StatefulWidget {
  final String creatorId;
  final String creatorName;
  final double planPrice;

  const SubscriptionPaymentScreen({
    super.key,
    required this.creatorId,
    required this.creatorName,
    required this.planPrice,
  });

  @override
  State<SubscriptionPaymentScreen> createState() => _SubscriptionPaymentScreenState();
}

class _SubscriptionPaymentScreenState extends State<SubscriptionPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senderController = TextEditingController();
  final _trxController = TextEditingController();
  bool _isSubmitting = false;

  static const _bkashNumber = '01313961899'; // Same admin bKash number

  @override
  void dispose() {
    _senderController.dispose();
    _trxController.dispose();
    super.dispose();
  }

  void _copyNumber() {
    Clipboard.setData(const ClipboardData(text: _bkashNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'bKash number copied to clipboard',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final db = Provider.of<DatabaseService>(context, listen: false);
    final myProfile = db.myProfile;
    if (myProfile == null) return;

    setState(() => _isSubmitting = true);

    try {
      final mc = Provider.of<MonetizationController>(context, listen: false);
      await mc.submitSubscription(
        myProfile.id,
        widget.creatorId,
        _senderController.text.trim(),
        _trxController.text.trim().toUpperCase(),
        widget.planPrice,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscription request sent! Pending admin approval.', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: context.greenAccent,
        )
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submission failed: $e', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red[600],
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Subscribe',
          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: context.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Subscribe to ${widget.creatorName}',
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get exclusive access to subscriber-only posts for ৳${widget.planPrice.toStringAsFixed(0)}/month.',
                  style: GoogleFonts.inter(fontSize: 15, color: context.textSecondary),
                ),
                const SizedBox(height: 32),
                
                // Instructions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.primaryAccent.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payment_rounded, color: context.primaryAccent, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'bKash Send Money',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('1. Go to your bKash app', style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary)),
                      const SizedBox(height: 8),
                      Text('2. Tap on "Send Money"', style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('3. Send ', style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary)),
                          Text('৳${widget.planPrice.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: context.textPrimary)),
                          Text(' to:', style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _bkashNumber,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1, color: context.textPrimary),
                            ),
                            InkWell(
                              onTap: _copyNumber,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: context.primaryAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('COPY', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: context.primaryAccent)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Form
                Text('bKash Sender Number', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _senderController,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.inter(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. 01712345678',
                    hintStyle: GoogleFonts.inter(color: context.textMuted),
                    filled: true,
                    fillColor: context.cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter the sender number';
                    if (val.length < 11) return 'Enter a valid 11-digit number';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                Text('Transaction ID (TrxID)', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: context.textPrimary)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _trxController,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.inter(color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. 9J6A7C8D',
                    hintStyle: GoogleFonts.inter(color: context.textMuted),
                    filled: true,
                    fillColor: context.cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter the Transaction ID';
                    if (val.length < 8) return 'Enter a valid TrxID';
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Submit for Review', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
