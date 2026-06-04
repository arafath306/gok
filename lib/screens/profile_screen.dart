import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_thread_card.dart';

class ProfileScreenContainer extends StatefulWidget {
  final VoidCallback onNavigateToEditProfile;

  const ProfileScreenContainer({super.key, required this.onNavigateToEditProfile});

  @override
  State<ProfileScreenContainer> createState() => _ProfileScreenContainerState();
}

class _ProfileScreenContainerState extends State<ProfileScreenContainer> {
  String _selectedTab = "my_threads"; // "my_threads", "replies", "likes"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DatabaseService>(context, listen: false).fetchMyProfile();
      Provider.of<DatabaseService>(context, listen: false).fetchMyThreads();
    });
  }

  Widget _buildTabItem(String title, String tabId) {
    final isSelected = _selectedTab == tabId;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tabId;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.black : Colors.grey.shade200,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.hindSiliguri(
              color: isSelected ? Colors.black : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final prof = dbService.myProfile;

    if (prof == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1E824C))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await dbService.fetchMyProfile();
            await dbService.fetchMyThreads();
          },
          color: const Color(0xFF1E824C),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header top action bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.public, color: Colors.black87, size: 22),
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black87, size: 22),
                        onPressed: () {
                          // Standard logout / options dialog
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (context) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit_outlined),
                                    title: Text("প্রোফাইল পরিবর্তন", style: GoogleFonts.hindSiliguri()),
                                    onTap: () {
                                      Navigator.pop(context);
                                      widget.onNavigateToEditProfile();
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.logout, color: Colors.red),
                                    title: Text("লগ আউট", style: GoogleFonts.hindSiliguri(color: Colors.red)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      // Mock log out message or logic
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("লগ আউট করা হয়েছে (Mock)")),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Profile description block
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main name + avatar row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prof.fullName,
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      prof.username,
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F1F1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "threads.net",
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  prof.bio ?? "কোন বায়ো নেই",
                                  style: GoogleFonts.hindSiliguri(
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: NetworkImage(
                              prof.avatarUrl ?? "https://i.pravatar.cc/150",
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Phone and Country metadata if present
                    if ((prof.phone != null && prof.phone!.isNotEmpty) ||
                        (prof.country != null && prof.country!.isNotEmpty)) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: [
                            if (prof.phone != null && prof.phone!.isNotEmpty) ...[
                              const Icon(Icons.phone, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                prof.phone!,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(width: 16),
                            ],
                            if (prof.country != null && prof.country!.isNotEmpty) ...[
                              const Icon(Icons.public, size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                prof.country!,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ],
                        ),
                      )
                    ],

                    // Follower count (Threads style)
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 26,
                            height: 16,
                            child: Stack(
                              children: const [
                                Positioned(
                                  left: 0,
                                  child: CircleAvatar(
                                    radius: 7,
                                    backgroundImage: NetworkImage("https://i.pravatar.cc/100?u=follower_1"),
                                  ),
                                ),
                                Positioned(
                                  left: 10,
                                  child: CircleAvatar(
                                    radius: 7,
                                    backgroundImage: NetworkImage("https://i.pravatar.cc/100?u=follower_2"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "১২৪ জন অনুসারী",
                            style: GoogleFonts.hindSiliguri(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Edit Profile and Share Profile twin flat outline buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.onNavigateToEditProfile,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300, width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                minimumSize: const Size(0, 36),
                                backgroundColor: Colors.transparent,
                              ),
                              child: Text(
                                "প্রোফাইল এডিট",
                                style: GoogleFonts.hindSiliguri(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("প্রোফাইল শেয়ার করুন", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
                                    content: Text(
                                      "আপনার প্রোফাইল লিঙ্কটি কপি করুন: \nhttps://dak.ngst.app/profile/${prof.username}",
                                      style: GoogleFonts.hindSiliguri(fontSize: 14),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("প্রোফাইল লিঙ্ক কপি করা হয়েছে")),
                                          );
                                        },
                                        child: Text("কপি করুন", style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300, width: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                minimumSize: const Size(0, 36),
                                backgroundColor: Colors.transparent,
                              ),
                              child: Text(
                                "শেয়ার করুন",
                                style: GoogleFonts.hindSiliguri(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Flat bottom tabs selector
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          _buildTabItem("আমার ডাক", "my_threads"),
                          _buildTabItem("উত্তর", "replies"),
                          _buildTabItem("পছন্দ", "likes"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Tab content sections
              if (_selectedTab == "my_threads") ...[
                dbService.myThreads.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Text(
                              "আপনি এখনও কোন ডাক দেননি।",
                              style: GoogleFonts.hindSiliguri(color: Colors.black45),
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final post = dbService.myThreads[index];
                            return Column(
                              children: [
                                CustomThreadCard(post: post),
                                const Divider(height: 1, color: Color(0xFFF5F5F5)),
                              ],
                            );
                          },
                          childCount: dbService.myThreads.length,
                        ),
                      )
              ] else ...[
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        _selectedTab == "replies"
                            ? "কোন উত্তর পাওয়া যায়নি।"
                            : "কোন পছন্দ করা পোস্ট পাওয়া যায়নি।",
                        style: GoogleFonts.hindSiliguri(color: Colors.black45),
                      ),
                    ),
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
