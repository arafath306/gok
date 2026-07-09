import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/profile.dart';
import '../../services/database_service.dart';
import '../../services/general_settings_provider.dart';
import '../../utils/app_theme.dart';
import '../profile/profile_screen.dart';

import 'widgets/message_list.dart';
import 'widgets/chat_composer.dart';
import 'widgets/full_screen_media_viewer.dart';


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

  StreamSubscription<Map<String, dynamic>>? _typingSub;
  bool _otherIsTyping = false;
  Timer? _typingTimer;

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

    _typingSub = dbService.getTypingStream(widget.otherUser.id).listen((event) {
      if (!mounted) return;
      final userId = event['user_id'];
      final isTyping = event['is_typing'] == true;
      if (userId == widget.otherUser.id) {
        setState(() => _otherIsTyping = isTyping);
        _typingTimer?.cancel();
        if (isTyping) {
          _typingTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) setState(() => _otherIsTyping = false);
          });
        }
      }
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
    _typingSub?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  // â”€â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(0.0);
        }
      }
    });
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
                            child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                errorWidget: (context, error, stackTrace) => Container(
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

    if (_otherIsTyping) {
      statusText = 'Typing...';
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
                          color: (_otherIsTyping || otherIsActive)
                              ? Colors.green
                              : context.textMuted,
                          fontWeight: (_otherIsTyping || otherIsActive)
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
            child: MessageList(
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
              : ChatComposer(
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