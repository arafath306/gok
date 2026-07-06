import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/profile.dart';
import '../../services/database_service.dart';
import '../../services/general_settings_provider.dart';
import '../../utils/app_theme.dart';
import '../profile/profile_screen.dart';
import '../../widgets/comment_attachment_picker_panel.dart';

// â”€â”€â”€ ChatScreen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class ChatScreen extends StatefulWidget {
  final Profile otherUser;
  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  late Stream<List<Map<String, dynamic>>> _messagesStream;
  List<Map<String, dynamic>> _allMessages = [];
  late Profile _realtimeOtherUser;

  // Optimistic pending messages
  final List<Map<String, dynamic>> _pendingMessages = [];

  // Optimistically deleted IDs â€“ hide them immediately before stream updates
  final Set<String> _deletedIds = {};

  Timer? _statusUpdateTimer;
  bool _isMuted = false;

  // â”€â”€ These are only managed at the top level (not inline in build) â”€â”€
  Map<String, dynamic>? _replyingToMessage;
  bool _showEmojiPanel = false;
  int _pickerTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _realtimeOtherUser = widget.otherUser;
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    _messagesStream = dbService.getMessagesStream(widget.otherUser.id);

    // Mark read once on enter, not on every rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dbService.markMessagesAsRead(widget.otherUser.id);
    });

    _loadMuteStatus();

    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshOtherUserStatus();
    });
  }

  Future<void> _refreshOtherUserStatus() async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final updatedProfile = await dbService.fetchProfile(widget.otherUser.id);
      if (updatedProfile != null && mounted) {
        setState(() => _realtimeOtherUser = updatedProfile);
      }
    } catch (e) {
      debugPrint('Error updating other user status: $e');
    }
  }

  Future<void> _loadMuteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isMuted = prefs.getBool('mute_chat_${widget.otherUser.id}') ?? false;
      });
    }
  }

  Future<void> _toggleMute(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mute_chat_${widget.otherUser.id}', value);
    setState(() => _isMuted = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(value ? 'Chat muted' : 'Chat unmuted',
            style: GoogleFonts.inter()),
        backgroundColor: context.primaryAccent,
      ));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  // â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature calling is coming soon!',
          style: GoogleFonts.inter()),
      backgroundColor: context.primaryAccent,
      duration: const Duration(seconds: 2),
    ));
  }

  // â”€â”€â”€ Send text message â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _sendMessage(String text, Map<String, dynamic>? parentMsg) {
    if (text.isEmpty) return;

    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id': tempId,
      'text': text,
      'isMe': true,
      'time': _formatToDhaka12Hr(DateTime.now()),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'is_read': false,
      'is_sending': true,
      if (parentMsg != null) ...{
        'reply_to_id': parentMsg['id'],
        'reply_to_text': parentMsg['text'],
        'reply_to_sender':
            parentMsg['isMe'] == true ? 'You' : _realtimeOtherUser.fullName,
      }
    };

    setState(() {
      _pendingMessages.add(tempMsg);
      _replyingToMessage = null;
      _showEmojiPanel = false;
    });
    _scrollToBottom();

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    String contentToSave = text;
    if (parentMsg != null) {
      contentToSave = jsonEncode({
        'reply_to_id': parentMsg['id'],
        'reply_to_text': parentMsg['text'] ?? '',
        'reply_to_sender':
            parentMsg['isMe'] == true ? 'You' : _realtimeOtherUser.fullName,
        'text': text,
      });
    }

    dbService
        .sendMessage(_realtimeOtherUser.id, contentToSave)
        .then((_) {
      if (mounted) {
        setState(() {
          final idx = _pendingMessages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) _pendingMessages[idx]['is_sending'] = false;
        });
      }
    }).catchError((err) {
      debugPrint('Error sending message: $err');
      if (mounted) {
        setState(() =>
            _pendingMessages.removeWhere((m) => m['id'] == tempId));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to send message', style: GoogleFonts.inter()),
        ));
      }
    });
  }

  // â”€â”€â”€ Send media message â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _sendMediaMessage() async {
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(imageQuality: 70);
      if (images.isEmpty) return;

      for (final image in images) {
        final bytes = await image.readAsBytes();
        final parentMsg = _replyingToMessage;
        final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${image.name.hashCode}';

        final tempMsg = {
          'id': tempId,
          'text': '',
          'isMe': true,
          'time': _formatToDhaka12Hr(DateTime.now()),
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'is_read': false,
          'is_sending': true,
          'local_media_bytes': bytes,
          'media_type': 'image',
          if (parentMsg != null) ...{
            'reply_to_id': parentMsg['id'],
            'reply_to_text': parentMsg['text'],
            'reply_to_sender':
                parentMsg['isMe'] == true ? 'You' : _realtimeOtherUser.fullName,
          }
        };

        if (mounted) {
          setState(() {
            _pendingMessages.add(tempMsg);
            _replyingToMessage = null; // Clear reply quote after first image
            _showEmojiPanel = false;
          });
          _scrollToBottom();
        }

        dbService.uploadChatMedia(bytes).then((mediaUrl) async {
          if (mediaUrl != null) {
            if (mounted) {
              setState(() {
                final idx =
                    _pendingMessages.indexWhere((m) => m['id'] == tempId);
                if (idx != -1) _pendingMessages[idx]['media_url'] = mediaUrl;
              });
            }
            String contentToSave = '';
            if (parentMsg != null) {
              contentToSave = jsonEncode({
                'reply_to_id': parentMsg['id'],
                'reply_to_text': parentMsg['text'] ?? '',
                'reply_to_sender': parentMsg['isMe'] == true
                    ? 'You'
                    : _realtimeOtherUser.fullName,
                'text': '',
              });
            }
            await dbService.sendMessage(_realtimeOtherUser.id, contentToSave,
                mediaUrl: mediaUrl, mediaType: 'image');
          } else {
            throw Exception('Media upload returned null');
          }
        }).then((_) {
          if (mounted) {
            setState(() {
              final idx =
                  _pendingMessages.indexWhere((m) => m['id'] == tempId);
              if (idx != -1) _pendingMessages[idx]['is_sending'] = false;
            });
          }
        }).catchError((err) {
          debugPrint('Error sending media: $err');
          if (mounted) {
            setState(() =>
                _pendingMessages.removeWhere((m) => m['id'] == tempId));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to send image.', style: GoogleFonts.inter()),
              backgroundColor: Colors.redAccent,
            ));
          }
        });

        // Add a tiny delay between starting uploads to avoid identical timestamp IDs
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
    }
  }

  // â”€â”€â”€ Send GIF â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _sendGifMessage(String gifUrl) {
    final parentMsg = _replyingToMessage;
    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    final tempMsg = {
      'id': tempId,
      'text': '',
      'isMe': true,
      'time': _formatToDhaka12Hr(DateTime.now()),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'is_read': false,
      'is_sending': true,
      'media_url': gifUrl,
      'media_type': 'image',
      if (parentMsg != null) ...{
        'reply_to_id': parentMsg['id'],
        'reply_to_text': parentMsg['text'],
        'reply_to_sender':
            parentMsg['isMe'] == true ? 'You' : _realtimeOtherUser.fullName,
      }
    };

    setState(() {
      _pendingMessages.add(tempMsg);
      _replyingToMessage = null;
      _showEmojiPanel = false;
    });
    _scrollToBottom();

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    String contentToSave = '';
    if (parentMsg != null) {
      contentToSave = jsonEncode({
        'reply_to_id': parentMsg['id'],
        'reply_to_text': parentMsg['text'] ?? '',
        'reply_to_sender':
            parentMsg['isMe'] == true ? 'You' : _realtimeOtherUser.fullName,
        'text': '',
      });
    }

    dbService
        .sendMessage(_realtimeOtherUser.id, contentToSave,
            mediaUrl: gifUrl, mediaType: 'image')
        .then((_) {
      if (mounted) {
        setState(() {
          final idx = _pendingMessages.indexWhere((m) => m['id'] == tempId);
          if (idx != -1) _pendingMessages[idx]['is_sending'] = false;
        });
      }
    }).catchError((err) {
      debugPrint('Error sending GIF: $err');
      if (mounted) {
        setState(() =>
            _pendingMessages.removeWhere((m) => m['id'] == tempId));
      }
    });
  }

  // â”€â”€â”€ Edit message â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showEditMessageDialog(String messageId, String currentText) {
    final controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text('Edit Message',
            style: GoogleFonts.inter(color: context.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: null,
          autofocus: true,
          style: GoogleFonts.inter(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: 'Edit your message...',
            hintStyle: GoogleFonts.inter(color: context.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty) return;
              Navigator.pop(ctx);

              // Optimistic UI update
              setState(() {
                for (final msg in _allMessages) {
                  if (msg['id'] == messageId) {
                    msg['text'] = newText;
                    break;
                  }
                }
              });

              final dbService =
                  Provider.of<DatabaseService>(context, listen: false);
              final ok = await dbService.editMessage(
                  messageId, _realtimeOtherUser.id, newText);
              if (!ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Failed to edit message.'),
                  backgroundColor: Colors.redAccent,
                ));
              }
            },
            child: Text('Save',
                style: GoogleFonts.inter(
                    color: context.primaryAccent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ Delete message â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _confirmDeleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text('Delete Message?',
            style: GoogleFonts.inter(color: context.textPrimary)),
        content: Text(
            'Are you sure you want to delete this message? This action cannot be undone.',
            style: GoogleFonts.inter(color: context.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // Optimistically hide the message immediately
              setState(() {
                _deletedIds.add(messageId);
                _pendingMessages.removeWhere((m) => m['id'] == messageId);
              });

              final dbService =
                  Provider.of<DatabaseService>(context, listen: false);
              final ok = await dbService.deleteMessage(messageId);
              if (!ok && mounted) {
                // Revert on failure
                setState(() => _deletedIds.remove(messageId));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Failed to delete message.'),
                  backgroundColor: Colors.redAccent,
                ));
              }
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ Message action menu â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showMessageActionMenu(Map<String, dynamic> msg) {
    final bool isMe = msg['isMe'] as bool;
    final String? text = msg['text'] as String?;
    final String? mediaUrl = msg['media_url'] as String?;
    final String messageId = msg['id'] as String;
    final bool isSending = msg['is_sending'] as bool? ?? false;

    if (isSending) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            // Reply
            ListTile(
              leading:
                  Icon(Icons.reply_rounded, color: context.primaryAccent),
              title: Text('Reply',
                  style: GoogleFonts.inter(color: context.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _replyingToMessage = msg);
              },
            ),
            // Copy
            if (text != null && text.isNotEmpty)
              ListTile(
                leading:
                    Icon(Icons.copy_rounded, color: context.primaryAccent),
                title: Text('Copy',
                    style: GoogleFonts.inter(color: context.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ));
                },
              ),
            // Edit (own text messages only)
            if (isMe &&
                text != null &&
                text.isNotEmpty &&
                (mediaUrl == null || mediaUrl.isEmpty))
              ListTile(
                leading:
                    Icon(Icons.edit_rounded, color: context.primaryAccent),
                title: Text('Edit',
                    style: GoogleFonts.inter(color: context.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditMessageDialog(messageId, text);
                },
              ),
            // Delete (own messages)
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_rounded,
                    color: Colors.redAccent),
                title: Text('Delete',
                    style: GoogleFonts.inter(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteMessage(messageId);
                },
              ),
            // Download media
            if (mediaUrl != null && mediaUrl.isNotEmpty)
              ListTile(
                leading: Icon(Icons.download_rounded,
                    color: context.primaryAccent),
                title: Text('Download',
                    style: GoogleFonts.inter(color: context.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _downloadMedia(mediaUrl);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadMedia(String url) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Downloading image...', style: GoogleFonts.inter()),
      backgroundColor: context.primaryAccent,
    ));
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Image downloaded to gallery successfully!'),
        backgroundColor: Colors.green,
      ));
    }
  }

  void _openFullScreenMedia(String mediaUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => FullScreenMediaViewer(mediaUrl: mediaUrl)),
    );
  }

  // â”€â”€â”€ Confirm block/delete conversation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _confirmBlockUser() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text('Block User?',
            style: GoogleFonts.inter(color: context.textPrimary)),
        content: Text(
            'Are you sure you want to block ${widget.otherUser.fullName}?',
            style: GoogleFonts.inter(color: context.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final settings =
                  Provider.of<GeneralSettingsProvider>(context, listen: false);
              await settings.blockUserById(widget.otherUser.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      '${widget.otherUser.fullName} has been blocked.'),
                  backgroundColor: Colors.redAccent,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Block',
                style: TextStyle(color: Colors.redAccent)),
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
        title: Text('Delete Conversation?',
            style: GoogleFonts.inter(color: context.textPrimary)),
        content: Text(
            'Are you sure you want to delete all messages? This action is permanent.',
            style: GoogleFonts.inter(color: context.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: context.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db =
                  Provider.of<DatabaseService>(context, listen: false);
              final success =
                  await db.deleteConversation(widget.otherUser.id);
              if (mounted) {
                if (success) {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Failed to delete conversation.'),
                    backgroundColor: Colors.orangeAccent,
                  ));
                }
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ Messenger info bottom sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showMessengerProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final sharedMedia = _allMessages
            .where((m) =>
                m['media_url'] != null &&
                (m['media_url'] as String).isNotEmpty)
            .toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    backgroundImage: widget.otherUser.avatarUrl != null &&
                            widget.otherUser.avatarUrl!.isNotEmpty
                        ? NetworkImage(widget.otherUser.avatarUrl!)
                        : null,
                    child: (widget.otherUser.avatarUrl == null ||
                            widget.otherUser.avatarUrl!.isEmpty)
                        ? Icon(Icons.person_rounded,
                            size: 48, color: context.textMuted)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.otherUser.fullName,
                        style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary),
                      ),
                      if (widget.otherUser.isVerified) ...{
                        const SizedBox(width: 6),
                        const Icon(Icons.verified,
                            color: Colors.blue, size: 18),
                      },
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('@${widget.otherUser.username}',
                      style: GoogleFonts.inter(
                          fontSize: 13.5, color: context.textMuted)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${widget.otherUser.followingCount}',
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
                      Text('${widget.otherUser.followersCount}',
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
                  if (widget.otherUser.bio != null &&
                      widget.otherUser.bio!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.otherUser.bio!,
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
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfileScreen(
                                    userId: widget.otherUser.id),
                              ),
                            );
                          },
                          icon: Icon(Icons.person_outline,
                              color: context.primaryAccent, size: 16),
                          label: Text('Profile',
                              style: GoogleFonts.inter(
                                  color: context.primaryAccent,
                                  fontSize: 13)),
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
                              _toggleMute(!_isMuted);
                              setMuteState(() {});
                            },
                            icon: Icon(
                                _isMuted
                                    ? Icons.notifications_off_outlined
                                    : Icons.notifications_outlined,
                                color: context.primaryAccent,
                                size: 16),
                            label: Text(_isMuted ? 'Unmute' : 'Mute',
                                style: GoogleFonts.inter(
                                    color: context.primaryAccent,
                                    fontSize: 13)),
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
                    leading: const Icon(Icons.block_rounded,
                        color: Colors.redAccent),
                    title: Text('Block User',
                        style: GoogleFonts.inter(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmBlockUser();
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    tileColor: Colors.redAccent.withValues(alpha: 0.05),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    title: Text('Delete Conversation',
                        style: GoogleFonts.inter(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmDeleteConversation();
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    tileColor: Colors.redAccent.withValues(alpha: 0.05),
                  ),
                  if (sharedMedia.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Shared Media',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: context.textPrimary)),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4),
                      itemCount:
                          sharedMedia.length > 9 ? 9 : sharedMedia.length,
                      itemBuilder: (context, i) {
                        final m = sharedMedia[i];
                        final url = m['media_url'] as String;
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _openFullScreenMedia(url);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    color: context.border,
                                    child: Icon(Icons.broken_image,
                                        color: context.textMuted))),
                          ),
                        );
                      },
                    ),
                  ],
                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String _formatToDhaka12Hr(DateTime dt) {
    final dhakaTime = dt.toUtc().add(const Duration(hours: 6));
    final hour24 = dhakaTime.hour;
    final minute = dhakaTime.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    int hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    return '$hour12:$minute $period';
  }

  // â”€â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    // Only watch GeneralSettingsProvider (not DatabaseService) to prevent
    // full rebuilds on unrelated database notifyListeners() calls.
    final settings =
        Provider.of<GeneralSettingsProvider>(context, listen: true);
    final myActiveStatusEnabled = settings.isActiveStatusEnabled;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 600;

    final db = Provider.of<DatabaseService>(context, listen: false);
    final bool isBlocked = context.select<DatabaseService, bool>(
        (db) => db.blockedUserIds.contains(widget.otherUser.id));
    final bool blockedByMe = context.select<DatabaseService, bool>(
        (db) => db.blockedByMeIds.contains(widget.otherUser.id));

    final bool otherIsActive = _realtimeOtherUser.isActiveStatusEnabled &&
        _realtimeOtherUser.lastSeen != null &&
        DateTime.now().difference(_realtimeOtherUser.lastSeen!).inMinutes <= 5;

    final bool showGreenDot = myActiveStatusEnabled && otherIsActive;

    String statusText = 'Offline';
    if (_realtimeOtherUser.isActiveStatusEnabled) {
      if (otherIsActive) {
        statusText = 'Active now';
      } else if (_realtimeOtherUser.lastSeen != null) {
        final diff = DateTime.now().difference(_realtimeOtherUser.lastSeen!);
        if (diff.inMinutes < 60) {
          statusText = 'Active ${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          statusText = 'Active ${diff.inHours}h ago';
        } else {
          statusText = 'Active ${diff.inDays}d ago';
        }
      }
    }

    Widget mainContent = Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.textPrimary, size: 18),
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
                      backgroundImage:
                          _realtimeOtherUser.avatarUrl != null &&
                                  _realtimeOtherUser.avatarUrl!.isNotEmpty
                              ? NetworkImage(_realtimeOtherUser.avatarUrl!)
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
                            border: Border.all(
                                color: context.scaffoldBg, width: 1.5),
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
                              _realtimeOtherUser.fullName,
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_realtimeOtherUser.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                color: Colors.blue, size: 15),
                          ],
                        ],
                      ),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: otherIsActive
                              ? Colors.green
                              : context.textMuted,
                          fontWeight: otherIsActive
                              ? FontWeight.w600
                              : FontWeight.normal,
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
              icon: Icon(Icons.phone_outlined,
                  color: context.textPrimary, size: 21),
              onPressed: () => _showComingSoon('Audio'),
            ),
            IconButton(
              icon: Icon(Icons.videocam_outlined,
                  color: context.textPrimary, size: 22),
              onPressed: () => _showComingSoon('Video'),
            ),
          ],
          IconButton(
            icon: Icon(Icons.info_outlined,
                color: context.textPrimary, size: 20),
            onPressed: _showMessengerProfile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // â”€â”€ Message list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Expanded(
            child: _MessageList(
              stream: _messagesStream,
              pendingMessages: _pendingMessages,
              deletedIds: _deletedIds,
              scrollController: _scrollController,
              onAllMessagesUpdated: (msgs) {
                _allMessages = msgs;
              },
              onScrollToBottom: () => _scrollToBottom(animated: false),
              onMessageAction: _showMessageActionMenu,
              onReply: (msg) => setState(() => _replyingToMessage = msg),
              onOpenMedia: _openFullScreenMedia,
            ),
          ),

          // â”€â”€ Composer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          isBlocked
              ? _buildBlockedBanner(context, blockedByMe, db)
              : _ChatComposer(
                  replyingToMessage: _replyingToMessage,
                  realtimeOtherUser: _realtimeOtherUser,
                  showEmojiPanel: _showEmojiPanel,
                  pickerTabIndex: _pickerTabIndex,
                  onSend: (text, parent) => _sendMessage(text, parent),
                  onPickMedia: _sendMediaMessage,
                  onClearReply: () =>
                      setState(() => _replyingToMessage = null),
                  onToggleEmojiPanel: (show, tabIdx) => setState(() {
                    _showEmojiPanel = show;
                    _pickerTabIndex = tabIdx;
                  }),
                  onGifSelected: (gifUrl) => _sendGifMessage(gifUrl),
                ),
        ],
      ),
    );

    if (isWide) {
      mainContent = Center(
        child: Container(
          width: 600,
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: context.scaffoldBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: context.border, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: mainContent,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isWide ? context.cardBg : context.scaffoldBg,
      body: mainContent,
    );
  }

  Widget _buildBlockedBanner(
      BuildContext context, bool blockedByMe, DatabaseService db) {
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
            style:
                GoogleFonts.inter(fontSize: 13, color: context.textMuted),
            textAlign: TextAlign.center,
          ),
          if (blockedByMe) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final settingsProvider =
                    Provider.of<GeneralSettingsProvider>(context,
                        listen: false);
                await settingsProvider.unblockAccount(widget.otherUser.id);
                await db.fetchBlockedMutedLists();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        '@${widget.otherUser.username} has been unblocked.'),
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

// â”€â”€â”€ Isolated Message List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// This is a separate StatefulWidget so the stream update NEVER causes the
// composer or the AppBar to rebuild.
class _MessageList extends StatefulWidget {
  final Stream<List<Map<String, dynamic>>> stream;
  final List<Map<String, dynamic>> pendingMessages;
  final Set<String> deletedIds;
  final ScrollController scrollController;
  final void Function(List<Map<String, dynamic>>) onAllMessagesUpdated;
  final VoidCallback onScrollToBottom;
  final void Function(Map<String, dynamic>) onMessageAction;
  final void Function(Map<String, dynamic>) onReply;
  final void Function(String) onOpenMedia;

  const _MessageList({
    required this.stream,
    required this.pendingMessages,
    required this.deletedIds,
    required this.scrollController,
    required this.onAllMessagesUpdated,
    required this.onScrollToBottom,
    required this.onMessageAction,
    required this.onReply,
    required this.onOpenMedia,
  });

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(
                  color: context.primaryAccent));
        }

        final messages = snapshot.data ?? [];
        widget.onAllMessagesUpdated(messages);

        // Merge stream + pending, skip already-confirmed and deleted
        final List<Map<String, dynamic>> display =
            List<Map<String, dynamic>>.from(messages)
              ..removeWhere((m) => widget.deletedIds.contains(m['id']));

        final List<String> idsToRemove = [];
        for (final pm in widget.pendingMessages) {
          final pmId = pm['id'] as String;
          if (widget.deletedIds.contains(pmId)) continue;
          final alreadyIn = messages.any((m) {
            final mText = m['text'] as String? ?? '';
            final pmText = pm['text'] as String? ?? '';
            final mMedia = m['media_url'] as String? ?? '';
            final pmMedia = pm['media_url'] as String? ?? '';
            return m['id'] == pmId ||
                (mText == pmText && mMedia == pmMedia && m['isMe'] == true);
          });
          if (alreadyIn) {
            idsToRemove.add(pmId);
          } else {
            display.add(pm);
          }
        }

        if (idsToRemove.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Notify parent to remove from pending
              widget.pendingMessages
                  .removeWhere((m) => idsToRemove.contains(m['id']));
            }
          });
        }

        // Scroll to bottom when new data arrives
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onScrollToBottom();
        });

        if (display.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined, size: 48, color: context.textMuted),
                const SizedBox(height: 12),
                Text('Send a message to start the conversation.',
                    style: GoogleFonts.inter(color: context.textMuted)),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: widget.scrollController,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: display.length,
          // RepaintBoundary prevents individual message rebuilds from
          // propagating up to the ListView.
          itemBuilder: (context, index) {
            final msg = display[index];
            return RepaintBoundary(
              child: _MessageBubble(
                key: ValueKey(msg['id']),
                msg: msg,
                onTap: () => widget.onMessageAction(msg),
                onReply: () => widget.onReply(msg),
                onOpenMedia: widget.onOpenMedia,
              ),
            );
          },
        );
      },
    );
  }
}

// â”€â”€â”€ Message Bubble â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final VoidCallback onTap;
  final VoidCallback onReply;
  final void Function(String) onOpenMedia;

  const _MessageBubble({
    super.key,
    required this.msg,
    required this.onTap,
    required this.onReply,
    required this.onOpenMedia,
  });  @override
  Widget build(BuildContext context) {
    final bool isMe = msg['isMe'] as bool;
    final String? mediaUrl = msg['media_url'] as String?;
    final localMediaBytes = msg['local_media_bytes'];
    final bool isRead = msg['is_read'] as bool? ?? false;
    final bool isSending = msg['is_sending'] as bool? ?? false;
    final String? replyToId = msg['reply_to_id'] as String?;
    final String? replyToText = msg['reply_to_text'] as String?;
    final String? replyToSender = msg['reply_to_sender'] as String?;
    final String? text = msg['text'] as String?;

    final bool hasMedia = localMediaBytes != null || (mediaUrl != null && mediaUrl.isNotEmpty);

    String timeStr = msg['time'] as String;
    if (msg['created_at'] != null) {
      try {
        final dt = DateTime.parse(msg['created_at'] as String);
        // Convert to Dhaka Time (GMT+6)
        final dhakaTime = dt.toUtc().add(const Duration(hours: 6));
        final hour24 = dhakaTime.hour;
        final minute = dhakaTime.minute.toString().padLeft(2, '0');
        final period = hour24 >= 12 ? 'PM' : 'AM';
        int hour12 = hour24 % 12;
        if (hour12 == 0) hour12 = 12;
        timeStr = '$hour12:$minute $period';
      } catch (_) {}
    }

    Widget buildTimeRow({required bool overlayMode}) {
      final textStyle = GoogleFonts.inter(
        fontSize: overlayMode ? 9.5 : 10,
        color: overlayMode
            ? Colors.white
            : (isMe ? Colors.white60 : context.textMuted),
      );

      final iconColor = overlayMode
          ? (isSending
              ? Colors.white.withValues(alpha: 0.5)
              : (isRead ? Colors.greenAccent : Colors.white.withValues(alpha: 0.8)))
          : (isSending
              ? Colors.white54
              : (isRead ? Colors.greenAccent : Colors.white60));

      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(timeStr, style: textStyle),
          if (isMe) ...[
            const SizedBox(width: 4),
            Icon(
              isSending
                  ? Icons.schedule_rounded
                  : (isRead ? Icons.done_all : Icons.done),
              size: 12,
              color: iconColor,
            ),
          ],
        ],
      );
    }

    Widget buildImageWidget(dynamic bytesOrUrl) {
      final clipRadius = BorderRadius.only(
        topLeft: replyToId == null ? const Radius.circular(16) : Radius.zero,
        topRight: replyToId == null ? const Radius.circular(16) : Radius.zero,
        bottomLeft: (text == null || text.isEmpty)
            ? (isMe ? const Radius.circular(16) : Radius.zero)
            : Radius.zero,
        bottomRight: (text == null || text.isEmpty)
            ? (isMe ? Radius.zero : const Radius.circular(16))
            : Radius.zero,
      );

      final image = bytesOrUrl is Uint8List
          ? Image.memory(
              bytesOrUrl,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
            )
          : Image.network(
              bytesOrUrl as String,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 50),
            );

      final imageWidget = bytesOrUrl is Uint8List
          ? image
          : GestureDetector(
              onTap: () => onOpenMedia(bytesOrUrl as String),
              child: image,
            );

      if (text == null || text.isEmpty) {
        // Overlay time row on top of image
        return ClipRRect(
          borderRadius: clipRadius,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              imageWidget,
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: buildTimeRow(overlayMode: true),
                ),
              ),
            ],
          ),
        );
      } else {
        // No overlay, just image
        return ClipRRect(
          borderRadius: clipRadius,
          child: imageWidget,
        );
      }
    }

    Widget bubbleContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Reply quote
        if (replyToId != null)
          Padding(
            padding: hasMedia
                ? const EdgeInsets.fromLTRB(12, 10, 12, 6)
                : EdgeInsets.zero,
            child: Container(
              margin: hasMedia ? EdgeInsets.zero : const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.15)
                    : (context.isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: isMe
                        ? Colors.white70
                        : context.primaryAccent,
                    width: 3.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    replyToSender ?? 'Someone',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isMe
                          ? Colors.white
                          : context.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    replyToText ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: isMe
                          ? Colors.white70
                          : context.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        // Media (image / GIF)
        if (localMediaBytes != null) ...[
          buildImageWidget(localMediaBytes),
          if (text != null && text.isNotEmpty)
            const SizedBox(height: 8),
        ] else if (mediaUrl != null && mediaUrl.isNotEmpty) ...[
          buildImageWidget(mediaUrl),
          if (text != null && text.isNotEmpty)
            const SizedBox(height: 8),
        ],
        // Text
        if (text != null && text.isNotEmpty)
          Padding(
            padding: hasMedia
                ? const EdgeInsets.fromLTRB(12, 6, 12, 4)
                : EdgeInsets.zero,
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                color:
                    isMe ? Colors.white : context.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        // Time + read receipt (only if NOT overlayed on media)
        if (!hasMedia || (text != null && text.isNotEmpty))
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: hasMedia
                  ? const EdgeInsets.only(right: 4, bottom: 2, top: 1, left: 12)
                  : const EdgeInsets.only(top: 2, left: 16),
              child: buildTimeRow(overlayMode: false),
            ),
          ),
      ],
    );

    if (!hasMedia) {
      bubbleContent = IntrinsicWidth(child: bubbleContent);
    }

    return SwipeToReply(
      onReply: onReply,
      isMe: isMe,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          constraints: BoxConstraints(
              maxWidth: (MediaQuery.of(context).size.width * 0.75).clamp(200.0, 450.0)),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: hasMedia
                  ? EdgeInsets.zero
                  : const EdgeInsets.fromLTRB(12, 8, 8, 4),
              decoration: BoxDecoration(
                color: isMe ? context.primaryAccent : context.cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe
                      ? const Radius.circular(16)
                      : const Radius.circular(0),
                  bottomRight: isMe
                      ? const Radius.circular(0)
                      : const Radius.circular(16),
                ),
                border: isMe
                    ? null
                    : Border.all(color: context.border, width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: bubbleContent,
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Chat Composer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Completely isolated widget. Only rebuilds when its own state changes,
// NOT when messages arrive. The input field is local â€” no external setState.
class _ChatComposer extends StatefulWidget {
  final Map<String, dynamic>? replyingToMessage;
  final Profile realtimeOtherUser;
  final bool showEmojiPanel;
  final int pickerTabIndex;
  final void Function(String text, Map<String, dynamic>? parent) onSend;
  final VoidCallback onPickMedia;
  final VoidCallback onClearReply;
  final void Function(bool show, int tabIdx) onToggleEmojiPanel;
  final void Function(String gifUrl) onGifSelected;

  const _ChatComposer({
    required this.replyingToMessage,
    required this.realtimeOtherUser,
    required this.showEmojiPanel,
    required this.pickerTabIndex,
    required this.onSend,
    required this.onPickMedia,
    required this.onClearReply,
    required this.onToggleEmojiPanel,
    required this.onGifSelected,
  });

  @override
  State<_ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<_ChatComposer> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text, widget.replyingToMessage);
    _ctrl.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.border, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply bar
          if (widget.replyingToMessage != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: context.isDarkMode
                  ? Colors.black26
                  : Colors.grey[100],
              width: double.infinity,
              child: Row(
                children: [
                  Icon(Icons.reply, size: 14, color: context.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to ${widget.replyingToMessage!['isMe'] == true ? 'You' : widget.realtimeOtherUser.fullName}: ${widget.replyingToMessage!['text'] ?? ''}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: context.textSecondary,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onClearReply,
                    child: Icon(Icons.close_rounded,
                        size: 16, color: context.textSecondary),
                  ),
                ],
              ),
            ),

          // Input row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? const Color(0xFF151824)
                          : const Color(0xFFF3F5F4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.border, width: 0.8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focusNode,
                      onTap: () {
                        if (widget.showEmojiPanel) {
                          widget.onToggleEmojiPanel(false, 0);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Write a message...',
                        hintStyle: GoogleFonts.inter(
                            color: context.textMuted, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: GoogleFonts.inter(
                          fontSize: 14.5, color: context.textPrimary),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: context.primaryAccent,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 16),
                      onPressed: _send,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Icon strip: Gallery | GIF | Emoji
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Row(
              children: [
                _ToolbarBtn(
                  icon: Icons.image_outlined,
                  onTap: widget.onPickMedia,
                  color: context.primaryAccent,
                ),
                const SizedBox(width: 8),
                _ToolbarBtn(
                  icon: Icons.gif_box_outlined,
                  onTap: () {
                    _focusNode.unfocus();
                    widget.onToggleEmojiPanel(
                      !(widget.showEmojiPanel &&
                          widget.pickerTabIndex == 1),
                      1,
                    );
                  },
                  color: context.primaryAccent,
                ),
                const SizedBox(width: 8),
                _ToolbarBtn(
                  icon: widget.showEmojiPanel && widget.pickerTabIndex == 0
                      ? Icons.keyboard_hide_outlined
                      : Icons.sentiment_satisfied_alt_outlined,
                  onTap: () {
                    _focusNode.unfocus();
                    widget.onToggleEmojiPanel(
                      !(widget.showEmojiPanel &&
                          widget.pickerTabIndex == 0),
                      0,
                    );
                  },
                  color: context.primaryAccent,
                ),
              ],
            ),
          ),

          // Emoji / GIF picker
          if (widget.showEmojiPanel)
            CommentAttachmentPickerPanel(
              initialTabIndex: widget.pickerTabIndex,
              onEmojiSelected: (emoji) {
                final text = _ctrl.text;
                final selection = _ctrl.selection;
                if (!selection.isValid) {
                  _ctrl.text = text + emoji;
                  _ctrl.selection = TextSelection.collapsed(
                      offset: _ctrl.text.length);
                } else {
                  final start = selection.start;
                  final end = selection.end;
                  _ctrl.text = text.replaceRange(start, end, emoji);
                  _ctrl.selection = TextSelection.collapsed(
                      offset: start + emoji.length);
                }
              },
              onGifSelected: (gifUrl) {
                widget.onToggleEmojiPanel(false, 0);
                widget.onGifSelected(gifUrl);
              },
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ToolbarBtn({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }
}

// â”€â”€â”€ Full-screen Media Viewer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class FullScreenMediaViewer extends StatelessWidget {
  final String mediaUrl;
  const FullScreenMediaViewer({super.key, required this.mediaUrl});

  Future<void> _downloadImage(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Downloading image...', style: GoogleFonts.inter()),
      backgroundColor: Theme.of(context).colorScheme.primary,
    ));
    await Future.delayed(const Duration(milliseconds: 1500));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Image downloaded to gallery successfully!'),
        backgroundColor: Colors.green,
      ));
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

// â”€â”€â”€ Swipe to Reply â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final bool isMe;

  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    required this.isMe,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> {
  double _dragOffset = 0.0;
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    const double maxDrag = 80.0;
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, maxDrag);
          if (_dragOffset >= 50.0 && !_triggered) {
            _triggered = true;
            HapticFeedback.lightImpact();
          }
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragOffset >= 50.0) widget.onReply();
        setState(() {
          _dragOffset = 0.0;
          _triggered = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(_dragOffset, 0, 0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -40,
              top: 0,
              bottom: 0,
              child: const Center(
                child: Icon(Icons.reply_rounded, color: Colors.grey, size: 20),
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}
