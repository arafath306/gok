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
import '../widgets/share_post_sheet.dart';
import 'create_thread_screen.dart';

class ThreadDetailScreen extends StatefulWidget {
  final ThreadPost post;

  const ThreadDetailScreen({super.key, required this.post});

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  final _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;
  bool _scrolledHeader = false;
  String _sortBy = 'top';
  String? _replyToCommentId;
  String? _replyToUsername;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      dbService.incrementThreadViews(widget.post.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final offset = _scrollController.offset;
    if (offset > 0 && !_scrolledHeader) {
      setState(() {
        _scrolledHeader = true;
      });
    } else if (offset <= 0 && _scrolledHeader) {
      setState(() {
        _scrolledHeader = false;
      });
    }
  }

  Future<void> _loadComments({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoadingComments = true;
      });
    }

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
        parentContext: context,
        onCommentHidden: (id) {
          setState(() {
            _comments.removeWhere((c) => c['id'] == id || c['parent_id'] == id);
          });
        },
        onCommentDeleted: (id) {
          setState(() {
            _comments.removeWhere((c) => c['id'] == id || c['parent_id'] == id);
          });
        },
        onCommentEdited: (id, newContent) {
          setState(() {
            final idx = _comments.indexWhere((c) => c['id'] == id);
            if (idx != -1) {
              _comments[idx]['content'] = newContent;
            }
          });
        },
      ),
    );
  }

  void _showPostQuickActions(BuildContext context, DatabaseService dbService, ThreadPost post) {
    final isAuthor = post.userId == dbService.currentUid;
    final isPinned = post.isPinned;
    final isMuted = post.muteNotifications;
    final isHiddenFromProfile = post.hideFromProfile;
    
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
              const SizedBox(height: 16),
              if (isAuthor) ...[
                ListTile(
                  leading: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: context.textPrimary),
                  title: Text(isPinned ? 'Unpin from profile' : 'Pin to profile', style: GoogleFonts.inter(color: context.textPrimary)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await dbService.togglePinPost(post.id, !isPinned);
                  },
                ),
                ListTile(
                  leading: Icon(isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined, color: context.textPrimary),
                  title: Text(isMuted ? 'Unmute notifications' : 'Mute notifications', style: GoogleFonts.inter(color: context.textPrimary)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await dbService.toggleMutePostNotifications(post.id, !isMuted);
                  },
                ),
                ListTile(
                  leading: Icon(isHiddenFromProfile ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: context.textPrimary),
                  title: Text(isHiddenFromProfile ? 'Show on profile' : 'Hide from profile', style: GoogleFonts.inter(color: context.textPrimary)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await dbService.toggleHidePostFromProfile(post.id, !isHiddenFromProfile);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Delete post', style: GoogleFonts.inter(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: context.cardBg,
                        title: const Text("Delete Post"),
                        content: const Text("Are you sure you want to delete this post?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text("Delete", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final success = await dbService.deletePost(post.id);
                      if (success && context.mounted) {
                        Navigator.pop(context); // Close detail screen
                      }
                    }
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.red),
                  title: Text('Report post', style: GoogleFonts.inter(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final reasonController = TextEditingController();
                    final success = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: context.cardBg,
                        title: const Text("Report Post"),
                        content: TextField(
                          controller: reasonController,
                          decoration: const InputDecoration(hintText: "Reason for reporting..."),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text("Submit", style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (success == true && reasonController.text.trim().isNotEmpty) {
                      await dbService.reportComment(post.id, reasonController.text.trim());
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Post reported")),
                        );
                      }
                    }
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
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
      final success = await dbService.addComment(
        widget.post.id,
        text,
        parentId: _replyToCommentId,
      );
      if (success) {
        _commentController.clear();
        setState(() {
          _replyToCommentId = null;
          _replyToUsername = null;
        });
        _loadComments(silent: true);
      }
    } catch (e) {
      debugPrint("Post comment error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to post comment: $e")),
        );
      }
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1).replaceAll('.0', '')}m';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
    }
    return '$count';
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

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.textSecondary, size: 20),
          if (label.isNotEmpty && label != '0') ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment, DatabaseService dbService, {bool isReply = false}) {
    final Profile author = comment['author'] as Profile;
    final isPostAuthor = author.id == widget.post.userId;
    final isLiked = comment['is_liked_by_me'] ?? false;
    final likesCount = comment['likes_count'] ?? 0;

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 56.0 : 24.0,
        right: 24.0,
        top: 10.0,
        bottom: 10.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundColor: Colors.grey[800],
            backgroundImage: (author.avatarUrl != null && author.avatarUrl!.isNotEmpty)
                ? NetworkImage(author.avatarUrl!)
                : null,
            child: (author.avatarUrl == null || author.avatarUrl!.isEmpty)
                ? Icon(Icons.person, size: isReply ? 14 : 18, color: Colors.white54)
                : null,
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
                            fontSize: 14,
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
                        size: 14,
                      ),
                    ],
                    const SizedBox(width: 4),
                    Text(
                      "@${author.username} · ${_formatTime(comment['created_at_raw'] ?? comment['created_at'] ?? '')}",
                      style: GoogleFonts.inter(
                        fontSize: 12,
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
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.more_horiz, size: 16, color: context.textSecondary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showQuickActions(context, comment, dbService),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment['content'] as String? ?? '',
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 13.5,
                    color: context.textPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Reply Action
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _replyToCommentId = comment['parent_id'] ?? comment['id'];
                          _replyToUsername = author.username;
                          _commentController.text = "@${author.username} ";
                        });
                        FocusScope.of(context).requestFocus(_commentFocusNode);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 14, color: context.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            "Reply",
                            style: GoogleFonts.hindSiliguri(fontSize: 11, color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Like Action
                    GestureDetector(
                      onTap: () async {
                        final newLiked = !isLiked;
                        final newLikesCount = newLiked ? likesCount + 1 : (likesCount - 1 < 0 ? 0 : likesCount - 1);
                        setState(() {
                          comment['is_liked_by_me'] = newLiked;
                          comment['likes_count'] = newLikesCount;
                        });
                        await dbService.toggleCommentLike(comment['id'], newLiked);
                        _loadComments(silent: true);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: isLiked ? Colors.red : context.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatCount(likesCount),
                            style: TextStyle(
                              fontSize: 12,
                              color: isLiked ? Colors.red : context.textSecondary,
                              fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sharePost(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SharePostSheet(post: widget.post),
    );
  }

  Widget _buildSortButton(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFF1E824C).withOpacity(0.15) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E824C) : context.border,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.hindSiliguri(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF1E824C) : context.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final activePost = dbService.getLatestPost(widget.post);

    // Sort comments based on selected sort option
    final sortedComments = List<Map<String, dynamic>>.from(_comments);
    if (_sortBy == 'recent') {
      sortedComments.sort((a, b) => (b['created_at_raw'] ?? '').compareTo(a['created_at_raw'] ?? ''));
    } else {
      sortedComments.sort((a, b) => (b['likes_count'] ?? 0).compareTo(a['likes_count'] ?? 0));
    }

    // Separate top-level comments and nested replies
    final topLevelComments = sortedComments.where((c) => c['parent_id'] == null).toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        centerTitle: false,
        leadingWidth: _scrolledHeader ? 0 : 56,
        leading: _scrolledHeader 
            ? const SizedBox.shrink()
            : IgnorePointer(
                ignoring: _scrolledHeader,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: context.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
        title: AnimatedOpacity(
          opacity: _scrolledHeader ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey[800],
                backgroundImage: activePost.author.avatarUrl != null && activePost.author.avatarUrl!.isNotEmpty
                    ? NetworkImage(activePost.author.avatarUrl!)
                    : null,
                child: activePost.author.avatarUrl == null || activePost.author.avatarUrl!.isEmpty
                    ? const Icon(Icons.person, size: 14)
                    : null,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activePost.author.fullName,
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    "${_formatCount(activePost.viewsCount)} views",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: context.textSecondary,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          AnimatedOpacity(
            opacity: _scrolledHeader ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_scrolledHeader,
              child: IconButton(
                icon: Icon(Icons.more_horiz, color: context.textPrimary),
                onPressed: () => _showPostQuickActions(context, dbService, activePost),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
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
                          backgroundColor: Colors.grey[800],
                          backgroundImage: (activePost.author.avatarUrl != null && activePost.author.avatarUrl!.isNotEmpty)
                              ? NetworkImage(activePost.author.avatarUrl!)
                              : null,
                          child: (activePost.author.avatarUrl == null || activePost.author.avatarUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 24, color: Colors.white54)
                              : null,
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
                                  const SizedBox(width: 8),
                                  Text(
                                    "· ${_formatTime(activePost.createdAt)}",
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    "@${activePost.author.username}",
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.remove_red_eye_outlined, size: 13, color: context.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${_formatCount(activePost.viewsCount)} views",
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showPostQuickActions(context, dbService, activePost),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(Icons.more_horiz, color: context.textSecondary),
                          ),
                        ),
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
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: context.textPrimary,
                          ),
                        ),
                        if (activePost.isRepost && activePost.repostedPost != null)
                          _buildNestedOriginalPost(context, dbService, activePost.repostedPost!),
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
                        Divider(height: 24, color: context.border),

                        // Action buttons with inline counts and Save post
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Like Button (React)
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                dbService.toggleLike(activePost.id, !activePost.isLikedByMe);
                              },
                              child: Row(
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(scale: animation, child: child),
                                    child: activePost.isLikedByMe
                                        ? const Icon(
                                            Icons.favorite,
                                            key: ValueKey<int>(1),
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
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatCount(activePost.likesCount),
                                    style: TextStyle(
                                      color: activePost.isLikedByMe ? Colors.red : context.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Comment Button
                            _buildActionButton(
                              icon: Icons.chat_bubble_outline_rounded,
                              label: _formatCount(_comments.length),
                              onTap: () {
                                FocusScope.of(context).requestFocus(_commentFocusNode);
                              },
                            ),
                            // Repost Button
                            _buildActionButton(
                              icon: Icons.repeat_rounded,
                              label: _formatCount(activePost.repostsCount),
                              onTap: () {
                                _showRepostOptions(context, dbService, activePost);
                              },
                            ),
                            // Save Button (Bookmark)
                            GestureDetector(
                              onTap: () async {
                                final wasSaved = dbService.isSaved(activePost.id);
                                await dbService.toggleSaveThread(activePost.id);
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
                                dbService.isSaved(activePost.id) ? Icons.bookmark : Icons.bookmark_border_rounded,
                                color: dbService.isSaved(activePost.id) ? const Color(0xFF1E824C) : context.textSecondary,
                                size: 20,
                              ),
                            ),
                            // Share Button
                            _buildActionButton(
                              icon: Icons.send_outlined,
                              label: "",
                              onTap: () {
                                _sharePost(context);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Comments section header with filter buttons
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    color: context.isDarkMode ? const Color(0xFF0A0B10) : Colors.grey[50],
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _sortBy = 'top';
                            });
                          },
                          child: Text(
                            "Top",
                            style: GoogleFonts.inter(
                              fontSize: 12.0,
                              fontWeight: _sortBy == 'top' ? FontWeight.bold : FontWeight.normal,
                              color: _sortBy == 'top' ? const Color(0xFF1E824C) : context.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _sortBy = _sortBy == 'top' ? 'recent' : 'top';
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 17,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.5),
                              color: context.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              alignment: _sortBy == 'top' ? Alignment.centerLeft : Alignment.centerRight,
                              child: Container(
                                width: 13,
                                height: 13,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF1E824C),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _sortBy = 'recent';
                            });
                          },
                          child: Text(
                            "Recent",
                            style: GoogleFonts.inter(
                              fontSize: 12.0,
                              fontWeight: _sortBy == 'recent' ? FontWeight.bold : FontWeight.normal,
                              color: _sortBy == 'recent' ? const Color(0xFF1E824C) : context.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Comments List (Supports nesting for replies)
                  if (_isLoadingComments)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF1E824C))),
                    )
                  else if (topLevelComments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          "No comments found.",
                          style: GoogleFonts.inter(color: context.textSecondary),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: topLevelComments.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
                      itemBuilder: (context, index) {
                        final comment = topLevelComments[index];
                        final replies = sortedComments.where((c) => c['parent_id'] == comment['id']).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCommentItem(comment, dbService, isReply: false),
                            if (replies.isNotEmpty) ...[
                              ...replies.map((reply) => _buildCommentItem(reply, dbService, isReply: true)),
                            ],
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // Replying preview banner
          if (_replyToCommentId != null)
            Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                border: Border(top: BorderSide(color: context.border, width: 0.5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Text(
                    "Replying to @$_replyToUsername",
                    style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _replyToCommentId = null;
                        _replyToUsername = null;
                      });
                    },
                    child: Icon(Icons.close, size: 14, color: context.textMuted),
                  ),
                ],
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
                            focusNode: _commentFocusNode,
                            style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                            decoration: InputDecoration(
                              hintText: _replyToCommentId != null ? "Reply..." : "Comment...",
                              hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
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
}
