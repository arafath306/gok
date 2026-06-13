import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/thread_post.dart';
import '../services/database_service.dart';
import '../screens/thread_detail_screen.dart';
import '../utils/routes.dart';
import 'comments_sheet.dart';
import 'reactions_sheet.dart';
import '../screens/profile/profile_screen.dart';

class CustomThreadCard extends StatelessWidget {
  final ThreadPost post;

  const CustomThreadCard({super.key, required this.post});


  void _sharePost(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Share Post", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.share, size: 40, color: Color(0xFF1E824C)),
            const SizedBox(height: 16),
            Text("Copy post link or share.", style: GoogleFonts.hindSiliguri(fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                "https://dak.ngst.app/thread/${post.id}",
                style: const TextStyle(fontSize: 12, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Link copied")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E824C),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text("Copy Link", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showQuickActions(BuildContext context, DatabaseService dbService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 350),
      ),
      builder: (sheetContext) => _QuickActionsSheet(
        post: post,
        dbService: dbService,
      ),
    );
  }


  void _showReactionsPopup(BuildContext context, DatabaseService dbService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReactionsListSheet(post: post),
    );
  }

  void _showCommentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(post: post),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final isVerified = post.author.fullName == 'Dak Official';

    // Mock category tags mapping based on post content
    List<String> tags = [];
    if (post.content.contains('প্রকৃতি') || post.content.contains('nature') || post.content.contains('Mountain') || post.imageUrls != null) {
      tags = ['Bangladesh', 'Nature'];
    } else if (post.content.contains('ডিজাইন') || post.content.contains('Dak')) {
      tags = ['Bangladesh', 'Design'];
    } else {
      tags = ['Bangladesh', 'Trending'];
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            NoTransitionPageRoute(
              child: ThreadDetailScreen(post: post),
            ),
          );
        },
        onLongPress: () => _showQuickActions(context, dbService),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(
                          child: ProfileScreen(userId: post.userId),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: NetworkImage(
                        post.author.avatarUrl ?? "https://i.pravatar.cc/150",
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.push(
                          context,
                          NoTransitionPageRoute(
                            child: ProfileScreen(userId: post.userId),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  post.author.fullName,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.hindSiliguri(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 15,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            "@${post.author.username} · ${post.createdAt}",
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.black54, size: 20),
                    onPressed: () => _showQuickActions(context, dbService),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Post Body Content Text
              Text(
                post.content,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14.5,
                  color: Colors.black87,
                  height: 1.45,
                ),
              ),

              // Image attachment
              if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Image.network(
                    post.imageUrls!.first,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],

              // Video attachment
              if (post.videoUrl != null && post.videoUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _sharePost(context),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16.0),
                      image: const DecorationImage(
                        image: NetworkImage("https://images.unsplash.com/photo-1492691527719-9d1e07e534b4"),
                        fit: BoxFit.cover,
                        opacity: 0.6,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white70,
                          child: Icon(Icons.play_arrow, color: Colors.black, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          color: Colors.black54,
                          child: Text(
                            post.videoUrl!,
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],

              // Tags Display
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF374151),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )).toList(),
                ),
              ],

              const SizedBox(height: 16),

              // Actions Footer Row
              Row(
                children: [
                  // Likes Action (Heart icon / Custom emoji)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          dbService.toggleLike(post.id, !post.isLikedByMe);
                        },
                        onLongPress: () => _showReactionsPopup(context, dbService),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: post.isLikedByMe
                              ? Text(
                                  post.reactionType ?? '❤️',
                                  key: ValueKey<String>(post.reactionType ?? '❤️'),
                                  style: const TextStyle(fontSize: 18),
                                )
                              : const Icon(
                                  Icons.favorite_border,
                                  key: ValueKey<int>(0),
                                  color: Colors.black87,
                                  size: 20,
                                ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showReactionsPopup(context, dbService),
                        child: Text(
                          "${post.likesCount}",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),

                  // Comment/Reply Action
                  GestureDetector(
                    onTap: () => _showCommentsBottomSheet(context),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.black87,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${post.repliesCount}",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Repost/Quote Action
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Post reposted successfully")),
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.repeat,
                          color: Colors.black87,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${post.repostsCount}",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // Send/Share Action
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.ios_share_outlined,
                      color: Colors.black87,
                      size: 20,
                    ),
                    onPressed: () => _sharePost(context),
                  ),
                  const SizedBox(width: 16),

                  // Bookmark Save Action
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.bookmark_border_outlined,
                      color: Colors.black87,
                      size: 20,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Saved to bookmarks")),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Quick Actions Bottom Sheet (Twitter/X Style) ─────────────────────────────
class _QuickActionsSheet extends StatefulWidget {
  final ThreadPost post;
  final DatabaseService dbService;

  const _QuickActionsSheet({required this.post, required this.dbService});

  @override
  State<_QuickActionsSheet> createState() => _QuickActionsSheetState();
}

class _QuickActionsSheetState extends State<_QuickActionsSheet>
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
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
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
    final username = widget.post.author.username;

    final actions = <_QuickActionItem>[
      _QuickActionItem(
        icon: Icons.sentiment_dissatisfied_outlined,
        label: 'Not interested in this post',
        onTap: () {
          Navigator.pop(context);
          _showSuccessSnackBar(context, 'Post hidden from your feed',
              undoLabel: 'Undo', onUndo: () {});
        },
      ),
      _QuickActionItem(
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
      _QuickActionItem(
        icon: Icons.playlist_add_outlined,
        label: 'Add/remove from Lists',
        onTap: () {
          Navigator.pop(context);
          _showSuccessSnackBar(context, 'List updated for @$username');
        },
      ),
      _QuickActionItem(
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
      _QuickActionItem(
        icon: Icons.block_outlined,
        label: _isBlocked ? 'Unblock @$username' : 'Block @$username',
        isDanger: true,
        onTap: () {
          Navigator.pop(context);
          _showBlockConfirm(context, username);
        },
      ),
      _QuickActionItem(
        icon: Icons.flag_outlined,
        label: 'Report post',
        isDanger: true,
        onTap: () {
          Navigator.pop(context);
          _showReportSheet(context);
        },
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                color: Colors.grey[300],
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

  Widget _buildActionTile(_QuickActionItem item) {
    final color = item.isDanger ? Colors.red[600]! : Colors.black87;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        splashColor: const Color(0xFF1E824C).withOpacity(0.08),
        highlightColor: const Color(0xFF1E824C).withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(item.icon, color: color, size: 22),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.outfit(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Block @$username?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'They will not be able to follow you, see your posts, or contact you on Dak.',
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.black54, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel',
                style: GoogleFonts.outfit(
                    color: Colors.grey[600], fontWeight: FontWeight.w600)),
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
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReportSheet(BuildContext ctx) {
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Report post',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Why are you reporting this post?',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              ...reasons.map((reason) => Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(reportCtx);
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
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: Colors.grey[400], size: 20),
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

class _QuickActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });
}
