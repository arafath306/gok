import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'settings/notification_settings_screen.dart';
import '../utils/routes.dart';

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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.black87),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
          title: Text(
            "Notifications",
            style: GoogleFonts.outfit(
              color: Colors.black87,
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
              icon: const Icon(Icons.settings_outlined, color: Colors.black87),
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
            labelColor: Colors.black87,
            unselectedLabelColor: Colors.black38,
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
              color: Colors.blueGrey.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              "No notifications yet!",
              style: GoogleFonts.outfit(
                color: Colors.black54,
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
        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF5F5F5)),
        itemBuilder: (context, index) {
          final item = list[index];
          return Container(
              color: item.read ? Colors.white : const Color(0xFFF0F7FF),
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
                  backgroundColor: Colors.grey[200],
                  backgroundImage: item.actor.avatarUrl != null && item.actor.avatarUrl.isNotEmpty
                      ? NetworkImage(item.actor.avatarUrl)
                      : const NetworkImage("https://i.pravatar.cc/150?u=actor"),
                ),
                title: RichText(
                  text: TextSpan(
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.black87,
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
                      color: Colors.black45,
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
