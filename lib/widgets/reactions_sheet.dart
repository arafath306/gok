import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/thread_post.dart';
import '../services/database_service.dart';
import '../screens/profile/profile_screen.dart';
import '../utils/routes.dart';

class ReactionsListSheet extends StatefulWidget {
  final ThreadPost post;

  const ReactionsListSheet({super.key, required this.post});

  @override
  State<ReactionsListSheet> createState() => _ReactionsListSheetState();
}

class _ReactionsListSheetState extends State<ReactionsListSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final List<Animation<double>> _emojiScaleAnims;
  final List<String> _emojis = ['❤️', '👍', '😂', '🥰', '😢', '😡', '✨'];
  
  List<Map<String, dynamic>> _reactors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Staggered animations for the 7 emojis
    _emojiScaleAnims = List.generate(_emojis.length, (index) {
      final start = (index * 0.08).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.elasticOut),
        ),
      );
    });

    _staggerController.forward();
    _loadReactors();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadReactors() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final reactorsList = await dbService.fetchThreadReactors(widget.post.id);
    if (mounted) {
      setState(() {
        _reactors = reactorsList;
        _isLoading = false;
      });
    }
  }

  void _onEmojiSelected(BuildContext context, String emoji) {
    HapticFeedback.lightImpact();
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    dbService.toggleLike(widget.post.id, true, reactionType: emoji);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Reacted successfully",
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1E824C),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildUserAvatar(String? avatarUrl, String fullName) {
    final initials = fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF1E824C), Color(0xFF1ABC9C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: Text(
                  initials,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Floating Animated Emoji Capsule Row
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_emojis.length, (index) {
                final emoji = _emojis[index];
                return ScaleTransition(
                  scale: _emojiScaleAnims[index],
                  child: GestureDetector(
                    onTap: () => _onEmojiSelected(context, emoji),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // Likes Count Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Text(
                  "${widget.post.likesCount > 0 ? widget.post.likesCount : _reactors.length} Likes",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // Reactors List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1E824C),
                    ),
                  )
                : ListView.builder(
                    itemCount: _reactors.length,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    itemBuilder: (context, index) {
                      final reactor = _reactors[index];
                      final reactorId = reactor['id'] as String;
                      final isFollowing = dbService.isFollowingUser(reactorId);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          children: [
                            _buildUserAvatar(reactor['avatar'] as String?, reactor['name'] as String),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.push(
                                        context,
                                        NoTransitionPageRoute(
                                          child: ProfileScreen(userId: reactorId),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      reactor['name'] as String,
                                      style: GoogleFonts.hindSiliguri(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    reactor['handle'] as String,
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey[500],
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                              
                              // Follow Button
                              if (reactorId != dbService.myProfile?.id)
                                SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      dbService.toggleFollowUser(reactorId);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isFollowing ? Colors.white : const Color(0xFF1E824C),
                                      foregroundColor: isFollowing ? Colors.black87 : Colors.white,
                                      elevation: 0,
                                      side: isFollowing
                                          ? const BorderSide(color: Color(0xFFD1D5DB), width: 1)
                                          : null,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    child: Text(
                                      isFollowing ? "Following" : "Follow",
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                  ),
          ),
        ],
      ),
    );
  }
}
