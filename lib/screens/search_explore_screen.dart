import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/profile.dart';
import '../utils/app_theme.dart';

class SearchExploreScreen extends StatefulWidget {
  const SearchExploreScreen({super.key});

  @override
  State<SearchExploreScreen> createState() => _SearchExploreScreenState();
}

class _SearchExploreScreenState extends State<SearchExploreScreen> {
  final List<String> _recentSearches = [];
  List<Profile> _searchResults = [];
  List<Profile> _recommended = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendations();
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

  void _onSearchChanged(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
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
    final results = await dbService.searchProfiles(trimmed);

    if (mounted) {
      setState(() {
        _searchResults = results;
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
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: InkWell(
        onTap: () {
          _addToHistory(user.fullName);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${user.fullName} এর প্রোফাইল ট্যাপ করা হয়েছে")),
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                children: [
                  // Username
                  Row(
                    children: [
                      Text(
                        user.username,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                      if (user.fullName == 'Dak Official') ...[
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
                  const SizedBox(height: 4),
                  // Bio
                  Text(
                    user.bio ?? "কোন বায়ো নেই",
                    style: GoogleFonts.hindSiliguri(
                      color: context.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Followers
                  Text(
                    "${user.followersCount} জন অনুসারী",
                    style: GoogleFonts.hindSiliguri(
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
                    "Search",
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
                style: GoogleFonts.outfit(color: context.textPrimary, fontSize: 14),
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

              // Search History / Recommendations OR Search Results
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: context.primaryAccent),
                      )
                    : isSearching
                        ? _searchResults.isEmpty
                            ? Center(
                                child: Text(
                                  "No results found",
                                  style: GoogleFonts.hindSiliguri(color: context.textMuted),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _searchResults.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  color: context.border,
                                ),
                                itemBuilder: (context, index) {
                                  return _buildUserRow(_searchResults[index], dbService);
                                },
                              )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                const SizedBox(height: 24),
                              ],

                              // Recommendations Header
                              Text(
                                "Recommended for you",
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Recommendations List
                              Expanded(
                                child: _recommended.isEmpty
                                    ? Center(
                                        child: Text(
                                          "No recommendations found",
                                          style: GoogleFonts.hindSiliguri(color: context.textMuted),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: _recommended.length,
                                        separatorBuilder: (context, index) => Divider(
                                          height: 1,
                                          color: context.border,
                                        ),
                                        itemBuilder: (context, index) {
                                          return _buildUserRow(_recommended[index], dbService);
                                        },
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
