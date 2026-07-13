import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../services/general_settings_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/thread_post.dart';
import '../services/database_service.dart';
import '../widgets/comments_sheet.dart';
import '../utils/app_theme.dart';
import '../widgets/thread_detail/thread_detail_header.dart';
import '../widgets/thread_detail/thread_detail_body.dart';
import '../widgets/thread_detail/thread_detail_comments_list.dart';
import 'package:flutter/services.dart';
import '../widgets/share_post_sheet.dart';
import '../widgets/comment_attachment_picker_panel.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  String? _selectedGifUrl;
  int _pickerTabIndex = 0;
  bool _isUploading = false;
  bool _showEmojiPanel = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      if (!mounted) return;
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
      return '${diff.inDays}d';
    } catch (e) {
      return isoString;
    }
  }

  void _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty && _selectedImageBytes == null && _selectedGifUrl == null) return;

    setState(() => _isUploading = true);
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    String? imageUrl;
    try {
      if (_selectedGifUrl != null) {
        imageUrl = _selectedGifUrl;
      } else if (_selectedImageBytes != null) {
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
          _selectedGifUrl = null;
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
        _selectedGifUrl = null;
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
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final activePost = context.select<DatabaseService, ThreadPost>((db) => db.getLatestPost(widget.post));

    final settings = Provider.of<GeneralSettingsProvider>(context);
    final isPriorityEnabled = settings.isAlgorithmicPriorityEnabled;

    int getPriority(Map<String, dynamic> c) {
      if (!isPriorityEnabled) return 0;
      final p = c['profiles'] as Map<String, dynamic>?;
      if (p == null) return 0;
      if (p['badge_type'] == 'gold') return 3;
      if (p['badge_type'] == 'gray') return 2;
      if (p['is_verified'] == true) return 1;
      return 0;
    }

    // Sort comments based on selected sort option
    final sortedComments = List<Map<String, dynamic>>.from(_comments);
    
    sortedComments.sort((a, b) {
      final pA = getPriority(a);
      final pB = getPriority(b);
      if (pA != pB) return pB.compareTo(pA); // higher priority first

      if (_sortBy == "Newest") {
        return (b['created_at_raw'] ?? b['created_at'] ?? '').compareTo(a['created_at_raw'] ?? a['created_at'] ?? '');
      } else if (_sortBy == "Oldest") {
        return (a['created_at_raw'] ?? a['created_at'] ?? '').compareTo(b['created_at_raw'] ?? b['created_at'] ?? '');
      } else {
        return (b['likes_count'] ?? 0).compareTo(a['likes_count'] ?? 0);
      }
    });

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
                    ? CachedNetworkImageProvider(activePost.author.avatarUrl!)
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
                  ThreadDetailHeader(
                    activePost: activePost,
                    dbService: dbService,
                    onMoreTap: () => _showPostQuickActions(context, dbService, activePost),
                    formatTime: _formatTime,
                    formatCount: _formatCount,
                  ),

                  // Post content & Action buttons
                  ThreadDetailBody(
                    activePost: activePost,
                    dbService: dbService,
                    commentsCount: _comments.length,
                    onCommentTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (sheetContext) => CommentsSheet(post: activePost),
                      ).then((_) => _loadComments(silent: true));
                    },
                    onShareTap: () => _sharePost(context),
                    formatCount: _formatCount,
                  ),

                  // Comments section
                  ThreadDetailCommentsList(
                    post: widget.post,
                    topLevelComments: topLevelComments,
                    isLoadingComments: _isLoadingComments,
                    sortBy: _sortBy,
                    onSortChanged: (val) {
                      setState(() {
                        _sortBy = val;
                      });
                    },
                    onReloadComments: () => _loadComments(silent: true),
                    onCommentDeleted: (cid) {
                      setState(() {
                        _comments.removeWhere((c) => c['id'] == cid);
                      });
                    },
                    onCommentHidden: (cid) {
                      setState(() {
                        _comments.removeWhere((c) => c['id'] == cid);
                      });
                    },
                    dbService: dbService,
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

                // Selected GIF preview
                if (_selectedGifUrl != null)
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
                            child: CachedNetworkImage(
                              imageUrl: _selectedGifUrl!,
                              height: 90,
                              width: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedGifUrl = null;
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
                            ? CachedNetworkImageProvider(dbService.myProfile!.avatarUrl!)
                            : null,
                        child: (dbService.myProfile?.avatarUrl == null || dbService.myProfile!.avatarUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 16, color: Colors.white54)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.isDarkMode 
                                ? const Color(0xFF161922) 
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: context.border,
                              width: 0.8,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TextField(
                            controller: _commentController,
                            focusNode: _commentFocusNode,
                            style: GoogleFonts.hindSiliguri(fontSize: 14.5, color: context.textPrimary),
                            maxLines: 5,
                            minLines: 1,
                            onTap: () {
                              setState(() {
                                _showEmojiPanel = false;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Write a comment...",
                              hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 14.5),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
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
                        icon: Icon(Icons.image_outlined, size: 22, color: Theme.of(context).primaryColor),
                        onPressed: _pickCommentImage,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(Icons.gif_box_outlined, size: 22, color: Theme.of(context).primaryColor),
                        onPressed: () {
                          _commentFocusNode.unfocus();
                          setState(() {
                            if (_showEmojiPanel && _pickerTabIndex == 1) {
                              _showEmojiPanel = false;
                            } else {
                              _showEmojiPanel = true;
                              _pickerTabIndex = 1;
                            }
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          _showEmojiPanel && _pickerTabIndex == 0 ? Icons.keyboard_hide_outlined : Icons.sentiment_satisfied_alt_outlined, 
                          size: 22, 
                          color: Theme.of(context).primaryColor
                        ),
                        onPressed: () {
                          _commentFocusNode.unfocus();
                          setState(() {
                            if (_showEmojiPanel && _pickerTabIndex == 0) {
                              _showEmojiPanel = false;
                            } else {
                              _showEmojiPanel = true;
                              _pickerTabIndex = 0;
                            }
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
                          final hasGif = _selectedGifUrl != null;
                          final isEnabled = (hasText || hasImage || hasGif) && !_isUploading;

                          return TextButton(
                            onPressed: isEnabled ? _postComment : null,
                            style: TextButton.styleFrom(
                              backgroundColor: isEnabled ? Theme.of(context).primaryColor : Colors.grey[300]?.withValues(alpha: 0.4),
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

                // Premium Emoji / GIF Picker Panel
                if (_showEmojiPanel)
                  CommentAttachmentPickerPanel(
                    initialTabIndex: _pickerTabIndex,
                    onEmojiSelected: (emoji) {
                      _insertEmoji(emoji);
                    },
                    onGifSelected: (gifUrl) {
                      setState(() {
                        _selectedGifUrl = gifUrl;
                        _selectedImageBytes = null; // Clear image when GIF is selected
                        _showEmojiPanel = false; // Close panel on selection
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
