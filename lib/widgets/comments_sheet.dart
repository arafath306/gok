import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/thread_post.dart';
import '../models/profile.dart';
import '../services/database_service.dart';
import '../services/general_settings_provider.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/comment_detail_screen.dart';
import 'share_comment_sheet.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';

import 'comment_attachment_picker_panel.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommentsSheet extends StatefulWidget {
  final ThreadPost post;
  const CommentsSheet({super.key, required this.post});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  final _focusNode = FocusNode();
  List<Map<String, dynamic>> _comments = [];
  List<Map<String, dynamic>> _sortedComments = [];
  bool _isLoading = false;
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
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _replyToCommentId;
  String? _replyToUsername;

  String get _effectiveThreadId => widget.post.isRepost && widget.post.repostedPost != null
      ? widget.post.repostedPost!.id
      : widget.post.id;

  void _sortComments() {
    final settings = Provider.of<GeneralSettingsProvider>(context, listen: false);
    final isPriorityEnabled = settings.isAlgorithmicPriorityEnabled;

    int getPriority(Map<String, dynamic> c) {
      if (!isPriorityEnabled) return 0;
      final author = c['author'];
      if (author == null) return 0;
      if (author.badgeType == 'gold') return 3;
      if (author.badgeType == 'gray') return 2;
      if (author.isVerified == true) return 1;
      return 0;
    }

    _sortedComments = List<Map<String, dynamic>>.from(_comments);
    
    _sortedComments.sort((a, b) {
      final pA = getPriority(a);
      final pB = getPriority(b);
      if (pA != pB) return pB.compareTo(pA);

      if (_sortBy == "Newest") {
        return (b['created_at_raw'] ?? b['created_at'] ?? '').compareTo(a['created_at_raw'] ?? a['created_at'] ?? '');
      } else if (_sortBy == "Oldest") {
        return (a['created_at_raw'] ?? a['created_at'] ?? '').compareTo(b['created_at_raw'] ?? b['created_at'] ?? '');
      } else {
        return (b['likes_count'] ?? 0).compareTo(a['likes_count'] ?? 0);
      }
    });
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      debugPrint("DEBUG: _effectiveThreadId is '$_effectiveThreadId', widget.post.id is '${widget.post.id}'");
      final comments = await dbService.fetchComments(_effectiveThreadId);
      if (mounted) {
        setState(() {
          // Filter: only display top-level comments (parent_id == null)
          _comments = comments.where((c) => c['parent_id'] == null).toList();
          _sortComments();
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

  void _submitComment() async {
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
        _effectiveThreadId,
        text,
        parentId: _replyToCommentId,
        imageUrl: imageUrl,
      );

      if (success) {
        _commentController.clear();
        setState(() {
          _selectedImageBytes = null;
          _selectedGifUrl = null;
          _replyToCommentId = null;
          _showEmojiPanel = false;
        });
        _loadComments();
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

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final myProf = dbService.myProfile;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85 - MediaQuery.of(context).viewInsets.bottom,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 2),
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
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : _comments.isEmpty
                      ? Center(
                          child: Text(
                            "No comments found.",
                            style: GoogleFonts.inter(color: context.textMuted),
                          ),
                        )
                      : (() {
                          final settings = Provider.of<GeneralSettingsProvider>(context);
                          final isPriorityEnabled = settings.isAlgorithmicPriorityEnabled;

                          int getPriority(Map<String, dynamic> c) {
                            if (!isPriorityEnabled) return 0;
                            // Wait, in comments_sheet, is 'profiles' available or is it mapped to 'author'?
                            // Let's check the code: final Profile author = comment['author'] as Profile;
                            final author = c['author'];
                            if (author == null) return 0;
                            if (author.badgeType == 'gold') return 3;
                            if (author.badgeType == 'gray') return 2;
                            if (author.isVerified == true) return 1;
                            return 0;
                          }

                          final sortedComments = List<Map<String, dynamic>>.from(_comments);
                          
                          sortedComments.sort((a, b) {
                            final pA = getPriority(a);
                            final pB = getPriority(b);
                            if (pA != pB) return pB.compareTo(pA);

                            if (_sortBy == "Newest") {
                              return (b['created_at_raw'] ?? b['created_at'] ?? '').compareTo(a['created_at_raw'] ?? a['created_at'] ?? '');
                            } else if (_sortBy == "Oldest") {
                              return (a['created_at_raw'] ?? a['created_at'] ?? '').compareTo(b['created_at_raw'] ?? b['created_at'] ?? '');
                            } else {
                              return (b['likes_count'] ?? 0).compareTo(a['likes_count'] ?? 0);
                            }
                          });
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: sortedComments.length,
                            itemBuilder: (context, index) {
                              final comment = sortedComments[index];
                            final Profile author = comment['author'] as Profile;
                            final isPostAuthor = author.id == widget.post.userId;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Commenter Avatar
                                  Container(
                                    margin: const EdgeInsets.only(top: 4.5),
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
                                      child: CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.grey[800],
                                        backgroundImage: (author.avatarUrl != null && author.avatarUrl!.isNotEmpty)
                                            ? CachedNetworkImageProvider(author.avatarUrl!)
                                            : null,
                                        child: (author.avatarUrl == null || author.avatarUrl!.isEmpty)
                                            ? const Icon(Icons.person, size: 18, color: Colors.white54)
                                            : null,
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
                                                 child: Row(
                                                   crossAxisAlignment: CrossAxisAlignment.center,
                                                   children: [
                                                     Expanded(
                                                       child: Text.rich(
                                                         TextSpan(
                                                           children: [
                                                             TextSpan(
                                                               text: '${author.fullName} ',
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
                                                                   padding: EdgeInsets.only(right: 4, bottom: 2),
                                                                   child: Icon(
                                                                     Icons.verified,
                                                                     color: Colors.blue,
                                                                     size: 15,
                                                                   ),
                                                                 ),
                                                               ),
                                                             TextSpan(
                                                               text: '@${author.username}',
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
                                                     if (comment['created_at'] != null && comment['created_at'].toString().isNotEmpty)
                                                       Padding(
                                                         padding: const EdgeInsets.only(left: 4),
                                                         child: Text(
                                                           '· ${comment['created_at']}',
                                                           style: GoogleFonts.inter(
                                                             fontSize: 13.5,
                                                             color: context.textSecondary,
                                                           ),
                                                         ),
                                                       ),
                                                   ],
                                                 ),
                                               ),
                                             ),
                                             if (isPostAuthor) ...[
                                               const SizedBox(width: 6),
                                               Container(
                                                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                 decoration: BoxDecoration(
                                                   color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                                   borderRadius: BorderRadius.circular(4),
                                                 ),
                                                 child: Text(
                                                   "Author",
                                                   style: GoogleFonts.inter(
                                                     color: Theme.of(context).primaryColor,
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

                                        // Content Text
                                        Text(
                                          comment['content'] as String,
                                          style: GoogleFonts.hindSiliguri(
                                            fontSize: 15.5,
                                            color: context.textPrimary,
                                            height: 1.45,
                                          ),
                                        ),
                                        if (comment['image_url'] != null && (comment['image_url'] as String).isNotEmpty) ...[
                                          const SizedBox(height: 2),
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
                                        const SizedBox(height: 2),

                                        // Action Row
                                        Row(
                                          children: [
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
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    (comment['is_liked_by_me'] as bool? ?? false)
                                                        ? CupertinoIcons.heart_fill
                                                        : CupertinoIcons.heart,
                                                    size: 15,
                                                    color: (comment['is_liked_by_me'] as bool? ?? false)
                                                        ? Colors.red
                                                        : context.textPrimary.withValues(alpha: 0.75),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "${comment['likes_count'] ?? 0}",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13, 
                                                      fontWeight: FontWeight.w500,
                                                      color: context.textPrimary.withValues(alpha: 0.75),
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
                                                      threadId: _effectiveThreadId,
                                                    ),
                                                  ),
                                                ).then((_) => _loadComments()); // Reload on back to get reply counts
                                              },
                                              child: Row(
                                                children: [
                                                  Icon(CupertinoIcons.chat_bubble, size: 15, color: context.textPrimary.withValues(alpha: 0.75)),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "${comment['replies_count'] ?? 0}",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13, 
                                                      fontWeight: FontWeight.w500,
                                                      color: context.textPrimary.withValues(alpha: 0.75),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 24),

                                            // Save/Bookmark comment
                                            GestureDetector(
                                              onTap: () {
                                                final bool currentSaved = comment['is_saved_by_me'] as bool? ?? false;
                                                final bool newSaved = !currentSaved;
                                                final int currentSaves = comment['saves_count'] as int? ?? 0;

                                                setState(() {
                                                  comment['is_saved_by_me'] = newSaved;
                                                  comment['saves_count'] = newSaved 
                                                      ? currentSaves + 1 
                                                      : (currentSaves > 0 ? currentSaves - 1 : 0);
                                                });
                                                dbService.toggleSaveComment(comment['id'] as String);
                                                ScaffoldMessenger.of(context).clearSnackBars();
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(newSaved ? "Comment saved to bookmarks" : "Comment removed from bookmarks"),
                                                    duration: const Duration(seconds: 1),
                                                  ),
                                                );
                                              },
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    (comment['is_saved_by_me'] as bool? ?? false)
                                                        ? CupertinoIcons.bookmark_fill
                                                        : CupertinoIcons.bookmark,
                                                    size: 15,
                                                    color: (comment['is_saved_by_me'] as bool? ?? false)
                                                        ? Theme.of(context).primaryColor
                                                        : context.textPrimary.withValues(alpha: 0.75),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "${comment['saves_count'] ?? 0}",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13, 
                                                      fontWeight: FontWeight.w500,
                                                      color: context.textPrimary.withValues(alpha: 0.75),
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
                                                  _loadComments();
                                                });
                                              },
                                              child: Row(
                                                children: [
                                                  Icon(CupertinoIcons.arrowshape_turn_up_right, size: 15, color: context.textPrimary.withValues(alpha: 0.75)),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "${comment['shares_count'] ?? 0}",
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13, 
                                                      fontWeight: FontWeight.w500,
                                                      color: context.textPrimary.withValues(alpha: 0.75),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        if (index < _comments.length - 1) ...[
                                          const SizedBox(height: 12),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      })(),
            ),

            // Sticky Bottom Input Composer
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
                  // 1. Replying to indicator
                  if (_replyToCommentId != null && _replyToUsername != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: context.isDarkMode ? Colors.black26 : Colors.grey[100],
                      width: double.infinity,
                      child: Row(
                        children: [
                          Icon(Icons.reply, size: 14, color: context.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Replying to @$_replyToUsername",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _replyToCommentId = null;
                                _replyToUsername = null;
                              });
                            },
                            child: Icon(Icons.close, size: 16, color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),

                  // 2. Selected image preview
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
                              child: Image.network(
                                _selectedGifUrl!,
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

                  // 3. Input Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: context.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          backgroundImage: (myProf?.avatarUrl != null && myProf!.avatarUrl!.isNotEmpty)
                              ? CachedNetworkImageProvider(myProf.avatarUrl!)
                              : null,
                          child: (myProf?.avatarUrl == null || myProf!.avatarUrl!.isEmpty)
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
                              focusNode: _focusNode,
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

                  // 4. Action toolbar (media buttons + send button)
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
                            _focusNode.unfocus();
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
                            _focusNode.unfocus();
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
                              onPressed: isEnabled ? _submitComment : null,
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
            // Extra padding for safe area at bottom
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

// ─── Comment Quick Actions Bottom Sheet (Twitter/X Style) ──────────────────────
class CommentQuickActionsSheet extends StatefulWidget {
  final Map<String, dynamic> comment;
  final DatabaseService dbService;
  final BuildContext parentContext;
  final Function(String) onCommentHidden;
  final Function(String)? onCommentDeleted;
  final Function(String, String)? onCommentEdited;

  const CommentQuickActionsSheet({
    super.key,
    required this.comment,
    required this.dbService,
    required this.parentContext,
    required this.onCommentHidden,
    this.onCommentDeleted,
    this.onCommentEdited,
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

  static const int _itemCount = 8;

  @override
  void initState() {
    super.initState();
    final author = widget.comment['author'] as Profile;
    _isFollowing = widget.dbService.isFollowingUser(author.id);
    _isMuted = widget.dbService.isMuted(author.id);
    _isBlocked = widget.dbService.isBlocked(author.id);

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
        backgroundColor: Theme.of(ctx).primaryColor,
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

  void _showEditCommentDialog(BuildContext ctx, String commentId, String currentContent) {
    final controller = TextEditingController(text: currentContent);
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Edit Comment", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold, color: context.textPrimary)),
        content: TextField(
          controller: controller,
          style: GoogleFonts.hindSiliguri(color: context.textPrimary),
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
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty) {
                Navigator.pop(dialogCtx);
                if (widget.onCommentEdited != null) {
                  widget.onCommentEdited!(commentId, newContent);
                }
                final success = await widget.dbService.editComment(commentId, newContent);
                if (!ctx.mounted) return;
                if (success) {
                  _showSuccessSnackBar(ctx, "Comment updated successfully");
                }
              }
            },
            child: Text("Save", style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showDeleteCommentConfirm(BuildContext ctx, String commentId) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Comment?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: context.textPrimary),
        ),
        content: Text(
          'Are you sure you want to permanently delete this comment?',
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
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (widget.onCommentDeleted != null) {
                widget.onCommentDeleted!(commentId);
              }
              final threadId = widget.comment['thread_id'] as String? ?? '';
              final parentId = widget.comment['parent_id'] as String?;
              final success = await widget.dbService.deleteComment(commentId, threadId, parentId: parentId);
              if (!ctx.mounted) return;
              if (success) {
                _showSuccessSnackBar(ctx, 'Comment deleted successfully');
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

  @override
  Widget build(BuildContext context) {
    final Profile author = widget.comment['author'] as Profile;
    final username = author.username;
    final commentId = widget.comment['id'] as String;
    final isMyComment = author.id == widget.dbService.currentUid;

    final List<_CommentQuickActionItem> actions;

    if (isMyComment) {
      actions = [
        _CommentQuickActionItem(
          icon: Icons.copy_rounded,
          label: 'Copy comment text',
          onTap: () {
            Navigator.pop(context);
            Clipboard.setData(ClipboardData(text: widget.comment['content'] as String? ?? ''));
            _showSuccessSnackBar(widget.parentContext, 'Comment text copied');
          },
        ),
        _CommentQuickActionItem(
          icon: Icons.edit_outlined,
          label: 'Edit comment',
          onTap: () {
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            _showEditCommentDialog(parentCtx, commentId, widget.comment['content'] as String? ?? '');
          },
        ),
        _CommentQuickActionItem(
          icon: Icons.delete_outline,
          label: 'Delete comment',
          isDanger: true,
          onTap: () {
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            _showDeleteCommentConfirm(parentCtx, commentId);
          },
        ),
      ];
    } else {
      actions = [
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
          onTap: () async {
            final wasFollowing = _isFollowing;
            setState(() {
              _isFollowing = !wasFollowing;
            });
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            await widget.dbService.toggleFollowUser(author.id);
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

        _CommentQuickActionItem(
          icon: _isMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
          label: _isMuted ? 'Unmute @$username' : 'Mute @$username',
          onTap: () async {
            final wasMuted = _isMuted;
            setState(() {
              _isMuted = !wasMuted;
            });
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            final settingsProvider = Provider.of<GeneralSettingsProvider>(parentCtx, listen: false);
            if (wasMuted) {
              await settingsProvider.unmuteAccount(author.id);
            } else {
              await settingsProvider.muteUserById(author.id);
            }
            await widget.dbService.fetchBlockedMutedLists();
            if (parentCtx.mounted) {
              _showSuccessSnackBar(
                parentCtx,
                wasMuted ? '@$username unmuted' : '@$username has been muted',
              );
            }
          },
        ),
        _CommentQuickActionItem(
          icon: Icons.block_outlined,
          label: _isBlocked ? 'Unblock @$username' : 'Block @$username',
          isDanger: true,
          onTap: () {
            final parentCtx = widget.parentContext;
            Navigator.pop(context);
            if (_isBlocked) {
              _unblockUser(parentCtx, author.id, username);
            } else {
              _showBlockConfirm(parentCtx, username);
            }
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
                color: context.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 2),
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
        splashColor: Theme.of(context).primaryColor.withValues(alpha: 0.08),
        highlightColor: Theme.of(context).primaryColor.withValues(alpha: 0.04),
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
          'They will not be able to follow you, see your posts, or contact you on Pigeon.',
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
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final author = widget.comment['author'] as Profile;
              final settingsProvider = Provider.of<GeneralSettingsProvider>(ctx, listen: false);
              await settingsProvider.blockUserById(author.id);
              await widget.dbService.fetchBlockedMutedLists();
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

  Future<void> _unblockUser(BuildContext ctx, String targetId, String username) async {
    final settingsProvider = Provider.of<GeneralSettingsProvider>(ctx, listen: false);
    await settingsProvider.unblockAccount(targetId);
    await widget.dbService.fetchBlockedMutedLists();
    if (ctx.mounted) {
      _showSuccessSnackBar(ctx, '@$username has been unblocked');
    }
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
                        if (!ctx.mounted) return;
                        _showSuccessSnackBar(
                          ctx,
                          'Report submitted. Thank you for helping keep Pigeon safe.',
                        );
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
