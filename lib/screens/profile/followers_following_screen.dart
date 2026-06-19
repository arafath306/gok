import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/profile.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/routes.dart';
import 'profile_screen.dart';

enum FollowListType { followers, following }

class FollowersFollowingScreen extends StatefulWidget {
  final String userId;
  final String username;
  final FollowListType listType;
  final bool isOwnProfile;

  const FollowersFollowingScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.listType,
    this.isOwnProfile = false,
  });

  @override
  State<FollowersFollowingScreen> createState() => _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen> {
  List<Profile> _users = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  List<Profile> _filtered = [];

  bool get _isFollowers => widget.listType == FollowListType.followers;

  @override
  void initState() {
    super.initState();
    _loadList();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadList() async {
    setState(() => _isLoading = true);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final list = _isFollowers
        ? await db.fetchUserFollowers(widget.userId)
        : await db.fetchUserFollowing(widget.userId);
    if (mounted) {
      setState(() {
        _users = list;
        _filtered = list;
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _users
          : _users.where((u) {
              return u.fullName.toLowerCase().contains(q) ||
                  u.username.toLowerCase().contains(q);
            }).toList();
    });
  }

  void _showUserOptions(BuildContext ctx, Profile user) {
    final db = Provider.of<DatabaseService>(ctx, listen: false);
    final isFollowingThem = db.isFollowingUser(user.id);

    showModalBottomSheet(
      context: ctx,
      backgroundColor: ctx.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: ctx.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Header with user info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _avatar(user, 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: ctx.textPrimary,
                        ),
                      ),
                      Text(
                        '@${user.username}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: ctx.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),

            // Options based on list type
            if (_isFollowers && widget.isOwnProfile) ...[
              ListTile(
                leading: Icon(Icons.person_remove_outlined,
                    color: Colors.red.shade400, size: 22),
                title: Text('Remove follower',
                    style: GoogleFonts.inter(
                        color: Colors.red.shade400, fontWeight: FontWeight.w500)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await db.removeFollower(user.id);
                  setState(() {
                    _users.removeWhere((u) => u.id == user.id);
                    _filtered.removeWhere((u) => u.id == user.id);
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${user.fullName} removed from followers',
                            style: GoogleFonts.inter()),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
              ),
            ] else if (!_isFollowers && widget.isOwnProfile) ...[
              ListTile(
                leading: Icon(
                  isFollowingThem
                      ? Icons.person_remove_outlined
                      : Icons.person_add_outlined,
                  color: isFollowingThem ? Colors.orange : ctx.primaryAccent,
                  size: 22,
                ),
                title: Text(
                  isFollowingThem ? 'Unfollow' : 'Follow',
                  style: GoogleFonts.inter(
                    color: isFollowingThem ? Colors.orange : ctx.primaryAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await db.toggleFollowUser(user.id);
                  setState(() {});
                },
              ),
            ],

            // Report user (always available)
            ListTile(
              leading: Icon(Icons.flag_outlined, color: ctx.textSecondary, size: 22),
              title: Text('Report user',
                  style: GoogleFonts.inter(color: ctx.textSecondary)),
              onTap: () {
                Navigator.pop(ctx);
                _showReportDialog(ctx, user, db);
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext ctx, Profile user, DatabaseService db) {
    String? selectedReason;
    final reasons = [
      'Spam or fake account',
      'Harassment or bullying',
      'Hate speech or symbols',
      'Violence or dangerous content',
      'Impersonation',
      'Inappropriate content',
      'Other',
    ];

    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (_, setLocalState) => AlertDialog(
          backgroundColor: ctx.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Report @${user.username}',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, color: ctx.textPrimary)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select a reason:',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: ctx.textSecondary)),
                const SizedBox(height: 10),
                ...reasons.map(
                  (r) => GestureDetector(
                    onTap: () => setLocalState(() => selectedReason = r),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: selectedReason == r
                            ? ctx.primaryAccent.withValues(alpha: 0.12)
                            : ctx.isDarkMode
                                ? const Color(0xFF1A1D2E)
                                : const Color(0xFFF3F5F8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedReason == r
                              ? ctx.primaryAccent
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(r,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: ctx.textPrimary,
                                )),
                          ),
                          if (selectedReason == r)
                            Icon(Icons.check_circle_rounded,
                                size: 16, color: ctx.primaryAccent),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: ctx.textMuted)),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(dialogCtx);
                      final success =
                          await db.reportUser(user.id, selectedReason!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Report submitted. Thank you.'
                                  : 'Failed to submit report.',
                              style: GoogleFonts.inter(),
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child:
                  Text('Submit', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(Profile user, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF0085FF),
      backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
          ? NetworkImage(user.avatarUrl!)
          : null,
      child: user.avatarUrl == null || user.avatarUrl!.isEmpty
          ? Icon(Icons.person_rounded, color: Colors.white, size: radius * 1.1)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputBg = context.isDarkMode
        ? const Color(0xFF1A1D2E)
        : const Color(0xFFF3F5F8);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: context.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isFollowers ? 'Followers' : 'Following',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            Text(
              '@${widget.username}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: context.textMuted,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: context.border),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search_rounded, color: context.textMuted, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () => _searchCtrl.clear(),
                        child: Icon(Icons.close_rounded,
                            color: context.textMuted, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: context.primaryAccent, strokeWidth: 2),
                  )
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isFollowers
                                  ? Icons.group_outlined
                                  : Icons.person_search_rounded,
                              size: 52,
                              color: context.textMuted,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _searchCtrl.text.isNotEmpty
                                  ? 'No results found'
                                  : _isFollowers
                                      ? 'No followers yet'
                                      : 'Not following anyone',
                              style: GoogleFonts.inter(
                                  fontSize: 15, color: context.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadList,
                        color: context.primaryAccent,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _filtered.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1, color: context.border),
                          itemBuilder: (_, i) {
                            final user = _filtered[i];
                            return Consumer<DatabaseService>(
                              builder: (ctx, db, _) {
                                final isFollowingThem =
                                    db.isFollowingUser(user.id);
                                final isMe = db.currentUid == user.id;
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  leading: GestureDetector(
                                    onTap: () => _goToProfile(user),
                                    child: _avatar(user, 22),
                                  ),
                                  title: GestureDetector(
                                    onTap: () => _goToProfile(user),
                                    child: Text(
                                      user.fullName,
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.5,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '@${user.username}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          color: context.textMuted,
                                        ),
                                      ),
                                      if (user.bio != null &&
                                          user.bio!.isNotEmpty)
                                        Text(
                                          user.bio!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Follow/Unfollow button (not for own account)
                                      if (!isMe)
                                        GestureDetector(
                                          onTap: () =>
                                              db.toggleFollowUser(user.id),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 14, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isFollowingThem
                                                  ? context.cardBg
                                                  : context.isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: isFollowingThem
                                                  ? Border.all(
                                                      color: context.border)
                                                  : null,
                                            ),
                                            child: Text(
                                              isFollowingThem
                                                  ? 'Following'
                                                  : 'Follow',
                                              style: GoogleFonts.inter(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600,
                                                color: isFollowingThem
                                                    ? context.textPrimary
                                                    : context.isDarkMode
                                                        ? Colors.black
                                                        : Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 6),
                                      // 3-dot menu
                                      if (!isMe)
                                        GestureDetector(
                                          onTap: () =>
                                              _showUserOptions(context, user),
                                          child: Icon(Icons.more_vert_rounded,
                                              size: 20, color: context.textMuted),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _goToProfile(Profile user) {
    Navigator.push(
      context,
      NoTransitionPageRoute(
        child: ProfileScreen(userId: user.id),
      ),
    );
  }
}
