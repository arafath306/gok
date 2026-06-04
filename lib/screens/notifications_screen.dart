import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = "সব";
  final List<String> _filters = ["সব", "উত্তর", "ফলো", "লাইক", "মেনশন"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DatabaseService>(context, listen: false).fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);

    // Filter logic
    final filteredNotifications = dbService.notifications.where((n) {
      if (_selectedFilter == "সব") return true;
      if (_selectedFilter == "লাইক") return n.type == "LIKE";
      if (_selectedFilter == "উত্তর") return n.type == "REPLY";
      if (_selectedFilter == "মেনশন") return n.type == "MENTION";
      if (_selectedFilter == "ফলো") return n.type == "FOLLOW";
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "কার্যক্রম",
          style: GoogleFonts.hindSiliguri(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flat Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: SizedBox(
              height: 34,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filter,
                        style: GoogleFonts.hindSiliguri(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),

          // Notifications List
          Expanded(
            child: filteredNotifications.isEmpty
                ? Center(
                    child: Text(
                      "কোন খবর পাওয়া যায়নি।",
                      style: GoogleFonts.hindSiliguri(color: Colors.black45),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredNotifications.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: Color(0xFFF5F5F5),
                    ),
                    itemBuilder: (context, index) {
                      final item = filteredNotifications[index];

                      // Define badge icon and color based on notification type
                      IconData badgeIcon = Icons.notifications;
                      Color badgeBgColor = Colors.grey;

                      if (item.type == "LIKE") {
                        badgeIcon = Icons.favorite;
                        badgeBgColor = Colors.red;
                      } else if (item.type == "REPLY") {
                        badgeIcon = Icons.reply;
                        badgeBgColor = Colors.blue;
                      } else if (item.type == "MENTION") {
                        badgeIcon = Icons.alternate_email;
                        badgeBgColor = const Color(0xFF1E824C);
                      } else if (item.type == "FOLLOW") {
                        badgeIcon = Icons.person;
                        badgeBgColor = Colors.purple;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Avatar with Overlay Badge
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: NetworkImage(
                                    item.actor.avatarUrl ?? "https://i.pravatar.cc/150",
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: badgeBgColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    child: Icon(
                                      badgeIcon,
                                      size: 8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),

                            // Center: Details text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.hindSiliguri(
                                        color: Colors.black,
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: item.actor.fullName,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const TextSpan(text: " "),
                                        TextSpan(
                                          text: item.content,
                                          style: const TextStyle(color: Colors.black87),
                                        ),
                                        const TextSpan(text: "  "),
                                        TextSpan(
                                          text: item.createdAt,
                                          style: const TextStyle(color: Colors.black38, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (item.type == "REPLY") ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      "\"উত্তর: ধন্যবাদ সুন্দর মন্তব্যের জন্য!\"",
                                      style: GoogleFonts.hindSiliguri(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Right: Follow Action button if applicable
                            if (item.type == "FOLLOW") ...[
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.black12, width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  minimumSize: const Size(0, 30),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  backgroundColor: Colors.transparent,
                                ),
                                child: Text(
                                  "ফলো ব্যাক",
                                  style: GoogleFonts.hindSiliguri(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
