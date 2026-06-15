import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/general_settings_provider.dart';
import '../../utils/app_theme.dart';
import '../messenger/chat_settings_screen.dart';
import 'blocked_accounts_screen.dart';
import 'muted_accounts_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GeneralSettingsProvider>(context, listen: false).fetchSettings();
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
          'Privacy Settings',
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
      body: Consumer<GeneralSettingsProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildSectionHeader(context, 'Account Privacy'),
              _buildSwitchTile(
                context,
                title: 'Private Account',
                subtitle: 'Only approved followers can see your posts and media.',
                value: provider.isPrivateAccount,
                onChanged: (val) {
                  provider.updatePrivacy(isPrivateAccount: val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val ? 'Account set to Private' : 'Account set to Public'),
                      backgroundColor: context.primaryAccent,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSectionHeader(context, 'Interactions'),
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
                context,
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
              _buildSectionHeader(context, 'Content Filters'),
              _buildSwitchTile(
                context,
                title: 'Filter Adult Content',
                subtitle: 'Hide potentially sensitive content and media from searches and feeds.',
                value: provider.filterAdultContent,
                onChanged: (val) {
                  provider.updatePrivacy(filterAdultContent: val);
                },
              ),
              _buildSwitchTile(
                context,
                title: 'Autoplay Videos',
                subtitle: 'Automatically play videos when browsing feeds.',
                value: provider.autoplayVideos,
                onChanged: (val) {
                  provider.updatePrivacy(autoplayVideos: val);
                },
              ),
              const SizedBox(height: 16),
              _buildSectionHeader(context, 'Safety Lists'),
              _buildNavigationTile(
                context,
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
                context,
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: context.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: context.cardBg,
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
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: context.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: context.primaryAccent,
            inactiveTrackColor: context.isDarkMode ? Colors.grey[800] : Colors.black12,
            inactiveThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      color: context.cardBg,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: context.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: context.textMuted,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: context.textMuted, size: 20),
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
      color: context.cardBg,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: context.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: context.primaryAccent,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: context.textMuted, size: 20),
        onTap: onTap,
      ),
    );
  }

  void _showMentionOptions(BuildContext context, GeneralSettingsProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
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
                        color: context.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Who can mention you',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRadioOption(context, provider, 'everyone', 'Everyone'),
                  _buildRadioOption(context, provider, 'people_you_follow', 'People you follow'),
                  _buildRadioOption(context, provider, 'no_one', 'No one'),
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
              style: GoogleFonts.inter(
                fontSize: 15,
                color: context.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: context.primaryAccent, size: 20)
            else
              Icon(Icons.circle_outlined, color: context.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
