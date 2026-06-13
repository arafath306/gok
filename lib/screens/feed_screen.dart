import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_thread_card.dart';

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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.black87, size: 24),
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
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
                                  color: isSelected ? const Color(0xFF1E824C) : Colors.black54,
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
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
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: NetworkImage(
                                    prof?.avatarUrl ?? "https://i.pravatar.cc/150",
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      "আজকে কী ভাবছেন?",
                                      style: GoogleFonts.hindSiliguri(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Feed List
                        if (dbService.feed.isEmpty)
                          SizedBox(
                            height: 300,
                            child: Center(
                              child: Text(
                                "কোন ডাক পাওয়া যায়নি।",
                                style: GoogleFonts.hindSiliguri(color: Colors.black45),
                              ),
                            ),
                          )
                        else
                          ...dbService.feed.map((post) {
                            return CustomThreadCard(post: post);
                          }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
