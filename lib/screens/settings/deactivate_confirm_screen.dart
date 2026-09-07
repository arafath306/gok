import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/general_settings_provider.dart';
import '../../utils/app_theme.dart';
import 'deactivate_status_screen.dart';

class DeactivateConfirmScreen extends StatefulWidget {
  final String username;
  const DeactivateConfirmScreen({super.key, required this.username});

  @override
  State<DeactivateConfirmScreen> createState() => _DeactivateConfirmScreenState();
}

class _DeactivateConfirmScreenState extends State<DeactivateConfirmScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _signOutOthers = false;
  bool _isLoading = false;

  void _showTopToast(String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.primaryAccent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Text(
              message,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) entry.remove();
    });
  }

  Future<void> _handleDeactivate() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _showTopToast('Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final email = authService.currentUser?.email;

    if (email != null && authService.currentUid != 'mock_uid') {
      final loginResult = await authService.handleLogin(email, password);
      if (!mounted) return;
      if (loginResult != LoginResult.success) {
        setState(() => _isLoading = false);
        _showTopToast(authService.errorMessage ?? 'Incorrect password');
        return;
      }
    }

    if (_signOutOthers) {
      final generalProvider = Provider.of<GeneralSettingsProvider>(context, listen: false);
      for (final session in generalProvider.activeSessions) {
        if (session['status'] != 'Active now') {
          await generalProvider.revokeSession(session['id']!);
        }
      }
    }

    // Schedule deactivation for 30 days safe harbor
    final success = await dbService.deactivateAccount(const Duration(days: 30));
    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DeactivateStatusScreen(username: widget.username)),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to deactivate account. Try again.')));
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myProfile = context.select((DatabaseService db) => db.myProfile);
    final email = Provider.of<AuthService>(context, listen: false).currentUser?.email ?? 'example@email.com';
    final avatarUrl = myProfile?.avatarUrl;

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize_rounded, color: context.textSecondary, size: 20), // Placeholder for Pigeon logo
            const SizedBox(width: 8),
            Text(
              'Confirm Deactivation',
              style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          Icon(Icons.settings_outlined, color: context.textPrimary, size: 22),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 12,
            backgroundColor: context.isDarkMode ? Colors.grey[900] : Colors.grey[200],
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
            child: (avatarUrl == null || avatarUrl.isEmpty) ? Icon(Icons.person, size: 16, color: context.textSecondary) : null,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            // Shield Icon
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shield_outlined, color: context.textPrimary, size: 32),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: context.primaryAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Confirm your password',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please re-enter your password to confirm that you want to deactivate your @${widget.username} account.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14.5, color: context.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Profile info card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.contact_mail_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text('@${widget.username}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary)),
                  const SizedBox(width: 8),
                  Icon(Icons.verified, color: context.textPrimary, size: 14),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '($email)',
                      style: GoogleFonts.inter(color: context.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Password Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Password *',
                        style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                      ),
                      Text(
                        'Forgot password?',
                        style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: GoogleFonts.inter(color: context.textMuted),
                      filled: true,
                      fillColor: context.isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: context.textSecondary),
                        onPressed: () => setState(() => _obscureText = !_obscureText),
                      ),
                    ),
                    style: GoogleFonts.inter(color: context.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.history, size: 14, color: context.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Minimum 8 characters with numbers or symbols', style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Warning Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.schedule, color: context.primaryAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(fontSize: 13.5, color: context.textPrimary, height: 1.5),
                              children: [
                                const TextSpan(text: 'By confirming, your profile will immediately '),
                                TextSpan(text: 'go dark', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                const TextSpan(text: ' and will be scheduled for permanent deletion in '),
                                TextSpan(text: '30 days.', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Timeline Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Immediate Deactivation', style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary)),
                            Text('Day 30 (Purge)', style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: context.isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: 0.2, // Visual representation
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: context.primaryAccent,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(width: 6, height: 6, decoration: BoxDecoration(color: context.primaryAccent, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text('Instant invisible state', style: GoogleFonts.inter(fontSize: 11, color: context.primaryAccent)),
                              ],
                            ),
                            Text('Permanent cleanup', style: GoogleFonts.inter(fontSize: 11, color: context.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sign out checkbox
            GestureDetector(
              onTap: () => setState(() => _signOutOthers = !_signOutOthers),
              child: Row(
                children: [
                  Icon(Icons.devices_rounded, color: context.textSecondary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sign out of all other devices',
                      style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _signOutOthers,
                      onChanged: (val) => setState(() => _signOutOthers = val ?? false),
                      activeColor: context.primaryAccent,
                      checkColor: Colors.white,
                      side: BorderSide(color: context.textSecondary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryAccent, // Match intro screen button
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.person_off_outlined, size: 20),
                label: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Deactivate @${widget.username}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: _isLoading ? null : _handleDeactivate,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  foregroundColor: context.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                ),
                child: Text('Cancel and keep account', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
