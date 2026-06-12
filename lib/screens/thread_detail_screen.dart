import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/thread_post.dart';
import '../models/profile.dart';
import '../services/database_service.dart';

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
          _comments = data.map((json) {
            final authorMap = json['profiles'] as Map<String, dynamic>?;
            final author = authorMap != null 
                ? Profile.fromJson(authorMap) 
                : Profile(id: json['user_id'] ?? '', username: 'unknown', fullName: 'Unknown User');
            final rawTime = json['created_at'] as String? ?? '';
            return {
              'author': author,
              'content': json['content'] as String,
              'created_at': _formatTime(rawTime),
            };
          }).toList();
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint("Load comments error: $e");
      if (mounted) {
        setState(() {
          _isLoadingComments = false;
        });
      }
    }
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
                            Text(
                              "${activePost.likesCount} ",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text("পছন্দ (Likes)   ", style: TextStyle(color: Colors.grey)),
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
                            IconButton(
                              icon: Icon(
                                activePost.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                                color: activePost.isLikedByMe ? Colors.red : Colors.black87,
                              ),
                              onPressed: () {
                                dbService.toggleLike(activePost.id, !activePost.isLikedByMe);
                              },
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
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          author.fullName,
                                          style: GoogleFonts.hindSiliguri(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          comment['created_at'] as String,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment['content'] as String,
                                      style: GoogleFonts.hindSiliguri(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
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
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "কমেন্ট করুন...",
                      hintStyle: GoogleFonts.hindSiliguri(color: Colors.black26),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _postComment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E824C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "পোস্ট",
                    style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
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
