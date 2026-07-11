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



  Widget _buildCommunityHeader() {
    final isCreator = _community.myRole == 'owner' || _community.myRole == 'moderator';
    final handle = _community.handle ?? _community.name.toLowerCase().replaceAll(' ', '_');
    const double coverHeight = 100.0;
    const double avatarRadius = 42.0;
    const double avatarOverlap = 36.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cover Photo with overlaid icons ──────────────────────────────
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover image container
            Container(
              width: double.infinity,
              height: coverHeight,
              decoration: BoxDecoration(
                color: context.cardBg,
                gradient: _community.bannerUrl == null
                    ? LinearGradient(
                        colors: [
                          const Color(0xFF0D2137),
                          const Color(0xFF1E824C).withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                image: _community.bannerUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(_community.bannerUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _community.bannerUrl == null
                  ? Center(
                      child: Opacity(
                        opacity: 0.12,
                        child: Icon(
                          Icons.groups_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),



            // Action icons: search, share, (mod tab for creators) — vertically centered in cover
            Positioned(
              top: 0,
              bottom: 0,
              right: 12,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _coverIconButton(
                        icon: Icons.search_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CommunityThreadSearchScreen(community: widget.community),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _coverIconButton(
                        icon: Icons.share_rounded,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Community link copied!")),
                          );
                        },
                      ),
                      if (isCreator) ...[
                        const SizedBox(width: 8),
                        _coverIconButton(
                          icon: Icons.edit_rounded,
                          onTap: _showEditCommunitySheet,
                          highlight: false,
                        ),
                        const SizedBox(width: 8),
                        _coverIconButton(
                          icon: Icons.shield_rounded,
                          onTap: _showModTabSheet,
                          highlight: false,
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        _coverIconButton(
                          icon: Icons.more_vert_rounded,
                          onTap: _showMemberSettingsSheet,
                          highlight: false,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),


            // Avatar overlapping the cover photo bottom
            Positioned(
              bottom: -(avatarRadius - avatarOverlap),
              left: 20,
              child: Container(
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.scaffoldBg, width: 3),
                  color: const Color(0xFF1E824C).withValues(alpha: 0.15),
                  image: _community.avatarUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(_community.avatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _community.avatarUrl == null
                    ? Center(
                        child: Text(
                          _community.name.substring(0, 1).toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E824C),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),

        // ── Info Row: Name + Members + Pin ───────────────────
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 16, top: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Center: name + handle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            _community.name,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: context.textPrimary,
                              height: 1.1,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_community.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: Colors.blue, size: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'd/$handle',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Members chip
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommunityMembersScreen(
                        community: _community,
                        members: _members,
                        onRefresh: _fetchData,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.border.withValues(alpha: 0.7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_rounded, size: 13, color: Color(0xFF1E824C)),
                      const SizedBox(width: 5),
                      Text(
                        "${_community.memberCount} ${_community.memberCount == 1 ? 'member' : 'members'}",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: context.textSecondary),
                    ],
                  ),
                ),
              ),
              // Join/Joined button (right side, hidden for owner)
              if (_community.myRole != 'owner') ...[
                const SizedBox(width: 8),
                _isActionLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : GestureDetector(
                        onTap: _toggleJoin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: _community.myRole != null
                                ? context.border.withValues(alpha: 0.5)
                                : const Color(0xFF1E824C),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _community.myRole != null ? 'Joined' : 'Join',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _community.myRole != null
                                  ? context.textPrimary
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ── Announcement Row ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showRulesSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.border.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign_rounded, size: 14, color: Color(0xFF1E824C)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRect(
                            child: _DescriptionTicker(
                              text: _community.description?.isNotEmpty == true 
                                  ? _community.description! 
                                  : 'Tap to view Community Rules & Guidelines',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),
        Divider(height: 1, thickness: 0.5, color: context.border),
      ],
    );
  }

  /// Shows the community rules & guidelines in a bottom sheet.
  void _showRulesSheet() {
    final isCreator = _community.myRole == 'owner' || _community.myRole == 'moderator';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.9,
          minChildSize: 0.35,
          builder: (_, sc) => Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 38, height: 4,
                  decoration: BoxDecoration(
                    color: context.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.gavel_rounded, size: 18, color: const Color(0xFF1E824C)),
                    const SizedBox(width: 8),
                    Text(
                      "Rules & Guidelines",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    if (_rules.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E824C).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${_rules.length}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E824C),
                          ),
                        ),
                      ),
                    ],
                    if (isCreator) ...[
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddEditRuleDialog(null);
                        },
                        icon: const Icon(Icons.add, size: 14),
                        label: Text("Add Rule", style: GoogleFonts.inter(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1E824C),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_community.description != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _community.description!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: context.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Divider(height: 1, color: context.border),
              Expanded(
                child: _rules.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.gavel_rounded, size: 40,
                                color: context.textSecondary.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              "No rules defined yet.",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: sc,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: _rules.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final rule = _rules[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.scaffoldBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: context.border.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 22, height: 22,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E824C).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "${index + 1}",
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E824C),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rule.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      if (rule.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          rule.description,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: context.textSecondary,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isCreator)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(ctx);
                                      _showAddEditRuleDialog(rule);
                                    },
                                    child: Icon(Icons.edit_outlined,
                                        size: 16, color: context.textSecondary),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }


  /// Small frosted-glass icon button used inside the cover photo
  Widget _coverIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFF1E824C).withValues(alpha: 0.80)
              : Colors.black.withValues(alpha: 0.42),
          shape: BoxShape.circle,
          border: Border.all(
            color: highlight
                ? Colors.white.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }


  void _showModTabSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Moderator Control Panel",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.people_outline, color: context.textPrimary),
                title: Text("Manage Members", style: GoogleFonts.inter(color: context.textPrimary)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommunityMembersScreen(
                        community: _community,
                        members: _members,
                        onRefresh: _fetchData,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.edit_outlined, color: context.textPrimary),
                title: Text("Edit Community Details", style: GoogleFonts.inter(color: context.textPrimary)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditCommunitySheet();
                },
              ),
              if (_community.myRole == 'owner')
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text("Delete Community", style: GoogleFonts.inter(color: Colors.red)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.red),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteCommunity();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showMemberSettingsSheet() {
    final bool isJoined = _community.myRole != null;
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Community Options",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (isJoined)
                ListTile(
                  leading: const Icon(Icons.exit_to_app_rounded, color: Colors.red),
                  title: Text(
                    "Leave Community",
                    style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _toggleJoin();
                  },
                ),
              ListTile(
                leading: Icon(Icons.report_gmailerrorred_rounded, color: context.textPrimary),
                title: Text(
                  "Report Community",
                  style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReportCommunitySheet();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportCommunitySheet() {
    final reasons = [
      'Spam',
      'Hate speech',
      'Harassment or bullying',
      'Misinformation',
      'Violence or threat',
      'Other',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (reportCtx) => Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Report community',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: context.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Why are you reporting this community?',
                  style: GoogleFonts.inter(fontSize: 13, color: context.textSecondary),
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: context.border),
              ...reasons.map((reason) => Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(reportCtx);
                        final dbService = Provider.of<DatabaseService>(context, listen: false);
                        final success = await dbService.reportCommunity(
                          _community.id,
                          _community.name,
                          reason,
                        );
                        if (!mounted) return;
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Report submitted. Thank you for helping keep Pigeon safe.',
                                style: GoogleFonts.inter(),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to submit report. Please try again.',
                                style: GoogleFonts.inter(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      splashColor: Colors.red.withValues(alpha: 0.06),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                reason,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: context.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              CupertinoIcons.chevron_right,
                              size: 14,
                              color: context.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

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

  void _showEditCommunitySheet() {
    final nameCtrl = TextEditingController(text: _community.name);
    final descCtrl = TextEditingController(text: _community.description);
    String privacy = _community.privacy;
    File? newAvatar;
    File? newBanner;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bctx) {
        return StatefulBuilder(
          builder: (sctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Edit Community Details",
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar picker
                        Column(
                          children: [
                            Text("Avatar", style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(source: ImageSource.gallery);
                                if (picked != null) {
                                  setSheetState(() => newAvatar = File(picked.path));
                                }
                              },
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: context.border,
                                backgroundImage: newAvatar != null 
                                    ? FileImage(newAvatar!) 
                                    : (_community.avatarUrl != null ? CachedNetworkImageProvider(_community.avatarUrl!) : null) as ImageProvider?,
                                child: (newAvatar == null && _community.avatarUrl == null)
                                    ? const Icon(Icons.camera_alt, size: 28)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        // Banner picker
                        Column(
                          children: [
                            Text("Cover Photo", style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final picked = await picker.pickImage(source: ImageSource.gallery);
                                if (picked != null) {
                                  setSheetState(() => newBanner = File(picked.path));
                                }
                              },
                              child: Container(
                                width: 140,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: context.border,
                                  borderRadius: BorderRadius.circular(8),
                                  image: newBanner != null
                                      ? DecorationImage(image: FileImage(newBanner!), fit: BoxFit.cover)
                                      : (_community.bannerUrl != null
                                          ? DecorationImage(image: CachedNetworkImageProvider(_community.bannerUrl!), fit: BoxFit.cover)
                                          : null),
                                ),
                                child: (newBanner == null && _community.bannerUrl == null)
                                    ? const Center(child: Icon(Icons.camera_alt, size: 28))
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text("Community Name", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      style: GoogleFonts.inter(color: context.textPrimary),
                      decoration: InputDecoration(
                        fillColor: context.scaffoldBg,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("Description", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      style: GoogleFonts.inter(color: context.textPrimary),
                      decoration: InputDecoration(
                        fillColor: context.scaffoldBg,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("Privacy", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: privacy,
                      dropdownColor: context.cardBg,
                      style: GoogleFonts.inter(color: context.textPrimary),
                      decoration: InputDecoration(
                        fillColor: context.scaffoldBg,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'public', child: Text("Public")),
                        DropdownMenuItem(value: 'restricted', child: Text("Restricted")),
                        DropdownMenuItem(value: 'private', child: Text("Private")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          privacy = val;
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E824C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: isSaving ? null : () async {
                          final name = nameCtrl.text.trim();
                          final desc = descCtrl.text.trim();
                          if (name.isEmpty || desc.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Name and Description cannot be empty.")),
                            );
                            return;
                          }
                          
                          setSheetState(() => isSaving = true);
                          
                          final service = Provider.of<CommunityService>(context, listen: false);
                          final ok = await service.updateCommunity(
                            id: _community.id,
                            name: name,
                            description: desc,
                            privacy: privacy,
                            avatarFile: newAvatar,
                            bannerFile: newBanner,
                          );
                          
                          if (ok) {
                            await _fetchData();
                            if (bctx.mounted) {
                              Navigator.pop(bctx);
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Community updated successfully.")),
                              );
                            }
                          } else {
                            setSheetState(() => isSaving = false);
                            if (bctx.mounted) {
                              ScaffoldMessenger.of(bctx).showSnackBar(
                                const SnackBar(content: Text("Failed to update community details.")),
                              );
                            }
                          }
                        },
                        child: isSaving 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text("Save Changes", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddEditRuleDialog(CommunityRule? rule) {
    final isEdit = rule != null;
    final titleCtrl = TextEditingController(text: rule?.title ?? '');
    final descCtrl = TextEditingController(text: rule?.description ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: context.cardBg,
              title: Text(
                isEdit ? "Edit Rule / Guide" : "Add Rule / Guide",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    style: GoogleFonts.inter(color: context.textPrimary),
                    decoration: InputDecoration(
                      labelText: "Rule Title",
                      labelStyle: GoogleFonts.inter(color: context.textSecondary),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.border)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: GoogleFonts.inter(color: context.textPrimary),
                    decoration: InputDecoration(
                      labelText: "Elaborated Guide",
                      labelStyle: GoogleFonts.inter(color: context.textSecondary),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.border)),
                    ),
                  ),
                ],
              ),
              actions: [
                if (isEdit)
                  TextButton(
                    onPressed: isSaving ? null : () async {
                      setStateDialog(() => isSaving = true);
                      final service = Provider.of<CommunityService>(context, listen: false);
                      final ok = await service.deleteCommunityRule(rule.id);
                      if (ok) {
                        await _fetchData();
                        if (mounted) Navigator.pop(ctx); // ignore: use_build_context_synchronously
                      } else {
                        setStateDialog(() => isSaving = false);
                      }
                    },
                    child: const Text("Delete", style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Cancel", style: TextStyle(color: context.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    final title = titleCtrl.text.trim();
                    final desc = descCtrl.text.trim();
                    if (title.isEmpty) return;

                    setStateDialog(() => isSaving = true);
                    final service = Provider.of<CommunityService>(context, listen: false);
                    
                    bool ok;
                    if (isEdit) {
                      ok = await service.updateCommunityRule(rule.id, title, desc);
                    } else {
                      ok = await service.addCommunityRule(_community.id, title, desc);
                    }

                    if (ok) {
                      await _fetchData();
                      if (mounted) Navigator.pop(ctx); // ignore: use_build_context_synchronously
                    } else {
                      setStateDialog(() => isSaving = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E824C)),
                  child: Text(isSaving ? "Saving..." : "Save", style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
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
        return CustomThreadCard(
          post: _posts[index],
          isCommunityModerator: _community.myRole == 'owner' || _community.myRole == 'moderator',
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
    final dbService = Provider.of<DatabaseService>(context);
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
                      final isFollowing = dbService.isFollowingUser(profile.id);
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
                              TextButton(
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
