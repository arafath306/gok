import 'package:flutter_test/flutter_test.dart';
import 'package:dak/models/notification.dart';

void main() {
  group('AppNotification Model Tests', () {
    test('fromJson parses basic notification correctly', () {
      final json = {
        'id': 'notif1',
        'user_id': 'my_uid',
        'actor': {
          'id': 'actor123',
          'username': 'actor_name',
          'full_name': 'Actor Full Name',
        },
        'type': 'LIKE',
        'thread_id': 'thread123',
        'content': 'liked your post',
        'created_at': '2026-07-13T10:00:00Z',
        'is_read': true,
      };

      final notification = AppNotification.fromJson(json);

      expect(notification.id, 'notif1');
      expect(notification.userId, 'my_uid');
      expect(notification.actor.id, 'actor123');
      expect(notification.type, 'LIKE');
      expect(notification.threadId, 'thread123');
      expect(notification.content, 'liked your post');
      expect(notification.read, true);
      expect(notification.createdAtDateTime, isNotNull);
    });

    test('fromJson handles missing actor gracefully', () {
      final json = {
        'id': 'notif2',
        'user_id': 'my_uid',
        'actor_id': 'actor456',
        // 'actor' object is missing
        'type': 'FOLLOW',
        'content': 'started following you',
      };

      final notification = AppNotification.fromJson(json);
      
      expect(notification.actor.id, 'actor456');
      expect(notification.actor.username, 'unknown');
    });

    test('fromJson sets default read state to false', () {
      final json = {
        'id': 'notif3',
        'user_id': 'my_uid',
        'type': 'MENTION',
        'content': 'mentioned you',
      };

      final notification = AppNotification.fromJson(json);
      expect(notification.read, false);
    });
  });
}
