import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_thread_card.dart';
import '../widgets/thread_shimmer.dart';
import '../utils/app_theme.dart';
import '../widgets/dak_logo.dart';
import '../widgets/custom_menu_button.dart';
import 'communities/community_home_screen.dart';
import 'main_screen.dart';
import '../models/profile.dart';
import '../models/thread_post.dart';
import 'package:cached_network_image/cached_network_image.dart';
class FeedScreen extends StatefulWidget {
  final VoidCallback onNavigateToChaStation;
  final VoidCallback onNavigateToCreate;

  const FeedScreen({
    super.key,
    required this.onNavigateToChaStation,
    required this.onNavigateToCreate,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with TickerProviderStateMixin {
  late final TabController _tabController;

  /// One ScrollController per tab – preserves scroll position on tab switch.
  final List<ScrollController> _scrollControllers = [
    ScrollController(),
    ScrollController(),
  ];

  /// Track last offsets per tab for direction detection.
  final List<double> _lastScrollOffsets = [0.0, 0.0];

  bool _isFetchingMore = false;

  /// AppBar visibility state.
  bool _isAppBarVisible = true;

  /// Height of the appbar content (excl. status bar).
  static const double _kAppBarContentHeight = 56.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) setState(() {});
      });

    for (int i = 0; i < _scrollControllers.length; i++) {
      _scrollControllers[i].addListener(() => _onTabScroll(i));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = Provider.of<DatabaseService>(context, listen: false);
      if (db.personalizedFeed.isEmpty && !db.isLoading) db.fetchAIFeed();
      if (db.feed.isEmpty && !db.isLoading) db.fetchFeed(silent: true);
      if (db.myProfile == null) db.fetchMyProfile();
    });
  }

  // ── Scroll listener ──────────────────────────────────────────────────────
  void _onTabScroll(int tabIndex) {
    final sc = _scrollControllers[tabIndex];
    if (!sc.hasClients) return;

    final currentOffset = sc.offset;
    final delta = currentOffset - _lastScrollOffsets[tabIndex];
    _lastScrollOffsets[tabIndex] = currentOffset;

    // Show / hide app-bar based on scroll direction.
    // Only react when the ACTIVE tab scrolls.
    if (tabIndex == _tabController.index) {
      if (delta > 8 && _isAppBarVisible && currentOffset > 80) {
        if (mounted) setState(() => _isAppBarVisible = false);
      } else if (delta < -8 && !_isAppBarVisible) {
        if (mounted) setState(() => _isAppBarVisible = true);
      }
    }

    // Infinite pagination (For You tab only).
    if (tabIndex == 0) {
      final threshold = sc.position.maxScrollExtent - 400;
      if (currentOffset >= threshold) _triggerLoadMore();
    }
  }

  void _triggerLoadMore() {
    final db = Provider.of<DatabaseService>(context, listen: false);
    if (db.aiFeedHasMore && !db.isLoading && !_isFetchingMore) {
      setState(() => _isFetchingMore = true);
      db.fetchAIFeed(loadMore: true, silent: true).then((_) {
        if (mounted) setState(() => _isFetchingMore = false);
      });
    }
  }

  Future<void> _onRefresh(int tabIndex) async {
    final db = Provider.of<DatabaseService>(context, listen: false);
    // Make the appbar reappear on pull-to-refresh.
    if (!_isAppBarVisible) setState(() => _isAppBarVisible = true);
    if (tabIndex == 0) {
      await db.fetchAIFeed();
    } else {
      await db.fetchFeed();
    }
  }

  void _onTabTapped(int index) {
    HapticFeedback.selectionClick();
    if (_tabController.index == index) {
      // Tapping the already-active tab scrolls back to top (X/Bluesky behaviour).
      _scrollControllers[index].animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      if (!_isAppBarVisible) setState(() => _isAppBarVisible = true);
    } else {
      setState(() => _tabController.animateTo(index));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final sc in _scrollControllers) { sc.dispose(); }
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final prof = context.select<DatabaseService, Profile?>((db) => db.myProfile);
    final showShimmer = context.select<DatabaseService, bool>((db) => db.isLoading && db.personalizedFeed.isEmpty && db.feed.isEmpty);
    final personalizedFeed = context.select<DatabaseService, List<ThreadPost>>((db) => db.personalizedFeed);
    final followingFeed = context.select<DatabaseService, List<ThreadPost>>((db) => db.feed.where((p) => db.isFollowingUser(p.userId)).toList());
    final topPadding = MediaQuery.of(context).padding.top;
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // ── Floating app-bar ─────────────────────────────────────────
          ClipRect(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _isAppBarVisible
                  ? topPadding + _kAppBarContentHeight
                  : topPadding,
              decoration: BoxDecoration(color: context.scaffoldBg),
              child: OverflowBox(
                // Keep the full intrinsic size so icons never squish.
                maxHeight: topPadding + _kAppBarContentHeight,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: topPadding + _kAppBarContentHeight,
                  child: Column(
                    children: [
                      SizedBox(height: topPadding),
                      SizedBox(
                        height: _kAppBarContentHeight,
                        child: Row(
                          children: [
                            // Hamburger button
                            if (!isDesktop) const CustomMenuButton(),
                            // Centred logo
                            Expanded(
                              child: Center(child: DakLogo(size: 42)),
                            ),


                            // Community icon
                            IconButton(
                              icon: Icon(CupertinoIcons.person_3_fill,
                                  color: context.textPrimary, size: 24),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CommunityHomeScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Divider ──────────────────────────────────────────────────
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: context.border,
          ),

          // ── Tab bar (always pinned) ───────────────────────────────────
          _buildTabBar(context),

          // ── Feed content ─────────────────────────────────────────────
          Expanded(
            child: showShimmer
                ? const ThreadShimmer()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      KeepAliveWrapper(
                        child: _buildFeedList(
                          tabIndex: 0,
                          posts: personalizedFeed,
                          dbService: dbService,
                          prof: prof,
                        ),
                      ),
                      KeepAliveWrapper(
                        child: _buildFeedList(
                          tabIndex: 1,
                          posts: followingFeed,
                          dbService: dbService,
                          prof: prof,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }



  // ── Tab bar ──────────────────────────────────────────────────────────────
  Widget _buildTabBar(BuildContext context) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: context.scaffoldBg,
            border: Border(
              bottom: BorderSide(color: context.border, width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              final isSelected = _tabController.index == index;
              final labels = ["For You", "Following"];
              return GestureDetector(
                onTap: () => _onTabTapped(index),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF1E824C)
                              : context.textSecondary,
                          letterSpacing: isSelected ? -0.2 : 0,
                        ),
                        child: Text(labels[index]),
                      ),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        height: 3,
                        width: isSelected ? 32 : 0,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E824C),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  // ── Feed list ─────────────────────────────────────────────────────────────
  Widget _buildFeedList({
    required int tabIndex,
    required List posts,
    required DatabaseService dbService,
    required dynamic prof,
  }) {
    return RefreshIndicator(
      onRefresh: () => _onRefresh(tabIndex),
      color: const Color(0xFF1E824C),
      displacement: 20,
      child: ListView.builder(
        controller: _scrollControllers[tabIndex],
        // Elastic, iOS-like bounce — same feel as X/Bluesky.
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 72),
        // ignore: deprecated_member_use
        cacheExtent: 3000.0,
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: true,
        itemCount: posts.isEmpty
            ? 2
            : 1 +
                posts.length +
                (_isFetchingMore && tabIndex == 0 ? 1 : 0),
        itemBuilder: (context, index) {
          // ① Create-post bar
          if (index == 0) return _buildCreatePostRow(context, prof);

          // ② Empty states
          if (posts.isEmpty) {
            if (tabIndex == 1 && dbService.followingIds.isEmpty) {
              return _buildEmptyFollowing(context);
            }
            return _buildEmptyFeed(context, tabIndex);
          }

          // ③ Post card
          final postIndex = index - 1;
          if (postIndex < posts.length) {
            return CustomThreadCard(
              key: ValueKey(posts[postIndex].id),
              post: posts[postIndex],
            );
          }

          // ④ Load-more spinner
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF1E824C)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────
  Widget _buildCreatePostRow(BuildContext context, dynamic prof) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onNavigateToCreate,
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: context.isDarkMode
                  ? Colors.grey[800]
                  : Colors.grey[200],
              backgroundImage:
                  (prof?.avatarUrl != null && prof!.avatarUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(prof.avatarUrl!)
                      : null,
              child: (prof?.avatarUrl == null || prof!.avatarUrl!.isEmpty)
                  ? Icon(Icons.person,
                      size: 14,
                      color: context.isDarkMode
                          ? Colors.white54
                          : Colors.black38)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? const Color(0xFF111827)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.border.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Send your thoughts...",
                        style: GoogleFonts.inter(
                          color: context.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFollowing(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "You are not following anyone",
              style: GoogleFonts.inter(
                fontSize: 15,
                color: context.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context
                  .findAncestorStateOfType<MainScreenState>()
                  ?.setTab(1),
              child: Text(
                "Follow users",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color:
                      const Color(0xFF1E824C).withValues(alpha: 0.6),
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

  Widget _buildEmptyFeed(BuildContext context, int tabIndex) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Text(
          tabIndex == 1
              ? "No posts found from people you follow."
              : "No posts found.",
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
      ),
    );
  }
}

// ── TrendingTopicPill ────────────────────────────────────────────────────────

class TrendingTopicPill extends StatefulWidget {
  const TrendingTopicPill({super.key});

  @override
  State<TrendingTopicPill> createState() => _TrendingTopicPillState();
}

class _TrendingTopicPillState extends State<TrendingTopicPill> {
  List<String> _topics = [];
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    final dbService =
        Provider.of<DatabaseService>(context, listen: false);
    final trending = await dbService.fetchTrendingTopics();

    if (trending.isNotEmpty) {
      if (mounted) {
        setState(() {
          _topics =
              trending.map((t) => t['topic_name'] as String).toList();
        });
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer =
        Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || _topics.isEmpty) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _topics.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_topics.isEmpty) return const Expanded(child: SizedBox());

    final currentTopic = _topics[_currentIndex];
    final displayTopic =
        currentTopic.startsWith('#') ? currentTopic : '#$currentTopic';

    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () {
            context
                .findAncestorStateOfType<MainScreenState>()
                ?.setTab(1);
          },
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E824C).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    const Color(0xFF1E824C).withValues(alpha: 0.2),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 14,
                  color: Color(0xFF1E824C),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.5),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      displayTopic,
                      key: ValueKey<String>(displayTopic),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E824C),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
