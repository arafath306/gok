import 'package:flutter/foundation.dart';
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
        final rawStr = json['created_at'] as String;
        final hasTimezone = rawStr.endsWith('Z') || rawStr.contains('+') || RegExp(r'-\d{2}:\d{2}$').hasMatch(rawStr);
        final normalizedStr = hasTimezone ? rawStr : '${rawStr.replaceAll(' ', 'T')}Z';
        parsedTime = DateTime.parse(normalizedStr).toUtc();
      } catch (e) {
        debugPrint('[AppNotification] Error parsing time: $e');
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
