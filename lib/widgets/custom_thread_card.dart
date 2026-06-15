import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/thread_post.dart';
import '../models/profile.dart';
import '../services/database_service.dart';
import '../services/general_settings_provider.dart';
import '../screens/thread_detail_screen.dart';
import '../screens/create_thread_screen.dart';
import '../utils/routes.dart';
import '../utils/app_theme.dart';
import 'comments_sheet.dart';
import '../screens/profile/profile_screen.dart';
import 'share_post_sheet.dart';

class CustomThreadCard extends StatefulWidget {
  final ThreadPost post;

  const CustomThreadCard({super.key, required this.post});

  @override
  State<CustomThreadCard> createState() => _CustomThreadCardState();
}

class _CustomThreadCardState extends State<CustomThreadCard> {
  List<Profile> _commenterProfiles = [];

  @override
  void initState() {
    super.initState();
    _loadCommenterProfiles();
  }

  @override
  void didUpdateWidget(CustomThreadCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final livePost = dbService.getLatestPost(widget.post);
    final oldLivePost = dbService.getLatestPost(oldWidget.post);
    if (oldWidget.post.id != widget.post.id ||
        oldLivePost.repliesCount != livePost.repliesCount) {
      _loadCommenterProfiles();
    }
  }

  Future<void> _loadCommenterProfiles() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final livePost = dbService.getLatestPost(widget.post);
    if (livePost.repliesCount == 0) {
      if (mounted) {
        setState(() {
          _commenterProfiles = [];
        });
      }
      return;
    }
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final comments = await dbService.fetchComments(widget.post.id);
      if (mounted) {
        final List<Profile> profiles = [];
        for (var comment in comments) {
          final author = comment['author'] as Profile?;
          if (author != null && !profiles.any((p) => p.id == author.id)) {
            profiles.add(author);
          }
          if (profiles.length >= 3) break;
        }
        setState(() {
          _commenterProfiles = profiles;
        });
      }
    } catch (e) {
      debugPrint("Error loading commenter profiles: $e");
    }
  }

  void _sharePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SharePostSheet(post: widget.post),
    );
  }

  void _showQuickActions(BuildContext context, DatabaseService dbService, ThreadPost post) {
    final isAuthor = post.userId == dbService.currentUid;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        if (isAuthor) {
          return _AuthorActionsSheet(
            post: post,
            dbService: dbService,
            parentContext: context,
          );
        } else {
          return _QuickActionsSheet(
            post: post,
            dbService: dbService,
            parentContext: context,
          );
        }
      },
    );
  }

  void _showCommentsBottomSheet(BuildContext context, ThreadPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(post: post),
    ).then((_) {
      _loadCommenterProfiles();
    });
  }

  void _showRepostOptions(BuildContext context, DatabaseService dbService, ThreadPost post) {
    final targetPostId = post.isRepost && post.repostedPost != null ? post.repostedPost!.id : post.id;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
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
                  color: context.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.repeat_rounded, color: context.textPrimary),
                title: Text('Repost', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, color: context.textPrimary)),
                subtitle: Text('Instantly share this post to your feed', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final success = await dbService.repostThread(targetPostId);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Post status updated")),
                    );
                  }
                },
              ),
              Divider(height: 1, color: context.border),
              ListTile(
                leading: Icon(Icons.edit_note, color: context.textPrimary),
                title: Text('Quote Post', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary)),
                subtitle: Text('Share this post and add your own comment', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final targetPost = post.isRepost && post.repostedPost != null ? post.repostedPost! : post;
                  Navigator.push(
                    context,
                    NoTransitionPageRoute(
                      child: CreateThreadScreen(quotePost: targetPost),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuoteInputDialog(BuildContext context, DatabaseService dbService, ThreadPost post) {
    final controller = TextEditingController();
    final targetPostId = post.isRepost && post.repostedPost != null ? post.repostedPost!.id : post.id;
    final displayContent = post.isRepost && post.repostedPost != null ? post.repostedPost!.content : post.content;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Quote Post", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, color: context.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              style: GoogleFonts.hindSiliguri(color: context.textPrimary),
              decoration: const InputDecoration(
                hintText: "Add a comment...",
                border: InputBorder.none,
              ),
              maxLines: 4,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: context.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayContent,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hindSiliguri(fontSize: 12, color: context.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(dialogCtx);
                final success = await dbService.repostThread(targetPostId, quoteText: text);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Post status updated")),
                  );
                }
              }
            },
            child: const Text("Post", style: TextStyle(color: Color(0xFF1E824C))),
          ),
        ],
      ),
    );
  }

  Widget _buildNestedOriginalPost(BuildContext context, DatabaseService dbService, ThreadPost origPost) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          NoTransitionPageRoute(
            child: ThreadDetailScreen(post: origPost),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 16, thickness: 0.5, color: context.border),
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundImage: origPost.author.avatarUrl != null && origPost.author.avatarUrl!.isNotEmpty
                    ? NetworkImage(origPost.author.avatarUrl!)
                    : null,
                child: origPost.author.avatarUrl == null || origPost.author.avatarUrl!.isEmpty
                    ? const Icon(Icons.person, size: 10)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                origPost.author.fullName,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: context.textPrimary),
              ),
              const SizedBox(width: 4),
              Text(
                "@${origPost.author.username}",
                style: TextStyle(fontSize: 10, color: context.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            origPost.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 13, color: context.textPrimary),
          ),
          if (origPost.imageUrls != null && origPost.imageUrls!.isNotEmpty) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                origPost.imageUrls!.first,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    // Resolve live post from cache so mutations (like, comment, edit, delete)
    // are reflected immediately without a full feed refresh.
    final post = dbService.getLatestPost(widget.post);

    // If this post was deleted, render nothing.
    if (dbService.isPostDeleted(post.id)) return const SizedBox.shrink();

    final isVerified = post.author.fullName == 'Dak Official';

    return InkWell(
      hoverColor: Colors.transparent,
      onTap: () {
        final targetPost = (post.isRepost && (post.quoteText == null || post.quoteText!.isEmpty)) 
            ? post.repostedPost! 
            : post;
        Navigator.push(
          context,
          NoTransitionPageRoute(
            child: ThreadDetailScreen(post: targetPost),
          ),
        );
      },
      onLongPress: () => _showQuickActions(context, dbService, post),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLeftColumn(context, dbService, post),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: _buildRightColumn(context, dbService, post, isVerified),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: context.border),
        ],
      ),
    );
  }

  Widget _buildLeftColumn(BuildContext context, DatabaseService dbService, ThreadPost post) {
    final isFollowing = dbService.isFollowingUser(post.userId);
    final hasReplies = post.repliesCount > 0 && _commenterProfiles.isNotEmpty;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[800],
              backgroundImage: (post.author.avatarUrl != null && post.author.avatarUrl!.isNotEmpty)
                  ? NetworkImage(post.author.avatarUrl!)
                  : null,
              child: (post.author.avatarUrl == null || post.author.avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 20, color: Colors.white54)
                  : null,
            ),
            if (post.userId != dbService.currentUid && !isFollowing)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E824C),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            width: 1.5,
            color: context.border,
          ),
        ),
        const SizedBox(height: 8),
        if (hasReplies) ...[
          _buildRepliesAvatars(context),
        ] else ...[
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildRepliesAvatars(BuildContext context) {
    if (_commenterProfiles.isEmpty) return const SizedBox.shrink();

    final count = _commenterProfiles.length;

    if (count == 1) {
      final avatarUrl = _commenterProfiles[0].avatarUrl;
      return Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.scaffoldBg, width: 1.5),
        ),
        child: ClipOval(
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? Image.network(avatarUrl, fit: BoxFit.cover)
              : Container(color: const Color(0xFF1E824C)),
        ),
      );
    } else if (count == 2) {
      final avatarUrl0 = _commenterProfiles[0].avatarUrl;
      final avatarUrl1 = _commenterProfiles[1].avatarUrl;
      return SizedBox(
        width: 24,
        height: 18,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.scaffoldBg, width: 1.5),
                ),
                child: ClipOval(
                  child: avatarUrl0 != null && avatarUrl0.isNotEmpty
                      ? Image.network(avatarUrl0, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF1E824C)),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.scaffoldBg, width: 1.5),
                ),
                child: ClipOval(
                  child: avatarUrl1 != null && avatarUrl1.isNotEmpty
                      ? Image.network(avatarUrl1, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF1E824C)),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final avatarUrl0 = _commenterProfiles[0].avatarUrl;
      final avatarUrl1 = _commenterProfiles[1].avatarUrl;
      final avatarUrl2 = _commenterProfiles[2].avatarUrl;
      return SizedBox(
        width: 28,
        height: 22,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.scaffoldBg, width: 1.2),
                ),
                child: ClipOval(
                  child: avatarUrl0 != null && avatarUrl0.isNotEmpty
                      ? Image.network(avatarUrl0, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF1E824C)),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.scaffoldBg, width: 1.2),
                ),
                child: ClipOval(
                  child: avatarUrl1 != null && avatarUrl1.isNotEmpty
                      ? Image.network(avatarUrl1, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF1E824C)),
                ),
              ),
            ),
            Positioned(
              left: 9,
              bottom: 6,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.scaffoldBg, width: 1.2),
                ),
                child: ClipOval(
                  child: avatarUrl2 != null && avatarUrl2.isNotEmpty
                      ? Image.network(avatarUrl2, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF1E824C)),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRightColumn(
    BuildContext context,
    DatabaseService dbService,
    ThreadPost post,
    bool isVerified,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                final isOwn = post.userId == dbService.currentUid;
                Navigator.push(
                  context,
                  NoTransitionPageRoute(
                    child: ProfileScreen(userId: isOwn ? null : post.userId),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    post.author.username,
                    style: GoogleFonts.hindSiliguri(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: context.textPrimary,
                    ),
                  ),
                  if (isVerified) ...[
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
            const Spacer(),
            Text(
              post.createdAt,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: context.textMuted,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _showQuickActions(context, dbService, post),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.more_horiz,
                  color: context.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          post.content,
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            color: context.textPrimary,
            height: 1.4,
          ),
        ),
        if (post.isRepost && post.repostedPost != null)
          _buildNestedOriginalPost(context, dbService, post.repostedPost!),
        if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.network(
              post.imageUrls!.first,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
        if (post.videoUrl != null && post.videoUrl!.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _sharePost(context),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12.0),
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
        const SizedBox(height: 10),
        Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.lightImpact();
                dbService.toggleLike(post.id, !post.isLikedByMe);
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: post.isLikedByMe
                    ? Icon(
                        Icons.favorite,
                        key: const ValueKey<int>(1),
                        color: Colors.red,
                        size: 20,
                      )
                    : Icon(
                        Icons.favorite_border,
                        key: const ValueKey<int>(0),
                        color: context.textSecondary,
                        size: 20,
                      ),
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () => _showCommentsBottomSheet(context, post),
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: context.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () => _showRepostOptions(context, dbService, post),
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.repeat_rounded,
                color: context.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () async {
                final wasSaved = dbService.isSaved(post.id);
                await dbService.toggleSaveThread(post.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        wasSaved ? "Removed from bookmarks" : "Post saved to bookmarks",
                        style: GoogleFonts.inter(),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: wasSaved ? Colors.grey[700] : const Color(0xFF1E824C),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              child: Icon(
                dbService.isSaved(post.id) ? Icons.bookmark : Icons.bookmark_border_rounded,
                color: dbService.isSaved(post.id) ? const Color(0xFF1E824C) : context.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () => _sharePost(context),
              child: Icon(
                Icons.send_outlined,
                color: context.textSecondary,
                size: 20,
              ),
            ),
          ],
        ),
        if (post.repliesCount > 0 || post.likesCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            _buildCombinedStatsString(post),
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: context.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        const SizedBox(height: 12), // Buffer to prevent font rendering/subpixel layout overflows
      ],
    );
  }

  String _buildCombinedStatsString(ThreadPost post) {
    final repCount = post.repliesCount;
    final lkCount = post.likesCount;
    if (repCount > 0 && lkCount > 0) {
      return "$repCount ${repCount == 1 ? 'reply' : 'replies'} · $lkCount ${lkCount == 1 ? 'like' : 'likes'}";
    } else if (repCount > 0) {
      return "$repCount ${repCount == 1 ? 'reply' : 'replies'}";
    } else {
      return "$lkCount ${lkCount == 1 ? 'like' : 'likes'}";
    }
  }
}

// ─── Quick Actions Bottom Sheet (Twitter/X Style) ─────────────────────────────
class _QuickActionsSheet extends StatefulWidget {
  final ThreadPost post;
  final DatabaseService dbService;
  final BuildContext parentContext;

  const _QuickActionsSheet({
    required this.post,
    required this.dbService,
    required this.parentContext,
  });

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
    _isFollowing = widget.dbService.isFollowingUser(widget.post.userId);
    _isMuted = widget.dbService.isMuted(widget.post.userId);
    _isBlocked = widget.dbService.isBlocked(widget.post.userId);

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
    final username = widget.post.author.username;

    final actions = <_QuickActionItem>[
      _QuickActionItem(
        icon: Icons.sentiment_dissatisfied_outlined,
        label: 'Not interested in this post',
        onTap: () async {
          Navigator.pop(context);
          final success = await widget.dbService.hideThreadForCurrentUser(widget.post.id);
          if (success && mounted) {
            _showSuccessSnackBar(context, 'Post hidden from your feed',
                undoLabel: 'Undo', onUndo: () async {
                  await widget.dbService.unhideThreadForCurrentUser(widget.post.id);
                });
          }
        },
      ),
      _QuickActionItem(
        icon: _isFollowing
            ? Icons.person_remove_outlined
            : Icons.person_add_alt_1_outlined,
        label: _isFollowing ? 'Unfollow @$username' : 'Follow @$username',
        onTap: () async {
          final wasFollowing = _isFollowing;
          Navigator.pop(context);
          await widget.dbService.toggleFollowUser(widget.post.userId);
          if (mounted) {
            _showSuccessSnackBar(
              context,
              wasFollowing
                  ? 'You unfollowed @$username'
                  : 'You are now following @$username',
            );
          }
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
        onTap: () async {
          final wasMuted = _isMuted;
          Navigator.pop(context);
          final settingsProvider = Provider.of<GeneralSettingsProvider>(context, listen: false);
          if (wasMuted) {
            await settingsProvider.unmuteAccount(widget.post.userId);
          } else {
            await settingsProvider.muteUserById(widget.post.userId);
          }
          await widget.dbService.fetchBlockedMutedLists();
          await widget.dbService.fetchFeed();
          if (mounted) {
            _showSuccessSnackBar(
              context,
              wasMuted ? '@$username unmuted' : '@$username has been muted',
              undoLabel: 'Undo',
              onUndo: () async {
                if (wasMuted) {
                  await settingsProvider.muteUserById(widget.post.userId);
                } else {
                  await settingsProvider.unmuteAccount(widget.post.userId);
                }
                await widget.dbService.fetchBlockedMutedLists();
                await widget.dbService.fetchFeed();
              },
            );
          }
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
                color: context.border,
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
    final color = item.isDanger ? Colors.red[600]! : context.textPrimary;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Block @$username?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
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
                    color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final settingsProvider = Provider.of<GeneralSettingsProvider>(ctx, listen: false);
              await settingsProvider.blockUserById(widget.post.userId);
              await widget.dbService.fetchBlockedMutedLists();
              await widget.dbService.fetchFeed();
              if (ctx.mounted) {
                _showSuccessSnackBar(ctx, '@$username has been blocked');
              }
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
                    color: context.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Report post',
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
                  'Why are you reporting this post?',
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
                        final success = await widget.dbService.reportPost(widget.post.id, reason);
                        if (success) {
                          _showSuccessSnackBar(
                            ctx,
                            'Report submitted. Thank you for helping keep Dak safe.',
                          );
                        }
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

class _AuthorActionsSheet extends StatefulWidget {
  final ThreadPost post;
  final DatabaseService dbService;
  final BuildContext parentContext;

  const _AuthorActionsSheet({
    required this.post,
    required this.dbService,
    required this.parentContext,
  });

  @override
  State<_AuthorActionsSheet> createState() => _AuthorActionsSheetState();
}

class _AuthorActionsSheetState extends State<_AuthorActionsSheet>
    with TickerProviderStateMixin {
  late final AnimationController _staggerController;
  late final List<Animation<double>> _slideAnims;
  late final List<Animation<double>> _fadeAnims;
  
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

  void _showSuccessSnackBar(BuildContext ctx, String message) {
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
      ),
    );
  }

  void _showEditRepostDialog(BuildContext ctx, ThreadPost post) {
    final controller = TextEditingController(text: post.quoteText);
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: ctx.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Edit Quote", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, color: ctx.textPrimary)),
        content: TextField(
          controller: controller,
          style: GoogleFonts.hindSiliguri(color: ctx.textPrimary),
          decoration: const InputDecoration(
            hintText: "Edit your comment...",
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                Navigator.pop(dialogCtx);
                final success = await widget.dbService.editRepost(post.id, newText);
                if (success) {
                  _showSuccessSnackBar(ctx, "Quote updated successfully");
                }
              }
            },
            child: const Text("Save", style: TextStyle(color: Color(0xFF1E824C))),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Post?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'This action is permanent and cannot be undone.',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.black54, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await widget.dbService.deletePost(widget.post.id);
              if (!mounted) return;
              if (success) {
                _showSuccessSnackBar(context, 'Post deleted successfully');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditPostSheet(BuildContext ctx) {
    final textController = TextEditingController(text: widget.post.content);
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Edit Post",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: context.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: context.textPrimary),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textController,
                  maxLines: 5,
                  style: GoogleFonts.hindSiliguri(fontSize: 15, color: context.textPrimary),
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    hintStyle: GoogleFonts.hindSiliguri(color: context.textMuted),
                    filled: true,
                    fillColor: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E824C), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final newContent = textController.text.trim();
                      if (newContent.isNotEmpty) {
                        Navigator.pop(sheetContext);
                        final success = await widget.dbService.editPostContent(widget.post.id, newContent);
                        if (!mounted) return;
                        if (success) {
                          _showSuccessSnackBar(context, "Post updated successfully");
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E824C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Save Changes",
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHideSpecificUsersSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _HidePostForUsersSheet(
        post: widget.post,
        dbService: widget.dbService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPinned = widget.post.isPinned;
    final isMuted = widget.post.muteNotifications;
    final isHiddenFromProfile = widget.post.hideFromProfile;

    final actions = <_QuickActionItem>[];
    if (widget.post.isRepost) {
      actions.addAll([
        _QuickActionItem(
          icon: Icons.delete_outline,
          label: 'Remove repost',
          isDanger: true,
          onTap: () async {
            Navigator.pop(context);
            final success = await widget.dbService.deleteRepost(widget.post.id, widget.post.repostedPost?.id ?? '');
            if (success) {
              _showSuccessSnackBar(widget.parentContext, 'Repost removed');
            }
          },
        ),
        _QuickActionItem(
          icon: isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
          label: isMuted ? 'Unmute notifications' : 'Mute notifications for this post',
          onTap: () async {
            Navigator.pop(context);
            final success = await widget.dbService.toggleMutePostNotifications(widget.post.id, !isMuted);
            if (success) {
              _showSuccessSnackBar(
                widget.parentContext,
                isMuted ? 'Notifications unmuted' : 'Notifications muted for this post',
              );
            }
          },
        ),
        if (widget.post.quoteText != null && widget.post.quoteText!.isNotEmpty)
          _QuickActionItem(
            icon: Icons.edit_outlined,
            label: 'Edit post',
            onTap: () {
              Navigator.pop(context);
              _showEditRepostDialog(widget.parentContext, widget.post);
            },
          ),
      ]);
    } else {
      actions.addAll([
        _QuickActionItem(
          icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
          label: isPinned ? 'Unpin from profile' : 'Pin to profile',
          onTap: () async {
            Navigator.pop(context);
            final success = await widget.dbService.togglePinPost(widget.post.id, !isPinned);
            if (success) {
              _showSuccessSnackBar(
                widget.parentContext,
                isPinned ? 'Post unpinned from profile' : 'Post pinned to profile',
              );
            }
          },
        ),
        _QuickActionItem(
          icon: isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
          label: isMuted ? 'Unmute notifications' : 'Mute notifications for this post',
          onTap: () async {
            Navigator.pop(context);
            final success = await widget.dbService.toggleMutePostNotifications(widget.post.id, !isMuted);
            if (success) {
              _showSuccessSnackBar(
                widget.parentContext,
                isMuted ? 'Notifications unmuted' : 'Notifications muted for this post',
              );
            }
          },
        ),
        _QuickActionItem(
          icon: Icons.edit_outlined,
          label: 'Edit post',
          onTap: () {
            Navigator.pop(context);
            _showEditPostSheet(widget.parentContext);
          },
        ),
        _QuickActionItem(
          icon: isHiddenFromProfile ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          label: isHiddenFromProfile ? 'Show on profile' : 'Hide from my profile',
          onTap: () async {
            Navigator.pop(context);
            final success = await widget.dbService.toggleHidePostFromProfile(widget.post.id, !isHiddenFromProfile);
            if (success) {
              _showSuccessSnackBar(
                widget.parentContext,
                isHiddenFromProfile ? 'Post is now visible on your profile' : 'Post hidden from your profile feed',
              );
            }
          },
        ),
        _QuickActionItem(
          icon: Icons.person_off_outlined,
          label: 'Hide for specific users',
          onTap: () {
            Navigator.pop(context);
            _showHideSpecificUsersSheet(widget.parentContext);
          },
        ),
        _QuickActionItem(
          icon: Icons.delete_outline,
          label: 'Delete post',
          isDanger: true,
          onTap: () {
            Navigator.pop(context);
            _showDeleteConfirm(widget.parentContext);
          },
        ),
      ]);
    }

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
                color: context.border,
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
    final color = item.isDanger ? Colors.red[600]! : context.textPrimary;
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
}

class _HidePostForUsersSheet extends StatefulWidget {
  final ThreadPost post;
  final DatabaseService dbService;

  const _HidePostForUsersSheet({required this.post, required this.dbService});

  @override
  State<_HidePostForUsersSheet> createState() => _HidePostForUsersSheetState();
}

class _HidePostForUsersSheetState extends State<_HidePostForUsersSheet> {
  List<dynamic> _friends = [];
  List<dynamic> _filteredFriends = [];
  Set<String> _selectedHides = {};
  bool _isLoading = true;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final friends = await widget.dbService.fetchFollowingProfiles();
    final hides = await widget.dbService.fetchThreadHides(widget.post.id);
    if (mounted) {
      setState(() {
        _friends = friends;
        _filteredFriends = friends;
        _selectedHides = hides.toSet();
        _isLoading = false;
      });
    }
  }

  void _filterFriends(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _filteredFriends = _friends;
      } else {
        _filteredFriends = _friends.where((friend) {
          final name = friend.fullName.toString().toLowerCase();
          final username = friend.username.toString().toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || username.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Hide Post From",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: context.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final success = await widget.dbService.updateThreadHides(
                        widget.post.id,
                        _selectedHides.toList(),
                      );
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Visibility settings updated")),
                        );
                      }
                    },
                    child: Text(
                      "Save",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E824C),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                onChanged: _filterFriends,
                style: GoogleFonts.inter(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: "Search friends...",
                  hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: context.textMuted, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E824C)))
                  : _filteredFriends.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty ? "You are not following any friends yet" : "No friends found matching '$_searchQuery'",
                            style: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredFriends.length,
                          itemBuilder: (context, index) {
                            final friend = _filteredFriends[index];
                            final isSelected = _selectedHides.contains(friend.id);
                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: const Color(0xFF1E824C),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedHides.add(friend.id);
                                  } else {
                                    _selectedHides.remove(friend.id);
                                  }
                                });
                              },
                              secondary: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  friend.avatarUrl ?? "",
                                ),
                              ),
                              title: Text(
                                friend.fullName,
                                style: GoogleFonts.hindSiliguri(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: context.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                "@${friend.username}",
                                style: GoogleFonts.inter(
                                  color: context.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
