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

  AppNotification({
    required this.id,
    required this.userId,
    required this.actor,
    required this.type,
    this.threadId,
    required this.content,
    required this.createdAt,
    this.read = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final actorMap = json['actor'] as Map<String, dynamic>?;
    final actorProfile = actorMap != null 
        ? Profile.fromJson(actorMap) 
        : Profile(id: json['actor_id'] ?? '', username: 'unknown', fullName: 'Unknown User');

    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actor: actorProfile,
      type: json['type'] as String,
      threadId: json['thread_id'] as String?,
      content: json['content'] as String,
      createdAt: json['created_at'] as String? ?? 'এখনই',
      read: json['read'] as bool? ?? false,
    );
  }
}
