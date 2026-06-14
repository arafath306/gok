import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'settings/notification_settings_screen.dart';
import '../utils/routes.dart';
import '../utils/app_theme.dart';

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
            style: GoogleFonts.outfit(
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
                          style: GoogleFonts.outfit(
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
            labelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(
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

            return TabBarView(
              children: [
                _buildNotificationList(notifications),
                _buildNotificationList(mentions),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<dynamic> list) {
    if (list.isEmpty) {
      return Center(
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
              style: GoogleFonts.outfit(
                color: context.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
        itemBuilder: (context, index) {
          final item = list[index];
          return Material(
              color: item.read 
                  ? context.scaffoldBg 
                  : (context.isDarkMode ? const Color(0xFF0A1931) : const Color(0xFFF0F7FF)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                onTap: () {
                  if (!item.read) {
                    Provider.of<DatabaseService>(context, listen: false)
                        .markNotificationRead(item.id);
                  }
                },
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: context.border,
                  backgroundImage: item.actor.avatarUrl != null && item.actor.avatarUrl.isNotEmpty
                      ? NetworkImage(item.actor.avatarUrl)
                      : const NetworkImage("https://i.pravatar.cc/150?u=actor"),
                ),
                title: RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: context.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: "${item.actor.fullName} ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: item.content),
                    ],
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    item.createdAt,
                    style: GoogleFonts.outfit(
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
