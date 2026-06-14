import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _faqs = [
    {
      'question': 'What is Dak?',
      'answer': 'Dak is a next-generation decentralized social network built to prioritize user privacy, modern real-time interactions, and premium aesthetics. It is designed to offer a smoother, more secure experience than platforms like Twitter and Bluesky.'
    },
    {
      'question': 'How do I control who can send me Direct Messages?',
      'answer': 'Navigate to your Chats list page and tap the Gear icon in the top-right corner. There you can set your direct message permissions to "Everyone", "Users I follow", or "No one".'
    },
    {
      'question': 'What are Follow Requests?',
      'answer': 'When someone whose DM setting is restricted attempts to chat with you, you will see a "Follow Request" button. Once sent, the recipient receives a notification to approve or deny the request before you can chat.'
    },
    {
      'question': 'How do I activate Two-Factor Authentication (2FA)?',
      'answer': 'Go to Settings -> Security and toggle on the "Two-Factor Authentication" option. This adds an extra layer of security to prevent unauthorized access.'
    },
    {
      'question': 'Can I audit my active login sessions?',
      'answer': 'Yes. Under Settings -> Security, you will see a list of "Active Sessions" showing devices and locations where you are logged in. You can instantly log out or revoke access to any other device by tapping the "Revoke" button.'
    },
    {
      'question': 'How do I report spam or abusive accounts?',
      'answer': 'You can block or mute any account by visiting Settings -> Blocked Accounts or Settings -> Muted Accounts and entering their display name or username.'
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((faq) {
      final q = faq['question']!.toLowerCase();
      final a = faq['answer']!.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return q.contains(query) || a.contains(query);
    }).toList();

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
          'Help Center',
          style: GoogleFonts.outfit(
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
      body: Column(
        children: [
          // Header search banner
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border(bottom: BorderSide(color: context.border)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help you?',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, color: context.textMuted, size: 20),
                    hintText: 'Search articles, questions...',
                    hintStyle: GoogleFonts.outfit(color: context.textMuted, fontSize: 14),
                    filled: true,
                    fillColor: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 18, color: context.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  style: GoogleFonts.outfit(fontSize: 14, color: context.textPrimary),
                ),
              ],
            ),
          ),

          // FAQ list
          Expanded(
            child: filteredFaqs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.help_center_outlined, size: 60, color: context.textMuted),
                          const SizedBox(height: 16),
                          Text(
                            'No articles match your search',
                            style: GoogleFonts.outfit(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try different keywords or view all questions.',
                            style: GoogleFonts.outfit(color: context.textMuted, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = filteredFaqs[index];
                      return Container(
                        color: context.cardBg,
                        margin: const EdgeInsets.only(bottom: 2),
                        child: ExpansionTile(
                          iconColor: context.primaryAccent,
                          collapsedIconColor: context.textMuted,
                          title: Text(
                            faq['question']!,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                              color: context.textPrimary,
                            ),
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          expandedAlignment: Alignment.topLeft,
                          children: [
                            Text(
                              faq['answer']!,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                color: context.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Contact support footer
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border(top: BorderSide(color: context.border)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Still need help?',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                      Text(
                        'Get in touch with support directly.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showContactForm(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Contact Us',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContactForm(BuildContext context) {
    final emailCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Contact Support',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We will get back to you within 24 hours.',
              style: GoogleFonts.outfit(color: context.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(
                hintText: 'Your email address...',
                hintStyle: GoogleFonts.outfit(color: context.textMuted, fontSize: 14),
                filled: true,
                fillColor: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: GoogleFonts.outfit(fontSize: 14, color: context.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe your issue...',
                hintStyle: GoogleFonts.outfit(color: context.textMuted, fontSize: 14),
                filled: true,
                fillColor: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: GoogleFonts.outfit(fontSize: 14, color: context.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailCtrl.text.trim().isEmpty || messageCtrl.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Support ticket submitted successfully!'),
                  backgroundColor: context.primaryAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Submit',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
