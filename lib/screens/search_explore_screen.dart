import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/profile.dart';
import '../models/thread_post.dart';
import '../utils/app_theme.dart';
import 'profile/profile_screen.dart';
import 'topic/topic_threads_screen.dart';
import '../widgets/custom_thread_card.dart';

class SearchExploreScreen extends StatefulWidget {
  const SearchExploreScreen({super.key});

  @override
  State<SearchExploreScreen> createState() => _SearchExploreScreenState();
}

class _SearchExploreScreenState extends State<SearchExploreScreen> {
  final List<String> _recentSearches = [];
  List<Profile> _searchResults = [];
  List<ThreadPost> _searchPostResults = [];
  List<Profile> _recommended = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();
  int _searchTabIndex = 0; // 0 for Accounts, 1 for Posts

  List<Map<String, dynamic>> _trendingTopics = [];
  List<Map<String, dynamic>> _risingTopics = [];
  List<Map<String, dynamic>> _discussedTopics = [];
  bool _isTopicsLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendations();
      _loadTopics();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRecommendations() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final recs = await dbService.getRecommendedProfiles();
    if (mounted) {
      setState(() {
        _recommended = recs;
      });
    }
  }

  void _loadTopics() async {
    if (!mounted) return;
    setState(() => _isTopicsLoading = true);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final trending = await dbService.fetchTrendingTopics();
    final rising = await dbService.fetchRisingTopics();
    final discussed = await dbService.fetchMostDiscussedTopics();
    if (mounted) {
      setState(() {
        _trendingTopics = trending;
        _risingTopics = rising;
        _discussedTopics = discussed;
        _isTopicsLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _searchPostResults = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final profileFuture = dbService.searchProfiles(trimmed);
    final threadFuture = dbService.searchThreads(trimmed);

    final results = await Future.wait([profileFuture, threadFuture]);

    if (mounted) {
      setState(() {
        _searchResults = results[0] as List<Profile>;
        _searchPostResults = results[1] as List<ThreadPost>;
        _isLoading = false;
      });
    }
  }

  void _addToHistory(String item) {
    if (item.trim().isEmpty) return;
    setState(() {
      _recentSearches.remove(item);
      _recentSearches.insert(0, item);
      if (_recentSearches.length > 6) {
        _recentSearches.removeLast();
      }
    });
  }

  Widget _buildUserRow(Profile user, DatabaseService dbService) {
    final isFollowing = dbService.isFollowingUser(user.id);
    final currentUid = dbService.myProfile?.id;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: InkWell(
        onTap: () {
          _addToHistory(user.fullName);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileScreen(userId: user.id == currentUid ? null : user.id),
            ),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: Circular Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: context.isDarkMode ? const Color(0xFF1B3B2B) : const Color(0xFFE8F5E9),
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: context.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Center: Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Username
                  Row(
                    children: [
                      Text(
                        user.username,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: Colors.blue,
                          size: 13,
                        ),
                      ],
                    ],
                  ),
                  // Name
                  Text(
                    user.fullName,
                    style: GoogleFonts.hindSiliguri(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Followers
                  Text(
                    "${user.followersCount} ${user.followersCount == 1 ? 'follower' : 'followers'}",
                    style: GoogleFonts.inter(
                      color: context.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Right: Follow Button
            OutlinedButton(
              onPressed: () {
                dbService.toggleFollowUser(user.id);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isFollowing 
                      ? (context.isDarkMode ? const Color(0xFF1E293B) : Colors.grey.shade300) 
                      : context.border,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.transparent,
              ),
              child: Text(
                isFollowing ? "Following" : "Follow",
                style: GoogleFonts.hindSiliguri(
                  color: isFollowing ? context.textMuted : context.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.hindSiliguri(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: context.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTrendingItem(String rank, String tag, String postsCount) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TopicThreadsScreen(topicName: tag)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rank,
              style: GoogleFonts.inter(
                color: context.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    postsCount,
                    style: GoogleFonts.inter(
                      color: context.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.more_horiz, color: context.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildRisingTopicItem(String topic, String growth) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TopicThreadsScreen(topicName: topic)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border, width: 0.8),
        ),
        child: Row(
          children: [
            const Icon(Icons.trending_up, color: Colors.blue, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                topic,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: context.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                growth,
                style: GoogleFonts.inter(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscussedItem(String topic, String replies) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TopicThreadsScreen(topicName: topic)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mode_comment_outlined, color: Colors.orange, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    replies,
                    style: GoogleFonts.inter(
                      color: context.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTabButton(int index, String label, int count) {
    final isSelected = _searchTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _searchTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isSelected ? const Color(0xFF1E824C) : context.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "($count)",
                  style: GoogleFonts.inter(
                    color: isSelected ? const Color(0xFF1E824C).withOpacity(0.8) : context.textMuted,
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isSelected ? 24 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFF1E824C),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 300,
          child: Center(
            child: Text(
              "No results found",
              style: GoogleFonts.hindSiliguri(color: context.textMuted),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final isSearching = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu_rounded, color: context.textPrimary),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Explorer",
                    style: GoogleFonts.hindSiliguri(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Search Input Box
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: (val) {
                  _addToHistory(val);
                },
                style: GoogleFonts.inter(color: context.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: context.textMuted, size: 20),
                  suffixIcon: isSearching
                      ? IconButton(
                          icon: Icon(Icons.clear, color: context.textSecondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  hintText: "Search...",
                  hintStyle: GoogleFonts.hindSiliguri(color: context.textMuted, fontSize: 15),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  fillColor: context.isDarkMode ? const Color(0xFF151824) : const Color(0xFFF1F1F1),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Search Tab Selector (Only shown when searching)
              if (isSearching) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSearchTabButton(0, "Accounts", _searchResults.length),
                    const SizedBox(width: 12),
                    _buildSearchTabButton(1, "Posts", _searchPostResults.length),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),

              // Search History / Recommendations OR Search Results
              Expanded(
                child: RefreshIndicator(
                  color: context.primaryAccent,
                  onRefresh: () async {
                    _loadRecommendations();
                    _loadTopics();
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: context.primaryAccent),
                        )
                      : isSearching
                          ? (() {
                              if (_searchTabIndex == 0) {
                                if (_searchResults.isEmpty) {
                                  return _buildNoResultsView();
                                }
                                return ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 72),
                                  itemCount: _searchResults.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: context.border,
                                  ),
                                  itemBuilder: (context, index) {
                                    return _buildUserRow(_searchResults[index], dbService);
                                  },
                                );
                              } else {
                                if (_searchPostResults.isEmpty) {
                                  return _buildNoResultsView();
                                }
                                return ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 72),
                                  itemCount: _searchPostResults.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: context.border,
                                  ),
                                  itemBuilder: (context, index) {
                                    return CustomThreadCard(
                                      key: ValueKey(_searchPostResults[index].id),
                                      post: _searchPostResults[index],
                                    );
                                  },
                                );
                              }
                            })()
                          : ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 72),
                              children: [
                                // Recent Searches Section
                                if (_recentSearches.isNotEmpty) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Recent Searches",
                                        style: GoogleFonts.hindSiliguri(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _recentSearches.clear();
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "Clear All",
                                          style: GoogleFonts.hindSiliguri(
                                            color: context.primaryAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 8.0,
                                    children: _recentSearches.map((search) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: context.cardBg,
                                          border: Border.all(color: context.border),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.history, size: 14, color: context.textMuted),
                                            const SizedBox(width: 6),
                                            GestureDetector(
                                              onTap: () {
                                                _searchController.text = search;
                                                _onSearchChanged(search);
                                              },
                                              child: Text(
                                                search,
                                                style: GoogleFonts.hindSiliguri(fontSize: 13, color: context.textPrimary),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _recentSearches.remove(search);
                                                });
                                              },
                                              child: Icon(Icons.close, size: 14, color: context.textMuted),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // 1- Trending Now 🔥
                                _buildSectionHeader("Trending Now 🔥"),
                                if (_isTopicsLoading)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: CircularProgressIndicator(color: Color(0xFF1E824C)),
                                    ),
                                  )
                                else if (_trendingTopics.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      "No trending topics right now",
                                      style: GoogleFonts.inter(color: context.textMuted, fontSize: 13),
                                    ),
                                  )
                                else
                                  ..._trendingTopics.mapIndexed((index, item) {
                                    final posts = item['post_count'] as int? ?? 0;
                                    return _buildTrendingItem(
                                      (index + 1).toString(),
                                      item['topic_name'] as String? ?? '',
                                      "$posts ${posts == 1 ? 'post' : 'posts'}",
                                    );
                                  }),
                                const SizedBox(height: 12),
                                Divider(height: 1, color: context.border),

                                // 2- Rising Topics 🚀
                                _buildSectionHeader("Rising Topics 🚀"),
                                if (_isTopicsLoading)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: CircularProgressIndicator(color: Color(0xFF1E824C)),
                                    ),
                                  )
                                else if (_risingTopics.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      "No rising topics right now",
                                      style: GoogleFonts.inter(color: context.textMuted, fontSize: 13),
                                    ),
                                  )
                                else
                                  ..._risingTopics.map((item) {
                                    final growth = item['growth_percentage'] ?? 0;
                                    final sign = growth >= 0 ? '+' : '';
                                    return _buildRisingTopicItem(
                                      item['topic_name'] as String? ?? '',
                                      "$sign$growth% growth",
                                    );
                                  }),
                                const SizedBox(height: 12),
                                Divider(height: 1, color: context.border),

                                // 3- Most Discussed 👑
                                _buildSectionHeader("Most Discussed 👑"),
                                if (_isTopicsLoading)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: CircularProgressIndicator(color: Color(0xFF1E824C)),
                                    ),
                                  )
                                else if (_discussedTopics.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      "No discussed topics right now",
                                      style: GoogleFonts.inter(color: context.textMuted, fontSize: 13),
                                    ),
                                  )
                                else
                                  ..._discussedTopics.map((item) {
                                    final replies = item['discussion_count'] as int? ?? 0;
                                    return _buildDiscussedItem(
                                      item['topic_name'] as String? ?? '',
                                      "$replies ${replies == 1 ? 'reply' : 'replies'} today",
                                    );
                                  }),
                                const SizedBox(height: 12),
                                Divider(height: 1, color: context.border),

                                // 4- Recommended for you
                                _buildSectionHeader("Recommended for you"),
                                if (_recommended.isEmpty)
                                  SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: Text(
                                        "No recommendations found",
                                        style: GoogleFonts.hindSiliguri(color: context.textMuted),
                                      ),
                                    ),
                                  )
                                else
                                  ..._recommended.map((user) {
                                    return Column(
                                      children: [
                                        _buildUserRow(user, dbService),
                                        Divider(height: 1, color: context.border),
                                      ],
                                    );
                                  }),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
