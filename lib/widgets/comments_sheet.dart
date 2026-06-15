import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/thread_post.dart';
import '../models/profile.dart';
import '../services/database_service.dart';
import '../screens/profile/profile_screen.dart';
import '../utils/app_theme.dart';

class CommentsSheet extends StatefulWidget {
  final ThreadPost post;
  const CommentsSheet({super.key, required this.post});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = false;
  String _sortBy = "Most relevant";

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

  String? _replyToCommentId;

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final comments = await dbService.fetchComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Load comments error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final dbService = Provider.of<DatabaseService>(context, listen: false);

    try {
      final success = await dbService.addComment(
        widget.post.id,
        text,
        parentId: _replyToCommentId,
      );
      if (success) {
        _commentController.clear();
        setState(() {
          _replyToCommentId = null;
        });
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

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final myProf = dbService.myProfile;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.grey[800] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Comments",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: context.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: context.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: context.border),

          // Sort Filter Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  dropdownColor: context.cardBg,
                  icon: Icon(Icons.keyboard_arrow_down, size: 18, color: context.textPrimary),
                  style: GoogleFonts.inter(
                    color: context.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  items: ["Most relevant", "Newest", "Oldest"].map((val) {
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(
                        val,
                        style: GoogleFonts.inter(color: context.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _sortBy = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          // Comments List / Loading Indicator
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1E824C),
                    ),
                  )
                : _comments.isEmpty
                    ? Center(
                        child: Text(
                          "কোন মন্তব্য পাওয়া যায়নি।",
                          style: GoogleFonts.hindSiliguri(color: context.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final Profile author = comment['author'] as Profile;
                          final isPostAuthor = author.id == widget.post.userId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Commenter Avatar
                                GestureDetector(
                                  onTap: () {
                                    final isOwn = author.id == (dbService.myProfile?.id ?? dbService.currentUid);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProfileScreen(userId: isOwn ? null : author.id),
                                      ),
                                    );
                                  },
                                  child: CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: NetworkImage(
                                      author.avatarUrl ?? "https://i.pravatar.cc/150",
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Comment details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Author Header Info Row
                                      Row(
                                        children: [
                                          Flexible(
                                            child: GestureDetector(
                                              onTap: () {
                                                final isOwn = author.id == (dbService.myProfile?.id ?? dbService.currentUid);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ProfileScreen(userId: isOwn ? null : author.id),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                author.fullName,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.hindSiliguri(
                                                  fontWeight: FontWeight.w700,
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
                                            "@${author.username} · ${comment['created_at']}",
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

                                      // Content Text
                                      Text(
                                        comment['content'] as String,
                                        style: GoogleFonts.hindSiliguri(
                                          fontSize: 14,
                                          color: context.textPrimary,
                                          height: 1.45,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Action Row
                                      Row(
                                        children: [
                                          // Comments/Replies metric
                                          GestureDetector(
                                            onTap: () {},
                                            child: Row(
                                              children: [
                                                Icon(Icons.chat_bubble_outline, size: 15, color: context.textSecondary),
                                                const SizedBox(width: 6),
                                                Text(
                                                  "${comment['replies_count'] ?? 0}",
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13, 
                                                    fontWeight: FontWeight.w500,
                                                    color: context.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          // Likes metric
                                          GestureDetector(
                                            onTap: () {
                                              final bool currentVal = comment['is_liked_by_me'] as bool? ?? false;
                                              final bool newVal = !currentVal;
                                              final int currentLikes = comment['likes_count'] as int? ?? 0;
                                              
                                              setState(() {
                                                comment['is_liked_by_me'] = newVal;
                                                comment['likes_count'] = newVal 
                                                    ? currentLikes + 1 
                                                    : (currentLikes > 0 ? currentLikes - 1 : 0);
                                              });
                                              dbService.toggleCommentLike(comment['id'] as String, newVal);
                                            },
                                            child: Icon(
                                              (comment['is_liked_by_me'] as bool? ?? false)
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              size: 15,
                                              color: (comment['is_liked_by_me'] as bool? ?? false)
                                                  ? Colors.red
                                                  : context.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          // Reply action button
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _replyToCommentId = comment['id'] as String?;
                                                _commentController.text = "@${author.username} ";
                                              });
                                            },
                                            child: Text(
                                              "Reply",
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: context.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Inline reply line separator styling
                                      // Inline reply line separator styling
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
                                      if (index < _comments.length - 1 && comment['id'] != 'mock-3') ...[
                                        const SizedBox(height: 12),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Sticky Bottom Input Composer
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: context.cardBg,
                border: Border(
                  top: BorderSide(color: context.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: context.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    backgroundImage: NetworkImage(
                      myProf?.avatarUrl ?? "https://i.pravatar.cc/150",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
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
                                hintText: "Write a comment...",
                                hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
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
                                  icon: const Icon(Icons.send, color: Color(0xFF7C4DFF), size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: _submitComment,
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
          ),
        ],
      ),
    );
  }
}

// ─── Comment Quick Actions Bottom Sheet (Twitter/X Style) ──────────────────────
class CommentQuickActionsSheet extends StatefulWidget {
  final Map<String, dynamic> comment;
  final DatabaseService dbService;
  final Function(String) onCommentHidden;

  const CommentQuickActionsSheet({
    super.key,
    required this.comment,
    required this.dbService,
    required this.onCommentHidden,
  });

  @override
  State<CommentQuickActionsSheet> createState() => CommentQuickActionsSheetState();
}

class CommentQuickActionsSheetState extends State<CommentQuickActionsSheet>
    with TickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final List<Animation<double>> _slideAnims;
  late final List<Animation<double>> _fadeAnims;
  bool _isMuted = false;
  bool _isBlocked = false;
  bool _isFollowing = false;

  static const int _itemCount = 6;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnims = List.generate(_itemCount, (i) {
      final start = (i * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<double>(begin: 40.0, end: 0.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _fadeAnims = List.generate(_itemCount, (i) {
      final start = (i * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  void _showSuccessSnackBar(BuildContext ctx, String message,
      {String? undoLabel, VoidCallback? onUndo}) {
    ScaffoldMessenger.of(ctx).clearSnackBars();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1E824C),
        duration: const Duration(seconds: 3),
        action: onUndo != null
            ? SnackBarAction(
                label: undoLabel ?? 'Undo',
                textColor: Colors.white,
                onPressed: onUndo,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Profile author = widget.comment['author'] as Profile;
    final username = author.username;
    final commentId = widget.comment['id'] as String;

    final actions = <_CommentQuickActionItem>[
      _CommentQuickActionItem(
        icon: Icons.sentiment_dissatisfied_outlined,
        label: 'Not interested in this comment',
        onTap: () {
          Navigator.pop(context);
          widget.onCommentHidden(commentId);
          _showSuccessSnackBar(context, 'Comment hidden from view',
              undoLabel: 'Undo', onUndo: () {});
        },
      ),
      _CommentQuickActionItem(
        icon: _isFollowing
            ? Icons.person_remove_outlined
            : Icons.person_add_alt_1_outlined,
        label: _isFollowing ? 'Unfollow @$username' : 'Follow @$username',
        onTap: () {
          setState(() => _isFollowing = !_isFollowing);
          Navigator.pop(context);
          _showSuccessSnackBar(
            context,
            _isFollowing
                ? 'You unfollowed @$username'
                : 'You are now following @$username',
          );
        },
      ),
      _CommentQuickActionItem(
        icon: Icons.playlist_add_outlined,
        label: 'Add/remove from Lists',
        onTap: () {
          Navigator.pop(context);
          _showSuccessSnackBar(context, 'List updated for @$username');
        },
      ),
      _CommentQuickActionItem(
        icon: _isMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
        label: _isMuted ? 'Unmute @$username' : 'Mute @$username',
        onTap: () {
          setState(() => _isMuted = !_isMuted);
          Navigator.pop(context);
          _showSuccessSnackBar(
            context,
            _isMuted ? '@$username unmuted' : '@$username has been muted',
            undoLabel: 'Undo',
            onUndo: () {},
          );
        },
      ),
      _CommentQuickActionItem(
        icon: Icons.block_outlined,
        label: _isBlocked ? 'Unblock @$username' : 'Block @$username',
        isDanger: true,
        onTap: () {
          Navigator.pop(context);
          _showBlockConfirm(context, username);
        },
      ),
      _CommentQuickActionItem(
        icon: Icons.flag_outlined,
        label: 'Report comment',
        isDanger: true,
        onTap: () {
          Navigator.pop(context);
          _showReportSheet(context, commentId);
        },
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(actions.length, (i) {
              final action = actions[i];
              return AnimatedBuilder(
                animation: _staggerController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnims[i].value),
                    child: Opacity(
                      opacity: _fadeAnims[i].value,
                      child: child,
                    ),
                  );
                },
                child: _buildActionTile(action),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(_CommentQuickActionItem item) {
    final color = item.isDanger ? Colors.red[600]! : context.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        splashColor: const Color(0xFF7C4DFF).withOpacity(0.08),
        highlightColor: const Color(0xFF7C4DFF).withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(item.icon, color: color, size: 22),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlockConfirm(BuildContext ctx, String username) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Block @$username?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: context.textPrimary),
        ),
        content: Text(
          'They will not be able to follow you, see your posts, or contact you on Dak.',
          style: GoogleFonts.inter(fontSize: 14, color: context.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: context.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _showSuccessSnackBar(ctx, '@$username has been blocked');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Block',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReportSheet(BuildContext ctx, String commentId) {
    final reasons = [
      'Spam',
      'Hate speech',
      'Harassment or bullying',
      'Misinformation',
      'Violence or threat',
      'Other',
    ];
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (reportCtx) => Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Report comment',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Why are you reporting this comment?',
                  style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: context.border),
              ...reasons.map((reason) => Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(reportCtx);
                        await widget.dbService.reportComment(commentId, reason);
                        if (!mounted) return;
                        _showSuccessSnackBar(
                          ctx,
                          'Report submitted. Thank you for helping keep Dak safe.',
                        );
                      },
                      splashColor: Colors.red.withOpacity(0.06),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                reason,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: context.textPrimary,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: context.textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentQuickActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  _CommentQuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });
}
