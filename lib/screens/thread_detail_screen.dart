import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/thread_post.dart';
import '../models/profile.dart';
import '../services/database_service.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/share_comment_sheet.dart';
import 'comment_detail_screen.dart';
import '../utils/routes.dart';
import '../utils/app_theme.dart';
import 'profile/profile_screen.dart';
import 'package:flutter/services.dart';
import '../widgets/share_post_sheet.dart';
import 'create_thread_screen.dart';
import '../services/sound_service.dart';

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
  String _sortBy = "Most relevant";

  Uint8List? _selectedImageBytes;
  bool _isUploading = false;
  bool _showEmojiPanel = false;

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
          // Store ALL comments (top-level + replies). The UI at line ~641 filters topLevelComments,
          // then looks up replies from this same list — so we need the full set here.
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
    if (text.isEmpty && _selectedImageBytes == null) return;

    setState(() => _isUploading = true);
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    String? imageUrl;
    try {
      if (_selectedImageBytes != null) {
        imageUrl = await dbService.uploadPostImage(_selectedImageBytes!);
      }

      final success = await dbService.addComment(
        widget.post.id,
        text,
        imageUrl: imageUrl,
      );

      if (success) {
        _commentController.clear();
        setState(() {
          _selectedImageBytes = null;
          _showEmojiPanel = false;
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
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _pickCommentImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return;
      
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    } catch (e) {
      debugPrint("Error picking comment image: $e");
    }
  }

  void _insertEmoji(String emoji) {
    final text = _commentController.text;
    final selection = _commentController.selection;
    
    if (!selection.isValid) {
      _commentController.text = text + emoji;
      return;
    }
    
    final start = selection.start;
    final end = selection.end;
    
    final newText = text.replaceRange(start, end, emoji);
    _commentController.text = newText;
    
    _commentController.selection = TextSelection.collapsed(
      offset: start + emoji.length,
    );
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
          Icon(icon, color: context.textSecondary, size: 18),
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

  Widget _buildCommentItem(Map<String, dynamic> comment, DatabaseService dbService) {
    final Profile author = comment['author'] as Profile;
    final isPostAuthor = author.id == widget.post.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              backgroundColor: Colors.grey[800],
              backgroundImage: (author.avatarUrl != null && author.avatarUrl!.isNotEmpty)
                  ? NetworkImage(author.avatarUrl!)
                  : null,
              child: (author.avatarUrl == null || author.avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 18, color: Colors.white54)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
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
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: author.fullName,
                                style: GoogleFonts.hindSiliguri(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15.5,
                                  color: context.textPrimary,
                                ),
                              ),
                              if (author.isVerified)
                                const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 15,
                                    ),
                                  ),
                                ),
                              TextSpan(
                                text: ' @${author.username}',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: context.textSecondary,
                                ),
                              ),
                              TextSpan(
                                text: ' · ${_formatTime(comment['created_at_raw'] ?? comment['created_at'] ?? '')}',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                    const SizedBox(width: 8),
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
                    fontSize: 15.5,
                    color: context.textPrimary,
                    height: 1.45,
                  ),
                ),
                if (comment['image_url'] != null && (comment['image_url'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      comment['image_url'] as String,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Likes action
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
                      child: Row(
                        children: [
                          Icon(
                            (comment['is_liked_by_me'] as bool? ?? false)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 15,
                            color: (comment['is_liked_by_me'] as bool? ?? false)
                                ? Colors.red
                                : context.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${comment['likes_count'] ?? 0}",
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

                    // Comments/Replies metric (opens CommentDetailScreen)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommentDetailScreen(
                              comment: comment,
                              threadId: widget.post.id,
                            ),
                          ),
                        ).then((_) => _loadComments(silent: true)); // Reload on back to get reply counts
                      },
                      child: Row(
                        children: [
                          Icon(Icons.mode_comment_outlined, size: 15, color: context.textSecondary),
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

                    // Save/Bookmark comment
                    GestureDetector(
                      onTap: () async {
                        final bool currentSaved = comment['is_saved_by_me'] as bool? ?? false;
                        final bool newSaved = !currentSaved;
                        final int currentSaves = comment['saves_count'] as int? ?? 0;

                        setState(() {
                          comment['is_saved_by_me'] = newSaved;
                          comment['saves_count'] = newSaved 
                              ? currentSaves + 1 
                              : (currentSaves > 0 ? currentSaves - 1 : 0);
                        });
                        await dbService.toggleSaveComment(comment['id'] as String);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(newSaved ? "Comment saved to bookmarks" : "Comment removed from bookmarks"),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            (comment['is_saved_by_me'] as bool? ?? false)
                                ? Icons.bookmark
                                : Icons.bookmark_border_rounded,
                            size: 15,
                            color: (comment['is_saved_by_me'] as bool? ?? false)
                                ? const Color(0xFF1E824C)
                                : context.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${comment['saves_count'] ?? 0}",
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

                    // Share Comment
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (sheetCtx) => ShareCommentSheet(comment: comment),
                        ).then((_) {
                          _loadComments(silent: true);
                        });
                      },
                      child: Row(
                        children: [
                          Icon(Icons.send_outlined, size: 15, color: context.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            "${comment['shares_count'] ?? 0}",
                            style: GoogleFonts.inter(
                              fontSize: 13, 
                              fontWeight: FontWeight.w500,
                              color: context.textSecondary,
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

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final activePost = dbService.getLatestPost(widget.post);

    // Sort comments based on selected sort option
    final sortedComments = List<Map<String, dynamic>>.from(_comments);
    if (_sortBy == "Newest") {
      sortedComments.sort((a, b) => (b['created_at_raw'] ?? b['created_at'] ?? '').compareTo(a['created_at_raw'] ?? a['created_at'] ?? ''));
    } else if (_sortBy == "Oldest") {
      sortedComments.sort((a, b) => (a['created_at_raw'] ?? a['created_at'] ?? '').compareTo(b['created_at_raw'] ?? b['created_at'] ?? ''));
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
                                  Flexible(
                                    child: GestureDetector(
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
                                          Flexible(
                                            child: Text(
                                              activePost.author.fullName,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              style: GoogleFonts.hindSiliguri(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                                color: context.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (activePost.author.isVerified) ...[
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
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.remove_red_eye_outlined, size: 13, color: context.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${_formatCount(activePost.viewsCount)} views",
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 13,
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
                          style: GoogleFonts.hindSiliguri(
                            fontSize: 17.5,
                            color: context.textPrimary,
                            height: 1.45,
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
                                if (!activePost.isLikedByMe) {
                                  SoundService.playLike();
                                }
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
                                            size: 18,
                                          )
                                        : Icon(
                                            Icons.favorite_border,
                                            key: const ValueKey<int>(0),
                                            color: context.textSecondary,
                                            size: 18,
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
                              icon: Icons.mode_comment_outlined,
                              label: _formatCount(_comments.length),
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (sheetContext) => CommentsSheet(post: activePost),
                                ).then((_) => _loadComments(silent: true));
                              },
                            ),
                            // Repost Button
                            GestureDetector(
                              onTap: () {
                                _showRepostOptions(context, dbService, activePost);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.repeat_rounded, 
                                    color: dbService.isReposted(activePost.id) 
                                        ? const Color(0xFF1E824C) 
                                        : context.textSecondary, 
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatCount(activePost.repostsCount),
                                    style: TextStyle(
                                      color: dbService.isReposted(activePost.id) 
                                          ? const Color(0xFF1E824C) 
                                          : context.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Save Button (Bookmark)
                            GestureDetector(
                              onTap: () {
                                final wasSaved = dbService.isSaved(activePost.id);
                                dbService.toggleSaveThread(activePost.id);
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    dbService.isSaved(activePost.id) ? Icons.bookmark : Icons.bookmark_border_rounded,
                                    color: dbService.isSaved(activePost.id) ? const Color(0xFF1E824C) : context.textSecondary,
                                    size: 18,
                                  ),
                                  if (activePost.savesCount > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatCount(activePost.savesCount),
                                      style: TextStyle(
                                        color: dbService.isSaved(activePost.id) ? const Color(0xFF1E824C) : context.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Share Button
                            _buildActionButton(
                              icon: Icons.send_outlined,
                              label: _formatCount(activePost.sharesCount),
                              onTap: () {
                                _sharePost(context);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Comments section header with filter dropdown
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    color: context.isDarkMode ? const Color(0xFF0A0B10) : Colors.grey[50],
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
                        return _buildCommentItem(comment, dbService);
                      },
                    ),
                ],
              ),
            ),
          ),

          // Unified Sticky Bottom Input Composer (matching CommentsSheet & CommentDetailScreen)
          Container(
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border(
                top: BorderSide(color: context.border, width: 1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected image preview
                if (_selectedImageBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 60, top: 12, bottom: 4),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.border, width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              _selectedImageBytes!,
                              height: 90,
                              width: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImageBytes = null;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Input Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: context.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        backgroundImage: (dbService.myProfile?.avatarUrl != null && dbService.myProfile!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(dbService.myProfile!.avatarUrl!)
                            : null,
                        child: (dbService.myProfile?.avatarUrl == null || dbService.myProfile!.avatarUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 16, color: Colors.white54)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocusNode,
                          style: GoogleFonts.hindSiliguri(fontSize: 14.5, color: context.textPrimary),
                          maxLines: 5,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: "Write a comment...",
                            hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 14.5),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action toolbar (media buttons + send button)
                Padding(
                  padding: const EdgeInsets.only(left: 44, right: 16, bottom: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.image_outlined, size: 20, color: const Color(0xFF1E824C)),
                        onPressed: _pickCommentImage,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          _showEmojiPanel ? Icons.keyboard_hide_outlined : Icons.sentiment_satisfied_alt_outlined, 
                          size: 20, 
                          color: const Color(0xFF1E824C)
                        ),
                        onPressed: () {
                          setState(() {
                            _showEmojiPanel = !_showEmojiPanel;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Spacer(),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _commentController,
                        builder: (context, value, child) {
                          final hasText = value.text.trim().isNotEmpty;
                          final hasImage = _selectedImageBytes != null;
                          final isEnabled = (hasText || hasImage) && !_isUploading;

                          return TextButton(
                            onPressed: isEnabled ? _postComment : null,
                            style: TextButton.styleFrom(
                              backgroundColor: isEnabled ? const Color(0xFF1E824C) : Colors.grey[300]?.withOpacity(0.4),
                              foregroundColor: isEnabled ? Colors.white : Colors.grey[400],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              minimumSize: const Size(60, 0),
                            ),
                            child: _isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    "Reply",
                                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Popular Emoji Row Panel
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: _showEmojiPanel ? 48 : 0,
                  child: _showEmojiPanel
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          color: context.isDarkMode ? Colors.black12 : Colors.grey[50],
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: [
                              '😂', '❤️', '👍', '😍', '🔥', '😮', '😢', '🙌', '👏', '🤔', '🎉', '✨', '💯', '🚀', '👀', '💡', '🌟', '😭'
                            ].map((emoji) {
                              return GestureDetector(
                                onTap: () => _insertEmoji(emoji),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  child: Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      : const SizedBox.shrink(),
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

}
