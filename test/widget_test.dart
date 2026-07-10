// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';

import 'package:dak/models/thread_post.dart';

void main() {
  test('ThreadPost parses Supabase thread payload', () {
    final post = ThreadPost.fromJson(
      {
        'id': 'thread-1',
        'user_id': 'user-1',
        'content': 'Assalamu alaikum Dak',
        'created_at': DateTime.now().toIso8601String(),
        'likes_count': 3,
        'replies_count': 1,
        'reposts_count': 0,
        'image_urls': ['https://example.com/photo.jpg'],
        'profiles': {
          'id': 'user-1',
          'username': 'arafath',
          'full_name': 'Arafath',
        },
        'likes': [
          {'user_id': 'user-2'},
        ],
      },
      currentUid: 'user-2',
    );

    expect(post.id, 'thread-1');
    expect(post.author.username, 'arafath');
    expect(post.imageUrls, contains('https://example.com/photo.jpg'));
    expect(post.isLikedByMe, isTrue);
  });
}
