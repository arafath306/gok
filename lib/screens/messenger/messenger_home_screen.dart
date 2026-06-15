import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/profile.dart';
import '../../utils/app_theme.dart';
import 'chat_screen.dart';
import 'chat_settings_screen.dart';
import 'member_search_sheet.dart';

class MessengerHomeScreen extends StatelessWidget {
  const MessengerHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: context.textPrimary, size: 24),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        titleSpacing: 0,
        title: Text(
          'Chats',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.mail_outline_rounded, color: context.textPrimary, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.textPrimary, size: 22),
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
          child: Container(color: context.border, height: 1.0),
        ),
      ),
      body: Consumer<DatabaseService>(
        builder: (context, dbService, _) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: dbService.fetchActiveChats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(color: context.primaryAccent),
                );
              }

              final activeChats = snapshot.data ?? [];

              if (activeChats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(60, 60),
                        painter: SpeechBubblePainter(color: context.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Say hi to someone',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimary,
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
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: activeChats.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
                itemBuilder: (context, index) {
                  final chat = activeChats[index];
                  final Profile profile = chat['profile'] as Profile;
                  final String lastMsg = chat['last_message'] as String;
                  final String time = chat['last_message_time'] as String;
                  final int unreadCount = chat['unread_count'] as int;

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(otherUser: profile),
                        ),
                      );
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: context.border,
                      backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                          ? NetworkImage(profile.avatarUrl!)
                          : const NetworkImage("https://i.pravatar.cc/150"),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            profile.fullName,
                            style: GoogleFonts.hindSiliguri(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          time,
                          style: GoogleFonts.inter(
                            color: unreadCount > 0 ? context.primaryAccent : context.textMuted,
                            fontSize: 12,
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMsg,
                              style: GoogleFonts.hindSiliguri(
                                color: unreadCount > 0 ? context.textPrimary : context.textSecondary,
                                fontSize: 13.5,
                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "$unreadCount",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
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
  final Color color;
  SpeechBubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
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
    final eyePaint = Paint()..color = color;
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.45), 2.5, eyePaint);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.45), 2.5, eyePaint);
    
    // Draw smile
    final smilePaint = Paint()
      ..color = color
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
