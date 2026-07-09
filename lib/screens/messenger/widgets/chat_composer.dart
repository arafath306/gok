import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_theme.dart';
import '../../../models/profile.dart';
import '../../../services/database_service.dart';
import '../../../widgets/comment_attachment_picker_panel.dart';


class ChatComposer extends StatefulWidget {
  final Map<String, dynamic>? replyingToMessage;
  final Profile realtimeOtherUser;
  final bool showEmojiPanel;
  final int pickerTabIndex;
  final void Function(String text, Map<String, dynamic>? parent) onSend;
  final VoidCallback onPickMedia;
  final VoidCallback onClearReply;
  final void Function(bool show, int tabIdx) onToggleEmojiPanel;
  final void Function(String gifUrl) onGifSelected;

  const ChatComposer({super.key, required this.replyingToMessage,
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
  State<ChatComposer> createState() => ChatComposerState();
}

class ChatComposerState extends State<ChatComposer> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);

      if (has) {
        if (!_isTyping) {
          _isTyping = true;
          Provider.of<DatabaseService>(context, listen: false)
              .sendTypingEvent(widget.realtimeOtherUser.id, true);
        }
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 2), () {
          if (_isTyping) {
            _isTyping = false;
            if (mounted) {
              Provider.of<DatabaseService>(context, listen: false)
                  .sendTypingEvent(widget.realtimeOtherUser.id, false);
            }
          }
        });
      } else {
        if (_isTyping) {
          _isTyping = false;
          _typingTimer?.cancel();
          Provider.of<DatabaseService>(context, listen: false)
              .sendTypingEvent(widget.realtimeOtherUser.id, false);
        }
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_isTyping) {
      Provider.of<DatabaseService>(context, listen: false)
          .sendTypingEvent(widget.realtimeOtherUser.id, false);
    }
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
                ToolbarBtn(
                  icon: Icons.image_outlined,
                  onTap: widget.onPickMedia,
                  color: context.primaryAccent,
                ),
                const SizedBox(width: 8),
                ToolbarBtn(
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
                ToolbarBtn(
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

class ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const ToolbarBtn({super.key, required this.icon,
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