import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:ui';
import 'feed_screen.dart';
import 'search_explore_screen.dart';
import 'notifications_screen.dart';
import 'profile/profile_screen.dart';
import '../utils/routes.dart';
import 'create_thread_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../state/monetization_controller.dart';
import '../services/presence_service.dart';
import '../services/general_settings_provider.dart';
import 'messenger/messenger_home_screen.dart';
import 'settings/settings_screen.dart';
import 'settings/beta_center_screen.dart';
import 'saved_posts_screen.dart';
import 'communities/community_home_screen.dart';
import '../utils/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  StreamSubscription? _notificationSubscription;
  bool _showBars = true;
  Timer? _scrollStopTimer;

  void _startScrollStopTimer() {
    _scrollStopTimer?.cancel();
    _scrollStopTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_showBars) {
        setState(() {
          _showBars = true;
        });
      }
    });
  }

  void _cancelScrollStopTimer() {
    _scrollStopTimer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        PresenceService().initialize(currentUser.id);
        PresenceService().updatePage('/home');
        Provider.of<MonetizationController>(context, listen: false).fetchMySubscriptions(currentUser.id);
        Provider.of<MonetizationController>(context, listen: false).fetchGlobalStatus();
        Provider.of<GeneralSettingsProvider>(context, listen: false).fetchSettings();
      }
      
      dbService.fetchVerificationPlans();

      _notificationSubscription = dbService.incomingNotificationStream.listen((event) {
        if (mounted) {
          if (event['type'] == 'message') {
            final currentActiveChatId = dbService.currentActiveChatUserId;
            final senderId = event['sender_id'];
            if (currentActiveChatId != null && currentActiveChatId == senderId) {
              return; // Do not show banner, because we are inside this exact chat!
            }
          }
          _showInAppNotificationBanner(event);
          dbService.fetchMyProfile();
        }
      });
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _scrollStopTimer?.cancel();
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _showInAppNotificationBanner(Map<String, dynamic> event) {
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          tween: Tween<double>(begin: -100.0, end: 0.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: Opacity(
                opacity: (1 - (value / -100)).clamp(0.0, 1.0),
                child: child,
              ),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: context.cardBg.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.border.withValues(alpha: 0.4), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.primaryAccent,
                              context.primaryAccent.withValues(alpha: 0.7)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: context.primaryAccent.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        ),
                        child: Icon(
                          event['type'] == 'message' ? Icons.forum_rounded : Icons.notifications_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              event['title'] as String,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: context.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              event['body'] as String,
                              style: GoogleFonts.hindSiliguri(
                                fontSize: 14,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => overlayEntry.remove(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: context.scaffoldBg.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded, size: 16, color: context.textSecondary),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void setTab(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
    
    const pages = ['/home', '/explore', '/messages', '/notifications', '/profile'];
    if (index >= 0 && index < pages.length) {
      PresenceService().updatePage(pages[index]);
    }
  }


  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Help & Support",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        content: Text(
          "Need help? Contact our support team at support@dak.social or check our online documentation.",
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E824C)),
            ),
          ),
        ],
      ),
    );
  }

  void _showModal(BuildContext context, String title, String contentText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    contentText,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: context.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E824C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Accept",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, myProfile, {bool isDesktop = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, top: 24.0, bottom: 20.0, right: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (!isDesktop) Navigator.pop(context);
              setTab(4);
            },
            child: CircleAvatar(
              radius: 32,
              backgroundColor: context.isDarkMode ? Colors.grey[900] : Colors.grey[200],
              backgroundImage: myProfile?.avatarUrl != null && myProfile!.avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(myProfile.avatarUrl!)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (!isDesktop) Navigator.pop(context);
              setTab(4);
            },
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    myProfile?.fullName ?? "Arafath",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                      letterSpacing: -0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (myProfile?.isVerified == true) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified,
                    color: Colors.blue,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "@${myProfile?.username ?? 'arafath306'}",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                color: context.textSecondary,
              ),
              children: [
                TextSpan(
                  text: '${myProfile?.followersCount ?? 0} ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                const TextSpan(text: 'followers  ·  '),
                TextSpan(
                  text: '${myProfile?.followingCount ?? 0} ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                const TextSpan(text: 'following'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    int badgeCount = 0,
  }) {
    return ListTile(
      tileColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      minLeadingWidth: 28,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF1E824C) : context.textPrimary,
            size: 26,
          ),
          if (badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 14,
                  minHeight: 14,
                ),
                child: Text(
                  "$badgeCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? const Color(0xFF1E824C) : context.textPrimary,
          letterSpacing: -0.1,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildFooterLinks(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showModal(
              context,
              "Terms of Service",
              '''Pigeon Terms of Service

Last Updated: June 19, 2026

1. Acceptance of Terms
Welcome to Pigeon, a social platform operated by NGST ("we", "our", "us"). By creating an account, accessing, or using Pigeon, you agree to be bound by these Terms of Service.
If you do not agree with these Terms, you must not use Pigeon.

2. Eligibility
You must be at least 13 years old to use Pigeon.
By using Pigeon, you represent and warrant that:
• You meet the minimum age requirement.
• You are legally capable of entering into these Terms.
• Information you provide is accurate and current.

3. User Accounts
You are responsible for:
• Maintaining account security.
• Protecting your password and authentication credentials.
• All activity that occurs under your account.
NGST may suspend, restrict, or terminate accounts at its sole discretion for security, policy violations, abuse, fraud, or legal compliance.

4. User Content
You retain ownership of content you post on Pigeon.
By posting content, you grant Pigeon a worldwide, non-exclusive, royalty-free license to host, store, reproduce, display, distribute, modify for technical purposes, and make available such content for operation and improvement of the service.

5. Prohibited Activities
Users may not:
• Post illegal content.
• Harass, threaten, or abuse others.
• Impersonate another person or entity.
• Distribute malware or malicious code.
• Engage in fraud, spam, or deceptive practices.
• Violate intellectual property rights.

6. Messaging and Communications
Pigeon may provide private messaging features.
Where End-to-End Encryption is available, message content may be protected from access by Pigeon. However, metadata, abuse reports, and account information may still be processed for security and service operations.

7. Videos and Media Uploads
Users may upload videos, images, audio, and other media subject to platform rules.
Pigeon reserves the right to remove, restrict, demonetize, or limit visibility of any content.

8. Virtual Currency
Pigeon may provide virtual currency and digital items.
Virtual currency:
• Has no cash value.
• Is non-transferable.
• Is non-refundable except where required by law.

9. Premium Features and Verification
Premium subscriptions, verification badges, and enhanced features may be offered.
Pigeon may revoke verification status or premium benefits if eligibility requirements are no longer met.

10. Advertising
Pigeon may display advertisements, sponsored content, and promotional materials.
Users acknowledge that advertising may be integrated into the platform experience.

11. Artificial Intelligence Features
Pigeon may provide AI-powered features.
AI-generated outputs may be inaccurate and should not be relied upon as professional advice.

12. Moderation and Enforcement
Pigeon may:
• Review reported content.
• Remove content.
• Restrict visibility.
• Suspend or terminate accounts.
Enforcement decisions may be made to protect platform integrity, safety, and legal compliance.

13. Termination
Users may stop using Pigeon at any time.
Pigeon may terminate or restrict access without prior notice when necessary.

14. Disclaimer of Warranties
Pigeon is provided "AS IS" and "AS AVAILABLE."
NGST does not guarantee uninterrupted, secure, or error-free operation.

15. Limitation of Liability
To the maximum extent permitted by law, NGST shall not be liable for indirect, incidental, special, consequential, or punitive damages arising from use of Pigeon.

16. Changes to Terms
Pigeon may update these Terms at any time.
Continued use of the service after updates constitutes acceptance of the revised Terms.

17. Contact Information
Operator: NGST

Support Contact:
WhatsApp: +8801313961899''',
            ),
            child: Text(
              "Terms of Service",
              style: GoogleFonts.inter(
                color: const Color(0xFF0085FF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showModal(
              context,
              "Privacy Policy",
              '''Pigeon Privacy Policy

Last Updated: June 19, 2026

1. Introduction
This Privacy Policy explains how Pigeon, operated by NGST, collects, uses, stores, and protects information.

2. Information We Collect
Account Information:
• Name
• Username
• Email address (if provided)
• Phone number (if provided)
• Profile information

Content Information:
• Posts
• Comments
• Messages
• Photos
• Videos
• Audio uploads

Device Information:
• Device model
• Operating system
• App version
• IP address
• Device identifiers

Usage Information:
• Likes
• Shares
• Follows
• Searches
• Interactions with content

Payment Information:
For premium services and virtual currency purchases, payment-related information may be processed through authorized payment providers.

3. How We Use Information
We use information to:
• Operate the platform.
• Provide features and services.
• Improve user experience.
• Detect abuse and fraud.
• Enforce policies.
• Provide customer support.
• Deliver advertisements and recommendations.

4. AI Features
Content submitted to AI-powered features may be processed to generate responses, improve services, and maintain safety.

5. Advertising
Pigeon may use information to:
• Personalize advertisements.
• Measure advertising effectiveness.
• Improve promotional systems.

6. Content Storage
Content uploaded by users may be stored on servers operated by or on behalf of NGST.

7. Security
We implement reasonable technical and organizational measures to protect information.
No security system is guaranteed to be completely secure.

8. Children's Privacy
Pigeon is not intended for children under 13.

9. User Rights
Depending on applicable law, users may have rights to:
• Access data.
• Correct data.
• Delete data.
• Request copies of data.

10. Data Retention
Information may be retained for operational, legal, security, and compliance purposes.

11. International Processing
Information may be processed and stored in different jurisdictions where service providers operate.

12. Changes to This Policy
We may update this Privacy Policy periodically.

13. Contact
Operator: NGST

Support Contact:
WhatsApp: +8801313961899''',
            ),
            child: Text(
              "Privacy Policy",
              style: GoogleFonts.inter(
                color: const Color(0xFF0085FF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButtons(BuildContext context, {bool isDesktop = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (!isDesktop) Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BetaCenterScreen()),
                );
              },
              icon: Icon(Icons.bug_report_outlined, size: 16, color: context.textPrimary),
              label: Text(
                "Beta Center",
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.isDarkMode ? const Color(0xFF121422) : const Color(0xFFF3F4F6),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: const StadiumBorder(),
                shadowColor: Colors.transparent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showHelpDialog(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.border, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: const StadiumBorder(),
              ),
              child: Text(
                "Help",
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(int tabIndex, IconData activeIcon, IconData inactiveIcon, {int badgeCount = 0}) {
    final bool isSelected = _currentIndex == tabIndex;
    final Color accentColor = context.greenAccent;

    final String label = const {
      0: 'Home Tab',
      1: 'Search and Explore Tab',
      2: 'Messages Tab',
      3: 'Notifications Tab',
      4: 'Profile Tab',
    }[tabIndex] ?? 'Tab';

    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: () {
            setTab(tabIndex);
          },
          behavior: HitTestBehavior.opaque,
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? accentColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AnimatedScale(
                      scale: isSelected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      child: Icon(
                        isSelected ? activeIcon : inactiveIcon,
                        color: isSelected ? accentColor : context.textPrimary.withValues(alpha: 0.75),
                        size: 24,
                      ),
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        "$badgeCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildNavigationSidebar(BuildContext context, DatabaseService dbService, {required bool isDesktop}) {
    final myProfile = dbService.myProfile;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(context, myProfile, isDesktop: isDesktop),
                  _buildDrawerItem(
                    icon: CupertinoIcons.search,
                    title: "Explore",
                    isActive: _currentIndex == 1,
                    onTap: () {
                      if (!isDesktop) Navigator.pop(context);
                      setTab(1);
                    },
                  ),
                  _buildDrawerItem(
                    icon: _currentIndex == 0 ? CupertinoIcons.house_fill : CupertinoIcons.house,
                    title: "Home",
                    isActive: _currentIndex == 0,
                    onTap: () {
                      if (!isDesktop) Navigator.pop(context);
                      setTab(0);
                    },
                  ),
                  _buildDrawerItem(
                    icon: _currentIndex == 2 ? CupertinoIcons.ellipses_bubble_fill : CupertinoIcons.ellipses_bubble,
                    title: "Chat",
                    isActive: _currentIndex == 2,
                    badgeCount: dbService.unreadMessagesCount,
                    onTap: () {
                      if (!isDesktop) Navigator.pop(context);
                      setTab(2);
                    },
                  ),
                  _buildDrawerItem(
                    icon: _currentIndex == 3 ? CupertinoIcons.bell_fill : CupertinoIcons.bell,
                    title: "Notifications",
                    isActive: _currentIndex == 3,
                    badgeCount: dbService.unreadNotificationsCount,
                    onTap: () {
                      if (!isDesktop) Navigator.pop(context);
                      setTab(3);
                    },
                  ),
                  _buildDrawerItem(
                    icon: CupertinoIcons.tag,
                    title: "Feeds",
                    isActive: false,
                    onTap: () {
                      if (!isDesktop) Navigator.pop(context);
                      setTab(0);
                    },
                  ),
                  _buildDrawerItem(
                    icon: CupertinoIcons.person_3_fill,
                    title: "Community",
                    isActive: false,
                    onTap: () {
                      if (!isDesktop) Navigator.pop(context);
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(
                          child: const CommunityHomeScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: CupertinoIcons.bookmark,
                    title: "Saved",
                    isActive: false,
                    onTap: () {
                      if (!isDesktop) Navigator.pop(context);
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(child: const SavedPostsScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: _currentIndex == 4 ? CupertinoIcons.person_fill : CupertinoIcons.person,
                    title: "Profile",
                    isActive: _currentIndex == 4,
                    onTap: () {
                      if (!isDesktop) Navigator.pop(context);
                      setTab(4);
                    },
                  ),
                  _buildDrawerItem(
                    icon: CupertinoIcons.settings,
                    title: "Settings",
                    isActive: false,
                    onTap: () {
                      if (!isDesktop) Navigator.pop(context);
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(
                          child: SettingsScreen(
                            onSwitchToProfile: () => setTab(4),
                          ),
                        ),
                      );
                    },
                  ),
                  if (isDesktop)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateThreadScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E824C),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: Text(
                            "Post",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: context.border),
          _buildFooterLinks(context),
          _buildFooterButtons(context, isDesktop: isDesktop),
        ],
      ),
    );
  }

  Widget _buildRightSidebar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.isDarkMode ? const Color(0xFF111827) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.border.withValues(alpha: 0.5), width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.search, size: 20, color: context.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setTab(1), // Go to search screen
                      child: Text(
                        "Search Pigeon...",
                        style: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Trending Topics",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Expanded(child: TrendingTopicsListDesktop()),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    final List<Widget> screens = [
      FeedScreen(
        onNavigateToChaStation: () => setTab(2),
        onNavigateToCreate: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateThreadScreen()),
          );
        },
      ),
      const SearchExploreScreen(),
      const MessengerHomeScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    Widget mainBody = SafeArea(
      bottom: false,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification) {
            if (notification.metrics.axis == Axis.vertical) {
              final double scrollDelta = notification.scrollDelta ?? 0;
              if (scrollDelta > 2.0) {
                if (_showBars) setState(() { _showBars = false; });
                _startScrollStopTimer();
              } else if (scrollDelta < -2.0) {
                if (!_showBars) setState(() { _showBars = true; });
                _cancelScrollStopTimer();
              }
              if (notification.metrics.pixels <= 0) {
                if (!_showBars) setState(() { _showBars = true; });
                _cancelScrollStopTimer();
              }
            }
          } else if (notification is ScrollEndNotification) {
            if (!_showBars) _startScrollStopTimer();
          }
          return false;
        },
        child: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            if (index != _currentIndex) {
              setState(() {
                _currentIndex = index;
                _showBars = true;
              });
            }
          },
          children: screens,
        ),
      ),
    );

    if (isDesktop) {
      return Scaffold(
        key: scaffoldKey,
        backgroundColor: context.scaffoldBg,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Sidebar
            Container(
              width: 280,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: context.border, width: 0.5)),
              ),
              child: Consumer<DatabaseService>(
                builder: (context, dbService, _) {
                  return _buildNavigationSidebar(context, dbService, isDesktop: true);
                },
              ),
            ),
            
            // Center Feed
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: mainBody,
                ),
              ),
            ),

            // Right Sidebar
            Container(
              width: 320,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: context.border, width: 0.5)),
              ),
              child: _buildRightSidebar(context),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: context.scaffoldBg,
      extendBody: true,
      drawer: Drawer(
        backgroundColor: context.scaffoldBg,
        child: Consumer<DatabaseService>(
          builder: (context, dbService, _) {
            return _buildNavigationSidebar(context, dbService, isDesktop: false);
          },
        ),
      ),
      body: mainBody,
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 4)
          ? AnimatedScale(
              scale: _showBars ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutBack,
              child: ScaleTransition(
                scale: TweenSequence<double>([
                  TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 25),
                  TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.12), weight: 45),
                  TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 30),
                ]).animate(_fabAnimationController),
                child: FloatingActionButton(
                  heroTag: 'main_fab',
                  tooltip: 'Create post',
                  backgroundColor: const Color(0xFF1E824C),
                  shape: const CircleBorder(),
                  elevation: 3,
                  mini: false,
                  onPressed: () {
                    _fabAnimationController.forward(from: 0.0);
                    Future.delayed(const Duration(milliseconds: 180), () {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateThreadScreen()),
                        );
                      }
                    });
                  },
                  child: const Icon(CupertinoIcons.create, color: Colors.white, size: 24),
                ),
              ),
            )
          : null,
      bottomNavigationBar: AnimatedSlide(
        offset: _showBars ? Offset.zero : const Offset(0, 1.3),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: Consumer<DatabaseService>(
          builder: (context, dbService, _) {
            final double bottomPadding = MediaQuery.of(context).padding.bottom;
            return ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                child: Container(
                  height: 58 + bottomPadding,
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? Colors.black.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.85),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: context.isDarkMode
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.black.withValues(alpha: 0.08),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        _buildBottomNavItem(0, CupertinoIcons.house_fill, CupertinoIcons.house),
                        _buildBottomNavItem(1, CupertinoIcons.search, CupertinoIcons.search),
                        _buildBottomNavItem(
                          2, 
                          CupertinoIcons.ellipses_bubble_fill, 
                          CupertinoIcons.ellipses_bubble,
                          badgeCount: dbService.unreadMessagesCount,
                        ),
                        _buildBottomNavItem(
                          3, 
                          CupertinoIcons.bell_fill, 
                          CupertinoIcons.bell,
                          badgeCount: dbService.unreadNotificationsCount,
                        ),
                        _buildBottomNavItem(4, CupertinoIcons.person_fill, CupertinoIcons.person),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TrendingTopicsListDesktop extends StatefulWidget {
  const TrendingTopicsListDesktop({super.key});
  @override
  State<TrendingTopicsListDesktop> createState() => _TrendingTopicsListDesktopState();
}

class _TrendingTopicsListDesktopState extends State<TrendingTopicsListDesktop> {
  List<String> _topics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final trending = await dbService.fetchTrendingTopics();
    if (mounted) {
      setState(() {
        _topics = trending.map((t) => t['topic_name'] as String).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_topics.isEmpty) {
      return Text("No trending topics yet.", style: GoogleFonts.inter(color: context.textSecondary));
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _topics.length > 8 ? 8 : _topics.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final topic = _topics[index];
        final displayTopic = topic.startsWith('#') ? topic : '#$topic';
        return GestureDetector(
          onTap: () {
            context.findAncestorStateOfType<MainScreenState>()?.setTab(1);
          },
          child: Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, size: 16, color: Color(0xFF1E824C)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  displayTopic,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
