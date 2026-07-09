import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/app_theme.dart';
import 'message_bubble.dart';


class MessageList extends StatefulWidget {
  final Stream<List<Map<String, dynamic>>> stream;
  final List<Map<String, dynamic>> pendingMessages;
  final Set<String> deletedIds;
  final ScrollController scrollController;
  final void Function(List<Map<String, dynamic>>) onAllMessagesUpdated;
  final VoidCallback onScrollToBottom;
  final void Function(Map<String, dynamic>) onMessageAction;
  final void Function(Map<String, dynamic>) onReply;
  final void Function(String) onOpenMedia;

  const MessageList({super.key, required this.stream,
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
  State<MessageList> createState() => MessageListState();
}

class MessageListState extends State<MessageList> {
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

        final List<Map<String, dynamic>> reversedDisplay = display.reversed.toList();

        return ListView.builder(
          reverse: true,
          controller: widget.scrollController,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: reversedDisplay.length,
          // RepaintBoundary prevents individual message rebuilds from
          // propagating up to the ListView.
          itemBuilder: (context, index) {
            final msg = reversedDisplay[index];
            return RepaintBoundary(
              child: MessageBubble(
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