import 'package:flutter/material.dart';
import 'package:flutter/services.dart';



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
