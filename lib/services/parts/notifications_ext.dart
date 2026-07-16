part of '../database_service.dart';

extension NotificationsExtension on DatabaseService {
  // --- Notifications ---

  Future<void> fetchNotifications() async {
    if (_currentUid.isEmpty) return;
    try {
      final response = await _supabase
          .from('notifications')
          .select('*, actor:profiles!actor_id(*)')
          .eq('user_id', _currentUid)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      _notifications = data.map((json) {
        return AppNotification.fromJson(json as Map<String, dynamic>);
      }).toList();
      updateState();
    } catch (e) {
      debugPrint("Fetch notifications error: $e");
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    if (_currentUid.isEmpty) return;
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      // Update local state immediately
      final idx = _notifications.indexWhere((n) => n.id == notificationId);
      if (idx != -1) {
        final old = _notifications[idx];
        if (!old.read) {
          _unreadNotificationsCount = (_unreadNotificationsCount - 1).clamp(0, 999999);
        }
        _notifications[idx] = AppNotification(
          id: old.id,
          userId: old.userId,
          actor: old.actor,
          type: old.type,
          threadId: old.threadId,
          content: old.content,
          createdAt: old.createdAt,
          read: true,
          createdAtDateTime: old.createdAtDateTime,
        );
        updateState();
      }
    } catch (e) {
      debugPrint("Mark notification read error: $e");
    }
  }

  Future<void> markAllNotificationsRead() async {
    if (_currentUid.isEmpty) return;
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', _currentUid)
          .eq('is_read', false);
      _notifications = _notifications.map((n) => AppNotification(
        id: n.id,
        userId: n.userId,
        actor: n.actor,
        type: n.type,
        threadId: n.threadId,
        content: n.content,
        createdAt: n.createdAt,
        read: true,
        createdAtDateTime: n.createdAtDateTime,
      )).toList();
      _unreadNotificationsCount = 0;
      updateState();
    } catch (e) {
      debugPrint("Mark all notifications read error: $e");
    }
  }

  String _getRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

}
