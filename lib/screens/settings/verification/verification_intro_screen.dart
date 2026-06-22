import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/verification_request.dart';
import '../../../state/verification_controller.dart';
import '../../../services/database_service.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import 'personal_details_screen.dart';
import 'pending_screen.dart';

class VerificationIntroScreen extends StatefulWidget {
  const VerificationIntroScreen({super.key});

  @override
  State<VerificationIntroScreen> createState() => _VerificationIntroScreenState();
}

class _VerificationIntroScreenState extends State<VerificationIntroScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      dbService.fetchVerificationPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final controller = context.watch<VerificationController>();
    final status = controller.request.status;
    final selectedPlanId = controller.request.selectedPlanId;

    // Plans list with dynamic values from DB if available, otherwise fallbacks
    final plans = dbService.verificationPlans.isNotEmpty
        ? dbService.verificationPlans
        : [
            {'id': 'weekly', 'name': 'Weekly Plan', 'price': 59.0, 'discount_price': null, 'interval_unit': 'week'},
            {'id': 'monthly', 'name': 'Monthly Plan', 'price': 199.0, 'discount_price': null, 'interval_unit': 'month'},
            {'id': 'yearly', 'name': 'Yearly Plan', 'price': 1999.0, 'discount_price': null, 'interval_unit': 'year'},
            {'id': 'lifetime', 'name': 'Lifetime Plan', 'price': 4999.0, 'discount_price': null, 'interval_unit': 'lifetime'},
          ];

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
          'Verification',
          style: GoogleFonts.inter(
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Beautiful glowing header visual
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer glowing circular ring
                        Container(
                          width: 106,
                          height: 106,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0095F6).withOpacity(0.06),
                          ),
                        ),
                        // Middle thin ring
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0095F6).withOpacity(0.15),
                              width: 1.2,
                            ),
                          ),
                        ),
                        // Profile Avatar
                        CircleAvatar(
                          radius: 39,
                          backgroundColor: context.isDarkMode ? const Color(0xFF1E293B) : Colors.grey[100],
                          backgroundImage: dbService.myProfile?.avatarUrl != null && dbService.myProfile!.avatarUrl!.isNotEmpty
                              ? NetworkImage(dbService.myProfile!.avatarUrl!)
                              : null,
                          child: (dbService.myProfile?.avatarUrl == null || dbService.myProfile!.avatarUrl!.isEmpty)
                              ? Icon(Icons.person_rounded, size: 36, color: context.textSecondary)
                              : null,
                        ),
                        // Blue Check Badge
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.scaffoldBg,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF0095F6),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Pigeon Verified',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Stand out, establish authenticity, and unlock dedicated safety and support tools.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: context.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Benefits
              _buildSectionHeader(context, "Exclusive Benefits"),
              const SizedBox(height: 8),
              _buildPremiumBenefitTile(
                context,
                icon: Icons.verified_rounded,
                iconColor: const Color(0xFF0095F6),
                title: "Verified Profile Badge",
                description: "Let your followers know your account is authentic with a premium blue checkmark.",
              ),
              _buildPremiumBenefitTile(
                context,
                icon: Icons.security_rounded,
                iconColor: const Color(0xFF10B981),
                title: "Advanced Impersonation Monitoring",
                description: "Proactive account defense mechanism designed to prevent copycat profiles.",
              ),
              _buildPremiumBenefitTile(
                context,
                icon: Icons.support_agent_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: "Direct Priority Support",
                description: "Dedicated routing queue for your account tickets to receive help rapidly.",
              ),
              _buildPremiumBenefitTile(
                context,
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: "Exclusive Custom Features",
                description: "Gain early access to beta customizations, exclusive badges, and layouts.",
              ),
              const SizedBox(height: 16),

              // Requirements
              _buildSectionHeader(context, "Before You Apply"),
              const SizedBox(height: 4),
              Text(
                "Verify that your account meets these fundamental guidelines before starting registration:",
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: context.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.border, width: 0.8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildRequirementItem(context, "A valid government photo ID card"),
                    Divider(color: context.border, height: 1, thickness: 0.5),
                    _buildRequirementItem(context, "A clear profile photo showing your full face"),
                    Divider(color: context.border, height: 1, thickness: 0.5),
                    _buildRequirementItem(context, "Complete profile details (Bio, birthdate, email)"),
                    Divider(color: context.border, height: 1, thickness: 0.5),
                    _buildRequirementItem(context, "Active history and standing on Pigeon"),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Process
              _buildSectionHeader(context, "Simple 3-Step Review"),
              const SizedBox(height: 16),
              _buildTimelineStep(
                context,
                stepNumber: 1,
                title: "Confirm Your Information",
                description: "Review your auto-filled profile info, add phone, and upload ID documents.",
                isLast: false,
              ),
              _buildTimelineStep(
                context,
                stepNumber: 2,
                title: "Confirm Your Identity",
                description: "Submit a clear face selfie for secure document comparison.",
                isLast: false,
              ),
              _buildTimelineStep(
                context,
                stepNumber: 3,
                title: "Review & Activate",
                description: "Our compliance agents review your case and issue the badge upon approval.",
                isLast: true,
              ),
              const SizedBox(height: 24),

              // Security info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.border, width: 0.8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline_rounded, color: context.primaryAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your privacy is our priority',
                            style: GoogleFonts.inter(
                              color: context.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Documents and face selfie data are fully encrypted and only processed to confirm identity. Sensitive details are never shared or made public.',
                            style: GoogleFonts.inter(
                              color: context.textSecondary,
                              fontSize: 12.5,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Selection
              _buildSectionHeader(context, "Select a Verification Plan"),
              const SizedBox(height: 4),
              Text(
                "Choose the plan that suits you best. Cancel or adjust your subscription anytime.",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: context.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: plans.map<Widget>((plan) {
                  final planId = plan['id'] as String;
                  final planName = plan['name'] as String;
                  final price = plan['price'] is num 
                      ? (plan['price'] as num).toDouble() 
                      : double.tryParse(plan['price'].toString()) ?? 199.0;
                  final discountPrice = plan['discount_price'] != null
                      ? (plan['discount_price'] is num 
                          ? (plan['discount_price'] as num).toDouble() 
                          : double.tryParse(plan['discount_price'].toString()))
                      : null;
                  final interval = plan['interval_unit'] as String;
                  final isSelected = selectedPlanId == planId;

                  String intervalText = '';
                  if (interval == 'week') intervalText = '/week';
                  if (interval == 'month') intervalText = '/month';
                  if (interval == 'year') intervalText = '/year';
                  if (interval == 'lifetime') intervalText = ' (one-time)';

                  return _AnimatedPlanCard(
                    planId: planId,
                    planName: planName,
                    price: price,
                    discountPrice: discountPrice,
                    intervalText: intervalText,
                    isSelected: isSelected,
                    onTap: () => controller.selectPlan(planId),
                  );
                }).toList(),
              ),
              if (selectedPlanId == 'yearly') ...[
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Annual billing offers maximum savings.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // FAQ
              _buildSectionHeader(context, "Frequently Asked Questions"),
              const SizedBox(height: 8),
              _SmartFAQItem(
                question: 'Does paying guarantee my verification badge?', 
                answer: 'No. All accounts must pass our security and identity criteria. If rejected, your subscription payment details can be managed or fully refunded.',
              ),
              _SmartFAQItem(
                question: 'Can I cancel or renew my subscription?', 
                answer: 'Yes. You can manage or cancel your active subscription at any time. When your subscription ends, your badge remains active until the end of the billing period.',
              ),
              _SmartFAQItem(
                question: 'Will my profile badge disappear if I cancel?', 
                answer: 'Yes. The verified badge and associated protection and support features are exclusive benefits of an active Pigeon Verified membership.',
              ),
              const SizedBox(height: 32),

              // Bottom CTA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.border, width: 0.8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Ready to elevate your profile?',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Begin verification and unlock premium benefits today.',
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 12.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    PigeonPrimaryButton(
                      label: 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        controller.resetApplication();
                        // Carry over the selected plan
                        controller.selectPlan(selectedPlanId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PersonalDetailsScreen()),
                        );
                      },
                    ),
                    if (status != VerificationStatus.incomplete) ...[
                      const SizedBox(height: 12),
                      PigeonPrimaryButton(
                        label: 'Check Application Status',
                        outlined: true,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PendingScreen()),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: context.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildPremiumBenefitTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: context.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 11, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    BuildContext context, {
    required int stepNumber,
    required String title,
    required String description,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: context.primaryAccent.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: context.primaryAccent, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                '$stepNumber',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.primaryAccent,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 1.2,
                height: 48,
                color: context.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: context.textSecondary,
                  height: 1.4,
                ),
              ),
              if (!isLast) const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmartFAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const _SmartFAQItem({required this.question, required this.answer});

  @override
  State<_SmartFAQItem> createState() => _SmartFAQItemState();
}

class _SmartFAQItemState extends State<_SmartFAQItem> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = context.primaryAccent;
    return GestureDetector(
      onTap: _toggleExpand,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      color: _isExpanded ? accentColor : context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                RotationTransition(
                  turns: _iconTurns,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _isExpanded ? accentColor : context.textSecondary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: SizedBox(
              width: double.infinity,
              child: _isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        widget.answer,
                        style: GoogleFonts.inter(
                          color: context.textSecondary,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Divider(color: context.border, height: 1, thickness: 0.5),
        ],
      ),
    );
  }
}

class _AnimatedPlanCard extends StatefulWidget {
  final String planId;
  final String planName;
  final double price;
  final double? discountPrice;
  final String intervalText;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnimatedPlanCard({
    required this.planId,
    required this.planName,
    required this.price,
    this.discountPrice,
    required this.intervalText,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedPlanCard> createState() => _AnimatedPlanCardState();
}

class _AnimatedPlanCardState extends State<_AnimatedPlanCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = context.primaryAccent;
    
    String? badgeText;
    Color? badgeBg;
    Color? badgeTextColor;
    
    if (widget.planId == 'monthly') {
      badgeText = 'Popular';
      badgeBg = accentColor;
      badgeTextColor = Colors.white;
    } else if (widget.planId == 'yearly') {
      badgeText = 'Best Value';
      badgeBg = const Color(0xFF10B981);
      badgeTextColor = Colors.white;
    } else if (widget.planId == 'lifetime') {
      badgeText = 'One-time';
      badgeBg = const Color(0xFFF59E0B);
      badgeTextColor = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: widget.isSelected 
                  ? (context.isDarkMode ? accentColor.withOpacity(0.08) : accentColor.withOpacity(0.04))
                  : context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelected ? accentColor : context.border,
                width: widget.isSelected ? 1.8 : 0.8,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isSelected ? accentColor : context.textMuted,
                      width: widget.isSelected ? 6 : 1.5,
                    ),
                    color: widget.isSelected ? Colors.white : Colors.transparent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.planName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: context.textPrimary,
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                badgeText,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: badgeTextColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (widget.discountPrice != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Save ${((1 - (widget.discountPrice! / widget.price)) * 100).toStringAsFixed(0)}% off regular price',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF10B981),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (widget.discountPrice != null) ...[
                          Text(
                            '৳${widget.price.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: context.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '৳${(widget.discountPrice ?? widget.price).toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      widget.intervalText,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
