import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../services/general_settings_provider.dart';
import '../../models/profile.dart';
import '../../models/thread_post.dart';
import '../../utils/routes.dart';
import '../../utils/app_theme.dart';
import '../settings/settings_screen.dart';
import 'edit_profile_screen.dart';
import '../messenger/chat_screen.dart';

class ProfileScreen extends StatefulWidget {
  /// Pass userId to view another user's profile. Leave null for own profile.
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Profile? _viewedProfile;
  List<ThreadPost> _viewedThreads = [];
  bool _isLoading = false;

  final List<String> _tabs = [
    'Posts', 'Replies', 'Media',
  ];

  /// Own profile if userId is null OR matches the current user's Supabase UID
  bool get _isOwnProfile {
    if (widget.userId == null) return true;
    final db = Provider.of<DatabaseService>(context, listen: false);
    final currentUid = db.currentUid;
    final myProfileId = db.myProfile?.id;
    // Check against both currentUid and myProfile.id for robustness
    if (currentUid.isNotEmpty && widget.userId == currentUid) return true;
    if (myProfileId != null && widget.userId == myProfileId) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    // If viewing another user's profile, fetch their data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isOwnProfile) {
        _fetchOtherProfile();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _doesFollowMe = false;

  Future<void> _fetchOtherProfile() async {
    setState(() => _isLoading = true);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final profile = await dbService.fetchProfile(widget.userId!);
    final threads = await dbService.fetchUserThreads(widget.userId!);
    final doesFollowMe = await dbService.doesUserFollowMe(widget.userId!);
    if (mounted) {
      setState(() {
        _viewedProfile = profile;
        _viewedThreads = threads;
        _doesFollowMe = doesFollowMe;
        _isLoading = false;
      });
    }
  }

  // ── Format helper ──────────────────────────────────────────
  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  // ── Build ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(
      builder: (context, db, _) {
        // Choose correct profile & posts
        final Profile? profile = _isOwnProfile ? db.myProfile : _viewedProfile;
        final List<ThreadPost> threads =
            _isOwnProfile ? db.myThreads : _viewedThreads;

        // While loading own profile for first time
        if (_isOwnProfile && db.myProfile == null) {
          return Scaffold(
            backgroundColor: context.scaffoldBg,
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFF0085FF)),
            ),
          );
        }

        if (!_isOwnProfile && _isLoading) {
          return Scaffold(
            backgroundColor: context.scaffoldBg,
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFF0085FF)),
            ),
          );
        }

        final double screenWidth = MediaQuery.of(context).size.width;
        final bool isWide = screenWidth > 800;

        Widget tabSection = Column(
          children: [
            _buildTabBar(),
            Expanded(child: _buildTabViews(profile, threads)),
          ],
        );

        Widget bodyContent = tabSection;

        return Scaffold(
          backgroundColor: context.scaffoldBg,
          body: RefreshIndicator(
            color: const Color(0xFF0085FF),
            onRefresh: () async {
              if (_isOwnProfile) {
                await db.fetchMyProfile();
                await db.fetchMyThreads();
              } else {
                await _fetchOtherProfile();
              }
            },
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: _buildHeader(profile, db),
                ),
              ],
              body: bodyContent,
            ),
          ),
          floatingActionButton: _isOwnProfile
              ? FloatingActionButton(
                  heroTag: 'profile_fab',
                  onPressed: () async {
                    if (profile != null) {
                      await Navigator.push(
                        context,
                        NoTransitionPageRoute(
                          child: EditProfileScreen(
                            profile: profile.toJson(),
                          ),
                        ),
                      );
                      db.fetchMyProfile();
                    }
                  },
                  backgroundColor: const Color(0xFF0085FF),
                  shape: const CircleBorder(),
                  elevation: 3,
                  child: const Icon(Icons.edit_rounded, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _buildHeader(Profile? profile, DatabaseService db) {
    final double coverHeight = 160;
    final double avatarRadius = 55; // 110px diameter
    final double avatarHeightOffset = coverHeight - avatarRadius;
    final List<ThreadPost> threads = _isOwnProfile ? db.myThreads : _viewedThreads;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover + Avatar stack
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover Image Area
            GestureDetector(
              onTap: _isOwnProfile ? () => _pickAndUploadImage(context, db, false) : null,
              child: Container(
                height: coverHeight,
                width: double.infinity,
                color: Colors.grey[200],
                child: profile?.coverUrl != null && profile!.coverUrl!.isNotEmpty
                    ? Image.network(
                        profile.coverUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: _isOwnProfile
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.camera_alt_outlined, color: Color(0xFF0085FF), size: 28),
                                    const SizedBox(height: 4),
                                    Text(
                                      'কভার ফটো যোগ করুন',
                                      style: GoogleFonts.hindSiliguri(
                                        fontSize: 12,
                                        color: const Color(0xFF0085FF),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : null,
                      ),
              ),
            ),
            
            // Header buttons overlay on cover
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    CircleAvatar(
                      backgroundColor: Colors.black38,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  const Spacer(),
                  if (_isOwnProfile)
                    CircleAvatar(
                      backgroundColor: Colors.black38,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 18),
                        onPressed: () {
                          Navigator.push(
                            context,
                            NoTransitionPageRoute(
                              child: const SettingsScreen(),
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                      ),
                    ),
                ],
              ),
            ),
            
            // Avatar stacked over cover bottom-left
            Positioned(
              top: avatarHeightOffset,
              left: 16,
              child: GestureDetector(
                onTap: _isOwnProfile ? () => _pickAndUploadImage(context, db, true) : null,
                child: Stack(
                  children: [
                    Container(
                      width: avatarRadius * 2,
                      height: avatarRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: context.scaffoldBg, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                            ? Image.network(
                                profile.avatarUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (_, child, progress) =>
                                    progress == null
                                        ? child
                                        : _defaultAvatar(size: avatarRadius * 2),
                                errorBuilder: (_, __, ___) =>
                                    _defaultAvatar(size: avatarRadius * 2),
                              )
                            : _defaultAvatar(size: avatarRadius * 2),
                      ),
                    ),
                    if (_isOwnProfile)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0085FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Spacer to account for overlapping avatar with nice separation
        SizedBox(height: avatarRadius + 14),

        // Name, username & Edit button inline Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.fullName ?? 'User',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      '@${profile?.username ?? ''}',
                      style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (_isOwnProfile) ...[
                _outlinedBtn('Edit Profile', onTap: () async {
                  if (profile != null) {
                    await Navigator.push(
                      context,
                      NoTransitionPageRoute(
                        child: EditProfileScreen(
                          profile: profile.toJson(),
                        ),
                      ),
                    );
                    db.fetchMyProfile();
                  }
                }),
                const SizedBox(width: 8),
                _iconBtn(Icons.more_horiz_rounded, onTap: _showMoreOptions),
              ] else ...[
                Consumer<DatabaseService>(
                  builder: (ctx, dbS, _) {
                    final isFollowing = dbS.isFollowingUser(widget.userId!);
                    return _filledBtn(
                      isFollowing ? 'Following' : 'Follow',
                      onTap: () => dbS.toggleFollowUser(widget.userId!),
                      outlined: isFollowing,
                    );
                  },
                ),
                const SizedBox(width: 8),
                if (profile != null && (!profile.isPrivate || _doesFollowMe)) ...[
                  _outlinedBtn(
                    'Message',
                    onTap: () {
                      Navigator.push(
                        context,
                        NoTransitionPageRoute(
                          child: ChatScreen(otherUser: profile),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                _iconBtn(Icons.more_horiz_rounded, onTap: _showMoreOptions),
              ],
            ],
          ),
        ),

        // Stats
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _statItem(_fmt(profile?.followersCount ?? 0), 'followers'),
              const SizedBox(width: 20),
              _statItem(_fmt(profile?.followingCount ?? 0), 'following'),
              const SizedBox(width: 20),
              _statItem(_fmt(threads.length), 'posts'),
            ],
          ),
        ),

        // Bio
        if (profile?.bio != null && profile!.bio!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              profile.bio!,
              style: GoogleFonts.hindSiliguri(
                fontSize: 14,
                color: context.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],

        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildAvatar(String? url, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.border, width: 1.0),
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _defaultAvatar(size: size),
                errorBuilder: (_, __, ___) => _defaultAvatar(size: size),
              )
            : _defaultAvatar(size: size),
      ),
    );
  }

  Widget _defaultAvatar({double size = 40}) => Container(
        color: const Color(0xFF0085FF),
        child: Icon(Icons.person_rounded, color: Colors.white, size: size * 0.55),
      );

  Widget _statItem(String count, String label) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(
          text: '$count ',
          style: GoogleFonts.hindSiliguri(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        TextSpan(
          text: label,
          style: GoogleFonts.hindSiliguri(fontSize: 14, color: context.textSecondary),
        ),
      ]),
    );
  }

  Widget _outlinedBtn(String label, {required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.border),
          ),
          child: Text(label,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary)),
        ),
      );

  Widget _filledBtn(String label,
      {required VoidCallback onTap, bool outlined = false}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
          decoration: BoxDecoration(
            color: outlined ? context.cardBg : (context.isDarkMode ? Colors.white : Colors.black),
            borderRadius: BorderRadius.circular(20),
            border:
                outlined ? Border.all(color: context.border) : null,
          ),
          child: Text(label,
              style: GoogleFonts.hindSiliguri(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: outlined ? context.textPrimary : (context.isDarkMode ? Colors.black : Colors.white))),
        ),
      );

  Widget _iconBtn(IconData icon, {required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.border),
          ),
          child: Icon(icon, size: 18, color: context.textPrimary),
        ),
      );

  // ── Tab Bar ────────────────────────────────────────────────
  Widget _buildTabBar() => Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.border, width: 1)),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: context.textPrimary,
          unselectedLabelColor: context.textSecondary,
          indicatorColor: context.textPrimary,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.hindSiliguri(
              fontSize: 14, fontWeight: FontWeight.bold),
          unselectedLabelStyle:
              GoogleFonts.hindSiliguri(fontSize: 14),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      );

  // ── Tab Views ──────────────────────────────────────────────
  Widget _buildTabViews(Profile? profile, List<ThreadPost> threads) =>
      TabBarView(
        controller: _tabController,
        children: [
          KeepAliveWrapper(child: _postsTab(profile, threads)),
          KeepAliveWrapper(child: _emptyTab('No replies yet')),
          KeepAliveWrapper(child: _emptyTab('No media yet')),
        ],
      );

  Widget _postsTab(Profile? profile, List<ThreadPost> threads) {
    if (threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                border: Border.all(color: context.border, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit_outlined,
                  size: 34, color: context.textMuted),
            ),
            const SizedBox(height: 14),
            Text('No posts yet',
                style: GoogleFonts.hindSiliguri(
                    fontSize: 16,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500)),
            if (_isOwnProfile) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0085FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  elevation: 0,
                ),
                child: Text('Write a post',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const BouncingScrollPhysics(),
      itemCount: threads.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: context.border),
      itemBuilder: (context, i) => _threadTile(threads[i], profile),
    );
  }

  Widget _threadTile(ThreadPost post, Profile? profile) {
    final age = post.createdAt; // already formatted by ThreadPost.fromJson
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(profile?.avatarUrl, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '${profile?.fullName ?? ''} ',
                          style: GoogleFonts.hindSiliguri(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: context.textPrimary),
                        ),
                        TextSpan(
                          text: '@${profile?.username ?? ''}',
                          style: GoogleFonts.hindSiliguri(
                              fontSize: 13, color: context.textSecondary),
                        ),
                      ]),
                    ),
                  ),
                  Text(age,
                      style: GoogleFonts.hindSiliguri(
                          fontSize: 12, color: context.textMuted)),
                ]),
                const SizedBox(height: 6),
                Text(post.content,
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 14,
                        color: context.textPrimary,
                        height: 1.4)),
                const SizedBox(height: 10),
                Row(children: [
                  _postAction(Icons.chat_bubble_outline_rounded,
                      post.repliesCount.toString()),
                  const SizedBox(width: 22),
                  _postAction(
                      Icons.repeat_rounded, post.repostsCount.toString()),
                  const SizedBox(width: 22),
                  _postAction(Icons.favorite_border_rounded,
                      post.likesCount.toString()),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _postAction(IconData icon, String count) => Row(children: [
        Icon(icon, size: 16, color: context.textSecondary),
        const SizedBox(width: 4),
        Text(count,
            style: GoogleFonts.hindSiliguri(
                fontSize: 12, color: context.textSecondary)),
      ]);

  Widget _emptyTab(String msg) => Center(
        child: Text(msg,
            style: GoogleFonts.hindSiliguri(
                fontSize: 15, color: context.textSecondary)),
      );

  // ── More Options ───────────────────────────────────────────
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      backgroundColor: context.cardBg,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            if (_isOwnProfile) ...[
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: Text('Share Profile',
                    style: GoogleFonts.hindSiliguri(fontSize: 15)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: Text('Log Out',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 15, color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  // handled by auth service
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.block_rounded, color: Colors.red),
                title: Text('Block',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 15, color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context); // close bottom sheet
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text(
                        'ব্লক করবেন?',
                        style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        'আপনি কি নিশ্চিতভাবে এই অ্যাকাউন্টটি ব্লক করতে চান?',
                        style: GoogleFonts.hindSiliguri(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('বাতিল', style: GoogleFonts.hindSiliguri(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                          child: Text('ব্লক', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    final settings = Provider.of<GeneralSettingsProvider>(context, listen: false);
                    final db = Provider.of<DatabaseService>(context, listen: false);
                    await settings.blockUserById(widget.userId!);
                    db.fetchBlockedMutedLists();
                    db.fetchFeed();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('অ্যাকাউন্টটি ব্লক করা হয়েছে।', style: GoogleFonts.hindSiliguri())),
                    );
                    Navigator.pop(context); // Go back
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.red),
                title: Text('Report',
                    style: GoogleFonts.hindSiliguri(
                        fontSize: 15, color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context); // close bottom sheet
                  final reason = await showDialog<String>(
                    context: context,
                    builder: (ctx) {
                      final controller = TextEditingController();
                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text(
                          'রিপোর্ট করার কারণ',
                          style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold),
                        ),
                        content: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'কেন রিপোর্ট করছেন তা লিখুন...',
                            hintStyle: GoogleFonts.hindSiliguri(),
                          ),
                          style: GoogleFonts.hindSiliguri(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('বাতিল', style: GoogleFonts.hindSiliguri(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            child: Text('রিপোর্ট', style: GoogleFonts.hindSiliguri(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      );
                    },
                  );
                  if (reason != null && reason.isNotEmpty && mounted) {
                    final db = Provider.of<DatabaseService>(context, listen: false);
                    await db.reportProfile(widget.userId!, reason);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('রিপোর্ট জমা দেওয়া হয়েছে। ধন্যবাদ!', style: GoogleFonts.hindSiliguri())),
                    );
                  }
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, DatabaseService db, bool isAvatar) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return;
      
       final bytes = await image.readAsBytes();
      final success = await db.updateProfileImage(bytes, isAvatar);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAvatar ? 'প্রোফাইল ছবি সফলভাবে পরিবর্তন করা হয়েছে।' : 'কভার ফটো সফলভাবে পরিবর্তন করা হয়েছে।',
              style: GoogleFonts.hindSiliguri(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ছবি আপলোড করতে ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
              style: GoogleFonts.hindSiliguri(),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Pick image error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ত্রুটি: $e',
            style: GoogleFonts.hindSiliguri(),
          ),
        ),
      );
    }
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
