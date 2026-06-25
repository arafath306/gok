import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
import '../services/sound_service.dart';
import 'thread_image_carousel.dart';

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
    final effPost = widget.post.isRepost && widget.post.repostedPost != null ? widget.post.repostedPost! : widget.post;
    final oldEffPost = oldWidget.post.isRepost && oldWidget.post.repostedPost != null ? oldWidget.post.repostedPost! : oldWidget.post;
    final livePost = dbService.getLatestPost(effPost);
    final oldLivePost = dbService.getLatestPost(oldEffPost);
    if (oldEffPost.id != effPost.id ||
        oldLivePost.repliesCount != livePost.repliesCount) {
      _loadCommenterProfiles();
    }
  }

  Future<void> _loadCommenterProfiles() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final effPost = widget.post.isRepost && widget.post.repostedPost != null ? widget.post.repostedPost! : widget.post;
    final livePost = dbService.getLatestPost(effPost);
    if (livePost.repliesCount == 0) {
      if (mounted) {
        setState(() {
          _commenterProfiles = [];
        });
      }
      return;
    }
    try {
      final comments = await dbService.fetchComments(effPost.id);
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
      useSafeArea: true,
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
                leading: Icon(CupertinoIcons.arrow_2_circlepath, color: context.textPrimary),
                title: Text('Repost', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, color: context.textPrimary)),
                subtitle: Text('Instantly share this post to your feed', style: TextStyle(color: context.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  dbService.repostThread(targetPostId).then((success) {
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Post status updated")),
                      );
                    }
                  });
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
                    ? CachedNetworkImageProvider(origPost.author.avatarUrl!)
                    : null,
                child: origPost.author.avatarUrl == null || origPost.author.avatarUrl!.isEmpty
                    ? const Icon(Icons.person, size: 10)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                origPost.author.fullName,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary),
              ),
              const SizedBox(width: 4),
              Text(
                "@${origPost.author.username}",
                style: TextStyle(fontSize: 11, color: context.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            origPost.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.hindSiliguri(fontSize: 14.5, color: context.textPrimary, height: 1.35),
          ),
          if (origPost.imageUrls != null && origPost.imageUrls!.isNotEmpty) ...[
            const SizedBox(height: 6),
            ThreadImageCarousel(
              imageUrls: origPost.imageUrls!,
              height: 120,
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

    final isVerified = post.author.isVerified;

    return RepaintBoundary(
      child: InkWell(
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
      ),
    );
  }

  Widget _buildLeftColumn(BuildContext context, DatabaseService dbService, ThreadPost post) {
    final effPost = post.isRepost && post.repostedPost != null ? post.repostedPost! : post;
    final hasReplies = effPost.repliesCount > 0 && _commenterProfiles.isNotEmpty;
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[800],
              backgroundImage: (post.author.avatarUrl != null && post.author.avatarUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(post.author.avatarUrl!)
                  : null,
              child: (post.author.avatarUrl == null || post.author.avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 20, color: Colors.white54)
                  : null,
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
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  fit: BoxFit.cover,
                  errorWidget: (c, u, e) => Container(color: const Color(0xFF1E824C)),
                )
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
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl0,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => Container(color: const Color(0xFF1E824C)),
                        )
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
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl1,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => Container(color: const Color(0xFF1E824C)),
                        )
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
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl0,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => Container(color: const Color(0xFF1E824C)),
                        )
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
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl1,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => Container(color: const Color(0xFF1E824C)),
                        )
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
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl2,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => Container(color: const Color(0xFF1E824C)),
                        )
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
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final isOwn = post.userId == dbService.currentUid;
                  Navigator.push(
                    context,
                    NoTransitionPageRoute(
                      child: ProfileScreen(userId: isOwn ? null : post.userId),
                    ),
                  );
                },
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: post.author.fullName,
                        style: GoogleFonts.hindSiliguri(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: context.textPrimary,
                        ),
                      ),
                      if (isVerified)
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 14,
                            ),
                          ),
                        ),
                      TextSpan(
                        text: ' @${post.author.username}',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              post.createdAt,
              style: GoogleFonts.inter(
                fontSize: 13.5,
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
        const SizedBox(height: 3),
        Text(
          post.content,
          style: GoogleFonts.hindSiliguri(
            fontSize: 16.5,
            color: context.textPrimary,
            height: 1.45,
          ),
        ),
        if (post.isRepost && post.repostedPost != null)
          _buildNestedOriginalPost(context, dbService, post.repostedPost!),
        if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
          const SizedBox(height: 8),
          ThreadImageCarousel(
            imageUrls: post.imageUrls!,
            height: 220,
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
        _buildPollSection(context, dbService, post),
        const SizedBox(height: 10),
        (() {
          final targetPost = post.isRepost && post.repostedPost != null ? post.repostedPost! : post;
          return Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Play bubble pop sound only when liking (not unliking)
                  if (!targetPost.isLikedByMe) {
                    SoundService.playLike();
                  }
                  dbService.toggleLike(targetPost.id, !targetPost.isLikedByMe);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: targetPost.isLikedByMe
                        ? const Icon(
                            CupertinoIcons.heart_fill,
                            key: ValueKey<int>(1),
                            color: Colors.red,
                            size: 20,
                          )
                        : Icon(
                            CupertinoIcons.heart,
                            key: const ValueKey<int>(0),
                            color: context.textPrimary.withValues(alpha: 0.75),
                            size: 20,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (targetPost.likesCount > 0)
                Text(
                  '${targetPost.likesCount}',
                  style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary.withValues(alpha: 0.75)),
                ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: () => _showCommentsBottomSheet(context, post),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Icon(
                    CupertinoIcons.chat_bubble,
                    color: context.textPrimary.withValues(alpha: 0.75),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (targetPost.repliesCount > 0)
                Text(
                  '${targetPost.repliesCount}',
                  style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary.withValues(alpha: 0.75)),
                ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: () => _showRepostOptions(context, dbService, post),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Icon(
                    CupertinoIcons.arrow_2_circlepath,
                    color: dbService.isReposted(targetPost.id) 
                        ? const Color(0xFF1E824C) 
                        : context.textPrimary.withValues(alpha: 0.75),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (targetPost.repostsCount > 0)
                Text(
                  '${targetPost.repostsCount}',
                  style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary.withValues(alpha: 0.75)),
                ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: () {
                  final wasSaved = dbService.isSaved(targetPost.id);
                  dbService.toggleSaveThread(targetPost.id);
                  ScaffoldMessenger.of(context).clearSnackBars();
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
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Icon(
                    dbService.isSaved(targetPost.id) ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                    color: dbService.isSaved(targetPost.id) ? const Color(0xFF1E824C) : context.textPrimary.withValues(alpha: 0.75),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (targetPost.savesCount > 0)
                Text(
                  '${targetPost.savesCount}',
                  style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary.withValues(alpha: 0.75)),
                ),
              const SizedBox(width: 18),
              GestureDetector(
                onTap: () => _sharePost(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Icon(
                    CupertinoIcons.arrowshape_turn_up_right,
                    color: context.textPrimary.withValues(alpha: 0.75),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (targetPost.sharesCount > 0)
                Text(
                  '${targetPost.sharesCount}',
                  style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary.withValues(alpha: 0.75)),
                ),
            ],
          );
        })(),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPollSection(BuildContext context, DatabaseService dbService, ThreadPost post) {
    final options = post.pollOptions;
    if (options == null || options.isEmpty) return const SizedBox.shrink();

    final totalVotes = post.totalPollVotes;
    final isExpired = post.isPollExpired;
    final hasVoted = post.hasVotedPoll;
    final votedOptionId = post.votedOptionId;
    final showResults = isExpired || hasVoted;

    // Find the winning option(s) (highest votes)
    int maxVotes = 0;
    for (var opt in options) {
      if (opt.votesCount > maxVotes) {
        maxVotes = opt.votesCount;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...options.map((option) {
            final double percent = totalVotes > 0 ? (option.votesCount / totalVotes) : 0.0;
            final isWinner = showResults && option.votesCount == maxVotes && maxVotes > 0;
            final isUserChoice = showResults && option.id == votedOptionId;

            if (showResults) {
              // --- Voted or Expired view: Animate progress bars ---
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isWinner 
                          ? Colors.blue.withValues(alpha: 0.3) 
                          : context.border,
                      width: isWinner ? 1.2 : 0.8,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Stack(
                      children: [
                        // Progress fill animation
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: percent),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, val, child) {
                            return FractionallySizedBox(
                              widthFactor: val,
                              heightFactor: 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isWinner
                                        ? [Colors.blue.withValues(alpha: 0.25), Colors.blue.withValues(alpha: 0.15)]
                                        : [context.textSecondary.withValues(alpha: 0.12), context.textSecondary.withValues(alpha: 0.08)],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Label & stats row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option.optionText,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: isWinner ? FontWeight.w700 : FontWeight.w500,
                                          color: isWinner 
                                              ? (context.isDarkMode ? Colors.blue[300] : Colors.blue[900])
                                              : context.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isUserChoice) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.check_circle,
                                        color: context.isDarkMode ? Colors.blue[300] : Colors.blue[600],
                                        size: 15,
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                              Text(
                                '${(percent * 100).toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: isWinner ? FontWeight.w700 : FontWeight.w600,
                                  color: isWinner 
                                      ? (context.isDarkMode ? Colors.blue[300] : Colors.blue[900])
                                      : context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              // --- Active & Not Voted view: Interactive pill-shaped buttons ---
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.5),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => dbService.votePoll(post.id, option.id),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: context.border,
                          width: 0.9,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        option.optionText,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          }),
          const SizedBox(height: 6),
          // Metadata row
          Row(
            children: [
              Text(
                '$totalVotes ${totalVotes == 1 ? "vote" : "votes"}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 3.5,
                height: 3.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.textMuted.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getPollDurationString(post.pollExpiresAt),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPollDurationString(DateTime? expiresAt) {
    if (expiresAt == null) return "Unknown duration";
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) {
      return "Final results";
    }
    final diff = expiresAt.difference(now);
    if (diff.inDays >= 1) {
      return "${diff.inDays}d left";
    }
    if (diff.inHours >= 1) {
      return "${diff.inHours}h left";
    }
    if (diff.inMinutes >= 1) {
      return "${diff.inMinutes}m left";
    }
    return "Less than a minute left";
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
          final parentCtx = widget.parentContext;
          Navigator.pop(context);
          final success = await widget.dbService.hideThreadForCurrentUser(widget.post.id);
          if (success && parentCtx.mounted) {
            _showSuccessSnackBar(parentCtx, 'Post hidden from your feed',
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
          final parentCtx = widget.parentContext;
          final wasFollowing = _isFollowing;
          Navigator.pop(context);
          await widget.dbService.toggleFollowUser(widget.post.userId);
          if (parentCtx.mounted) {
            _showSuccessSnackBar(
              parentCtx,
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
          final parentCtx = widget.parentContext;
          final wasMuted = _isMuted;
          final settingsProvider = Provider.of<GeneralSettingsProvider>(parentCtx, listen: false);
          Navigator.pop(context);
          if (wasMuted) {
            await settingsProvider.unmuteAccount(widget.post.userId);
          } else {
            await settingsProvider.muteUserById(widget.post.userId);
          }
          await widget.dbService.fetchBlockedMutedLists();
          await widget.dbService.fetchFeed();
          if (parentCtx.mounted) {
            _showSuccessSnackBar(
              parentCtx,
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
          final parentCtx = widget.parentContext;
          Navigator.pop(context);
          _showBlockConfirm(parentCtx, username);
        },
      ),
      _QuickActionItem(
        icon: Icons.flag_outlined,
        label: 'Report post',
        isDanger: true,
        onTap: () {
          final parentCtx = widget.parentContext;
          Navigator.pop(context);
          _showReportSheet(parentCtx);
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
        splashColor: const Color(0xFF1E824C).withValues(alpha: 0.08),
        highlightColor: const Color(0xFF1E824C).withValues(alpha: 0.04),
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
          'They will not be able to follow you, see your posts, or contact you on Pigeon.',
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
                        if (!ctx.mounted) return;
                        if (success) {
                          _showSuccessSnackBar(
                            ctx,
                            'Report submitted. Thank you for helping keep Pigeon safe.',
                          );
                        }
                      },
                      splashColor: Colors.red.withValues(alpha: 0.06),
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
                if (success && ctx.mounted) {
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
              if (success && ctx.mounted) {
                _showSuccessSnackBar(ctx, 'Post deleted successfully');
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
    // Navigate to the full composer screen in edit mode.
    // This avoids the "unmounted widget" error that the bottom-sheet approach had.
    Navigator.of(ctx).push(
      MaterialPageRoute(
        builder: (_) => CreateThreadScreen(editPost: widget.post),
      ),
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
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            final success = await widget.dbService.deleteRepost(widget.post.id, widget.post.repostedPost?.id ?? '');
            if (success && parentCtx.mounted) {
              _showSuccessSnackBar(parentCtx, 'Repost removed');
            }
          },
        ),
        _QuickActionItem(
          icon: isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
          label: isMuted ? 'Unmute notifications' : 'Mute notifications for this post',
          onTap: () async {
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            final success = await widget.dbService.toggleMutePostNotifications(widget.post.id, !isMuted);
            if (success && parentCtx.mounted) {
              _showSuccessSnackBar(
                parentCtx,
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
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            final success = await widget.dbService.togglePinPost(widget.post.id, !isPinned);
            if (success && parentCtx.mounted) {
              _showSuccessSnackBar(
                parentCtx,
                isPinned ? 'Post unpinned from profile' : 'Post pinned to profile',
              );
            }
          },
        ),
        _QuickActionItem(
          icon: isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
          label: isMuted ? 'Unmute notifications' : 'Mute notifications for this post',
          onTap: () async {
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            final success = await widget.dbService.toggleMutePostNotifications(widget.post.id, !isMuted);
            if (success && parentCtx.mounted) {
              _showSuccessSnackBar(
                parentCtx,
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
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            final success = await widget.dbService.toggleHidePostFromProfile(widget.post.id, !isHiddenFromProfile);
            if (success && parentCtx.mounted) {
              _showSuccessSnackBar(
                parentCtx,
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
        splashColor: const Color(0xFF1E824C).withValues(alpha: 0.08),
        highlightColor: const Color(0xFF1E824C).withValues(alpha: 0.04),
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
                                backgroundImage: (friend.avatarUrl != null && friend.avatarUrl!.isNotEmpty)
                                    ? CachedNetworkImageProvider(friend.avatarUrl!)
                                    : null,
                                child: (friend.avatarUrl == null || friend.avatarUrl!.isEmpty)
                                    ? const Icon(Icons.person)
                                    : null,
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
