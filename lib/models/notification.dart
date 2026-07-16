import 'profile.dart';

class AppNotification {
  final String id;
  final String userId;
  final Profile actor;
  final String type; // "LIKE", "REPLY", "FOLLOW", "MENTION"
  final String? threadId;
  final String content;
  final String createdAt;
  final bool read;
  final DateTime? createdAtDateTime;

  AppNotification({
    required this.id,
    required this.userId,
    required this.actor,
    required this.type,
    this.threadId,
    required this.content,
    required this.createdAt,
    this.read = false,
    this.createdAtDateTime,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final actorMap = json['actor'] as Map<String, dynamic>?;
    final actorProfile = actorMap != null 
        ? Profile.fromJson(actorMap) 
        : Profile(id: json['actor_id'] ?? '', username: 'unknown', fullName: 'Unknown User');

    DateTime? parsedTime;
    if (json['created_at'] != null) {
      try {
        // Always parse as UTC to avoid local-time vs UTC mismatch
        // which caused all notifications to appear as "Just now"
        final raw = DateTime.parse(json['created_at'] as String);
        // If the parsed DateTime is not already UTC, treat it as UTC
        parsedTime = raw.isUtc ? raw : DateTime.utc(
          raw.year, raw.month, raw.day,
          raw.hour, raw.minute, raw.second, raw.millisecond,
        );
      } catch (e) {
        // ignore: avoid_print
        print("Error in models/notification.dart: $e");
      }
    }

    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actor: actorProfile,
      type: json['type'] as String,
      threadId: json['thread_id'] as String?,
      content: json['content'] as String,
      createdAt: json['created_at'] as String? ?? 'Just now',
      read: json['is_read'] as bool? ?? false,
      createdAtDateTime: parsedTime,
    );
  }
}
