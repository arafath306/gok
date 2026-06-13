import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/general_settings_provider.dart';
import '../messenger/chat_settings_screen.dart';
import 'blocked_accounts_screen.dart';
import 'muted_accounts_screen.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

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
          'Privacy Settings',
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
      body: Consumer<GeneralSettingsProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildSectionHeader('Account Privacy'),
              _buildSwitchTile(
                title: 'Private Account',
                subtitle: 'Only approved followers can see your posts and media.',
                value: provider.isPrivateAccount,
                onChanged: (val) {
                  provider.updatePrivacy(isPrivateAccount: val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val ? 'Account set to Private' : 'Account set to Public'),
                      backgroundColor: const Color(0xFF1E824C),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Interactions'),
              _buildSelectionTile(
                context,
                title: 'Who can mention you',
                subtitle: provider.allowMentionsFrom == 'everyone'
                    ? 'Everyone'
                    : provider.allowMentionsFrom == 'people_you_follow'
                        ? 'People you follow'
                        : 'No one',
                onTap: () => _showMentionOptions(context, provider),
              ),
              _buildNavigationTile(
                title: 'Direct Messages',
                subtitle: 'Control who can send you direct messages',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatSettingsScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Content Filters'),
              _buildSwitchTile(
                title: 'Filter Adult Content',
                subtitle: 'Hide potentially sensitive content and media from searches and feeds.',
                value: provider.filterAdultContent,
                onChanged: (val) {
                  provider.updatePrivacy(filterAdultContent: val);
                },
              ),
              _buildSwitchTile(
                title: 'Autoplay Videos',
                subtitle: 'Automatically play videos when browsing feeds.',
                value: provider.autoplayVideos,
                onChanged: (val) {
                  provider.updatePrivacy(autoplayVideos: val);
                },
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Safety Lists'),
              _buildNavigationTile(
                title: 'Blocked Accounts',
                subtitle: 'Manage accounts you have blocked',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BlockedAccountsScreen()),
                  );
                },
              ),
              _buildNavigationTile(
                title: 'Muted Accounts',
                subtitle: 'Manage accounts you have muted',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MutedAccountsScreen()),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black45,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1E824C),
            activeTrackColor: const Color(0x331E824C),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.black12,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            color: Colors.black45,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSelectionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            color: const Color(0xFF1E824C),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
        onTap: onTap,
      ),
    );
  }

  void _showMentionOptions(BuildContext context, GeneralSettingsProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
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
                    'Who can mention you',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRadioOption(ctx, provider, 'everyone', 'Everyone'),
                  _buildRadioOption(ctx, provider, 'people_you_follow', 'People you follow'),
                  _buildRadioOption(ctx, provider, 'no_one', 'No one'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRadioOption(BuildContext context, GeneralSettingsProvider provider, String value, String label) {
    final isSelected = provider.allowMentionsFrom == value;
    return InkWell(
      onTap: () {
        provider.updatePrivacy(allowMentionsFrom: value);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF1E824C), size: 20)
            else
              const Icon(Icons.circle_outlined, color: Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}
