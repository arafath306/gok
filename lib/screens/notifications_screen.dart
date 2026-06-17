import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'settings/notification_settings_screen.dart';
import '../utils/routes.dart';
import '../utils/app_theme.dart';
import 'profile/profile_screen.dart';
import '../models/notification.dart';

class GroupedNotification {
  final String id;
  final String type;
  final List<AppNotification> rawNotifications;
  final String displayTitle;
  final String displayContent;
  final String displayTime;
  final bool read;

  GroupedNotification({
    required this.id,
    required this.type,
    required this.rawNotifications,
    required this.displayTitle,
    required this.displayContent,
    required this.displayTime,
    required this.read,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DatabaseService>(context, listen: false).fetchNotifications();
    });
  }

  List<GroupedNotification> _groupNotifications(List<AppNotification> list) {
    final List<GroupedNotification> grouped = [];
    final Set<String> processedIds = {};

    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      if (processedIds.contains(item.id)) continue;

      if (item.type.toLowerCase() == 'follow') {
        // Find other follow notifications within a 3-minute window (180 seconds)
        final List<AppNotification> group = [item];
        processedIds.add(item.id);

        final DateTime? currentParsed = item.createdAtDateTime;
        if (currentParsed != null) {
          for (int j = i + 1; j < list.length; j++) {
            final other = list[j];
            if (processedIds.contains(other.id)) continue;
            if (other.type.toLowerCase() == 'follow') {
              final DateTime? otherParsed = other.createdAtDateTime;
              if (otherParsed != null) {
                final diff = currentParsed.difference(otherParsed).inSeconds.abs();
                if (diff <= 180) { // 3 minutes
                  group.add(other);
                  processedIds.add(other.id);
                }
              }
            }
          }
        }

        // Format display
        final isGroupRead = group.every((n) => n.read);
        String displayTitle;
        String displayContent;

        if (group.length == 1) {
          displayTitle = item.actor.fullName;
          displayContent = "followed you";
        } else if (group.length == 2) {
          displayTitle = "${group[0].actor.fullName} and ${group[1].actor.fullName}";
          displayContent = "followed you";
        } else {
          final extraCount = group.length - 2;
          displayTitle = "${group[0].actor.fullName}, ${group[1].actor.fullName}";
          displayContent = "and $extraCount others followed you";
        }

        grouped.add(GroupedNotification(
          id: item.id,
          type: 'follow',
          rawNotifications: group,
          displayTitle: displayTitle,
          displayContent: displayContent,
          displayTime: item.createdAt,
          read: isGroupRead,
        ));
      } else {
        // Non-follow notification
        processedIds.add(item.id);
        grouped.add(GroupedNotification(
          id: item.id,
          type: item.type,
          rawNotifications: [item],
          displayTitle: item.actor.fullName,
          displayContent: item.content,
          displayTime: item.createdAt,
          read: item.read,
        ));
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(
          backgroundColor: context.scaffoldBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.menu_rounded, color: context.textPrimary),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          title: Text(
            "Notifications",
            style: GoogleFonts.inter(
              color: context.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            // Mark all read button
            Consumer<DatabaseService>(
              builder: (context, dbService, _) {
                final hasUnread = dbService.notifications.any((n) => !n.read);
                return hasUnread
                    ? TextButton(
                        onPressed: () => dbService.markAllNotificationsRead(),
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
              icon: Icon(Icons.settings_outlined, color: context.textPrimary),
              onPressed: () {
                Navigator.push(
                  context,
                  NoTransitionPageRoute(child: const NotificationSettingsScreen()),
                );
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: const Color(0xFF0085FF),
            indicatorWeight: 2,
            labelColor: context.textPrimary,
            unselectedLabelColor: context.textMuted,
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.normal,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: "All"),
              Tab(text: "Mentions"),
            ],
          ),
        ),
        body: Consumer<DatabaseService>(
          builder: (context, dbService, _) {
            final notifications = dbService.notifications;
            final mentions = notifications.where((n) => n.type == 'mention').toList();

            final groupedNotifications = _groupNotifications(notifications);
            final groupedMentions = _groupNotifications(mentions);

            return TabBarView(
              children: [
                _buildNotificationList(groupedNotifications),
                _buildNotificationList(groupedMentions),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<GroupedNotification> list) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => Provider.of<DatabaseService>(context, listen: false).fetchNotifications(),
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
                      size: 90,
                      color: context.isDarkMode ? Colors.white30 : Colors.blueGrey.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No notifications yet!",
                      style: GoogleFonts.inter(
                        color: context.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
      onRefresh: () => Provider.of<DatabaseService>(context, listen: false).fetchNotifications(),
      child: ListView.separated(
        itemCount: list.length,
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 72),
        separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
        itemBuilder: (context, index) {
          final item = list[index];
          final firstActor = item.rawNotifications[0].actor;
          final avatarUrl = firstActor.avatarUrl;

          return Material(
            color: item.read 
                ? context.scaffoldBg 
                : (context.isDarkMode ? const Color(0xFF0A1931) : const Color(0xFFF0F7FF)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              onTap: () {
                final db = Provider.of<DatabaseService>(context, listen: false);
                for (final n in item.rawNotifications) {
                  if (!n.read) {
                    db.markNotificationRead(n.id);
                  }
                }
                if (item.type.toLowerCase() == 'follow') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
                }
              },
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: context.border,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        firstActor.fullName.isNotEmpty ? firstActor.fullName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: context.primaryAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              title: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: context.textPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: "${item.displayTitle} ",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: item.displayContent),
                  ],
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  item.displayTime,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: context.textMuted,
                  ),
                ),
              ),
              trailing: !item.read
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0085FF),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
