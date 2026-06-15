import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/chat_settings_provider.dart';
import '../../utils/app_theme.dart';

class ChatSettingsScreen extends StatelessWidget {
  const ChatSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chat Settings',
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
      body: Consumer<ChatSettingsProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              // DMPermission Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Allow direct messages from',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'You can continue ongoing conversations regardless of which setting you choose.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: context.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Radios
              _buildRadioTile(
                context: context,
                title: 'Everyone',
                value: DMPermission.everyone,
                groupValue: provider.dmPermission,
                onTap: () => provider.setDMPermission(DMPermission.everyone),
              ),
              _buildRadioTile(
                context: context,
                title: 'Users I follow',
                value: DMPermission.followed,
                groupValue: provider.dmPermission,
                onTap: () => provider.setDMPermission(DMPermission.followed),
              ),
              _buildRadioTile(
                context: context,
                title: 'No one',
                value: DMPermission.none,
                groupValue: provider.dmPermission,
                onTap: () => provider.setDMPermission(DMPermission.none),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1, color: context.border),
              ),

              // Switch for Notification Sounds
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Icon(Icons.notifications_none_outlined, color: context.textPrimary, size: 24),
                title: Text(
                  'Notification sounds',
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                trailing: Switch(
                  value: provider.notificationSounds,
                  activeColor: const Color(0xFF0085FF),
                  activeTrackColor: const Color(0xFF0085FF).withOpacity(0.25),
                  inactiveThumbColor: context.textMuted,
                  inactiveTrackColor: context.isDarkMode ? const Color(0xFF1E293B) : Colors.grey[200],
                  onChanged: (val) => provider.setNotificationSounds(val),
                ),
              ),

              Divider(height: 1, color: context.border),

              // Export my chat data
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Icon(Icons.archive_outlined, color: context.textPrimary, size: 24),
                title: Text(
                  'Export my chat data',
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: context.textMuted, size: 22),
                onTap: () {
                  _showExportDialog(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRadioTile({
    required BuildContext context,
    required String title,
    required DMPermission value,
    required DMPermission groupValue,
    required VoidCallback onTap,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0085FF).withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0085FF) : context.border,
                  width: isSelected ? 6.5 : 2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Export Chat Data',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        content: Text(
          'Your chat data export has been requested. We will prepare the download and notify you soon.',
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.inter(color: const Color(0xFF0085FF), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
