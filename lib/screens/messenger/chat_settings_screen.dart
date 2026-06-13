import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/chat_settings_provider.dart';

class ChatSettingsScreen extends StatelessWidget {
  const ChatSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chat Settings',
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
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'You can continue ongoing conversations regardless of which setting you choose.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.black45,
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

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(height: 1, color: Color(0xFFEEEEEE)),
              ),

              // Switch for Notification Sounds
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.notifications_none_outlined, color: Colors.black87, size: 24),
                title: Text(
                  'Notification sounds',
                  style: GoogleFonts.outfit(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                trailing: Switch(
                  value: provider.notificationSounds,
                  activeColor: const Color(0xFF0085FF),
                  activeTrackColor: const Color(0xFF0085FF).withOpacity(0.25),
                  inactiveThumbColor: Colors.grey[400],
                  inactiveTrackColor: Colors.grey[200],
                  onChanged: (val) => provider.setNotificationSounds(val),
                ),
              ),

              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              // Export my chat data
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.archive_outlined, color: Colors.black87, size: 24),
                title: Text(
                  'Export my chat data',
                  style: GoogleFonts.outfit(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.black38, size: 22),
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
                  color: isSelected ? const Color(0xFF0085FF) : Colors.grey[300]!,
                  width: isSelected ? 6.5 : 2,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 15.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: Colors.black87,
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Export Chat Data',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        content: Text(
          'Your chat data export has been requested. We will prepare the download and notify you soon.',
          style: GoogleFonts.outfit(color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: GoogleFonts.outfit(color: const Color(0xFF0085FF), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
