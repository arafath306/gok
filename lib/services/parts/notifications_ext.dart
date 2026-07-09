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
        final actorMap = json['actor'] as Map<String, dynamic>?;
        final actorProfile = actorMap != null 
            ? Profile.fromJson(actorMap) 
            : Profile(id: json['actor_id'] ?? '', username: 'unknown', fullName: 'Unknown User');

        // Parse creation time to display relative timing
        final DateTime createdAtTime = DateTime.parse(json['created_at'] as String);
        final String relativeTime = _getRelativeTime(createdAtTime);

        return AppNotification(
          id: json['id'] as String,
          userId: json['user_id'] as String,
          actor: actorProfile,
          type: json['type'] as String,
          threadId: json['thread_id'] as String?,
          content: json['content'] as String,
          createdAt: relativeTime,
          read: json['is_read'] as bool? ?? false,
          createdAtDateTime: createdAtTime,
        );
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
        _notifications[idx] = AppNotification(
          id: old.id,
          userId: old.userId,
          actor: old.actor,
          type: old.type,
          threadId: old.threadId,
          content: old.content,
          createdAt: old.createdAt,
          read: true,
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
      )).toList();
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
