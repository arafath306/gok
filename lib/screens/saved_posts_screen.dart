import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../widgets/custom_thread_card.dart';
import '../utils/app_theme.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      dbService.fetchSavedPosts();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _refresh(DatabaseService dbService) async {
    setState(() => _isRefreshing = true);
    await dbService.fetchSavedPosts();
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    // Filter out posts deleted during this session
    final savedPosts = dbService.savedPosts
        .where((p) => !dbService.isPostDeleted(p.id))
        .toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: RefreshIndicator(
        color: const Color(0xFF1E824C),
        onRefresh: () => _refresh(dbService),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          // ── Sliver AppBar ──
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: context.scaffoldBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: context.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: context.isDarkMode
                        ? [
                            const Color(0xFF0D2E1C),
                            const Color(0xFF000000),
                          ]
                        : [
                            const Color(0xFFE8F5E9),
                            const Color(0xFFF5F6F8),
                          ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E824C).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.bookmark_rounded,
                                color: Color(0xFF1E824C),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'সংরক্ষিত পোস্ট',
                                    style: GoogleFonts.hindSiliguri(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    savedPosts.isEmpty
                                        ? 'কোনো পোস্ট সংরক্ষিত নেই'
                                        : '${savedPosts.length}টি পোস্ট সংরক্ষিত আছে',
                                    style: GoogleFonts.hindSiliguri(
                                      fontSize: 13,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isRefreshing)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF1E824C),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 0.8, color: context.border),
            ),
            title: Text(
              'সংরক্ষিত পোস্ট',
              style: GoogleFonts.hindSiliguri(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: context.textPrimary,
              ),
            ),
          ),

          // ── Content ──
          savedPosts.isEmpty
              ? SliverFillRemaining(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildEmptyState(context),
                  ),
                )
              : SliverPadding(
                  padding: EdgeInsets.zero,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          return GestureDetector(
                            onTap: () => _refresh(dbService),
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E824C).withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF1E824C).withOpacity(0.15),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: Color(0xFF1E824C),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'শুধুমাত্র আপনি এই পোস্টগুলো দেখতে পারবেন',
                                      style: GoogleFonts.hindSiliguri(
                                        fontSize: 12.5,
                                        color: const Color(0xFF1E824C),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final post = savedPosts[index - 1];
                        return FadeTransition(
                          opacity: _fadeAnim,
                          child: Stack(
                            children: [
                              CustomThreadCard(post: post),
                              Positioned(
                                top: 12,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E824C).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF1E824C).withOpacity(0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.bookmark_rounded,
                                        size: 11,
                                        color: Color(0xFF1E824C),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'সেভড',
                                        style: GoogleFonts.hindSiliguri(
                                          fontSize: 10,
                                          color: const Color(0xFF1E824C),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: savedPosts.length + 1,
                    ),
                  ),
                ),
        ],
      ),
     ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E824C).withOpacity(0.08),
                  const Color(0xFF1E824C).withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_border_rounded,
              size: 48,
              color: Color(0xFF1E824C),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'কোনো পোস্ট সংরক্ষিত নেই',
            style: GoogleFonts.hindSiliguri(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'যে পোস্টগুলো পরে পড়তে চান, সেগুলো বুকমার্ক আইকন চেপে সংরক্ষণ করুন।',
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                color: context.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E824C),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E824C).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bookmark_add_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ফিডে ফিরে যান',
                    style: GoogleFonts.hindSiliguri(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
