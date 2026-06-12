import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings/notification_settings_screen.dart';
import '../utils/routes.dart';
import 'main_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Follow/following list interaction states
  final Set<String> _followedBack = {};

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                final mainState = context.findAncestorStateOfType<MainScreenState>();
                if (mainState != null) {
                  mainState.setTab(0); // Go back to Home tab (index 0: FeedScreen)
                }
              }
            },
          ),
          title: Text(
            "নোটিফিকেশন",
            style: GoogleFonts.hindSiliguri(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.black87),
              onPressed: () {
                Navigator.push(
                  context,
                  NoTransitionPageRoute(child: const NotificationSettingsScreen()),
                );
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: const Color(0xFF1E824C),
            labelColor: const Color(0xFF1E824C),
            unselectedLabelColor: Colors.black54,
            labelStyle: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.normal,
              fontSize: 13,
            ),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "সব"),
              Tab(text: "অপ্রঠিত"),
              Tab(text: "ফলো/ফলোয়িং"),
              Tab(text: "উল্লেখ"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAllTab(),
            _buildUnreadTab(),
            _buildFollowTab(),
            _buildMentionsTab(),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: সব (ALL) ---
  Widget _buildAllTab() {
    final allNotifications = [
      {
        'name': 'নিলয় চৌধুরী',
        'action': 'আপনার পোস্ট লাইক দিয়েছেন।',
        'time': '2 মিনিট আগে',
        'avatar': 'https://i.pravatar.cc/150?u=niloy',
        'unread': true,
      },
      {
        'name': 'তানভীর আহমেদ',
        'action': 'আপনার পোস্টে মন্তব্য করেছেন।',
        'time': '10 মিনিট আগে',
        'avatar': 'https://i.pravatar.cc/150?u=tanvir',
        'unread': true,
      },
      {
        'name': 'ফারহান ইসলাম',
        'action': 'আপনার পোস্ট শেয়ার করেছেন।',
        'time': '1 ঘণ্টা আগে',
        'avatar': 'https://i.pravatar.cc/150?u=farhan',
        'unread': true,
      },
      {
        'name': 'মেহেজবা নাদিয়া',
        'action': 'আপনার সাথে ফলো করেছেন।',
        'time': '2 ঘণ্টা আগে',
        'avatar': 'https://i.pravatar.cc/150?u=mehezba',
        'unread': true,
      },
      {
        'name': 'জাকির হোসেন',
        'action': 'আপনার সাথে ফলো করেছেন।',
        'time': '3 ঘণ্টা আগে',
        'avatar': 'https://i.pravatar.cc/150?u=zakir',
        'unread': true,
      },
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "নতুন",
            style: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        ...allNotifications.map((item) {
          return _buildNotificationItem(
            name: item['name'] as String,
            action: item['action'] as String,
            time: item['time'] as String,
            avatar: item['avatar'] as String,
            unread: item['unread'] as bool,
          );
        }),
      ],
    );
  }

  // --- TAB 2: অপ্রঠিত (UNREAD) ---
  Widget _buildUnreadTab() {
    final unreadNotifications = [
      {
        'name': 'তানভীর আহমেদ',
        'content': 'খুব সুন্দর হয়েছে! 😍',
        'time': '10 মিনিট আগে',
        'avatar': 'https://i.pravatar.cc/150?u=tanvir',
      },
      {
        'name': 'ফারহান ইসলাম',
        'content': 'এক কাপ কফি আর প্রিয় মানুষের সাথে কিছু সময় — দারুণ! ☕️',
        'time': '1 ঘণ্টা আগে',
        'avatar': 'https://i.pravatar.cc/150?u=farhan',
      },
      {
        'name': 'সায়মা আক্তার',
        'content': 'দারুণ ছবি! কোথায় এটা?',
        'time': '2 ঘণ্টা আগে',
        'avatar': 'https://i.pravatar.cc/150?u=sayma',
      },
      {
        'name': 'জাকির হোসেন',
        'content': 'সুন্দর ক্যাপশন!',
        'time': '3 ঘণ্টা আগে',
        'avatar': 'https://i.pravatar.cc/150?u=zakir',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: unreadNotifications.length,
      itemBuilder: (context, index) {
        final item = unreadNotifications[index];
        return _buildUnreadNotificationItem(
          name: item['name']!,
          content: item['content']!,
          time: item['time']!,
          avatar: item['avatar']!,
        );
      },
    );
  }

  // --- TAB 3: ফলো/ফলোয়িং (FOLLOW/FOLLOWING) ---
  Widget _buildFollowTab() {
    final newFollowers = [
      {
        'id': 'saida',
        'name': 'সায়দা আক্তার',
        'action': 'আপনাকে ফলো করেছে',
        'time': '2 মিনিট আগে',
        'avatar': 'https://i.pravatar.cc/150?u=saida',
      },
      {
        'id': 'zakir_follow',
        'name': 'জাকির হোসেন',
        'action': 'আপনাকে ফলো করেছে',
        'time': '1 ঘণ্টা আগে',
        'avatar': 'https://i.pravatar.cc/150?u=zakir',
      },
      {
        'id': 'rifat',
        'name': 'রিফাত হাসান',
        'action': 'আপনাকে ফলো করেছে',
        'time': '3 ঘণ্টা আগে',
        'avatar': 'https://i.pravatar.cc/150?u=rifat',
      },
    ];

    final followingUpdates = [
      {
        'name': 'নিলয় চৌধুরী',
        'action': 'একটি নতুন পোস্ট করেছেন',
        'time': '10 মিনিট আগে',
        'avatar': 'https://i.pravatar.cc/150?u=niloy',
        'thumbnail': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=120&auto=format&fit=crop',
      }
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // Section: নতুন ফলোয়ার
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "নতুন ফলোয়ার",
            style: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        ...newFollowers.map((item) {
          final isFollowed = _followedBack.contains(item['id']);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: NetworkImage(item['avatar']!),
            ),
            title: Text(
              item['name']!,
              style: GoogleFonts.hindSiliguri(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              "${item['action']} • ${item['time']}",
              style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                color: Colors.black45,
              ),
            ),
            trailing: ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isFollowed) {
                    _followedBack.remove(item['id']);
                  } else {
                    _followedBack.add(item['id']!);
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowed ? Colors.grey[200] : Colors.transparent,
                foregroundColor: isFollowed ? Colors.black87 : const Color(0xFF1E824C),
                elevation: 0,
                side: BorderSide(
                  color: isFollowed ? Colors.transparent : const Color(0xFF1E824C),
                  width: 1,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(0, 30),
              ),
              child: Text(
                isFollowed ? "ফলোয়িং" : "ফলো ব্যাক",
                style: GoogleFonts.hindSiliguri(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }),

        const Divider(height: 24, color: Color(0xFFF5F5F5)),

        // Section: আপনার ফলোয়িং
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "আপনার ফলোয়িং",
            style: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        ...followingUpdates.map((item) {
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: NetworkImage(item['avatar']!),
            ),
            title: Text(
              item['name']!,
              style: GoogleFonts.hindSiliguri(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              "${item['action']} • ${item['time']}",
              style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                color: Colors.black45,
              ),
            ),
            trailing: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                image: DecorationImage(
                  image: NetworkImage(item['thumbnail']!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- TAB 4: উল্লেখ (MENTIONS) ---
  Widget _buildMentionsTab() {
    final mentions = [
      {
        'name': 'নিলয় চৌধুরী',
        'action': 'আপনাকে একটি পোস্টে উল্লেখ করেছেন।',
        'time': '10 মিনিট আগে',
        'avatar': 'https://i.pravatar.cc/150?u=niloy',
        'thumbnail': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=120&auto=format&fit=crop',
      },
      {
        'name': 'তানভীর আহমেদ',
        'action': 'আপনাকে একটি মন্তব্যে উল্লেখ করেছেন।',
        'time': '1 ঘণ্টা আগে',
        'avatar': 'https://i.pravatar.cc/150?u=tanvir',
        'thumbnail': 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=120&auto=format&fit=crop',
      },
      {
        'name': 'ফারহান ইসলাম',
        'action': 'আপনাকে একটি কমেন্টে উল্লেখ করেছেন।',
        'time': '2 ঘণ্টা আগে',
        'avatar': 'https://i.pravatar.cc/150?u=farhan',
        'thumbnail': 'https://images.unsplash.com/photo-1517433456452-f9633a875f6f?w=120&auto=format&fit=crop',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: mentions.length,
      itemBuilder: (context, index) {
        final item = mentions[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            backgroundImage: NetworkImage(item['avatar']!),
          ),
          title: Text(
            item['name']!,
            style: GoogleFonts.hindSiliguri(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            "${item['action']} • ${item['time']}",
            style: GoogleFonts.hindSiliguri(
              fontSize: 11,
              color: Colors.black45,
            ),
          ),
          trailing: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              image: DecorationImage(
                image: NetworkImage(item['thumbnail']!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Common List Items Builders ---
  Widget _buildNotificationItem({
    required String name,
    required String action,
    required String time,
    required String avatar,
    required bool unread,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[200],
        backgroundImage: NetworkImage(avatar),
      ),
      title: RichText(
        text: TextSpan(
          style: GoogleFonts.hindSiliguri(
            fontSize: 14,
            color: Colors.black87,
          ),
          children: [
            TextSpan(
              text: "$name ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: action),
          ],
        ),
      ),
      subtitle: Text(
        time,
        style: GoogleFonts.hindSiliguri(
          fontSize: 11,
          color: Colors.black45,
        ),
      ),
      trailing: unread
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  Widget _buildUnreadNotificationItem({
    required String name,
    required String content,
    required String time,
    required String avatar,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF5F5F5), width: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[200],
          backgroundImage: NetworkImage(avatar),
        ),
        title: Text(
          name,
          style: GoogleFonts.hindSiliguri(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              content,
              style: GoogleFonts.hindSiliguri(
                fontSize: 13,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: GoogleFonts.hindSiliguri(
                fontSize: 11,
                color: Colors.black45,
              ),
            ),
          ],
        ),
        trailing: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
