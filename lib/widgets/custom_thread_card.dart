import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/thread_post.dart';
import '../services/database_service.dart';
import '../screens/thread_detail_screen.dart';
import '../utils/routes.dart';

class CustomThreadCard extends StatelessWidget {
  final ThreadPost post;

  const CustomThreadCard({super.key, required this.post});

  void _showReportDialog(BuildContext context, DatabaseService dbService) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("পোস্ট রিপোর্ট করুন", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("কেন এই পোস্টটি রিপোর্ট করতে চান?", style: GoogleFonts.hindSiliguri(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "কারণ লিখুন...",
                hintStyle: GoogleFonts.hindSiliguri(fontSize: 13),
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("বাতিল", style: GoogleFonts.hindSiliguri(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = controller.text.trim();
              if (reason.isNotEmpty) {
                await dbService.reportPost(post.id, reason);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("রিপোর্ট সফলভাবে জমা হয়েছে")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text("জমা দিন", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _sharePost(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("পোস্ট শেয়ার করুন", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.share, size: 40, color: Color(0xFF1E824C)),
            const SizedBox(height: 16),
            Text("পোস্টের লিঙ্ক কপি করুন অথবা শেয়ার করুন।", style: GoogleFonts.hindSiliguri(fontSize: 14)),
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
                const SnackBar(content: Text("লিঙ্ক কপি করা হয়েছে")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E824C),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: Text("লিঙ্ক কপি করুন", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          NoTransitionPageRoute(
            child: ThreadDetailScreen(post: post),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left column: User Avatar & Vertical Thread Line
              Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: NetworkImage(
                      post.author.avatarUrl ?? "https://i.pravatar.cc/150",
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Overlapping tiny avatars representing active comments/replies
                  SizedBox(
                    width: 28,
                    height: 20,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 7,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 6,
                              backgroundImage: NetworkImage("https://i.pravatar.cc/100?u=${post.id}_1"),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: CircleAvatar(
                            radius: 7,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 6,
                              backgroundImage: NetworkImage("https://i.pravatar.cc/100?u=${post.id}_2"),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Right Column: Post Body details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row (Name, verified badge, relative time, options popup)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  post.author.fullName,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.hindSiliguri(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                post.createdAt,
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
                          onSelected: (value) {
                            if (value == 'report') {
                              _showReportDialog(context, dbService);
                            } else if (value == 'share') {
                              _sharePost(context);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(Icons.share, size: 18),
                                  SizedBox(width: 8),
                                  Text("শেয়ার করুন"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'report',
                              child: Row(
                                children: [
                                  Icon(Icons.report, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text("রিপোর্ট করুন", style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Post content text
                    Text(
                      post.content,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),

                    // Image attachment
                    if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          post.imageUrls!.first,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],

                    // Video attachment
                    if (post.videoUrl != null && post.videoUrl!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _sharePost(context),
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8.0),
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

                    const SizedBox(height: 12),

                    // Actions row (Threads alignment)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Likes button
                            GestureDetector(
                              onTap: () {
                                dbService.toggleLike(post.id, !post.isLikedByMe);
                              },
                              child: Icon(
                                post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                                color: post.isLikedByMe ? Colors.red : Colors.black87,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Comment/Reply button
                            const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.black87,
                              size: 18,
                            ),
                            const SizedBox(width: 16),

                            // Repost/Quote button
                            const Icon(
                              Icons.swap_horiz,
                              color: Colors.black87,
                              size: 18,
                            ),
                          ],
                        ),

                        // Paper plane share icon
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.send_outlined,
                            color: Colors.black87,
                            size: 18,
                          ),
                          onPressed: () => _sharePost(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Counts metadata
                    Text(
                      "${post.likesCount} likes • ${post.repliesCount} replies",
                      style: GoogleFonts.hindSiliguri(
                        color: Colors.grey[500],
                        fontSize: 12,
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
  }
}
