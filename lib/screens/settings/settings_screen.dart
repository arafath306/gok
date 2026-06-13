import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/routes.dart';
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
          'Settings',
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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        children: [
          // --- Profile Header Card ---
          GestureDetector(
            onTap: () {
              final profileMap = myProfile?.toJson() ?? {
                'full_name': 'Arafath',
                'username': 'arafath306',
                'bio': 'Social developer',
              };
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profileMap)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[100],
                    backgroundImage: myProfile?.avatarUrl != null && myProfile!.avatarUrl!.isNotEmpty
                        ? NetworkImage(myProfile.avatarUrl!)
                        : const NetworkImage('https://i.pravatar.cc/150?u=current_user'),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          myProfile?.fullName ?? 'User',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${myProfile?.username ?? 'username'}',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black26, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- Account Group ---
          _buildSectionHeader('Account'),
          _buildSettingsGroup([
            _SettingsTileItem(
              icon: Icons.person_outline_rounded,
              title: 'Edit Profile',
              onTap: () {
                final profileMap = myProfile?.toJson() ?? {
                  'full_name': 'Arafath',
                  'username': 'arafath306',
                  'bio': 'Social developer',
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

          // --- Content & Activity Group ---
          _buildSectionHeader('Content & Activity'),
          _buildSettingsGroup([
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
          _buildSectionHeader('Support'),
          _buildSettingsGroup([
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDEDEC)),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Log Out',
                    style: GoogleFonts.outfit(
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: Colors.black45,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<_SettingsTileItem> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (context, index) {
          final tile = tiles[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: Icon(tile.icon, color: Colors.black87, size: 22),
            title: Text(
              tile.title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontSize: 14.5,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.black26, size: 18),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Log Out',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: GoogleFonts.outfit(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.black54),
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
              style: GoogleFonts.outfit(
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
