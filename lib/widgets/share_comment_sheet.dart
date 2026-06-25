import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import '../screens/messenger/member_search_sheet.dart';

class ShareCommentSheet extends StatefulWidget {
  final Map<String, dynamic> comment;
  const ShareCommentSheet({super.key, required this.comment});

  @override
  State<ShareCommentSheet> createState() => _ShareCommentSheetState();
}

class _ShareCommentSheetState extends State<ShareCommentSheet> {
  late Future<List<Map<String, dynamic>>> _activeChatsFuture;

  @override
  void initState() {
    super.initState();
    final db = Provider.of<DatabaseService>(context, listen: false);
    _activeChatsFuture = db.fetchActiveChats();
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);
    final String commentId = widget.comment['id'] as String;
    final String commentLink = "https://dak.ngst.app/comment/$commentId";

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle/pill marker
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: context.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          
          // Card 1: Direct Message Card
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top section: Active chats or placeholder
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _activeChatsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final chats = snapshot.data ?? [];
                    if (chats.isEmpty) {
                      // Show placeholder with circular silhouettes
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: context.isDarkMode 
                                        ? Colors.white.withValues(alpha: 0.05) 
                                        : Colors.black.withValues(alpha: 0.03),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: context.isDarkMode 
                                        ? Colors.white24 
                                        : Colors.black26,
                                    size: 20,
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Start a conversation, and it will appear here.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w500,
                                // Height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Render active chats row
                    return Container(
                      height: 100,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          final profile = chat['profile'] as Profile;
                          return GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              db.incrementCommentShareCount(commentId);
                              await db.sendMessage(profile.id, "Shared a comment: $commentLink");
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Sent to ${profile.fullName}"),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 16),
                              width: 60,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                                        ? NetworkImage(profile.avatarUrl!)
                                        : null,
                                    child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    profile.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: context.border),
                // "Send via direct message" button
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MemberSearchSheet(),
                      ),
                    );
                  },
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Send via direct message",
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              color: context.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          CupertinoIcons.arrowshape_turn_up_right,
                          color: context.textPrimary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Card 2: Share and Copy Card
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "Share via..." Row
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: commentLink));
                    Navigator.pop(context);
                    db.incrementCommentShareCount(commentId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Link copied for sharing"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Share via...",
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              color: context.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.ios_share,
                          color: context.textPrimary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(height: 1, color: context.border),
                // "Copy link to comment" Row
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: commentLink));
                    Navigator.pop(context);
                    db.incrementCommentShareCount(commentId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Link copied to clipboard"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Copy link to comment",
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              color: context.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.link,
                          color: context.textPrimary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
