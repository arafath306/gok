import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/thread_post.dart';
import '../models/profile.dart';
import '../services/database_service.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/reactions_sheet.dart';
import '../utils/routes.dart';
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
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('replies')
          .select('*, profiles(*)')
          .eq('thread_id', widget.post.id)
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      if (mounted) {
        setState(() {
          final dbComments = data.map((json) {
            final authorMap = json['profiles'] as Map<String, dynamic>?;
            final author = authorMap != null 
                ? Profile.fromJson(authorMap) 
                : Profile(id: json['user_id'] ?? '', username: 'unknown', fullName: 'Unknown User');
            final rawTime = json['created_at'] as String? ?? '';
            return {
              'id': json['id'] as String? ?? 'db-${json['created_at']}',
              'author': author,
              'content': json['content'] as String,
              'created_at': _formatTime(rawTime),
              'likes_count': 0,
              'replies_count': 5,
              'is_liked_by_me': false,
            };
          }).toList();

          if (dbComments.isEmpty) {
            _comments = [
              {
                'id': 'mock-1',
                'author': Profile(
                  id: 'mock-user-1',
                  username: 'nusrat.jahan',
                  fullName: 'Nusrat Jahan',
                  avatarUrl: 'https://i.pravatar.cc/150?u=nusrat',
                ),
                'content': 'অসাধারণ ছবি! মনটা ভরে গেল 😍 🌿',
                'created_at': '2h',
                'likes_count': 0,
                'replies_count': 12,
                'is_liked_by_me': false,
              },
              {
                'id': 'mock-2',
                'author': Profile(
                  id: 'mock-user-2',
                  username: 'rifat_ahmed',
                  fullName: 'Rifat Ahmed',
                  avatarUrl: 'https://i.pravatar.cc/150?u=rifat',
                ),
                'content': 'দারুণ! কোথায় এটা?',
                'created_at': '2h',
                'likes_count': 0,
                'replies_count': 6,
                'is_liked_by_me': false,
              },
              {
                'id': 'mock-3',
                'author': Profile(
                  id: widget.post.userId,
                  username: 'dakofficial',
                  fullName: 'Dak Official',
                  avatarUrl: 'https://i.pravatar.cc/150?u=dakofficial',
                ),
                'content': 'বান্দরবান, বাংলাদেশের সুন্দর জায়গা ❤️',
                'created_at': '1h',
                'likes_count': 0,
                'replies_count': 24,
                'is_liked_by_me': true,
              }
            ];
          } else {
            _comments = dbComments;
          }
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint("Load comments error: $e");
      if (mounted) {
        setState(() {
          _comments = [
            {
              'id': 'mock-1',
              'author': Profile(
                id: 'mock-user-1',
                username: 'nusrat.jahan',
                fullName: 'Nusrat Jahan',
                avatarUrl: 'https://i.pravatar.cc/150?u=nusrat',
              ),
              'content': 'অসাধারণ ছবি! মনটা ভরে গেল 😍 🌿',
              'created_at': '2h',
              'likes_count': 0,
              'replies_count': 12,
              'is_liked_by_me': false,
            },
            {
              'id': 'mock-2',
              'author': Profile(
                id: 'mock-user-2',
                username: 'rifat_ahmed',
                fullName: 'Rifat Ahmed',
                avatarUrl: 'https://i.pravatar.cc/150?u=rifat',
              ),
              'content': 'দারুণ! কোথায় এটা?',
              'created_at': '2h',
              'likes_count': 0,
              'replies_count': 6,
              'is_liked_by_me': false,
            },
            {
              'id': 'mock-3',
              'author': Profile(
                id: widget.post.userId,
                username: 'dakofficial',
                fullName: 'Dak Official',
                avatarUrl: 'https://i.pravatar.cc/150?u=dakofficial',
              ),
              'content': 'বান্দরবান, বাংলাদেশের সুন্দর জায়গা ❤️',
              'created_at': '1h',
              'likes_count': 0,
              'replies_count': 24,
              'is_liked_by_me': true,
            }
          ];
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

    final supabase = Supabase.instance.client;
    final currentUid = supabase.auth.currentUser?.id;
    if (currentUid == null) return;

    try {
      // Let Supabase auto-set created_at via DB default
      await supabase.from('replies').insert({
        'thread_id': widget.post.id,
        'user_id': currentUid,
        'content': text,
      });
      _commentController.clear();
      _loadComments();
    } catch (e) {
      debugPrint("Post comment error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("মন্তব্য পোস্ট করতে ব্যর্থ হয়েছে")),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black87),
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(
                          child: ProfileScreen(userId: activePost.userId),
                        ),
                      );
                    },
                    child: Padding(
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
                                  children: [
                                    Text(
                                      activePost.author.fullName,
                                      style: GoogleFonts.hindSiliguri(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 14,
                                    ),
                                  ],
                                ),
                                Text(
                                  "@${activePost.author.username}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.more_horiz, color: Colors.grey),
                        ],
                      ),
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
                            color: Colors.black,
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
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const Divider(height: 24, color: Color(0xFFF0F0F0)),

                        // Likes/Comments Count row
                        Row(
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => ReactionsListSheet(post: activePost),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${activePost.likesCount} ",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const Text("পছন্দ (Likes)   ", style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            Text(
                              "${_comments.length} ",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text("মন্তব্য (Replies)", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFF0F0F0)),

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
                              onLongPress: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => ReactionsListSheet(post: activePost),
                                );
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
                                      : const Icon(
                                          Icons.favorite_border,
                                          key: ValueKey<int>(0),
                                          color: Colors.black87,
                                          size: 24,
                                        ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.swap_horiz, color: Colors.black87),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.send_outlined, color: Colors.black87),
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
                    color: Colors.grey[50],
                    child: Text(
                      "মন্তব্যসমূহ",
                      style: GoogleFonts.hindSiliguri(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
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
                          style: GoogleFonts.hindSiliguri(color: Colors.black45),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final Profile author = comment['author'] as Profile;
                        final isPostAuthor = author.id == widget.post.userId;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    NoTransitionPageRoute(
                                      child: ProfileScreen(userId: author.id),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundImage: NetworkImage(
                                    author.avatarUrl ?? "https://i.pravatar.cc/150",
                                  ),
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
                                                color: Colors.black,
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
                                          style: GoogleFonts.outfit(
                                            fontSize: 12.5,
                                            color: Colors.grey[500],
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
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFF1E824C),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.more_horiz, size: 18, color: Colors.black54),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _showQuickActions(context, comment, dbService),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment['content'] as String,
                                      style: GoogleFonts.hindSiliguri(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        // Replies metric
                                        GestureDetector(
                                          onTap: () {},
                                          child: Row(
                                            children: [
                                              const Icon(Icons.chat_bubble_outline, size: 15, color: Colors.black54),
                                              const SizedBox(width: 6),
                                              Text(
                                                "${comment['replies_count'] ?? 0}",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 13, 
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        // Likes metric - heart outline toggling (without number, exactly like screenshot)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              comment['is_liked_by_me'] = !(comment['is_liked_by_me'] as bool? ?? false);
                                            });
                                          },
                                          child: Icon(
                                            (comment['is_liked_by_me'] as bool? ?? false)
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            size: 15,
                                            color: (comment['is_liked_by_me'] as bool? ?? false)
                                                ? Colors.red
                                                : Colors.black54,
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        // Reply button
                                        GestureDetector(
                                          onTap: () {
                                            _commentController.text = "@${author.username} ";
                                          },
                                          child: Text(
                                            "Reply",
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black54,
                                            ),
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
                                              style: GoogleFonts.outfit(
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
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFF0F0F0)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: GoogleFonts.hindSiliguri(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: "কমেন্ট করুন...",
                              hintStyle: GoogleFonts.hindSiliguri(color: Colors.black26, fontSize: 14),
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
                                    icon: const Icon(Icons.image_outlined, size: 18, color: Colors.black54),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {},
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: const Icon(Icons.gif_box_outlined, size: 18, color: Colors.black54),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {},
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: const Icon(Icons.sentiment_satisfied_alt_outlined, size: 18, color: Colors.black54),
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
}
