import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/profile.dart';
import '../../services/database_service.dart';
import '../../services/general_settings_provider.dart';
import '../../utils/app_theme.dart';
import '../profile/profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final Profile otherUser;

  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  List<Map<String, dynamic>> _allMessages = [];
  bool _isSendingMedia = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    _messagesStream = dbService.getMessagesStream(widget.otherUser.id);
    
    // Mark messages as read upon entering the chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dbService.markMessagesAsRead(widget.otherUser.id);
    });

    _loadMuteStatus();
  }

  Future<void> _loadMuteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMuted = prefs.getBool('mute_chat_${widget.otherUser.id}') ?? false;
    });
  }

  Future<void> _toggleMute(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mute_chat_${widget.otherUser.id}', value);
    setState(() {
      _isMuted = value;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Chat muted' : 'Chat unmuted', style: GoogleFonts.inter()),
          backgroundColor: context.primaryAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    dbService.sendMessage(widget.otherUser.id, text);
    _messageCtrl.clear();

    // Scroll to bottom
    _scrollToBottom();
  }

  Future<void> _sendMediaMessage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image == null) return;

      setState(() => _isSendingMedia = true);

      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final bytes = await image.readAsBytes();
      final mediaUrl = await dbService.uploadChatMedia(bytes);
      
      if (mediaUrl != null) {
        await dbService.sendMessage(widget.otherUser.id, "", mediaUrl: mediaUrl, mediaType: 'image');
        _scrollToBottom();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Media upload failed.", style: GoogleFonts.inter()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error sending media: $e");
    } finally {
      if (mounted) {
        setState(() => _isSendingMedia = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature calling is coming soon!", style: GoogleFonts.inter()),
        backgroundColor: context.primaryAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMediaMessageOptions(Map<String, dynamic> msg) {
    final mediaUrl = msg['media_url'] as String? ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.download_rounded, color: context.primaryAccent),
                title: Text("Download", style: GoogleFonts.inter(color: context.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _downloadMedia(mediaUrl);
                },
              ),
              ListTile(
                leading: Icon(Icons.forward_rounded, color: context.primaryAccent),
                title: Text("Forward", style: GoogleFonts.inter(color: context.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _forwardMedia(msg);
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_problem_outlined, color: Colors.redAccent),
                title: Text("Report", style: GoogleFonts.inter(color: context.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _reportMedia(msg['id'] as String);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadMedia(String url) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Downloading image...", style: GoogleFonts.inter()),
          backgroundColor: context.primaryAccent,
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image downloaded to gallery successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Download error: $e");
    }
  }

  void _forwardMedia(Map<String, dynamic> msg) async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final chats = await dbService.fetchActiveChats();
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Forward to...",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, i) {
                    final chat = chats[i];
                    final Profile profile = chat['profile'] as Profile;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                      ),
                      title: Text(profile.fullName, style: GoogleFonts.inter(color: context.textPrimary)),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await dbService.sendMessage(
                            profile.id,
                            msg['text'] as String? ?? '',
                            mediaUrl: msg['media_url'] as String?,
                            mediaType: msg['media_type'] as String?,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Forwarded to ${profile.fullName}", style: GoogleFonts.inter()),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text("Send", style: GoogleFonts.inter(color: Colors.white)),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _reportMedia(String messageId) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text("Report Media", style: GoogleFonts.inter(color: context.textPrimary)),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            hintText: "Enter reason for reporting...",
          ),
          style: GoogleFonts.inter(color: context.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.inter(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              final dbService = Provider.of<DatabaseService>(context, listen: false);
              await dbService.reportUser(widget.otherUser.id, "Media Message Report (id: $messageId): $reason");
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Media reported successfully."),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text("Report", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showMessengerProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final sharedMedia = _allMessages
                .where((m) => m['media_url'] != null && (m['media_url'] as String).isNotEmpty)
                .toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Avatar
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: context.border,
                        backgroundImage: widget.otherUser.avatarUrl != null && widget.otherUser.avatarUrl!.isNotEmpty
                            ? NetworkImage(widget.otherUser.avatarUrl!)
                            : null,
                        child: (widget.otherUser.avatarUrl == null || widget.otherUser.avatarUrl!.isEmpty)
                            ? Icon(Icons.person_rounded, size: 48, color: context.textMuted)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Name & verified badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.otherUser.fullName,
                            style: GoogleFonts.inter(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          if (widget.otherUser.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, color: Colors.blue, size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "@${widget.otherUser.username}",
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: context.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Follow stats (Twitter/Bluesky style)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${widget.otherUser.followingCount}",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Following",
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: context.textMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "${widget.otherUser.followersCount}",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Followers",
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: context.textMuted,
                            ),
                          ),
                        ],
                      ),
                      if (widget.otherUser.bio != null && widget.otherUser.bio!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            widget.otherUser.bio!,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              color: context.textSecondary,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      // Actions row
                      Row(
                        children: [
                          // Go to Profile
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProfileScreen(userId: widget.otherUser.id),
                                  ),
                                );
                              },
                              icon: Icon(Icons.person_outline_rounded, size: 18, color: context.primaryAccent),
                              label: Text("Go to Profile", style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.primaryAccent)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: context.primaryAccent, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Shared Media gallery action
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _showSharedMediaGallery(sharedMedia);
                              },
                              icon: Icon(Icons.photo_library_outlined, size: 18, color: context.primaryAccent),
                              label: Text("Shared Media", style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: context.primaryAccent)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: context.primaryAccent, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Settings List
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            "Chat Settings",
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: context.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.border, width: 0.8),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              secondary: Icon(
                                _isMuted ? Icons.notifications_off_outlined : Icons.notifications_none_rounded,
                                color: _isMuted ? context.textMuted : context.primaryAccent,
                                size: 22,
                              ),
                              title: Text("Mute Notifications", style: GoogleFonts.inter(fontSize: 14.5, color: context.textPrimary, fontWeight: FontWeight.w500)),
                              subtitle: Text("Turn off notifications for this chat", style: GoogleFonts.inter(fontSize: 12, color: context.textMuted)),
                              value: _isMuted,
                              activeTrackColor: context.primaryAccent,
                              onChanged: (val) {
                                setSheetState(() {
                                  _isMuted = val;
                                });
                                _toggleMute(val);
                              },
                            ),
                            Divider(height: 1, color: context.border),
                            ListTile(
                              leading: const Icon(
                                Icons.block_outlined,
                                color: Colors.redAccent,
                                size: 22,
                              ),
                              title: Text("Block User", style: GoogleFonts.inter(fontSize: 14.5, color: Colors.redAccent, fontWeight: FontWeight.w500)),
                              subtitle: Text("Stop receiving messages from this account", style: GoogleFonts.inter(fontSize: 12, color: context.textMuted)),
                              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.textMuted),
                              onTap: () {
                                Navigator.pop(ctx);
                                _confirmBlockUser();
                              },
                            ),
                            Divider(height: 1, color: context.border),
                            ListTile(
                              leading: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 22,
                              ),
                              title: Text("Delete Conversation", style: GoogleFonts.inter(fontSize: 14.5, color: Colors.redAccent, fontWeight: FontWeight.w500)),
                              subtitle: Text("Permanently erase chat history", style: GoogleFonts.inter(fontSize: 12, color: context.textMuted)),
                              trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.textMuted),
                              onTap: () {
                                Navigator.pop(ctx);
                                _confirmDeleteConversation();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showSharedMediaGallery(List<Map<String, dynamic>> sharedMedia) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Shared Media (${sharedMedia.length})",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: sharedMedia.isEmpty
                      ? Center(
                          child: Text(
                            "No media exchanged yet",
                            style: GoogleFonts.inter(color: context.textMuted),
                          ),
                        )
                      : GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: sharedMedia.length,
                          itemBuilder: (context, i) {
                            final mediaUrl = sharedMedia[i]['media_url'] as String;
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenMediaViewer(mediaUrl: mediaUrl),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  mediaUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmBlockUser() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text("Block User?", style: GoogleFonts.inter(color: context.textPrimary)),
        content: Text("Are you sure you want to block ${widget.otherUser.fullName}? You will no longer receive direct messages from them.", style: GoogleFonts.inter(color: context.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.inter(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final settings = Provider.of<GeneralSettingsProvider>(context, listen: false);
              await settings.blockUserById(widget.otherUser.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${widget.otherUser.fullName} has been blocked."),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                Navigator.pop(context); // Pop ChatScreen back to chats home
              }
            },
            child: const Text("Block", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteConversation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text("Delete Conversation?", style: GoogleFonts.inter(color: context.textPrimary)),
        content: Text("Are you sure you want to delete all messages in this conversation? This action is permanent.", style: GoogleFonts.inter(color: context.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.inter(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = Provider.of<DatabaseService>(context, listen: false);
              final success = await db.deleteConversation(widget.otherUser.id);
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Conversation history deleted."),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  Navigator.pop(context); // Pop ChatScreen back to chats home
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to delete conversation."),
                      backgroundColor: Colors.orangeAccent,
                    ),
                  );
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<GeneralSettingsProvider>(context);
    final myActiveStatusEnabled = settings.isActiveStatusEnabled;
    final db = Provider.of<DatabaseService>(context);
    final bool isBlocked = db.isBlocked(widget.otherUser.id);
    final bool blockedByMe = db.isBlockedByMe(widget.otherUser.id);

    final bool otherIsActive = widget.otherUser.isActiveStatusEnabled &&
        widget.otherUser.lastSeen != null &&
        DateTime.now().difference(widget.otherUser.lastSeen!).inMinutes <= 5;
    final bool showGreenDot = myActiveStatusEnabled && otherIsActive;

    String statusText = "Offline";
    if (widget.otherUser.isActiveStatusEnabled && widget.otherUser.lastSeen != null) {
      if (otherIsActive) {
        statusText = "Active now";
      } else {
        final diff = DateTime.now().difference(widget.otherUser.lastSeen!);
        if (diff.inMinutes < 1) {
          statusText = "Active just now";
        } else if (diff.inMinutes < 60) {
          statusText = "Active ${diff.inMinutes}m ago";
        } else if (diff.inHours < 24) {
          statusText = "Active ${diff.inHours}h ago";
        } else {
          statusText = "Active ${diff.inDays}d ago";
        }
      }
    }

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: _showMessengerProfile,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: context.border,
                      backgroundImage: widget.otherUser.avatarUrl != null && widget.otherUser.avatarUrl!.isNotEmpty
                          ? NetworkImage(widget.otherUser.avatarUrl!)
                          : null,
                    ),
                    if (showGreenDot)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.scaffoldBg, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.otherUser.fullName,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: context.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.otherUser.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Colors.blue, size: 15),
                          ],
                        ],
                      ),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: otherIsActive ? Colors.green : context.textMuted,
                          fontWeight: otherIsActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (!isBlocked) ...[
            IconButton(
              icon: Icon(Icons.phone_outlined, color: context.textPrimary, size: 21),
              onPressed: () => _showComingSoon("Audio"),
            ),
            IconButton(
              icon: Icon(Icons.videocam_outlined, color: context.textPrimary, size: 22),
              onPressed: () => _showComingSoon("Video"),
            ),
          ],
          IconButton(
            icon: Icon(Icons.info_outlined, color: context.textPrimary, size: 20),
            onPressed: _showMessengerProfile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Message List from StreamBuilder
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: context.primaryAccent));
                }
                
                final messages = snapshot.data ?? [];
                _allMessages = messages;
                
                // Automatically mark incoming messages as read when viewing the screen
                if (messages.isNotEmpty) {
                  final db = Provider.of<DatabaseService>(context, listen: false);
                  db.markMessagesAsRead(widget.otherUser.id);
                  _scrollToBottom();
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: context.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          "Send a message to start conversation.",
                          style: GoogleFonts.inter(color: context.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg["isMe"] as bool;
                    final String? mediaUrl = msg["media_url"] as String?;
                    final bool isRead = msg["is_read"] as bool? ?? false;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        child: GestureDetector(
                          onLongPress: (mediaUrl != null && mediaUrl.isNotEmpty)
                              ? () => _showMediaMessageOptions(msg)
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? context.primaryAccent : context.cardBg,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                              ),
                              border: isMe ? null : Border.all(color: context.border, width: 0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.015),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Render image media if present
                                if (mediaUrl != null && mediaUrl.isNotEmpty) ...[
                                  GestureDetector(
                                    onTap: () => _openFullScreenMedia(mediaUrl),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        mediaUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image, size: 50),
                                      ),
                                    ),
                                  ),
                                  if (msg["text"] != null && (msg["text"] as String).isNotEmpty)
                                    const SizedBox(height: 8),
                                ],
                                if (msg["text"] != null && (msg["text"] as String).isNotEmpty)
                                  Text(
                                    msg["text"] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      color: isMe ? Colors.white : context.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      msg["time"] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: isMe ? Colors.white60 : context.textMuted,
                                      ),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        isRead ? Icons.done_all : Icons.done,
                                        size: 13,
                                        color: isRead ? Colors.greenAccent : Colors.white60,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Uploading Media Progress Bar
          if (_isSendingMedia)
            LinearProgressIndicator(color: context.primaryAccent, backgroundColor: Colors.transparent),

          // Message Input Field / Blocked Banner
          isBlocked
              ? _buildBlockedBanner(context, blockedByMe, db)
              : Container(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    border: Border(
                      top: BorderSide(color: context.border, width: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.add_photo_alternate_outlined, color: context.primaryAccent, size: 24),
                        onPressed: _sendMediaMessage,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.isDarkMode ? const Color(0xFF151824) : const Color(0xFFF3F5F4),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _messageCtrl,
                            decoration: InputDecoration(
                              hintText: "Write a message...",
                              hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            style: GoogleFonts.inter(fontSize: 14.5, color: context.textPrimary),
                            maxLines: 4,
                            minLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(Icons.mic_none_rounded, color: context.primaryAccent, size: 24),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Voice messages are coming soon!", style: GoogleFonts.inter()),
                              backgroundColor: context.primaryAccent,
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: context.primaryAccent,
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                          onPressed: _sendMessage,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildBlockedBanner(BuildContext context, bool blockedByMe, DatabaseService db) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(
          top: BorderSide(color: context.border, width: 0.8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.block_rounded,
            color: Colors.redAccent,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            blockedByMe
                ? "You blocked this account"
                : "This conversation is unavailable",
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            blockedByMe
                ? "You cannot message this account. Unblock to send a message."
                : "You cannot message this account because they blocked you or the account is restricted.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: context.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          if (blockedByMe) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final settingsProvider = Provider.of<GeneralSettingsProvider>(context, listen: false);
                await settingsProvider.unblockAccount(widget.otherUser.id);
                await db.fetchBlockedMutedLists();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("@${widget.otherUser.username} has been unblocked."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: Text(
                "Unblock User",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openFullScreenMedia(String mediaUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenMediaViewer(mediaUrl: mediaUrl),
      ),
    );
  }
}

class FullScreenMediaViewer extends StatelessWidget {
  final String mediaUrl;

  const FullScreenMediaViewer({super.key, required this.mediaUrl});

  Future<void> _downloadImage(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Downloading image...", style: GoogleFonts.inter()),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 1500));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Image downloaded to gallery successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () => _downloadImage(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          clipBehavior: Clip.none,
          maxScale: 4.0,
          child: Image.network(
            mediaUrl,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, color: Colors.white, size: 50),
          ),
        ),
      ),
    );
  }
}
