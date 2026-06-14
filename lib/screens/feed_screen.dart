import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_thread_card.dart';
import '../utils/app_theme.dart';
import 'main_screen.dart';

class FeedScreen extends StatefulWidget {
  final VoidCallback onNavigateToChaStation;
  final VoidCallback onNavigateToCreate;

  const FeedScreen({
    Key? key,
    required this.onNavigateToChaStation,
    required this.onNavigateToCreate,
  }) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = [
    "For You",
    "Following",
    "Video",
    "Topic",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DatabaseService>(context, listen: false).fetchFeed();
      Provider.of<DatabaseService>(context, listen: false).fetchMyProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final prof = dbService.myProfile;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: context.textPrimary, size: 24),
          onPressed: () {
            Scaffold.of(context).openDrawer(); 
          },
        ),
        centerTitle: true,
        title: Image.asset(
          "assets/logo_transparent.png",
          height: 48,
          width: 48,
        ),
      ),
      body: dbService.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E824C)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal Scrollable Tabs Bar
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.scaffoldBg,
                    border: Border(
                      bottom: BorderSide(color: context.border, width: 1),
                    ),
                  ),
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _tabs.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedTabIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _tabs[index],
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? const Color(0xFF1E824C) : context.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Rounded Green Underline Indicator
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 3,
                                width: isSelected ? 32 : 0,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E824C),
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Feed Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: dbService.fetchFeed,
                    color: const Color(0xFF1E824C),
                    child: ListView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        // Composer Panel Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: context.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.border, width: 0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: widget.onNavigateToCreate,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: context.isDarkMode ? Colors.grey[900] : Colors.grey[200],
                                  backgroundImage: NetworkImage(
                                    prof?.avatarUrl ?? "https://i.pravatar.cc/150",
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: context.isDarkMode ? const Color(0xFF121422) : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      "আজকে কী ভাবছেন?",
                                      style: GoogleFonts.hindSiliguri(
                                        color: context.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Feed List based on selected tab
                        if (_selectedTabIndex == 2) ...[
                          // Video tab
                          SizedBox(
                            height: 300,
                            child: Center(
                              child: Text(
                                "ভিডিও আপলোড করার সিস্টেম এখনও চালু হয়নি।",
                                style: GoogleFonts.hindSiliguri(color: context.textSecondary),
                              ),
                            ),
                          )
                        ] else ...[
                          (() {
                            final posts = _selectedTabIndex == 1
                                  ? dbService.feed
                                      .where((post) => dbService.isFollowingUser(post.userId))
                                      .toList()
                                  : dbService.feed;

                            if (_selectedTabIndex == 1 && dbService.followingIds.isEmpty) {
                              return SizedBox(
                                height: 300,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "আপনার ফলোয়িং লিস্টে কেউ নেই",
                                        style: GoogleFonts.hindSiliguri(
                                          fontSize: 16,
                                          color: context.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () {
                                          context.findAncestorStateOfType<MainScreenState>()?.setTab(1);
                                        },
                                        child: Text(
                                          "ইউজারদের ফলো করুন",
                                          style: GoogleFonts.hindSiliguri(
                                            fontSize: 15,
                                            color: const Color(0xFF1E824C).withOpacity(0.6),
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (posts.isEmpty) {
                              return SizedBox(
                                height: 300,
                                child: Center(
                                  child: Text(
                                    _selectedTabIndex == 1
                                        ? "আপনি যাদের ফলো করছেন তাদের কোনো ডাক পাওয়া যায়নি।"
                                        : "কোন ডাক পাওয়া যায়নি।",
                                    style: GoogleFonts.hindSiliguri(color: context.textSecondary),
                                  ),
                                ),
                              );
                            }

                            return Column(
                              children: posts.map((post) => CustomThreadCard(post: post)).toList(),
                            );
                          })(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
