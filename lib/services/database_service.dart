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
    if (query.isEmpty) return [];
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .or('full_name.ilike.%$query%,username.ilike.%$query%')
          .limit(20);
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Profile.fromJson(json)).toList();
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

  Future<void> toggleLike(String threadId, bool shouldLike) async {
    if (_currentUid.isEmpty) return;

    // Local state optimistic update for instant UX feedback
    final feedIndex = _feed.indexWhere((p) => p.id == threadId);
    if (feedIndex != -1) {
      final post = _feed[feedIndex];
      _feed[feedIndex] = ThreadPost(
        id: post.id,
        userId: post.userId,
        author: post.author,
        content: post.content,
        imageUrls: post.imageUrls,
        videoUrl: post.videoUrl,
        likesCount: post.likesCount + (shouldLike ? 1 : -1),
        repliesCount: post.repliesCount,
        repostsCount: post.repostsCount,
        createdAt: post.createdAt,
        isLikedByMe: shouldLike,
      );
      notifyListeners();
    }

    final myThreadsIndex = _myThreads.indexWhere((p) => p.id == threadId);
    if (myThreadsIndex != -1) {
      final post = _myThreads[myThreadsIndex];
      _myThreads[myThreadsIndex] = ThreadPost(
        id: post.id,
        userId: post.userId,
        author: post.author,
        content: post.content,
        imageUrls: post.imageUrls,
        videoUrl: post.videoUrl,
        likesCount: post.likesCount + (shouldLike ? 1 : -1),
        repliesCount: post.repliesCount,
        repostsCount: post.repostsCount,
        createdAt: post.createdAt,
        isLikedByMe: shouldLike,
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

  String _getRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'এখনই';
    if (diff.inMinutes < 60) return '${diff.inMinutes} মিনিট আগে';
    if (diff.inHours < 24) return '${diff.inHours} ঘণ্টা আগে';
    return '${diff.inDays} দিন আগে';
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
