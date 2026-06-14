import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_thread_card.dart';
import '../utils/app_theme.dart';

class TopicFeedScreen extends StatefulWidget {
  final String topicName;

  const TopicFeedScreen({
    Key? key,
    required this.topicName,
  }) : super(key: key);

  @override
  State<TopicFeedScreen> createState() => _TopicFeedScreenState();
}

class _TopicFeedScreenState extends State<TopicFeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _subTabs = ["Top", "Latest", "People", "Media"];
  bool _isFollowingTopic = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _subTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    
    // Filter real posts by hashtag/topic keyword
    final lowercaseTopic = widget.topicName.toLowerCase();
    final matchedPosts = dbService.feed.where((post) {
      final text = post.content.toLowerCase();
      return text.contains('#$lowercaseTopic') || text.contains(lowercaseTopic);
    }).toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: context.scaffoldBg,
                border: Border(bottom: BorderSide(color: context.border, width: 1)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Image.asset(
                    'assets/pigeon_logo.png',
                    height: 28,
                    width: 28,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Piagoan',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40), // Symmetric placeholder for back button
                ],
              ),
            ),

            // ── Topic Banner Card ──────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.border),
                gradient: LinearGradient(
                  colors: [context.cardBg, context.primaryAccent.withOpacity(0.12)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // Circle Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: context.primaryAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.tag_rounded,
                      color: context.primaryAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Topic info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.topicName,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          matchedPosts.isEmpty ? '12.4K posts' : '${matchedPosts.length * 3 + 12}K posts',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Follow Topic Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFollowingTopic = !_isFollowingTopic;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isFollowingTopic ? context.border : context.primaryAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isFollowingTopic ? 'Following' : 'Follow',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _isFollowingTopic ? context.textPrimary : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Sub Navigation Tabs (Top, Latest, People, Media) ───────
            Container(
              height: 40,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.border, width: 0.8)),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: context.primaryAccent,
                indicatorWeight: 2.5,
                dividerColor: Colors.transparent,
                labelColor: context.textPrimary,
                unselectedLabelColor: context.textSecondary,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13.5),
                unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13.5),
                tabs: _subTabs.map((t) => Tab(text: t)).toList(),
              ),
            ),

            // ── Tab contents / Filtered list ───────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPostsList(matchedPosts), // Top
                  _buildPostsList(matchedPosts.reversed.toList()), // Latest
                  _buildPlaceholderView('No users in this topic yet'), // People
                  _buildMediaOnlyView(matchedPosts), // Media
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(List<dynamic> posts) {
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, color: context.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              'No posts found for this topic',
              style: GoogleFonts.outfit(color: context.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: posts.length,
      itemBuilder: (context, i) => CustomThreadCard(post: posts[i]),
    );
  }

  Widget _buildPlaceholderView(String msg) {
    return Center(
      child: Text(
        msg,
        style: GoogleFonts.outfit(color: context.textMuted, fontSize: 14),
      ),
    );
  }

  Widget _buildMediaOnlyView(List<dynamic> posts) {
    final mediaPosts = posts.where((p) => p.imageUrls != null && p.imageUrls!.isNotEmpty).toList();
    if (mediaPosts.isEmpty) {
      return _buildPlaceholderView('No media in this topic');
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: mediaPosts.length,
      itemBuilder: (context, i) {
        final post = mediaPosts[i];
        final url = post.imageUrls!.first;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: context.border),
          ),
        );
      },
    );
  }
}
