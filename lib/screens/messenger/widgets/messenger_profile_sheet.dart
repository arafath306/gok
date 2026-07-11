import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dak/models/profile.dart';
import 'package:dak/screens/profile/profile_screen.dart';
import 'package:dak/utils/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessengerProfileSheet extends StatelessWidget {
  final Profile otherUser;
  final bool isMuted;
  final List<Map<String, dynamic>> sharedMedia;
  final ValueChanged<bool> onToggleMute;
  final VoidCallback onChangeTheme;
  final VoidCallback onBlockUser;
  final VoidCallback onDeleteConversation;
  final ValueChanged<String> onMediaTapped;

  const MessengerProfileSheet({
    super.key,
    required this.otherUser,
    required this.isMuted,
    required this.sharedMedia,
    required this.onToggleMute,
    required this.onChangeTheme,
    required this.onBlockUser,
    required this.onDeleteConversation,
    required this.onMediaTapped,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: context.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 48,
                backgroundColor: context.border,
                backgroundImage: otherUser.avatarUrl != null &&
                        otherUser.avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(otherUser.avatarUrl!)
                    : null,
                child: (otherUser.avatarUrl == null ||
                        otherUser.avatarUrl!.isEmpty)
                    ? Icon(Icons.person_rounded,
                        size: 48, color: context.textMuted)
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    otherUser.fullName,
                    style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary),
                  ),
                  if (otherUser.isVerified) ...{
                    const SizedBox(width: 6),
                    const Icon(Icons.verified, color: Colors.blue, size: 18),
                  },
                ],
              ),
              const SizedBox(height: 4),
              Text('@${otherUser.username}',
                  style: GoogleFonts.inter(
                      fontSize: 13.5, color: context.textMuted)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${otherUser.followingCount}',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary)),
                  const SizedBox(width: 4),
                  Text('Following',
                      style: GoogleFonts.inter(
                          fontSize: 13.5, color: context.textMuted)),
                  const SizedBox(width: 12),
                  Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                          color: context.textMuted,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Text('${otherUser.followersCount}',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary)),
                  const SizedBox(width: 4),
                  Text('Followers',
                      style: GoogleFonts.inter(
                          fontSize: 13.5, color: context.textMuted)),
                ],
              ),
              if (otherUser.bio != null && otherUser.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  otherUser.bio!,
                  style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: context.textSecondary,
                      height: 1.4),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(userId: otherUser.id),
                          ),
                        );
                      },
                      icon: Icon(Icons.person_outline,
                          color: context.primaryAccent, size: 16),
                      label: Text('Profile',
                          style: GoogleFonts.inter(
                              color: context.primaryAccent, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.primaryAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatefulBuilder(
                      builder: (_, setMuteState) => OutlinedButton.icon(
                        onPressed: () {
                          onToggleMute(!isMuted);
                          setMuteState(() {});
                        },
                        icon: Icon(
                            isMuted
                                ? Icons.notifications_off_outlined
                                : Icons.notifications_outlined,
                            color: context.primaryAccent,
                            size: 16),
                        label: Text(isMuted ? 'Unmute' : 'Mute',
                            style: GoogleFonts.inter(
                                color: context.primaryAccent, fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.primaryAccent),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.palette_outlined, color: Colors.blueAccent),
                title: Text('Change Theme', style: GoogleFonts.inter(color: Colors.blueAccent)),
                onTap: () {
                  Navigator.pop(context);
                  onChangeTheme();
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.blueAccent.withValues(alpha: 0.05),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.block_rounded, color: Colors.redAccent),
                title: Text('Block User', style: GoogleFonts.inter(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  onBlockUser();
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.redAccent.withValues(alpha: 0.05),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text('Delete Conversation', style: GoogleFonts.inter(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  onDeleteConversation();
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.redAccent.withValues(alpha: 0.05),
              ),
              if (sharedMedia.isNotEmpty) ...[
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Shared Media (${sharedMedia.length})',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8),
                  itemCount: sharedMedia.length,
                  itemBuilder: (context, index) {
                    final mediaUrl = sharedMedia[index]['media_url'] as String;
                    return GestureDetector(
                      onTap: () => onMediaTapped(mediaUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          mediaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                              color: context.border,
                              child: const Icon(Icons.error)),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        );
      },
    );
  }
}
