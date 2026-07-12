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
import 'package:cached_network_image/cached_network_image.dart';

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

    final verificationPlans = context.select<DatabaseService, List<Map<String, dynamic>>>((db) => db.verificationPlans);
    final myAvatarUrl = context.select<DatabaseService, String?>((db) => db.myProfile?.avatarUrl);
    
    final controller = context.watch<VerificationController>();
    final status = controller.request.status;
    final selectedPlanId = controller.request.selectedPlanId;

    // Plans list with dynamic values from DB if available, otherwise fallbacks
    final plans = verificationPlans.isNotEmpty
        ? verificationPlans
        : [
            {'id': 'weekly', 'name': 'Weekly', 'price': 59.0, 'discount_price': null, 'interval_unit': 'week'},
            {'id': 'monthly', 'name': 'Monthly', 'price': 199.0, 'discount_price': null, 'interval_unit': 'month'},
            {'id': 'yearly', 'name': 'Yearly', 'price': 1999.0, 'discount_price': 1599.0, 'interval_unit': 'year'},
            {'id': 'lifetime', 'name': 'Lifetime', 'price': 4999.0, 'discount_price': null, 'interval_unit': 'lifetime'},
          ];

    // Find the currently selected plan details
    final selectedPlan = plans.firstWhere(
      (p) => p['id'] == selectedPlanId,
      orElse: () => plans.first,
    );

    final selectedPlanName = selectedPlan['name'] as String;
    final selectedPlanPrice = selectedPlan['price'] is num 
        ? (selectedPlan['price'] as num).toDouble() 
        : double.tryParse(selectedPlan['price'].toString()) ?? 199.0;
    final selectedPlanDiscount = selectedPlan['discount_price'] != null
        ? (selectedPlan['discount_price'] is num 
            ? (selectedPlan['discount_price'] as num).toDouble() 
            : double.tryParse(selectedPlan['discount_price'].toString()))
        : null;
    final selectedPlanInterval = selectedPlan['interval_unit'] as String;

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
          'Pigeon Verified',
          style: GoogleFonts.inter(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.3,
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
              // 1. Pulsating Radar Avatar Header (Biometric Scanner Feel)
              _PulsingAvatarHeader(avatarUrl: myAvatarUrl),
              const SizedBox(height: 28),

              // 2. Section: Plan Custom Selection Tabs
              _buildSectionHeader(context, "Select Subscription Model"),
              const SizedBox(height: 12),
              
              // Sliding segments list
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: plans.map<Widget>((plan) {
                    final planId = plan['id'] as String;
                    final planName = plan['name'] as String;
                    final isSelected = selectedPlanId == planId;
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => controller.selectPlan(planId),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? (context.isDarkMode ? const Color(0xFF2E3045) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Text(
                            planName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? context.textPrimary : context.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Featured Plan Detail Card (Facebook/Meta Verified Style)
              _PremiumPlanInfoCard(
                planId: selectedPlanId,
                planName: selectedPlanName,
                price: selectedPlanPrice,
                discountPrice: selectedPlanDiscount,
                interval: selectedPlanInterval,
              ),
              const SizedBox(height: 28),

              // 4. Exclusive Benefits Redesigned
              _buildSectionHeader(context, "What's Included in Pigeon Verified"),
              const SizedBox(height: 12),
              _buildPremiumBenefitTile(
                context,
                icon: Icons.verified_rounded,
                iconColor: const Color(0xFF0095F6),
                title: "Verified Profile Badge",
                description: "Establish authenticity. Let your followers and community know you are a verified public figure.",
              ),
              _buildPremiumBenefitTile(
                context,
                icon: Icons.shield_outlined,
                iconColor: const Color(0xFF10B981),
                title: "Impersonation Protection",
                description: "Proactive, automated monitoring filters to safeguard your username and prevent copycat profiles.",
              ),
              _buildPremiumBenefitTile(
                context,
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: "Direct Priority Support",
                description: "Dedicated account support helpdesk. Resolve support issues rapidly with real human support.",
              ),
              _buildPremiumBenefitTile(
                context,
                icon: Icons.auto_awesome_outlined,
                iconColor: const Color(0xFFF59E0B),
                title: "Exclusive Stickers & Features",
                description: "Unlock premium verification stickers for chating and profile layout customization.",
              ),
              const SizedBox(height: 28),

              // 5. Requirements Checkbox List
              _buildSectionHeader(context, "Eligibility Requirements"),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.border, width: 0.8),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildRequirementItem(context, "Must be at least 18 years of age"),
                    _buildRequirementItem(context, "Must provide a government-issued photo ID card"),
                    _buildRequirementItem(context, "Full profile picture showing your face clearly"),
                    _buildRequirementItem(context, "Enabled 2FA or secure recovery email on account"),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 6. Security/Data Privacy Statement
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0095F6).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0095F6).withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_user_outlined, color: Color(0xFF0095F6), size: 22),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Identity is Secure',
                            style: GoogleFonts.inter(
                              color: context.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'We do not sell or share your identity details. NID images and face selfie records are immediately encrypted and processed for compliance check only.',
                            style: GoogleFonts.inter(
                              color: context.textSecondary,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 7. Accordion FAQs
              _buildSectionHeader(context, "Frequently Asked Questions"),
              const SizedBox(height: 12),
              _SmartFAQItem(
                question: 'What happens to my payment if rejected?',
                answer: 'All submitted verification requests are reviewed manually. If our compliance team rejects your request due to blur images or incorrect document formats, you will be given an option to re-apply for free or claim a full refund.',
              ),
              _SmartFAQItem(
                question: 'Can I cancel my subscription anytime?',
                answer: 'Yes, your subscription can be managed or canceled directly in Settings. Once canceled, your verified checkmark badge remains active until the end of the current billing interval.',
              ),
              _SmartFAQItem(
                question: 'Will my badge be removed if I change username?',
                answer: 'Yes. To protect against profile impersonation, changing your username or full name will temporarily hide the verified checkmark until a fast re-verification is completed.',
              ),
              const SizedBox(height: 32),

              // 8. Bottom Action Panel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.border, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    PigeonPrimaryButton(
                      label: 'Subscribe & Continue',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        controller.resetApplication();
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
                        label: 'Check Current Status',
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
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: context.textPrimary,
        letterSpacing: -0.3,
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
              color: iconColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom pulsing avatar widget representing high quality multinational style
class _PulsingAvatarHeader extends StatefulWidget {
  final String? avatarUrl;
  const _PulsingAvatarHeader({this.avatarUrl});

  @override
  State<_PulsingAvatarHeader> createState() => _PulsingAvatarHeaderState();
}

class _PulsingAvatarHeaderState extends State<_PulsingAvatarHeader> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final double value = _pulseController.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse Ring 1
                  Transform.scale(
                    scale: 1.0 + (value * 0.45),
                    child: Opacity(
                      opacity: (1.0 - value).clamp(0.0, 1.0),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0095F6), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  // Pulse Ring 2
                  Transform.scale(
                    scale: 1.0 + (((value + 0.5) % 1.0) * 0.45),
                    child: Opacity(
                      opacity: (1.0 - ((value + 0.5) % 1.0)).clamp(0.0, 1.0),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0095F6), width: 1),
                        ),
                      ),
                    ),
                  ),
                  // Solid Avatar frame
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.customCardBg,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0095F6).withValues(alpha: 0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                  // Actual Avatar
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                    backgroundImage: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(widget.avatarUrl!)
                        : null,
                    child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                        ? Icon(Icons.person, size: 36, color: isDark ? Colors.white30 : Colors.black26)
                        : null,
                  ),
                  // Glowing Badge Checkmark icon
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
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
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Pigeon Verified',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: context.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'A subscription bundle to build your presence and credibility with safety tools and priority support.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: context.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Premium details container for the selected plan
class _PremiumPlanInfoCard extends StatelessWidget {
  final String planId;
  final String planName;
  final double price;
  final double? discountPrice;
  final String interval;

  const _PremiumPlanInfoCard({
    required this.planId,
    required this.planName,
    required this.price,
    this.discountPrice,
    required this.interval,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Choose gradient theme based on planId
    final LinearGradient cardGradient = planId == 'lifetime'
        ? const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: isDark 
                ? [const Color(0xFF2A2D4A), const Color(0xFF1B1D30)]
                : [const Color(0xFFE3F2FD), const Color(0xFFF3E5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final Color textColor = planId == 'lifetime' 
        ? Colors.white 
        : (context.textPrimary);
        
    final Color subColor = planId == 'lifetime' 
        ? Colors.white70 
        : (isDark ? Colors.white70 : const Color(0xFF475569));

    final double activePrice = discountPrice ?? price;
    String billingInterval = 'each interval';
    if (interval == 'week') billingInterval = 'billed weekly';
    if (interval == 'month') billingInterval = 'billed monthly';
    if (interval == 'year') billingInterval = 'billed annually';
    if (interval == 'lifetime') billingInterval = 'one-time pay';

    // Monthly equivalence math
    String? equivalentMonthText;
    if (interval == 'year') {
      final monthlyEq = activePrice / 12;
      equivalentMonthText = '৳${monthlyEq.toStringAsFixed(0)}/month equivalent';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: planId == 'lifetime' 
              ? const Color(0xFFF59E0B) 
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$planName Package',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
              if (discountPrice != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'PROMO OFFER',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (discountPrice != null) ...[
                Text(
                  '৳${price.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: planId == 'lifetime' ? Colors.white60 : Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '৳${activePrice.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                interval == 'lifetime' ? '' : '/$interval',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            billingInterval,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: planId == 'lifetime' ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF0095F6),
            ),
          ),
          if (equivalentMonthText != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white60,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                equivalentMonthText,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: planId == 'lifetime' ? Colors.white : const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ],
      ),
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
    final accentColor = const Color(0xFF0095F6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.border, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _toggleExpand,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.question,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
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
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: SizedBox(
                    width: double.infinity,
                    child: _isExpanded
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              widget.answer,
                              style: GoogleFonts.inter(
                                color: context.textSecondary,
                                fontSize: 12.5,
                                height: 1.45,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
