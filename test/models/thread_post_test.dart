import 'package:flutter_test/flutter_test.dart';
import 'package:dak/models/thread_post.dart';

void main() {
  group('ThreadPost Model Tests', () {
    test('fromJson parses basic text post correctly', () {
      final json = {
        'id': 'post123',
        'user_id': 'user123',
        'profiles': {
          'id': 'user123',
          'username': 'john_doe',
          'full_name': 'John Doe',
        },
        'content': 'Hello world!',
        'likes_count': 10,
        'replies_count': 5,
        'created_at': '2026-07-13T10:00:00Z',
      };

      final post = ThreadPost.fromJson(json, currentUid: 'user456');

      expect(post.id, 'post123');
      expect(post.userId, 'user123');
      expect(post.author.username, 'john_doe');
      expect(post.content, 'Hello world!');
      expect(post.likesCount, 10);
      expect(post.repliesCount, 5);
      expect(post.imageUrls, isNull);
      expect(post.isLikedByMe, false);
      expect(post.isRepost, false);
    });

    test('fromJson correctly parses liked state for current user', () {
      final json = {
        'id': 'post123',
        'user_id': 'user123',
        'profiles': {'id': 'user123'},
        'content': 'Liked post',
        'likes': [
          {'user_id': 'my_uid'}
        ]
      };

      final post = ThreadPost.fromJson(json, currentUid: 'my_uid');
      expect(post.isLikedByMe, true);
    });

    test('fromJson handles missing profiles gracefully', () {
      final json = {
        'id': 'post123',
        'user_id': 'user123',
        // 'profiles' is missing
        'content': 'Orphan post',
      };

      final post = ThreadPost.fromJson(json, currentUid: 'my_uid');
      expect(post.author.id, 'user123'); // fallback uses user_id
      expect(post.author.fullName, 'Unknown User');
    });

    test('fromJson parses images array correctly', () {
      final json = {
        'id': 'post123',
        'user_id': 'user123',
        'profiles': {'id': 'user123'},
        'content': 'Look at these pictures',
        'image_urls': ['https://example.com/1.png', 'https://example.com/2.png'],
      };

      final post = ThreadPost.fromJson(json, currentUid: 'my_uid');
      expect(post.imageUrls, isNotNull);
      expect(post.imageUrls!.length, 2);
      expect(post.imageUrls![0], 'https://example.com/1.png');
    });

    test('fromJson handles stringified arrays (Supabase issue fallback)', () {
      final json = {
        'id': 'post123',
        'user_id': 'user123',
        'profiles': {'id': 'user123'},
        'content': 'Look at these pictures',
        'image_urls': '["https://example.com/1.png"]',
      };

      final post = ThreadPost.fromJson(json, currentUid: 'my_uid');
      expect(post.imageUrls, isNotNull);
      expect(post.imageUrls!.length, 1);
    });
  });
}
