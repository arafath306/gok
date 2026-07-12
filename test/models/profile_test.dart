import 'package:flutter_test/flutter_test.dart';
import 'package:dak/models/profile.dart';

void main() {
  group('Profile Model Tests', () {
    test('fromJson parses correctly with all valid data', () {
      final json = {
        'id': 'user123',
        'username': 'john_doe',
        'full_name': 'John Doe',
        'bio': 'Software Developer',
        'avatar_url': 'https://example.com/avatar.png',
        'followers_count': 100,
        'following_count': 50,
        'is_verified': true,
        'badge_type': 'blue',
        'last_seen': '2026-07-13T10:00:00Z',
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'user123');
      expect(profile.username, 'john_doe');
      expect(profile.fullName, 'John Doe');
      expect(profile.bio, 'Software Developer');
      expect(profile.avatarUrl, 'https://example.com/avatar.png');
      expect(profile.followersCount, 100);
      expect(profile.followingCount, 50);
      expect(profile.isVerified, true);
      expect(profile.badgeType, 'blue');
      expect(profile.lastSeen, isNotNull);
    });

    test('fromJson uses safe fallbacks for missing fields', () {
      final json = {
        'id': 'user456',
        // username missing
        // full_name missing
      };

      final profile = Profile.fromJson(json);

      expect(profile.id, 'user456');
      expect(profile.username, 'anonymous');
      expect(profile.fullName, 'Anonymous User');
      expect(profile.followersCount, 0);
      expect(profile.followingCount, 0);
      expect(profile.isVerified, false);
      expect(profile.bio, isNull);
    });

    test('toJson serializes correctly', () {
      final profile = Profile(
        id: 'user789',
        username: 'alice',
        fullName: 'Alice Smith',
        followersCount: 5,
        isVerified: false,
      );

      final json = profile.toJson();

      expect(json['id'], 'user789');
      expect(json['username'], 'alice');
      expect(json['full_name'], 'Alice Smith');
      expect(json['followers_count'], 5);
      expect(json['is_verified'], false);
    });
  });
}
