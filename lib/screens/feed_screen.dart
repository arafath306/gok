import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_thread_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
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
    final List<dynamic> displayedPosts = dbService.feed;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
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
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: dbService.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E824C)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Feed List
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
                            itemCount: displayedPosts.length,
                            separatorBuilder: (context, index) => const Divider(
                              height: 1,
                              color: Color(0xFFF0F0F0),
                            ),
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
