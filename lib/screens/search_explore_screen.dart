import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../models/profile.dart';

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
              backgroundColor: const Color(0xFFE8F5E9),
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Color(0xFF1E824C),
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
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 13,
                      ),
                    ],
                  ),
                  // Name
                  Text(
                    user.fullName,
                    style: GoogleFonts.hindSiliguri(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Bio
                  Text(
                    user.bio ?? "কোন বায়ো নেই",
                    style: GoogleFonts.hindSiliguri(
                      color: Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Followers
                  Text(
                    "${user.followersCount} জন অনুসারী",
                    style: GoogleFonts.hindSiliguri(
                      color: Colors.black38,
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
                  color: isFollowing ? Colors.grey.shade300 : Colors.black12,
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
                isFollowing ? "ফলো করছেন" : "ফলো করুন",
                style: GoogleFonts.hindSiliguri(
                  color: isFollowing ? Colors.black38 : Colors.black87,
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Threads style title
              Text(
                "খুঁজুন",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Search Input Box
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: (val) {
                  _addToHistory(val);
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
                  suffixIcon: isSearching
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black54, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  hintText: "খুঁজুন...",
                  hintStyle: GoogleFonts.hindSiliguri(color: Colors.black38, fontSize: 15),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  fillColor: const Color(0xFFF1F1F1),
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
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF1E824C)),
                      )
                    : isSearching
                        ? _searchResults.isEmpty
                            ? Center(
                                child: Text(
                                  "কোনো ফলাফল পাওয়া যায়নি",
                                  style: GoogleFonts.hindSiliguri(color: Colors.black45),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _searchResults.length,
                                separatorBuilder: (context, index) => const Divider(
                                  height: 1,
                                  color: Color(0xFFF5F5F5),
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
                                      "সাম্প্রতিক খোঁজ",
                                      style: GoogleFonts.hindSiliguri(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
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
                                        "সব মুছুন",
                                        style: GoogleFonts.hindSiliguri(
                                          color: const Color(0xFF1E824C),
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
                                        color: Colors.white,
                                        border: Border.all(color: Colors.black12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.history, size: 14, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () {
                                              _searchController.text = search;
                                              _onSearchChanged(search);
                                            },
                                            child: Text(
                                              search,
                                              style: GoogleFonts.hindSiliguri(fontSize: 13, color: Colors.black87),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _recentSearches.remove(search);
                                              });
                                            },
                                            child: const Icon(Icons.close, size: 14, color: Colors.grey),
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
                                "আপনার জন্য পরামর্শ",
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Recommendations List
                              Expanded(
                                child: _recommended.isEmpty
                                    ? Center(
                                        child: Text(
                                          "কোন পরামর্শ পাওয়া যায়নি",
                                          style: GoogleFonts.hindSiliguri(color: Colors.black45),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: _recommended.length,
                                        separatorBuilder: (context, index) => const Divider(
                                          height: 1,
                                          color: Color(0xFFF5F5F5),
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
