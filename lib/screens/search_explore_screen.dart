import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchExploreScreen extends StatefulWidget {
  const SearchExploreScreen({super.key});

  @override
  State<SearchExploreScreen> createState() => _SearchExploreScreenState();
}

class _SearchExploreScreenState extends State<SearchExploreScreen> {
  final List<String> _recentSearches = ["তানভীর আহমেদ", "@dhaka_vibes", "পিঠা উৎসব"];
  final List<bool> _isFollowing = [false, false, false, false];

  final List<String> _names = ["রিয়াদ হাসান", "নাদিয়া সুলতানা", "ফাহিম আহমেদ", "সাদিয়া চৌধুরী"];
  final List<String> _usernames = ["riyad_h", "nadia_s", "fahim_cse", "sadia_ch"];
  final List<String> _bios = ["ঢাকার ছেলে | চা লাভার", "ভ্রমন পিপাসু ☕", "CSE student | Flutter developer", "Nature photographer 📸"];
  final List<String> _followers = ["১২.৪ হাজার ফলোয়ার", "৮.৯ হাজার ফলোয়ার", "১৫.২ হাজার ফলোয়ার", "৫.৪ হাজার ফলোয়ার"];

  @override
  Widget build(BuildContext context) {
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
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.black38, size: 20),
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
                          Text(
                            search,
                            style: GoogleFonts.hindSiliguri(fontSize: 13, color: Colors.black87),
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

              // Suggestions Section
              Text(
                "আপনার জন্য পরামর্শ",
                style: GoogleFonts.hindSiliguri(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.separated(
                  itemCount: _names.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    color: Color(0xFFF5F5F5),
                  ),
                  itemBuilder: (context, index) {
                    final isFollowing = _isFollowing[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Circular Avatar
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFE8F5E9),
                            child: Text(
                              _names[index][0],
                              style: const TextStyle(
                                color: Color(0xFF1E824C),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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
                                      _usernames[index],
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
                                  _names[index],
                                  style: GoogleFonts.hindSiliguri(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Bio
                                Text(
                                  _bios[index],
                                  style: GoogleFonts.hindSiliguri(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Followers
                                Text(
                                  _followers[index],
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
                              setState(() {
                                _isFollowing[index] = !isFollowing;
                              });
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
