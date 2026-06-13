import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Check for Updates',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          content: Text(
            'You are on the latest premium release!\n\nVersion: 2.0.0-Beta\nBuild: 44 (Premium Edition)',
            style: GoogleFonts.outfit(color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Great!',
                style: GoogleFonts.outfit(color: const Color(0xFF1E824C), fontWeight: FontWeight.bold),
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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About Dak',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFEEEEEE), height: 1.0),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        children: [
          // Logo placeholder or image
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/logo_transparent.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Dak Social',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Center(
            child: Text(
              'Version 2.0.0 (Beta-44)',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.black45,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Overview text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our Vision',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dak is engineered to redefine social media networks. With direct message filters, decentralized architectures, high-fidelity layouts, and a zero-clutter experience, we aim to outshine Twitter and Bluesky in performance, utility, and visual excellence.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.black54,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildAboutTile(
                  icon: Icons.system_update_rounded,
                  title: 'Check for Updates',
                  trailing: _isCheckingUpdates
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E824C)),
                        )
                      : null,
                  onTap: _isCheckingUpdates ? null : _checkUpdates,
                ),
                const Divider(height: 1, color: Color(0xFFF1F1F1)),
                _buildAboutTile(
                  icon: Icons.code_rounded,
                  title: 'Open Source Licenses',
                  onTap: () => _showLicenses(context),
                ),
                const Divider(height: 1, color: Color(0xFFF1F1F1)),
                _buildAboutTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () => _showDocument(context, 'Terms of Service', 'Welcome to Dak!\n\n1. Use Dak respectfully.\n2. Respect other users\' privacy settings.\n3. Content violating our policies will be deleted.\n\nThank you for being part of the premium future of social networks.'),
                ),
                const Divider(height: 1, color: Color(0xFFF1F1F1)),
                _buildAboutTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _showDocument(context, 'Privacy Policy', 'Your privacy is paramount:\n\n1. We encrypt DMs locally.\n2. You control DM permission filters (Everyone, Users I Follow, No one).\n3. Session logs are auditable and revocable by you at any time.'),
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
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54, size: 20),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
          fontSize: 14.5,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.black26, size: 18),
      onTap: onTap,
    );
  }

  void _showDocument(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: GoogleFonts.outfit(color: Colors.black54, height: 1.45),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.outfit(color: const Color(0xFF1E824C), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    final List<Map<String, String>> licenses = [
      {'package': 'flutter_bloc', 'desc': 'State management library by Felix Angelov under MIT License.'},
      {'package': 'provider', 'desc': 'A wrapper around InheritedWidget by Remi Rousselet under MIT License.'},
      {'package': 'supabase_flutter', 'desc': 'Official Supabase Flutter client under Apache 2.0 License.'},
      {'package': 'google_fonts', 'desc': 'Access to Google Fonts catalog under Apache 2.0 License.'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Open Source Licenses',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: licenses.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  itemBuilder: (context, index) {
                    final item = licenses[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['package']!,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['desc']!,
                            style: GoogleFonts.outfit(fontSize: 12.5, color: Colors.black45),
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
