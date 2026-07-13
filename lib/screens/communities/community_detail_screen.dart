import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/community_service.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../models/community.dart';
import '../../models/community_rule.dart';
import '../../models/thread_post.dart';
import '../../widgets/custom_thread_card.dart';
import '../../widgets/thread_shimmer.dart';
import '../create_thread_screen.dart';
import 'community_thread_search_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
part 'community_detail_screen_extensions.dart';

class CommunityDetailScreen extends StatefulWidget {
  final Community community;

  const CommunityDetailScreen({super.key, required this.community});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  late Community _community;
  bool _isLoading = true;
  List<ThreadPost> _posts = [];
  List<Map<String, dynamic>> _members = [];
  bool _isActionLoading = false;
  List<CommunityRule> _rules = [];
  @override
  void initState() {
    super.initState();
    _community = widget.community;
    _fetchData();
  }
  
  @override
  void dispose() {
    super.dispose();
  }


  Future<void> _fetchData() async {
    final service = Provider.of<CommunityService>(context, listen: false);
    
    final details = await service.getCommunityDetails(_community.id);
    if (details != null && mounted) {
      setState(() {
        _community = details;
      });
    }

    final results = await Future.wait([
      service.fetchCommunityPosts(_community.id),
      service.fetchCommunityRules(_community.id),
      service.fetchCommunityMembers(_community.id),
    ]);

    if (mounted) {
      setState(() {
        _posts = results[0] as List<ThreadPost>;
        _rules = results[1] as List<CommunityRule>;
        _members = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleJoin() async {
    setState(() => _isActionLoading = true);
    final service = Provider.of<CommunityService>(context, listen: false);
    
    bool success = false;
    if (_community.myRole == null) {
      success = await service.joinCommunity(_community.id);
      if (success && mounted) {
        setState(() {
          _community = _community.copyWith(myRole: 'member', memberCount: _community.memberCount + 1);
        });
      }
    } else {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.cardBg,
          title: Text("Leave Community", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary)),
          content: Text("Are you sure you want to leave ${_community.name}?", style: GoogleFonts.inter(color: context.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text("Cancel", style: TextStyle(color: context.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Leave", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirm != true) {
        setState(() => _isActionLoading = false);
        return;
      }

      success = await service.leaveCommunity(_community.id);
      if (success && mounted) {
        setState(() {
          _community = _community.copyWith(myRole: null, memberCount: (_community.memberCount - 1).clamp(0, 999999));
        });
      }
    }
    
    setState(() => _isActionLoading = false);
  }




  /// Shows the community rules & guidelines in a bottom sheet.


  /// Small frosted-glass icon button used inside the cover photo





  Future<void> _deleteCommunity() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        title: Text("Delete Community", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary)),
        content: Text("Are you sure you want to delete this community? This action cannot be undone.", style: GoogleFonts.inter(color: context.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: GoogleFonts.inter(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Delete", style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final service = Provider.of<CommunityService>(context, listen: false);
      final success = await service.deleteCommunity(_community.id);
      if (success) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Community deleted successfully.")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to delete community.")),
          );
        }
      }
    }
  }






  Widget _buildFeedTab() {
    if (_isLoading) {
      return const ThreadShimmer();
    }
    if (_posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.doc_text, size: 48, color: context.textMuted),
              const SizedBox(height: 16),
              Text(
                "No posts yet. Be the first to post!",
                style: GoogleFonts.inter(color: context.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: CustomThreadCard(
            post: _posts[index],
            isCommunityModerator: _community.myRole == 'owner' || _community.myRole == 'moderator',
          ),
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchData,
            color: context.greenAccent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCommunityHeader(),
                  _buildFeedTab(),
                ],
              ),
            ),
          ),
          // Floating Back Button (replacing AppBar so it doesn't block touches)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _community.myRole != null ? FloatingActionButton(
        backgroundColor: context.greenAccent,
        shape: const CircleBorder(),
        child: const Icon(CupertinoIcons.create, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateThreadScreen(communityId: _community.id)),
          ).then((_) {
            _fetchData();
          });
        },
      ) : null,
    );
  }
}

class CommunityMembersScreen extends StatefulWidget {
  final Community community;
  final List<Map<String, dynamic>> members;
  final Function() onRefresh;

  const CommunityMembersScreen({
    super.key, 
    required this.community, 
    required this.members,
    required this.onRefresh,
  });

  @override
  State<CommunityMembersScreen> createState() => _CommunityMembersScreenState();
}

class _CommunityMembersScreenState extends State<CommunityMembersScreen> {
  late List<Map<String, dynamic>> _members;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _members = widget.members;
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    final service = Provider.of<CommunityService>(context, listen: false);
    final updated = await service.fetchCommunityMembers(widget.community.id);
    if (mounted) {
      setState(() {
        _members = updated;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final currentUid = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: context.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Members",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _members.isEmpty
              ? const Center(child: Text("No members found."))
              : RefreshIndicator(
                  onRefresh: _fetchMembers,
                  color: context.greenAccent,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final memberMap = _members[index];
                      final profile = memberMap['profile'];
                      final role = memberMap['role'];
                      final isMe = profile.id == currentUid;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: profile.avatarUrl != null ? CachedNetworkImageProvider(profile.avatarUrl) : null,
                          backgroundColor: context.greenAccent.withValues(alpha: 0.1),
                          child: profile.avatarUrl == null 
                            ? Text(profile.fullName.substring(0, 1).toUpperCase(), style: TextStyle(color: context.greenAccent))
                            : null,
                        ),
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                profile.fullName,
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (profile.isVerified == true) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Colors.blue, size: 14),
                            ],
                            if (role == 'owner' || role == 'moderator') ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: role == 'owner' 
                                      ? context.greenAccent.withValues(alpha: 0.1)
                                      : Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: role == 'owner'
                                      ? context.greenAccent.withValues(alpha: 0.3)
                                      : Colors.blue.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  role == 'owner' ? "Owner" : "Mod",
                                  style: GoogleFonts.inter(
                                    fontSize: 9, 
                                    fontWeight: FontWeight.bold, 
                                    color: role == 'owner' ? context.greenAccent : Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          "@${profile.username}",
                          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMe) ...[
                              Selector<DatabaseService, bool>(
                                selector: (_, db) => db.isFollowingUser(profile.id),
                                builder: (context, isFollowing, _) {
                                  return TextButton(
                                    onPressed: () async {
                                      await dbService.toggleFollowUser(profile.id);
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      backgroundColor: isFollowing ? Colors.transparent : context.greenAccent.withValues(alpha: 0.1),
                                      side: isFollowing ? BorderSide(color: context.border) : null,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text(
                                      isFollowing ? "Following" : "Follow",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isFollowing ? context.textSecondary : context.greenAccent,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                            if (widget.community.myRole == 'owner' && role != 'owner') ...[
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert, color: context.textSecondary),
                                color: context.cardBg,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onSelected: (val) async {
                                  final service = Provider.of<CommunityService>(context, listen: false);
                                  if (val == 'make_mod') {
                                    await service.updateMemberRole(widget.community.id, profile.id, 'moderator');
                                    _fetchMembers();
                                    widget.onRefresh();
                                  } else if (val == 'remove_mod') {
                                    await service.updateMemberRole(widget.community.id, profile.id, 'member');
                                    _fetchMembers();
                                    widget.onRefresh();
                                  } else if (val == 'remove_member') {
                                    await service.removeMember(widget.community.id, profile.id);
                                    _fetchMembers();
                                    widget.onRefresh();
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  if (role == 'member')
                                    PopupMenuItem(
                                      value: 'make_mod',
                                      child: Text("Make Moderator", style: GoogleFonts.inter(color: context.textPrimary)),
                                    ),
                                  if (role == 'moderator')
                                    PopupMenuItem(
                                      value: 'remove_mod',
                                      child: Text("Remove Moderator", style: GoogleFonts.inter(color: context.textPrimary)),
                                    ),
                                  PopupMenuItem(
                                    value: 'remove_member',
                                    child: Text("Remove from Community", style: GoogleFonts.inter(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

/// Auto-scrolling marquee ticker widget for the community description.
class _DescriptionTicker extends StatefulWidget {
  final String text;
  const _DescriptionTicker({required this.text});

  @override
  State<_DescriptionTicker> createState() => _DescriptionTickerState();
}

class _DescriptionTickerState extends State<_DescriptionTicker> {
  late final ScrollController _sc;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _sc = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loop());
  }

  Future<void> _loop() async {
    if (_running) return;
    _running = true;
    while (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || !_sc.hasClients) break;
      
      final max = _sc.position.maxScrollExtent;
      if (max > 0) {
        // Scroll to end
        await _sc.animateTo(
          max,
          duration: Duration(milliseconds: (max * 30).toInt()), // smooth slightly slower speed
          curve: Curves.linear,
        );
        if (!mounted || !_sc.hasClients) break;
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted || !_sc.hasClients) break;
        // Jump back instantly
        _sc.jumpTo(0);
      }
    }
    _running = false;
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _sc,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        maxLines: 1,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          height: 1.3,
        ),
      ),
    );
  }
}
