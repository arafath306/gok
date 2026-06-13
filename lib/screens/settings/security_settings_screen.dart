import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/general_settings_provider.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

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
          'Security',
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
          final sessions = provider.activeSessions;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildSectionHeader('Login Protection'),
              _buildSwitchTile(
                context: context,
                title: 'Two-Factor Authentication (2FA)',
                subtitle: 'Secure your account by requiring a code during login.',
                value: provider.isTwoFactorEnabled,
                onChanged: (val) {
                  provider.toggleTwoFactor(val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val ? '2FA Enabled successfully!' : '2FA Disabled'),
                      backgroundColor: const Color(0xFF1E824C),
                    ),
                  );
                },
              ),
              _buildActionTile(
                title: 'Change Password',
                subtitle: 'Update your login credentials regularly.',
                onTap: () => _showChangePasswordSheet(context),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader('Active Sessions'),
              if (sessions.isEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  alignment: Alignment.center,
                  child: Text(
                    'No other active sessions found.',
                    style: GoogleFonts.outfit(color: Colors.black38, fontSize: 14),
                  ),
                )
              else
                ...sessions.map((session) => _buildSessionTile(context, provider, session)).toList(),
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
    required BuildContext context,
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

  Widget _buildActionTile({
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

  Widget _buildSessionTile(BuildContext context, GeneralSettingsProvider provider, Map<String, String> session) {
    final isCurrent = session['status'] == 'Active now';
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            session['device']!.contains('iPhone') || session['device']!.contains('Pixel')
                ? Icons.phone_android_rounded
                : Icons.computer_rounded,
            color: Colors.black54,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      session['device']!,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        color: Colors.black87,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x1A1E824C),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Current',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF1E824C),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${session['location']}  ·  ${session['status']}',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrent)
            TextButton(
              onPressed: () {
                provider.revokeSession(session['id']!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Session revoked: ${session['device']}'),
                    backgroundColor: const Color(0xFF1E824C),
                  ),
                );
              },
              child: Text(
                'Revoke',
                style: GoogleFonts.outfit(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 32),
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
                'Change Password',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              _buildPasswordField('Old Password', oldPasswordController),
              const SizedBox(height: 12),
              _buildPasswordField('New Password', newPasswordController),
              const SizedBox(height: 12),
              _buildPasswordField('Confirm New Password', confirmPasswordController),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    final oldPass = oldPasswordController.text.trim();
                    final newPass = newPasswordController.text.trim();
                    final confirmPass = confirmPasswordController.text.trim();

                    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                      _showToast(context, 'All fields are required.');
                      return;
                    }
                    if (newPass.length < 6) {
                      _showToast(context, 'Password must be at least 6 characters.');
                      return;
                    }
                    if (newPass != confirmPass) {
                      _showToast(context, 'New passwords do not match.');
                      return;
                    }

                    // Success!
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password updated successfully!'),
                        backgroundColor: Color(0xFF1E824C),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E824C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Update Password',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
