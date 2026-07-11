import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dak/models/profile.dart';
import 'package:dak/services/database_service.dart';
import 'package:dak/services/general_settings_provider.dart';
import 'package:dak/utils/app_theme.dart';

class BlockedBanner extends StatelessWidget {
  final Profile otherUser;
  final bool blockedByMe;
  final DatabaseService db;

  const BlockedBanner({
    super.key,
    required this.otherUser,
    required this.blockedByMe,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.border, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.block_rounded, color: Colors.redAccent, size: 32),
          const SizedBox(height: 12),
          Text(
            blockedByMe
                ? 'You blocked this account'
                : 'This conversation is unavailable',
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: context.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            blockedByMe
                ? 'You cannot message this account. Unblock to send a message.'
                : 'You cannot message this account because they blocked you.',
            style: GoogleFonts.inter(fontSize: 13, color: context.textMuted),
            textAlign: TextAlign.center,
          ),
          if (blockedByMe) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final settingsProvider = Provider.of<GeneralSettingsProvider>(
                    context,
                    listen: false);
                await settingsProvider.unblockAccount(otherUser.id);
                await db.fetchBlockedMutedLists();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text('@${otherUser.username} has been unblocked.'),
                    backgroundColor: Colors.green,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: Text('Unblock User',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ],
      ),
    );
  }
}
