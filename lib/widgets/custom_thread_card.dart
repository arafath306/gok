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
    final isVerified = post.author.fullName == 'Dak Official';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: NetworkImage(
                      post.author.avatarUrl ?? "https://i.pravatar.cc/150",
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
                              const SizedBox(width: 6),
                              Text(
                                "• ${post.createdAt}",
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (!isVerified) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                post.createdAt,
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "•",
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.public,
                                color: Colors.grey[500],
                                size: 12,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_horiz, color: Colors.black87, size: 20),
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
              const SizedBox(height: 12),

              // Post Body Content Text
              Text(
                post.content,
                style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.45,
                ),
              ),

              // Image attachment
              if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
                const SizedBox(height: 10),
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

              const SizedBox(height: 16),

              // Actions Row
              Row(
                children: [
                  // Likes Action
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      dbService.toggleLike(post.id, !post.isLikedByMe);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                          color: post.isLikedByMe ? Colors.red : Colors.black87,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "${post.likesCount}",
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

                  // Comment/Reply Action
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.black87,
                        size: 19,
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
                  const SizedBox(width: 24),

                  // Repost/Quote Action
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.swap_horiz,
                        color: Colors.black87,
                        size: 21,
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
                  const Spacer(),

                  // Send/Share Action
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.send_outlined,
                      color: Colors.black87,
                      size: 19,
                    ),
                    onPressed: () => _sharePost(context),
                  ),
                ],
              ),

              // Overlapping avatars / replies footer representing active engagement
              if (post.likesCount > 0) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 20,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: const CircleAvatar(
                                radius: 8,
                                backgroundImage: NetworkImage("https://i.pravatar.cc/100?u=niloy"),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: const CircleAvatar(
                                radius: 8,
                                backgroundImage: NetworkImage("https://i.pravatar.cc/100?u=tanzir"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${isVerified ? 'নিলয় চৌধুরী' : 'তনজীর আহমেদ'} এবং আরও ${post.likesCount - 1} জন",
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 12.5,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
