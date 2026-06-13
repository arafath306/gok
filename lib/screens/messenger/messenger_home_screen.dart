import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_settings_screen.dart';
import 'member_search_sheet.dart';

class MessengerHomeScreen extends StatelessWidget {
  const MessengerHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black87, size: 24),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        titleSpacing: 0,
        title: Text(
          'Chats',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline_rounded, color: Colors.black87, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatSettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFEEEEEE), height: 1.0),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom drawn smiley speech bubble
            CustomPaint(
              size: const Size(60, 60),
              painter: SpeechBubblePainter(),
            ),
            const SizedBox(height: 16),
            Text(
              'Say hi to someone',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MemberSearchSheet()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0085FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_comment_rounded, size: 18),
              label: Text(
                'New chat',
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MemberSearchSheet()),
          );
        },
        backgroundColor: const Color(0xFF0085FF),
        shape: const CircleBorder(),
        elevation: 3,
        child: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}

class SpeechBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 0.9);
    
    // Draw bubble
    path.addArc(rect, 0.75 * 3.14159, 1.75 * 3.14159);
    // Draw bubble tail
    path.lineTo(size.width * 0.15, size.height * 1.0);
    path.lineTo(size.width * 0.32, size.height * 0.85);
    path.close();
    canvas.drawPath(path, paint);
    
    // Draw eyes
    final eyePaint = Paint()..color = Colors.black87;
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.45), 2.5, eyePaint);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.45), 2.5, eyePaint);
    
    // Draw smile
    final smilePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    
    final smilePath = Path();
    smilePath.moveTo(size.width * 0.43, size.height * 0.56);
    smilePath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.66,
      size.width * 0.57,
      size.height * 0.56,
    );
    canvas.drawPath(smilePath, smilePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

