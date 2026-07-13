import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/profile.dart';
import '../../utils/app_theme.dart';
import '../../utils/routes.dart';
import '../../screens/create_thread_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/beta_center_screen.dart';
import '../../screens/saved_posts_screen.dart';
import '../../screens/communities/community_home_screen.dart';

/// Full drawer / desktop left-sidebar navigation panel.
///
/// Works both as a mobile [Drawer] child (set [isDesktop] = false) and as
/// a persistent desktop sidebar (set [isDesktop] = true).
/// All tab switches are delegated to [onTabChanged]; internal navigation
/// (push to Settings, Community, etc.) is handled inside this widget.
class MainDrawer extends StatelessWidget {
  final int currentIndex;
  final Profile? myProfile;
  final bool isDesktop;
  final int unreadMessagesCount;
  final int unreadNotificationsCount;
  final void Function(int) onTabChanged;

  const MainDrawer({
    super.key,
    required this.currentIndex,
    required this.myProfile,
    required this.isDesktop,
    required this.unreadMessagesCount,
    required this.unreadNotificationsCount,
    required this.onTabChanged,
  });

  // ── Private helpers ──────────────────────────────────────────────────────

  void _closeIfMobile(BuildContext context) {
    if (!isDesktop) Navigator.pop(context);
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
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, color: const Color(0xFF1E824C)),
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
                        borderRadius: BorderRadius.circular(12)),
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

  // ── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, top: 24.0, bottom: 20.0, right: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              _closeIfMobile(context);
              onTabChanged(4);
            },
            child: CircleAvatar(
              radius: 32,
              backgroundColor: context.isDarkMode ? Colors.grey[900] : Colors.grey[200],
              backgroundImage: myProfile?.avatarUrl != null &&
                      myProfile!.avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(myProfile!.avatarUrl!)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              _closeIfMobile(context);
              onTabChanged(4);
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
                  const Icon(Icons.verified, color: Colors.blue, size: 16),
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "@${myProfile?.username ?? 'arafath306'}",
            style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary),
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

  Widget _buildDrawerItem(
    BuildContext context, {
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
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
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

  Widget _buildFooterButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _closeIfMobile(context);
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
                backgroundColor: context.isDarkMode
                    ? const Color(0xFF121422)
                    : const Color(0xFFF3F4F6),
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

  // ── Main build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
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
                  _buildProfileHeader(context),
                  _buildDrawerItem(
                    context,
                    icon: CupertinoIcons.search,
                    title: "Explore",
                    isActive: currentIndex == 1,
                    onTap: () {
                      _closeIfMobile(context);
                      onTabChanged(1);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: currentIndex == 0
                        ? CupertinoIcons.house_fill
                        : CupertinoIcons.house,
                    title: "Home",
                    isActive: currentIndex == 0,
                    onTap: () {
                      _closeIfMobile(context);
                      onTabChanged(0);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: currentIndex == 2
                        ? CupertinoIcons.ellipses_bubble_fill
                        : CupertinoIcons.ellipses_bubble,
                    title: "Chat",
                    isActive: currentIndex == 2,
                    badgeCount: unreadMessagesCount,
                    onTap: () {
                      _closeIfMobile(context);
                      onTabChanged(2);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: currentIndex == 3
                        ? CupertinoIcons.bell_fill
                        : CupertinoIcons.bell,
                    title: "Notifications",
                    isActive: currentIndex == 3,
                    badgeCount: unreadNotificationsCount,
                    onTap: () {
                      _closeIfMobile(context);
                      onTabChanged(3);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: CupertinoIcons.tag,
                    title: "Feeds",
                    isActive: false,
                    onTap: () {
                      _closeIfMobile(context);
                      onTabChanged(0);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: CupertinoIcons.person_3_fill,
                    title: "Community",
                    isActive: false,
                    onTap: () {
                      _closeIfMobile(context);
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(child: const CommunityHomeScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: CupertinoIcons.bookmark,
                    title: "Saved",
                    isActive: false,
                    onTap: () {
                      _closeIfMobile(context);
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(child: const SavedPostsScreen()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: currentIndex == 4
                        ? CupertinoIcons.person_fill
                        : CupertinoIcons.person,
                    title: "Profile",
                    isActive: currentIndex == 4,
                    onTap: () {
                      _closeIfMobile(context);
                      onTabChanged(4);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: CupertinoIcons.settings,
                    title: "Settings",
                    isActive: false,
                    onTap: () {
                      _closeIfMobile(context);
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(
                          child: SettingsScreen(
                            onSwitchToProfile: () => onTabChanged(4),
                          ),
                        ),
                      );
                    },
                  ),
                  if (isDesktop)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 24.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CreateThreadScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E824C),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
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
          _buildFooterButtons(context),
        ],
      ),
    );
  }
}
