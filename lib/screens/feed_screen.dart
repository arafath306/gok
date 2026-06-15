import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_thread_card.dart';
import '../widgets/thread_shimmer.dart';
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
  ];
  bool _showFullHeader = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = Provider.of<DatabaseService>(context, listen: false);
      if (db.feed.isEmpty && !db.isLoading) {
        db.fetchFeed();
      }
      if (db.myProfile == null) {
        db.fetchMyProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final prof = dbService.myProfile;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: _showFullHeader ? context.scaffoldBg : Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        leading: AnimatedOpacity(
          opacity: _showFullHeader ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: IconButton(
            icon: Icon(Icons.menu_rounded, color: context.textPrimary, size: 24),
            onPressed: _showFullHeader
                ? () {
                    Scaffold.of(context).openDrawer(); 
                  }
                : null,
          ),
        ),
        centerTitle: true,
        title: AnimatedSlide(
          offset: _showFullHeader ? Offset.zero : const Offset(0, 0.05),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "assets/pigeon_logo.png",
                height: 28,
                width: 28,
              ),
              const SizedBox(width: 8),
              Text(
                "Pigeon",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_showFullHeader ? 0.5 : 0.0),
          child: AnimatedOpacity(
            opacity: _showFullHeader ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Divider(
              height: 0.5,
              thickness: 0.5,
              color: context.border,
            ),
          ),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification && notification.metrics.axis == Axis.vertical) {
            final double scrollDelta = notification.scrollDelta ?? 0;
            if (scrollDelta > 5.0 && _showFullHeader) {
              setState(() {
                _showFullHeader = false;
              });
            } else if (scrollDelta < -5.0 && !_showFullHeader) {
              setState(() {
                _showFullHeader = true;
              });
            }
            if (notification.metrics.pixels <= 0 && !_showFullHeader) {
              setState(() {
                _showFullHeader = true;
              });
            }
          }
          return false;
        },
        child: dbService.isLoading
            ? const ThreadShimmer()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    height: _showFullHeader ? 50 : 0,
                    child: AnimatedOpacity(
                      opacity: _showFullHeader ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: context.scaffoldBg,
                            border: Border(
                              bottom: BorderSide(color: context.border, width: 1),
                            ),
                          ),
                          height: 50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_tabs.length, (index) {
                              final isSelected = _selectedTabIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedTabIndex = index;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 28),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _tabs[index],
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF1E824C) : context.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
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
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Feed Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: dbService.fetchFeed,
                    color: const Color(0xFF1E824C),
                    child: ListView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 72),
                      children: [
                        // Composer Panel Card (Flat & Borderless)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: context.border, width: 0.5),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: widget.onNavigateToCreate,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: context.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                  backgroundImage: (prof?.avatarUrl != null && prof!.avatarUrl!.isNotEmpty)
                                      ? NetworkImage(prof.avatarUrl!)
                                      : null,
                                  child: (prof?.avatarUrl == null || prof!.avatarUrl!.isEmpty)
                                      ? Icon(Icons.person, size: 16, color: context.isDarkMode ? Colors.white54 : Colors.black38)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "আজকে কী ভাবছেন?",
                                    style: GoogleFonts.hindSiliguri(
                                      color: context.textMuted,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Feed List based on selected tab
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
                            children: posts.map((post) => CustomThreadCard(key: ValueKey(post.id), post: post)).toList(),
                          );
                        })(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ),
    );
  }
}
