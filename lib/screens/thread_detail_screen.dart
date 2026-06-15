import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/thread_post.dart';
import '../models/profile.dart';
import '../services/database_service.dart';
import '../widgets/comments_sheet.dart';
import '../utils/routes.dart';
import '../utils/app_theme.dart';
import 'profile/profile_screen.dart';
import 'package:flutter/services.dart';

class ThreadDetailScreen extends StatefulWidget {
  final ThreadPost post;

  const ThreadDetailScreen({super.key, required this.post});

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  final _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final dbComments = await dbService.fetchComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = dbComments;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint("Load comments error: $e");
      if (mounted) {
        setState(() {
          _comments = [];
          _isLoadingComments = false;
        });
      }
    }
  }

  void _showQuickActions(BuildContext context, Map<String, dynamic> comment, DatabaseService dbService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 350),
      ),
      builder: (sheetContext) => CommentQuickActionsSheet(
        comment: comment,
        dbService: dbService,
        onCommentHidden: (id) {
          setState(() {
            _comments.removeWhere((c) => c['id'] == id);
          });
        },
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'এখনই';
      if (diff.inMinutes < 60) return '${diff.inMinutes}মি';
      if (diff.inHours < 24) return '${diff.inHours}ঘ';
      if (diff.inDays < 7) return '${diff.inDays}দিন';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  void _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final success = await dbService.addComment(widget.post.id, text);
      if (success) {
        _commentController.clear();
        _loadComments();
      }
    } catch (e) {
      debugPrint("Post comment error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("মন্তব্য পোস্ট করতে ব্যর্থ হয়েছে: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);

    // Find the latest post representation in the feed list to match like status
    final feedIndex = dbService.feed.indexWhere((p) => p.id == widget.post.id);
    final activePost = feedIndex != -1 ? dbService.feed[feedIndex] : widget.post;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: context.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Thread Detail Card
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Details Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(
                            activePost.author.avatarUrl ?? "https://i.pravatar.cc/150",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        NoTransitionPageRoute(
                                          child: ProfileScreen(userId: activePost.userId),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          activePost.author.fullName,
                                          style: GoogleFonts.hindSiliguri(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        if (activePost.author.fullName == 'Dak Official') ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.verified,
                                            color: Colors.blue,
                                            size: 14,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (activePost.userId != dbService.currentUid) ...[
                                    const SizedBox(width: 8),
                                    _buildFollowButton(context, dbService, activePost.userId),
                                  ],
                                ],
                              ),
                              Text(
                                "@${activePost.author.username}",
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.more_horiz, color: context.textSecondary),
                      ],
                    ),
                  ),

                  // Post content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activePost.content,
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 16,
                            color: context.textPrimary,
                          ),
                        ),
                        if (activePost.imageUrls != null && activePost.imageUrls!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.network(
                              activePost.imageUrls!.first,
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          _formatTime(activePost.createdAt),
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Divider(height: 24, color: context.border),

                        // Likes/Comments Count row
                        Row(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "${activePost.likesCount} ",
                                  style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
                                ),
                                Text("পছন্দ (Likes)   ", style: TextStyle(color: context.textSecondary)),
                              ],
                            ),
                            Text(
                              "${_comments.length} ",
                              style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
                            ),
                            Text("মন্তব্য (Replies)", style: TextStyle(color: context.textSecondary)),
                          ],
                        ),
                        Divider(height: 24, color: context.border),

                        // Quick Actions Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                dbService.toggleLike(activePost.id, !activePost.isLikedByMe);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, animation) =>
                                      ScaleTransition(scale: animation, child: child),
                                  child: activePost.isLikedByMe
                                      ? Text(
                                          activePost.reactionType ?? '❤️',
                                          key: ValueKey<String>(activePost.reactionType ?? '❤️'),
                                          style: const TextStyle(fontSize: 22),
                                        )
                                      : Icon(
                                          Icons.favorite_border,
                                          key: const ValueKey<int>(0),
                                          color: context.textSecondary,
                                          size: 24,
                                        ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.chat_bubble_outline, color: context.textSecondary),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Icon(Icons.swap_horiz, color: context.textSecondary),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Icon(Icons.send_outlined, color: context.textSecondary),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Comments section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    color: context.isDarkMode ? const Color(0xFF0A0B10) : Colors.grey[50],
                    child: Text(
                      "মন্তব্যসমূহ",
                      style: GoogleFonts.hindSiliguri(
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                      ),
                    ),
                  ),

                  // Comments List
                  if (_isLoadingComments)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF1E824C))),
                    )
                  else if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          "কোন মন্তব্য পাওয়া যায়নি।",
                          style: GoogleFonts.hindSiliguri(color: context.textSecondary),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final Profile author = comment['author'] as Profile;
                        final isPostAuthor = author.id == widget.post.userId;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: NetworkImage(
                                  author.avatarUrl ?? "https://i.pravatar.cc/150",
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                NoTransitionPageRoute(
                                                  child: ProfileScreen(userId: author.id),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              author.fullName,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.hindSiliguri(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.5,
                                                color: context.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (author.fullName == 'Dak Official') ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.verified,
                                            color: Colors.blue,
                                            size: 15,
                                          ),
                                        ],
                                        const SizedBox(width: 4),
                                        Text(
                                          "@${author.username} · ${_formatTime(comment['created_at'] ?? '')}",
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                        if (isPostAuthor) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E824C).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              "Author",
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF1E824C),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        IconButton(
                                          icon: Icon(Icons.more_horiz, size: 18, color: context.textSecondary),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _showQuickActions(context, comment, dbService),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment['content'] as String? ?? '',
                                      style: GoogleFonts.hindSiliguri(
                                        fontSize: 14,
                                        color: context.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // Actions inside comment item
                                    Row(
                                      children: [
                                        // Comment Reply
                                        GestureDetector(
                                          onTap: () {},
                                          child: Row(
                                            children: [
                                              Icon(Icons.chat_bubble_outline, size: 15, color: context.textSecondary),
                                              const SizedBox(width: 4),
                                              Text(
                                                "0",
                                                style: TextStyle(fontSize: 12, color: context.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        // Comment Like
                                        GestureDetector(
                                          onTap: () {},
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.favorite_border,
                                                size: 15,
                                                color: context.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "0",
                                                style: TextStyle(fontSize: 12, color: context.textSecondary),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Inline separator replies link mockup helper
                                    if (comment['id'] == 'mock-3') ...[
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4.0, top: 4.0, bottom: 8.0),
                                        child: Row(
                                          children: [
                                            const SizedBox(
                                              width: 12,
                                              child: Divider(color: Color(0xFF1E824C), thickness: 1.5),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "View 2 more replies",
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFF1E824C),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Bottom Input row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border(
                top: BorderSide(color: context.border),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.isDarkMode ? const Color(0xFF121422) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: GoogleFonts.hindSiliguri(fontSize: 14, color: context.textPrimary),
                            decoration: InputDecoration(
                              hintText: "কমেন্ট করুন...",
                              hintStyle: GoogleFonts.hindSiliguri(color: context.textMuted, fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        // Media actions and dynamic Send button inside the container
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _commentController,
                          builder: (context, value, child) {
                            final text = value.text.trim();
                            if (text.isNotEmpty) {
                              return IconButton(
                                icon: const Icon(Icons.send, color: Color(0xFF1E824C), size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _postComment,
                              );
                            } else {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.image_outlined, size: 18, color: context.textSecondary),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {},
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: Icon(Icons.gif_box_outlined, size: 18, color: context.textSecondary),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {},
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: Icon(Icons.sentiment_satisfied_alt_outlined, size: 18, color: context.textSecondary),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {},
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context, DatabaseService dbService, String targetUserId) {
    final isFollowing = dbService.isFollowingUser(targetUserId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => dbService.toggleFollowUser(targetUserId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: isFollowing 
              ? Colors.transparent 
              : (isDark ? Colors.white : Colors.black),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isFollowing 
                ? (isDark ? Colors.white24 : Colors.black12) 
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isFollowing 
                ? context.textPrimary 
                : (isDark ? Colors.black : Colors.white),
          ),
        ),
      ),
    );
  }
}
