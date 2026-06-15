import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/general_settings_provider.dart';
import '../../utils/routes.dart';
import '../../utils/app_theme.dart';
import '../profile/edit_profile_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'security_settings_screen.dart';
import 'saved_threads_screen.dart';
import 'blocked_accounts_screen.dart';
import 'muted_accounts_screen.dart';
import 'help_center_screen.dart';
import 'about_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final myProfile = dbService.myProfile;

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
          'Settings',
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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          // --- Profile Header Card ---
          GestureDetector(
            onTap: () {
              final profileMap = myProfile?.toJson() ?? {
                'full_name': '',
                'username': '',
                'bio': '',
              };
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profileMap)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: context.isDarkMode ? Colors.grey[900] : Colors.grey[100],
                    backgroundImage: myProfile?.avatarUrl != null && myProfile!.avatarUrl!.isNotEmpty
                        ? NetworkImage(myProfile.avatarUrl!)
                        : null,
                    child: (myProfile?.avatarUrl == null || myProfile!.avatarUrl!.isEmpty)
                        ? Icon(Icons.person, color: context.textPrimary)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          myProfile?.fullName ?? 'User',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          myProfile?.username != null ? '@${myProfile!.username}' : '',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: context.textMuted, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Account Group ---
          _buildSectionHeader(context, 'Account'),
          _buildSettingsGroup(context, [
            _SettingsTileItem(
              icon: Icons.person_outline_rounded,
              title: 'Edit Profile',
              onTap: () {
                final profileMap = myProfile?.toJson() ?? {
                  'full_name': '',
                  'username': '',
                  'bio': '',
                };
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profileMap)),
                );
              },
            ),
            _SettingsTileItem(
              icon: Icons.lock_outline_rounded,
              title: 'Privacy',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                );
              },
            ),
            _SettingsTileItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {
                Navigator.push(
                  context,
                  NoTransitionPageRoute(child: const NotificationSettingsScreen()),
                );
              },
            ),
            _SettingsTileItem(
              icon: Icons.security_rounded,
              title: 'Security',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 20),

          // --- Theme / Display Section ---
          _buildSectionHeader(context, 'Display & Theme'),
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border),
            ),
            child: Consumer<GeneralSettingsProvider>(
              builder: (context, settingsProvider, _) {
                return SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  secondary: Icon(
                    settingsProvider.isDarkTheme ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: context.textPrimary,
                    size: 22,
                  ),
                  title: Text(
                    'Dark Theme',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      color: context.textPrimary,
                      fontSize: 14.5,
                    ),
                  ),
                  activeThumbColor: context.primaryAccent,
                  activeTrackColor: context.primaryAccent.withOpacity(0.38),
                  value: settingsProvider.isDarkTheme,
                  onChanged: (val) {
                    settingsProvider.toggleTheme(val);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // --- Content & Activity Group ---
          _buildSectionHeader(context, 'Content & Activity'),
          _buildSettingsGroup(context, [
            _SettingsTileItem(
              icon: Icons.bookmark_border_rounded,
              title: 'Saved Posts',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedThreadsScreen()),
                );
              },
            ),
            _SettingsTileItem(
              icon: Icons.block_rounded,
              title: 'Blocked Accounts',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlockedAccountsScreen()),
                );
              },
            ),
            _SettingsTileItem(
              icon: Icons.volume_off_rounded,
              title: 'Muted Accounts',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MutedAccountsScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 20),

          // --- Support Group ---
          _buildSectionHeader(context, 'Support'),
          _buildSettingsGroup(context, [
            _SettingsTileItem(
              icon: Icons.help_outline_rounded,
              title: 'Help Center',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                );
              },
            ),
            _SettingsTileItem(
              icon: Icons.info_outline_rounded,
              title: 'About Dak',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutSettingsScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),

          // --- Logout ---
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.isDarkMode
                      ? const Color(0x33EF4444)
                      : const Color(0xFFFDEDEC),
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Log Out',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: context.textSecondary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<_SettingsTileItem> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tiles.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
        itemBuilder: (context, index) {
          final tile = tiles[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: Icon(tile.icon, color: context.textPrimary, size: 22),
            title: Text(
              tile.title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: context.textPrimary,
                fontSize: 14.5,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: context.textMuted, size: 18),
            onTap: tile.onTap,
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Out',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthService>(context, listen: false).handleSignout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Log Out',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTileItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTileItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
