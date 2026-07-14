import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../widgets/dak_logo.dart';

class AboutSettingsScreen extends StatefulWidget {
  const AboutSettingsScreen({super.key});

  @override
  State<AboutSettingsScreen> createState() => _AboutSettingsScreenState();
}

class _AboutSettingsScreenState extends State<AboutSettingsScreen> {
  bool _isCheckingUpdates = false;

  void _checkUpdates() {
    setState(() {
      _isCheckingUpdates = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isCheckingUpdates = false;
      });
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Check for Updates',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          content: Text(
            'You are on the latest release!\n\nVersion: 4.2.0\nBuild: 42',
            style: GoogleFonts.inter(color: context.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Great!',
                style: GoogleFonts.inter(
                  color: context.primaryAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About Pigeon',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: context.border, height: 1.0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        children: [
          // Logo
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
                border: Border.all(color: context.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 
                      context.isDarkMode ? 0.2 : 0.04,
                    ),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: DakLogo(
                  size: context.isDarkMode ? 62 : 58,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Pigeon Social',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ),
          Center(
            child: Text(
              'Version 4.2.0 (Build 42)',
              style: GoogleFonts.inter(fontSize: 13, color: context.textMuted),
            ),
          ),
          const SizedBox(height: 24),

          // Overview text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our Vision',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pigeon is engineered to redefine social media networks. With direct message filters, decentralized architectures, high-fidelity layouts, and a zero-clutter experience, we aim to outshine Twitter and Bluesky in performance, utility, and visual excellence.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: context.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About options
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border),
            ),
            child: Column(
              children: [
                _buildAboutTile(
                  context: context,
                  icon: Icons.system_update_rounded,
                  title: 'Check for Updates',
                  trailing: _isCheckingUpdates
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.primaryAccent,
                          ),
                        )
                      : null,
                  onTap: _isCheckingUpdates ? null : _checkUpdates,
                ),
                Divider(height: 1, color: context.border),
                _buildAboutTile(
                  context: context,
                  icon: Icons.code_rounded,
                  title: 'Open Source Licenses',
                  onTap: () => _showLicenses(context),
                ),
                Divider(height: 1, color: context.border),
                _buildAboutTile(
                  context: context,
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () => _showDocument(
                    context,
                    'Terms of Service',
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
                ),
                Divider(height: 1, color: context.border),
                _buildAboutTile(
                  context: context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _showDocument(
                    context,
                    'Privacy Policy',
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAboutTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: context.textSecondary, size: 20),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: context.textPrimary,
          fontSize: 14.5,
        ),
      ),
      trailing:
          trailing ??
          Icon(Icons.chevron_right, color: context.textMuted, size: 18),
      onTap: onTap,
    );
  }

  void _showDocument(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: GoogleFonts.inter(
              color: context.textSecondary,
              height: 1.45,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.inter(
                color: context.primaryAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    final List<Map<String, String>> licenses = [
      {
        'package': 'audioplayers',
        'desc': 'Audio playback library by luan.dev under MIT License.',
      },
      {
        'package': 'provider',
        'desc':
            'A wrapper around InheritedWidget by Remi Rousselet under MIT License.',
      },
      {
        'package': 'supabase_flutter',
        'desc': 'Official Supabase Flutter client under Apache 2.0 License.',
      },
      {
        'package': 'google_fonts',
        'desc': 'Access to Google Fonts catalog under Apache 2.0 License.',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Open Source Licenses',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: licenses.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: context.border),
                  itemBuilder: (context, index) {
                    final item = licenses[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['package']!,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['desc']!,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: context.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
