import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/general_settings_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import 'two_factor_setup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _is2faEnabled = false;
  sb.Factor? _enrolledFactor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GeneralSettingsProvider>(context, listen: false).fetchActiveSessions();
      _load2faStatus();
    });
  }

  Future<void> _load2faStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final factor = await authService.getEnrolledFactor();
    if (mounted) {
      setState(() {
        _enrolledFactor = factor;
        _is2faEnabled = factor != null;
      });
    }
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
          'Security',
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
          final sessions = provider.activeSessions;
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildSectionHeader(context, 'Login Protection'),
              _buildSwitchTile(
                context: context,
                title: 'Two-Factor Authentication (2FA)',
                subtitle: _is2faEnabled ? '2FA is currently enabled for this account.' : 'Secure your account by requiring a code during login.',
                value: _is2faEnabled,
                onChanged: (val) async {
                  if (val) {
                    final success = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TwoFactorSetupScreen()),
                    );
                    if (success == true) {
                      _load2faStatus();
                    }
                  } else {
                    if (_enrolledFactor != null) {
                      // Prompt for confirmation
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: context.cardBg,
                          title: Text('Disable 2FA?', style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.bold)),
                          content: Text('Are you sure you want to disable Two-Factor Authentication? Your account will be less secure.', style: GoogleFonts.inter(color: context.textSecondary)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true), 
                              child: const Text('Disable', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        if (!mounted) return;
                        final authService = Provider.of<AuthService>(context, listen: false);
                        await authService.unenrollMfa(_enrolledFactor!.id);
                        _load2faStatus();
                      }
                    }
                  }
                },
              ),
              _buildActionTile(
                context,
                title: 'Change Password',
                subtitle: 'Update your login credentials regularly.',
                onTap: () => _showChangePasswordSheet(context),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader(context, 'Active Sessions'),
              if (sessions.isEmpty)
                Container(
                  color: context.cardBg,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  alignment: Alignment.center,
                  child: Text(
                    'No other active sessions found.',
                    style: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                  ),
                )
              else
                ...sessions.map((session) => _buildSessionTile(context, provider, session)),
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

  Widget _buildSwitchTile({
    required BuildContext context,
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
            activeThumbColor: Colors.white,
            activeTrackColor: context.primaryAccent,
            inactiveTrackColor: context.isDarkMode ? Colors.grey[800] : Colors.black12,
            inactiveThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
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

  Widget _buildSessionTile(BuildContext context, GeneralSettingsProvider provider, Map<String, String> session) {
    final isCurrent = session['status'] == 'Active now';
    return Container(
      color: context.cardBg,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            session['device']!.contains('iPhone') || session['device']!.contains('Pixel')
                ? Icons.phone_android_rounded
                : Icons.computer_rounded,
            color: context.textSecondary,
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
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                        color: context.textPrimary,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.isDarkMode ? const Color(0xFF0C2517) : const Color(0x1A1E824C),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Current',
                          style: GoogleFonts.inter(
                            color: context.primaryAccent,
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
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: context.textMuted,
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
                    backgroundColor: context.primaryAccent,
                  ),
                );
              },
              child: Text(
                'Revoke',
                style: GoogleFonts.inter(
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
      backgroundColor: context.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                        color: context.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Change Password',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(context, 'Old Password', oldPasswordController),
                  const SizedBox(height: 12),
                  _buildPasswordField(context, 'New Password', newPasswordController),
                  const SizedBox(height: 12),
                  _buildPasswordField(context, 'Confirm New Password', confirmPasswordController),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        final oldPass = oldPasswordController.text.trim();
                        final newPass = newPasswordController.text.trim();
                        final confirmPass = confirmPasswordController.text.trim();

                        if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                          _showToast(ctx, 'All fields are required.');
                          return;
                        }
                        if (newPass.length < 6) {
                          _showToast(ctx, 'Password must be at least 6 characters.');
                          return;
                        }
                        if (newPass != confirmPass) {
                          _showToast(ctx, 'New passwords do not match.');
                          return;
                        }

                        setModalState(() => isLoading = true);

                        final authService = Provider.of<AuthService>(ctx, listen: false);
                        final email = authService.currentUser?.email;

                        if (email != null && authService.currentUid != 'mock_uid') {
                          // Try to verify old password by logging in
                          final oldPassCorrect = await authService.handleLogin(email, oldPass);
                          if (!ctx.mounted) return;
                          if (oldPassCorrect != LoginResult.success) {
                            setModalState(() => isLoading = false);
                            _showToast(ctx, authService.errorMessage ?? 'Incorrect old password.');
                            return;
                          }

                          // Correct! Now update the password
                          final success = await authService.updatePassword(newPass);
                          if (!ctx.mounted) return;
                          if (success) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: const Text('Password updated successfully! Please log in again.'),
                                backgroundColor: ctx.primaryAccent,
                              ),
                            );
                          } else {
                            setModalState(() => isLoading = false);
                            _showToast(ctx, authService.errorMessage ?? 'Failed to update password.');
                          }
                        } else {
                          // Mock success (e.g. bypassed login or testing)
                          await Future.delayed(const Duration(seconds: 1));
                          if (!ctx.mounted) return;
                          setModalState(() => isLoading = false);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: const Text('Password updated (Mock Success).'),
                              backgroundColor: ctx.primaryAccent,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Update Password',
                              style: GoogleFonts.inter(
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
      },
    );
  }

  Widget _buildPasswordField(BuildContext context, String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
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
