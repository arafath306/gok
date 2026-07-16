import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../core/injection.dart';
import '../features/notifications/domain/usecases/clear_notification_inbox_use_case.dart';
import 'settings/notification_settings_screen.dart';
import '../utils/routes.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_menu_button.dart';
import 'profile/profile_screen.dart';
import 'thread_detail_screen.dart';
import '../models/notification.dart';
import '../models/thread_post.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ─── Grouped notification model ───────────────────────────────────────────────

class GroupedNotification {
  final String id;
  final String type;
  final List<AppNotification> rawNotifications;
  final String? groupKey; // thread_id for likes/comments/reposts, actor_id for follows
  final String displayTitle;
  final String displayContent;
  final DateTime sortTime;
  final bool read;

  GroupedNotification({
    required this.id,
    required this.type,
    required this.rawNotifications,
    this.groupKey,
    required this.displayTitle,
    required this.displayContent,
    required this.sortTime,
    required this.read,
  });

  String get displayTime => _relativeTime(sortTime);

  static String _relativeTime(DateTime t) {
    // Use UTC now to compare against the UTC-parsed server timestamp.
    // Without this, a 6-hour timezone offset (e.g. BST +6) caused every
    // notification to show "Just now" on first load.
    final now = DateTime.now().toUtc();
    final utcT = t.isUtc ? t : t.toUtc();
    final diff = now.difference(utcT);

    // Guard against future-dated timestamps (clock skew / DST edge cases)
    if (diff.isNegative || diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    // For older notifications show the date
    final day = utcT.toLocal().day.toString().padLeft(2, '0');
    final month = utcT.toLocal().month.toString().padLeft(2, '0');
    return '$day/$month';
  }
}

// ─── Grouping logic ───────────────────────────────────────────────────────────

List<GroupedNotification> groupNotifications(List<AppNotification> list) {
  final result = <GroupedNotification>[];
  final seen = <String>{};

  // Types that are grouped by thread_id (post-centric grouping)
  const postGroupTypes = {'like', 'comment', 'repost', 'reply'};
  // Types that are grouped by proximity in time (social grouping)
  const socialGroupTypes = {'follow'};
  // Window for time-based social grouping (15 minutes)
  const socialWindowSec = 900;

  // ── 1. Post-centric grouping (likes/comments/reposts on same thread) ────────
  final byTypeAndThread = <String, List<AppNotification>>{};
  for (final n in list) {
    final t = n.type.toLowerCase();
    if (!postGroupTypes.contains(t)) continue;
    final key = '${t}_${n.threadId ?? 'no_thread'}';
    byTypeAndThread.putIfAbsent(key, () => []).add(n);
  }

  for (final entry in byTypeAndThread.entries) {
    final group = entry.value;
    group.sort((a, b) => (b.createdAtDateTime ?? DateTime(0))
        .compareTo(a.createdAtDateTime ?? DateTime(0)));
    final representative = group.first;
    final type = representative.type.toLowerCase();
    final allRead = group.every((n) => n.read);
    for (final n in group) {
      seen.add(n.id);
    }

    String title;
    String content;
    if (group.length == 1) {
      title = representative.actor.fullName;
      content = representative.content;
    } else if (group.length == 2) {
      title = '${group[0].actor.fullName} and ${group[1].actor.fullName}';
      content = _postGroupContent(type, 0);
    } else {
      final extra = group.length - 2;
      title = '${group[0].actor.fullName}, ${group[1].actor.fullName}';
      content = _postGroupContent(type, extra);
    }

    result.add(GroupedNotification(
      id: representative.id,
      type: type,
      rawNotifications: group,
      groupKey: representative.threadId,
      displayTitle: title,
      displayContent: content,
      sortTime: representative.createdAtDateTime ?? DateTime.now(),
      read: allRead,
    ));
  }

  // ── 2. Social grouping (follows within a time window) ───────────────────────
  for (int i = 0; i < list.length; i++) {
    final item = list[i];
    final type = item.type.toLowerCase();
    if (!socialGroupTypes.contains(type)) continue;
    if (seen.contains(item.id)) continue;
    seen.add(item.id);

    final group = <AppNotification>[item];
    final baseTime = item.createdAtDateTime;

    if (baseTime != null) {
      for (int j = i + 1; j < list.length; j++) {
        final other = list[j];
        if (seen.contains(other.id)) continue;
        if (other.type.toLowerCase() != type) continue;
        final otherTime = other.createdAtDateTime;
        if (otherTime != null &&
            baseTime.difference(otherTime).inSeconds.abs() <= socialWindowSec) {
          group.add(other);
          seen.add(other.id);
        }
      }
    }

    final allRead = group.every((n) => n.read);
    String title;
    String content;
    if (group.length == 1) {
      title = item.actor.fullName;
      content = 'followed you';
    } else if (group.length == 2) {
      title = '${group[0].actor.fullName} and ${group[1].actor.fullName}';
      content = 'followed you';
    } else {
      final extra = group.length - 2;
      title = '${group[0].actor.fullName}, ${group[1].actor.fullName}';
      content = 'and $extra others followed you';
    }

    result.add(GroupedNotification(
      id: item.id,
      type: type,
      rawNotifications: group,
      groupKey: null,
      displayTitle: title,
      displayContent: content,
      sortTime: item.createdAtDateTime ?? DateTime.now(),
      read: allRead,
    ));
  }

  // ── 3. Remaining notifications (mention, etc.) ───────────────────────────────
  for (final n in list) {
    if (seen.contains(n.id)) continue;
    seen.add(n.id);
    result.add(GroupedNotification(
      id: n.id,
      type: n.type.toLowerCase(),
      rawNotifications: [n],
      groupKey: n.threadId,
      displayTitle: n.actor.fullName,
      displayContent: n.content,
      sortTime: n.createdAtDateTime ?? DateTime.now(),
      read: n.read,
    ));
  }

  result.sort((a, b) => b.sortTime.compareTo(a.sortTime));
  return result;
}

String _postGroupContent(String type, int extra) {
  final suffix = extra > 0 ? ' and $extra others' : '';
  switch (type) {
    case 'like':
      return 'liked your post$suffix';
    case 'comment':
      return 'commented on your post$suffix';
    case 'repost':
      return 'reposted your post$suffix';
    case 'reply':
      return 'replied to your post$suffix';
    default:
      return 'interacted with your post$suffix';
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  final bool isActive;
  const NotificationsScreen({super.key, this.isActive = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final TabController _tabController;
  bool _clearingInbox = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final db = Provider.of<DatabaseService>(context, listen: false);
      await db.fetchNotifications();
      if (widget.isActive) {
        await db.markAllNotificationsRead();
      }
      // Clear OS inbox when user opens the screen
      if (!_clearingInbox) {
        _clearingInbox = true;
        sl<ClearNotificationInboxUseCase>().call();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Navigation helpers ─────────────────────────────────────────────────────
  void _navigateForItem(GroupedNotification item) async {
    final db = Provider.of<DatabaseService>(context, listen: false);

    // Mark all raw notifications in group as read
    for (final n in item.rawNotifications) {
      if (!n.read) db.markNotificationRead(n.id);
    }

    final threadId = item.groupKey;
    final type = item.type;

    if (type == 'follow' || threadId == null) {
      // Navigate to the actor's profile
      final actorId = item.rawNotifications.first.actor.id;
      final isOwn = actorId == (db.myProfile?.id ?? db.currentUid);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(userId: isOwn ? null : actorId),
          ),
        );
      }
      return;
    }

    // Navigate to the thread
    if (!mounted) return;
    final post = await _fetchPost(db, threadId);
    if (!mounted) return;
    if (post != null) {
      Navigator.push(
        context,
        NoTransitionPageRoute(child: ThreadDetailScreen(post: post)),
      );
    }
  }

  Future<ThreadPost?> _fetchPost(DatabaseService db, String threadId) async {
    try {
      final data = await db.fetchSingleThread(threadId);
      return data;
    } catch (e) {
      return null;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: _buildAppBar(),
      body: Consumer<DatabaseService>(
        builder: (context, dbService, _) {
          if (widget.isActive && dbService.unreadNotificationsCount > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                dbService.markAllNotificationsRead();
              }
            });
          }
          final all = dbService.notifications;
          final mentions = all.where((n) => n.type.toLowerCase() == 'mention').toList();

          final groupedAll = groupNotifications(all);
          final groupedMentions = groupNotifications(mentions);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(groupedAll),
              _buildList(groupedMentions),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.scaffoldBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: const CustomMenuButton(),
      title: Text(
        'Notifications',
        style: GoogleFonts.inter(
          color: context.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        Consumer<DatabaseService>(
          builder: (context, db, _) {
            final hasUnread = db.notifications.any((n) => !n.read);
            return hasUnread
                ? TextButton(
                    onPressed: () => db.markAllNotificationsRead(),
                    child: Text(
                      'Mark all',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0085FF),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
        IconButton(
          tooltip: 'Notification settings',
          icon: Icon(Icons.settings_outlined, color: context.textPrimary),
          onPressed: () => Navigator.push(
            context,
            NoTransitionPageRoute(child: const NotificationSettingsScreen()),
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF0085FF),
        indicatorWeight: 2,
        labelColor: context.textPrimary,
        unselectedLabelColor: context.textMuted,
        labelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
        unselectedLabelStyle:
            GoogleFonts.inter(fontWeight: FontWeight.normal, fontSize: 15),
        tabs: const [Tab(text: 'All'), Tab(text: 'Mentions')],
      ),
    );
  }

  Widget _buildList(List<GroupedNotification> list) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            Provider.of<DatabaseService>(context, listen: false).fetchNotifications(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 80,
                      color: context.isDarkMode
                          ? Colors.white24
                          : Colors.blueGrey.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Activity will appear here',
                      style: GoogleFonts.inter(
                        color: context.textMuted,
                        fontSize: 13,
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

    return RefreshIndicator(
      onRefresh: () =>
          Provider.of<DatabaseService>(context, listen: false).fetchNotifications(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
        itemCount: list.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: context.border),
        itemBuilder: (context, index) => RepaintBoundary(child: _buildItem(list[index])),
      ),
    );
  }

  // ── Notification item tile ─────────────────────────────────────────────────
  Widget _buildItem(GroupedNotification item) {
    final isUnread = !item.read;

    return Material(
      color: isUnread
          ? (context.isDarkMode
              ? const Color(0xFF0A1931)
              : const Color(0xFFF0F7FF))
          : context.scaffoldBg,
      child: InkWell(
        onTap: () => _navigateForItem(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Avatar(s) ──────────────────────────────────────────────────
              _buildAvatarStack(item.rawNotifications),
              const SizedBox(width: 14),

              // ── Text ───────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: context.textPrimary,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: '${item.displayTitle} ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: item.displayContent),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _typeChip(item.type),
                        const SizedBox(width: 8),
                        Text(
                          item.displayTime,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: context.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Unread dot ─────────────────────────────────────────────────
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0085FF),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stacked multi-avatar for grouped notifications ─────────────────────────
  Widget _buildAvatarStack(List<AppNotification> notifications) {
    final unique = <String, AppNotification>{};
    for (final n in notifications) {
      if (!unique.containsKey(n.actor.id)) {
        unique[n.actor.id] = n;
      }
      if (unique.length >= 3) break;
    }
    final actors = unique.values.toList();

    if (actors.length == 1) {
      return _singleAvatar(actors[0].actor.avatarUrl, actors[0].actor.fullName, 22);
    }

    // Stack of up to 3 overlapping avatars
    const radius = 18.0;
    const overlap = 10.0;
    final count = actors.length.clamp(1, 3);
    final totalWidth = radius * 2 + (count - 1) * (radius * 2 - overlap);

    return SizedBox(
      width: totalWidth,
      height: radius * 2,
      child: Stack(
        children: List.generate(count, (i) {
          final actor = actors[count - 1 - i]; // render front-to-back
          return Positioned(
            left: i * (radius * 2 - overlap),
            child: _singleAvatar(actor.actor.avatarUrl, actor.actor.fullName, radius,
                border: true),
          );
        }).reversed.toList(),
      ),
    );
  }

  Widget _singleAvatar(String? url, String name, double radius,
      {bool border = false}) {
    final child = CircleAvatar(
      radius: radius,
      backgroundColor: context.border,
      backgroundImage:
          url != null && url.isNotEmpty ? CachedNetworkImageProvider(url) : null,
      child: url == null || url.isEmpty
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: context.primaryAccent,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );

    if (!border) return child;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: context.scaffoldBg,
          width: 2,
        ),
      ),
      child: child,
    );
  }

  // ── Type label chip ────────────────────────────────────────────────────────
  Widget _typeChip(String type) {
    final data = _chipData(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: data.$2.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.$1, size: 10, color: data.$2),
          const SizedBox(width: 3),
          Text(
            data.$3,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: data.$2,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _chipData(String type) {
    switch (type) {
      case 'like':
        return (Icons.favorite_rounded, const Color(0xFFE53935), 'Like');
      case 'comment':
        return (Icons.mode_comment_rounded, const Color(0xFF1E88E5), 'Comment');
      case 'follow':
        return (Icons.person_add_rounded, const Color(0xFF43A047), 'Follow');
      case 'mention':
        return (Icons.alternate_email_rounded, const Color(0xFF8E24AA), 'Mention');
      case 'repost':
        return (Icons.repeat_rounded, const Color(0xFF00ACC1), 'Repost');
      case 'reply':
        return (Icons.reply_rounded, const Color(0xFF1E88E5), 'Reply');
      case 'generic':
      case 'message':
        return (Icons.notifications_rounded, const Color(0xFF0085FF), 'System');
      default:
        return (Icons.notifications_rounded, const Color(0xFF0085FF), type);
    }
  }


}
