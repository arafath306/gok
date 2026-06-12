import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_thread_card.dart';
import '../utils/routes.dart';
import 'new_post_screen.dart';
import 'messenger/messenger_home_screen.dart';
import 'marketplace/marketplace_home_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DatabaseService>(context, listen: false).fetchFeed();
      Provider.of<DatabaseService>(context, listen: false).fetchMyProfile();
    });
  }

  Widget _buildStoriesSection() {
    final mockStories = [
      {'name': 'নিলয় চৌধুরী', 'avatar': 'https://i.pravatar.cc/150?u=niloy'},
      {'name': 'তনজীর আহমেদ', 'avatar': 'https://i.pravatar.cc/150?u=tanzir'},
      {'name': 'ফারহান ইসলাম', 'avatar': 'https://i.pravatar.cc/150?u=farhan'},
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // "আপনার স্টোরি" item
            GestureDetector(
              onTap: () {},
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black12, width: 0.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/logo_d_icon_v2.jpg',
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E824C),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "আপনার স্টোরি",
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Mock users stories
            ...mockStories.map((story) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF3498DB), // Story blue border
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: NetworkImage(story['avatar']!),
                          ),
                        ),
                        Positioned(
                          right: 3,
                          bottom: 3,
                          child: Container(
                            padding: const EdgeInsets.all(1.5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2ECC71), // Online green dot
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      story['name']!,
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePostBar(String? myAvatarUrl) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            NoTransitionPageRoute(child: const NewPostScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF3EE), // Soft green/cream background
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                backgroundImage: NetworkImage(
                  myAvatarUrl ?? "https://i.pravatar.cc/150?u=current_user",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "কি ভাবছেন?",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 15,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.image_outlined,
                color: Color(0xFF1E824C), // Brand green color
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabsSelector() {
    final tabs = ["সবার জন্য", "ফলোয়িং", "জনপ্রিয়"];
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ...tabs.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final label = entry.value;
                  final isSelected = _selectedTab == idx;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTab = idx;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      margin: const EdgeInsets.only(right: 24),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected ? const Color(0xFF1E824C) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? const Color(0xFF1E824C) : Colors.black54,
                            ),
                          ),
                          if (idx == 0) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: isSelected ? const Color(0xFF1E824C) : Colors.black54,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const Spacer(),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.tune_outlined,
                    color: Colors.black54,
                    size: 22,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFECEFF1)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final List<dynamic> displayedPosts = dbService.feed;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8), // Soft warm grey/cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFFEBF5EF), // Light sage-green branding tint
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/logo_d_icon_v2.jpg',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Dak",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E824C),
                    height: 1.1,
                  ),
                ),
                Text(
                  "— সংযোগ থাকুক হৃদয়ের —",
                  style: GoogleFonts.hindSiliguri(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF1E824C), size: 22),
            onPressed: () {
              Navigator.push(
                context,
                NoTransitionPageRoute(child: const MessengerHomeScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.storefront_outlined, color: Colors.black87, size: 23),
            onPressed: () {
              Navigator.push(
                context,
                NoTransitionPageRoute(child: const MarketplaceHomeScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dbService.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E824C)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal Stories row
                _buildStoriesSection(),
                
                // "কি ভাবছেন?" create post bar
                _buildCreatePostBar(dbService.myProfile?.avatarUrl),
                
                // Filters selector bar
                _buildTabsSelector(),
                
                // Feed list with rounded white cards
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: dbService.fetchFeed,
                    color: const Color(0xFF1E824C),
                    child: displayedPosts.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 120),
                              Center(
                                child: Text(
                                  "কোন ডাক পাওয়া যায়নি।",
                                  style: GoogleFonts.hindSiliguri(color: Colors.black45),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            itemCount: displayedPosts.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return CustomThreadCard(post: displayedPosts[index]);
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
