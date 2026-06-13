import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/thread_post.dart';
import '../models/notification.dart';

class DatabaseService with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // Firebase UID passed from AuthGate — used as fallback for read-only queries
  // when Supabase session isn't established yet
  String _firebaseUid = '';

  // Cache variables
  Profile? _myProfile;
  Profile? get myProfile => _myProfile;

  List<ThreadPost> _feed = [];
  List<ThreadPost> get feed => _feed;

  List<ThreadPost> _myThreads = [];
  List<ThreadPost> get myThreads => _myThreads;

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  Set<String> _followingIds = {};
  Set<String> get followingIds => _followingIds;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Supabase session UID — used for write operations (RLS checks auth.uid())
  String get _supabaseSessionUid => _supabase.auth.currentUser?.id ?? '';

  // Effective UID: prefers Supabase session, falls back to Firebase UID for reads
  String get _currentUid {
    if (_supabaseSessionUid.isNotEmpty) return _supabaseSessionUid;
    return _firebaseUid;
  }

  RealtimeChannel? _threadsChannel;
  RealtimeChannel? _likesChannel;
  RealtimeChannel? _repliesChannel;
  RealtimeChannel? _followsChannel;
  RealtimeChannel? _notificationsChannel;
  StreamSubscription<AuthState>? _supabaseAuthSub;

  DatabaseService() {
    // Listen to Supabase auth state — auto-reload when session established
    _supabaseAuthSub = _supabase.auth.onAuthStateChange.listen((data) {
      debugPrint('[DB] Supabase auth event: ${data.event}');
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed) {
        _onUserReady();
      } else if (data.event == AuthChangeEvent.signedOut) {
        // Only clear if Firebase UID also not set (full logout)
        if (_firebaseUid.isEmpty) {
          _clearAllData();
        }
      }
    });

    subscribeToRealtime();
    if (_currentUid.isNotEmpty) {
      _onUserReady();
    }
  }

  /// Called by AuthGate after Firebase login — enables read-only operations
  /// even before Supabase session is established.
  void setFirebaseUid(String uid) {
    if (uid == _firebaseUid && _myProfile != null) return;
    _firebaseUid = uid;
    debugPrint('[DB] Firebase UID set: $uid');
    if (uid.isNotEmpty) {
      _onUserReady();
    }
  }

  /// Called on full logout
  void clearUser() {
    _firebaseUid = '';
    _clearAllData();
  }

  void _onUserReady() {
    fetchMyProfile();
    fetchFollowingList();
    fetchFeed();
    fetchNotifications();
    subscribeToRealtime();
  }

  void _clearAllData() {
    _myProfile = null;
    _feed = [];
    _myThreads = [];
    _notifications = [];
    _followingIds = {};
    unsubscribeRealtime();
    notifyListeners();
  }

  void subscribeToRealtime() {
    // Unsubscribe if channels already exist
    unsubscribeRealtime();

    _threadsChannel = _supabase
        .channel('public:threads')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'threads',
            callback: (payload) {
              fetchFeed();
              if (_currentUid.isNotEmpty) {
                fetchMyThreads();
              }
            })
        .subscribe();

    _likesChannel = _supabase
        .channel('public:likes')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'likes',
            callback: (payload) {
              fetchFeed();
              if (_currentUid.isNotEmpty) {
                fetchMyThreads();
              }
            })
        .subscribe();

    _repliesChannel = _supabase
        .channel('public:replies')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'replies',
            callback: (payload) {
              fetchFeed();
              if (_currentUid.isNotEmpty) {
                fetchMyThreads();
              }
            })
        .subscribe();

    _followsChannel = _supabase
        .channel('public:follows')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'follows',
            callback: (payload) {
              fetchFollowingList();
              fetchMyProfile();
            })
        .subscribe();

    _notificationsChannel = _supabase
        .channel('public:notifications')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              fetchNotifications();
            })
        .subscribe();
  }

  void unsubscribeRealtime() {
    if (_threadsChannel != null) _supabase.removeChannel(_threadsChannel!);
    if (_likesChannel != null) _supabase.removeChannel(_likesChannel!);
    if (_repliesChannel != null) _supabase.removeChannel(_repliesChannel!);
    if (_followsChannel != null) _supabase.removeChannel(_followsChannel!);
    if (_notificationsChannel != null) _supabase.removeChannel(_notificationsChannel!);
  }

  // --- Profile Operations ---

  Future<Profile?> fetchProfile(String userId) async {
    if (userId.startsWith('mock-')) {
      if (userId == 'mock-tamim') {
        return Profile(
          id: 'mock-tamim',
          username: 'tamim_hossain',
          fullName: 'Tamim Hossain',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&fit=crop',
          bio: 'Tech enthusiast, developer, and open-source contributor from Dhaka.',
          followersCount: 1200,
          followingCount: 340,
        );
      } else if (userId == 'mock-nusrat') {
        return Profile(
          id: 'mock-nusrat',
          username: 'nusrat.jahan',
          fullName: 'Nusrat Jahan',
          avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&fit=crop',
          bio: 'Designer, photographer, and travel enthusiast. Capturing life one frame at a time.',
          followersCount: 2500,
          followingCount: 890,
        );
      } else if (userId == 'mock-mehedi') {
        return Profile(
          id: 'mock-mehedi',
          username: 'mehedi.hasan',
          fullName: 'Mehedi Hasan',
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&fit=crop',
          bio: 'Digital content creator, explorer, and coffee lover.',
          followersCount: 950,
          followingCount: 150,
        );
      }
    }
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final profile = Profile.fromJson(response);
        if (userId == _currentUid) {
          _myProfile = profile;
          notifyListeners();
        }
        return profile;
      }
      return null;
    } catch (e) {
      debugPrint("Fetch profile error: $e");
      return null;
    }
  }

  Future<void> fetchMyProfile() async {
    if (_currentUid.isEmpty) return;
    final result = await fetchProfile(_currentUid);
    if (result != null) {
      _myProfile = result;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String username,
    required String bio,
    required String phone,
    required String country,
    String? division,
    String? city,
    String? village,
    String? zip,
    String? gender,
    String? birthdate,
  }) async {
    if (_currentUid.isEmpty) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('profiles')
          .update({
            'full_name': fullName,
            'username': username,
            'bio': bio,
            'phone': phone,
            'country': country,
            'division': division,
            'city': city,
            'village': village,
            'zip': zip,
            'gender': gender,
            'birthdate': birthdate,
          })
          .eq('id', _currentUid)
          .select()
          .single();

      _myProfile = Profile.fromJson(response);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Update profile error: $e");
      return false;
    }
  }



  // --- Follow Operations ---

  bool isFollowingUser(String targetUserId) {
    return _followingIds.contains(targetUserId);
  }

  Future<void> fetchFollowingList() async {
    if (_currentUid.isEmpty) return;
    try {
      final response = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', _currentUid);
      final List<dynamic> data = response as List<dynamic>;
      _followingIds = data.map((json) => json['following_id'] as String).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint("Fetch following list error: $e");
    }
  }

  Future<void> toggleFollowUser(String targetUserId) async {
    if (_currentUid.isEmpty) return;
    try {
      final isCurrentlyFollowing = isFollowingUser(targetUserId);
      if (isCurrentlyFollowing) {
        await _supabase
            .from('follows')
            .delete()
            .eq('follower_id', _currentUid)
            .eq('following_id', targetUserId);
      } else {
        await _supabase.from('follows').insert({
          'follower_id': _currentUid,
          'following_id': targetUserId,
        });
      }
      await fetchFollowingList();
      await fetchMyProfile();
    } catch (e) {
      debugPrint("Toggle follow user error: $e");
    }
  }

  // --- Search & Recommendations ---

  Future<List<Profile>> searchProfiles(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .or('username.ilike.%$query%,full_name.ilike.%$query%')
          .limit(20);
      final List<dynamic> data = response as List<dynamic>;
      final List<Profile> results = data.map((json) => Profile.fromJson(json)).toList();
      
      results.sort((a, b) {
        final aUser = a.username.toLowerCase();
        final bUser = b.username.toLowerCase();
        final q = query.toLowerCase();
        
        final aExact = aUser == q;
        final bExact = bUser == q;
        if (aExact && !bExact) return -1;
        if (!aExact && bExact) return 1;
        
        final aStart = aUser.startsWith(q);
        final bStart = bUser.startsWith(q);
        if (aStart && !bStart) return -1;
        if (!aStart && bStart) return 1;
        
        return 0;
      });
      
      return results;
    } catch (e) {
      debugPrint("Search profiles error: $e");
      return [];
    }
  }

  Future<List<Profile>> getRecommendedProfiles() async {
    if (_currentUid.isEmpty) return [];
    try {
      // Recommend newly created users, excluding oneself
      final response = await _supabase
          .from('profiles')
          .select()
          .neq('id', _currentUid)
          .order('created_at', ascending: false)
          .limit(10);
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Profile.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Get recommended profiles error: $e");
      return [];
    }
  }

  // --- Storage Operations (Avatar/Cover) ---

  Future<String?> _uploadToStorage(String bucket, String path, Uint8List bytes) async {
    try {
      await _supabase.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint("Upload to storage error: $e");
      return null;
    }
  }

  Future<bool> updateProfileImage(Uint8List bytes, bool isAvatar) async {
    if (_currentUid.isEmpty) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final bucket = isAvatar ? 'avatars' : 'covers';
      final path = '$_currentUid/img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final publicUrl = await _uploadToStorage(bucket, path, bytes);
      if (publicUrl != null) {
        final updateField = isAvatar ? 'avatar_url' : 'cover_url';
        await _supabase.from('profiles').update({updateField: publicUrl}).eq('id', _currentUid);
        await fetchMyProfile();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint("Update profile image error: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProfileImage(bool isAvatar) async {
    if (_currentUid.isEmpty) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final updateField = isAvatar ? 'avatar_url' : 'cover_url';
      await _supabase.from('profiles').update({updateField: null}).eq('id', _currentUid);
      await fetchMyProfile();
      return true;
    } catch (e) {
      debugPrint("Delete profile image error: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- Feed / Threads Operations ---

  Future<void> fetchFeed() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('threads')
          .select('*, profiles(*), likes(user_id)')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      _feed = data.map((json) => ThreadPost.fromJson(json, currentUid: _currentUid)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint("Fetch feed error: $e");
    }
  }

  Future<void> fetchMyThreads() async {
    if (_currentUid.isEmpty) return;
    try {
      final response = await _supabase
          .from('threads')
          .select('*, profiles(*), likes(user_id)')
          .eq('user_id', _currentUid)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      _myThreads = data.map((json) => ThreadPost.fromJson(json, currentUid: _currentUid)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Fetch my threads error: $e");
    }
  }

  Future<bool> createThread(String content, {List<String>? imageUrls, String? videoUrl}) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('threads').insert({
        'user_id': _currentUid,
        'content': content,
        'image_urls': imageUrls,
        'video_url': videoUrl,
      });
      await fetchFeed();
      await fetchMyThreads();
      return true;
    } catch (e) {
      debugPrint("Create thread error: $e");
      return false;
    }
  }

  // --- Likes CRUD ---

  Future<void> toggleLike(String threadId, bool shouldLike, {String? reactionType}) async {
    if (_currentUid.isEmpty) return;

    // Local state optimistic update for instant UX feedback
    final feedIndex = _feed.indexWhere((p) => p.id == threadId);
    if (feedIndex != -1) {
      final post = _feed[feedIndex];
      final int countDelta = shouldLike 
          ? (post.isLikedByMe ? 0 : 1) 
          : -1;
      _feed[feedIndex] = post.copyWith(
        likesCount: post.likesCount + countDelta,
        isLikedByMe: shouldLike,
        reactionType: shouldLike ? (reactionType ?? '❤️') : null,
      );
      notifyListeners();
    }

    final myThreadsIndex = _myThreads.indexWhere((p) => p.id == threadId);
    if (myThreadsIndex != -1) {
      final post = _myThreads[myThreadsIndex];
      final int countDelta = shouldLike 
          ? (post.isLikedByMe ? 0 : 1) 
          : -1;
      _myThreads[myThreadsIndex] = post.copyWith(
        likesCount: post.likesCount + countDelta,
        isLikedByMe: shouldLike,
        reactionType: shouldLike ? (reactionType ?? '❤️') : null,
      );
      notifyListeners();
    }

    try {
      if (shouldLike) {
        await _supabase.from('likes').insert({
          'user_id': _currentUid,
          'thread_id': threadId,
        });
      } else {
        await _supabase
            .from('likes')
            .delete()
            .eq('user_id', _currentUid)
            .eq('thread_id', threadId);
      }
    } catch (e) {
      debugPrint("Toggle like error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchThreadReactors(String threadId) async {
    final List<Map<String, dynamic>> reactors = [];
    
    // Always include our mock users to keep the reactions list populated and beautiful
    reactors.addAll([
      {
        'id': 'mock-tamim',
        'name': 'Tamim Hossain',
        'handle': '@tamim_hossain',
        'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&fit=crop',
        'isFollowing': isFollowingUser('mock-tamim'),
      },
      {
        'id': 'mock-nusrat',
        'name': 'Nusrat Jahan',
        'handle': '@nusrat.jahan',
        'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&fit=crop',
        'isFollowing': isFollowingUser('mock-nusrat'),
      },
      {
        'id': 'mock-mehedi',
        'name': 'Mehedi Hasan',
        'handle': '@mehedi.hasan',
        'avatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&fit=crop',
        'isFollowing': isFollowingUser('mock-mehedi'),
      },
    ]);

    try {
      final response = await _supabase
          .from('likes')
          .select('user_id, profiles(*)')
          .eq('thread_id', threadId);
      final List<dynamic> data = response as List<dynamic>;
      
      for (final item in data) {
        final profileMap = item['profiles'] as Map<String, dynamic>?;
        if (profileMap != null) {
          final profile = Profile.fromJson(profileMap);
          // Avoid duplicating if mock accounts overlap with real profiles
          if (profile.id != _currentUid && !reactors.any((r) => r['id'] == profile.id)) {
            reactors.add({
              'id': profile.id,
              'name': profile.fullName,
              'handle': '@${profile.username}',
              'avatar': profile.avatarUrl ?? '',
              'isFollowing': isFollowingUser(profile.id),
            });
          }
        }
      }

      // If current user liked it, make sure they are in the list
      final feedIndex = _feed.indexWhere((p) => p.id == threadId);
      final isLikedByMe = feedIndex != -1 ? _feed[feedIndex].isLikedByMe : false;
      if (isLikedByMe && _myProfile != null) {
        if (!reactors.any((r) => r['id'] == _myProfile!.id)) {
          reactors.insert(0, {
            'id': _myProfile!.id,
            'name': _myProfile!.fullName,
            'handle': '@${_myProfile!.username}',
            'avatar': _myProfile!.avatarUrl ?? '',
            'isFollowing': false,
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch thread reactors error: $e");
    }

    return reactors;
  }

  Future<List<ThreadPost>> fetchUserThreads(String userId) async {
    try {
      if (userId.startsWith('mock-')) {
        final profile = await fetchProfile(userId);
        if (profile == null) return [];
        return [
          ThreadPost(
            id: 'mock-thread-${userId}-1',
            userId: userId,
            author: profile,
            content: 'ডাক অ্যাপের এই চমৎকার ডিজাইন দেখে ভালো লাগলো। একদম সিম্পল এবং আধুনিক! 🚀✨',
            createdAt: '2ঘ',
            likesCount: 12,
            repliesCount: 4,
            isLikedByMe: false,
          ),
          ThreadPost(
            id: 'mock-thread-${userId}-2',
            userId: userId,
            author: profile,
            content: 'ডিজাইন সৌন্দর্যের চেয়ে ইউজার এক্সপেরিয়েন্স বেশি গুরুত্বপূর্ণ। আপনাদের কি মত?',
            createdAt: '1দিন',
            likesCount: 34,
            repliesCount: 9,
            isLikedByMe: true,
            reactionType: '👍',
          ),
        ];
      }

      final response = await _supabase
          .from('threads')
          .select('*, profiles(*), likes(user_id)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => ThreadPost.fromJson(json, currentUid: _currentUid)).toList();
    } catch (e) {
      debugPrint("Fetch user threads error: $e");
      return [];
    }
  }

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
        );
      }).toList();
      notifyListeners();
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
        notifyListeners();
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
      notifyListeners();
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

  // --- Report Operations ---

  Future<bool> reportPost(String threadId, String reason) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('reports').insert({
        'user_id': _currentUid,
        'thread_id': threadId,
        'reason': reason,
      });
      return true;
    } catch (e) {
      debugPrint("Report post error: $e");
      return false;
    }
  }

  Future<bool> reportComment(String replyId, String reason) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('reports').insert({
        'user_id': _currentUid,
        'reply_id': replyId,
        'reason': reason,
      });
      return true;
    } catch (e) {
      debugPrint("Report comment error (reply_id): $e");
      try {
        await _supabase.from('reports').insert({
          'user_id': _currentUid,
          'comment_id': replyId,
          'reason': reason,
        });
        return true;
      } catch (inner) {
        debugPrint("Report comment error (comment_id): $inner");
        return false;
      }
    }
  }


  @override
  void dispose() {
    _supabaseAuthSub?.cancel();
    unsubscribeRealtime();
    super.dispose();
  }
}

extension IterableExtension<E> on Iterable<E> {
  List<T> mapIndexed<T>(T Function(int index, E element) f) {
    var index = 0;
    return map((e) => f(index++, e)).toList();
  }
}
