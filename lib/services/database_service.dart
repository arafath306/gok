import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/thread_post.dart';
import '../models/notification.dart';

class DatabaseService with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  // Cache variables
  Profile? _myProfile;
  Profile? get myProfile => _myProfile;

  List<ThreadPost> _feed = [];
  List<ThreadPost> get feed => _feed;

  List<ThreadPost> _myThreads = [];
  List<ThreadPost> get myThreads => _myThreads;

  List<ThreadPost> _myReplies = [];
  List<ThreadPost> get myReplies => _myReplies;

  final Map<String, ThreadPost> _postsCache = {};
  final Set<String> _deletedPostIds = {};

  bool isPostDeleted(String id) => _deletedPostIds.contains(id);

  void _updateCache(List<ThreadPost> posts) {
    for (final post in posts) {
      _postsCache[post.id] = post;
    }
  }

  ThreadPost getLatestPost(ThreadPost fallbackPost) {
    final cached = _postsCache[fallbackPost.id];
    if (cached == null) {
      _postsCache[fallbackPost.id] = fallbackPost;
      return fallbackPost;
    }
    return cached;
  }

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  Set<String> _followingIds = {};
  Set<String> get followingIds => _followingIds;

  Set<String> _blockedUserIds = {};
  Set<String> get blockedUserIds => _blockedUserIds;

  Set<String> _mutedUserIds = {};
  Set<String> get mutedUserIds => _mutedUserIds;

  Set<String> _savedThreadIds = {};
  Set<String> get savedThreadIds => _savedThreadIds;

  List<ThreadPost> _savedPosts = [];
  List<ThreadPost> get savedPosts => _savedPosts;

  bool isBlocked(String targetUserId) => _blockedUserIds.contains(targetUserId);
  bool isMuted(String targetUserId) => _mutedUserIds.contains(targetUserId);
  bool isSaved(String threadId) => _savedThreadIds.contains(threadId);

  Future<void> toggleSaveThread(String threadId) async {
    final wasAlreadySaved = _savedThreadIds.contains(threadId);
    // Optimistic update
    if (wasAlreadySaved) {
      _savedThreadIds.remove(threadId);
      _savedPosts.removeWhere((p) => p.id == threadId);
    } else {
      _savedThreadIds.add(threadId);
    }
    notifyListeners();

    if (_currentUid.isEmpty) return;
    try {
      if (wasAlreadySaved) {
        await _supabase
            .from('saved_posts')
            .delete()
            .eq('user_id', _currentUid)
            .eq('thread_id', threadId);
      } else {
        await _supabase.from('saved_posts').upsert({
          'user_id': _currentUid,
          'thread_id': threadId,
        });
        // Fetch that post and add to savedPosts
        await fetchSavedPosts();
      }
    } catch (e) {
      debugPrint('Toggle save thread error: $e');
      // Rollback optimistic update
      if (wasAlreadySaved) {
        _savedThreadIds.add(threadId);
      } else {
        _savedThreadIds.remove(threadId);
      }
      notifyListeners();
    }
  }

  Future<void> fetchSavedThreadIds() async {
    if (_currentUid.isEmpty) return;
    try {
      final response = await _supabase
          .from('saved_posts')
          .select('thread_id')
          .eq('user_id', _currentUid);
      final List<dynamic> data = response as List<dynamic>;
      _savedThreadIds = data.map((json) => json['thread_id'] as String).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch saved thread ids error: $e');
    }
  }

  Future<void> fetchSavedPosts() async {
    if (_currentUid.isEmpty) return;
    try {
      final response = await _supabase
          .from('saved_posts')
          .select('thread_id, threads(*, profiles(*), likes(user_id), thread_hides(user_id))')
          .eq('user_id', _currentUid)
          .order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      final List<ThreadPost> posts = [];
      for (final row in data) {
        final threadMap = row['threads'] as Map<String, dynamic>?;
        if (threadMap != null) {
          try {
            posts.add(ThreadPost.fromJson(threadMap, currentUid: _currentUid));
          } catch (e) {
            debugPrint('Error parsing saved post: $e');
          }
        }
      }
      _updateCache(posts);
      _savedPosts = posts;
      _savedThreadIds = posts.map((p) => p.id).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch saved posts error: $e');
      // Fallback: filter from feed
      _savedPosts = _feed.where((p) => _savedThreadIds.contains(p.id)).toList();
      notifyListeners();
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Supabase session UID — used for all database operations (UUID format)
  String get _supabaseSessionUid => _supabase.auth.currentUser?.id ?? '';

  // Effective UID: ONLY use Supabase session UID (UUID format).
  // Firebase UID is NOT a valid UUID and CANNOT be used for Supabase queries.
  String get _currentUid => _supabaseSessionUid;

  String get currentUid => _currentUid;

  int _unreadMessagesCount = 0;
  int get unreadMessagesCount => _unreadMessagesCount;

  int _unreadNotificationsCount = 0;
  int get unreadNotificationsCount => _unreadNotificationsCount;

  final StreamController<Map<String, dynamic>> _incomingNotificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get incomingNotificationStream =>
      _incomingNotificationStreamController.stream;

  RealtimeChannel? _threadsChannel;
  RealtimeChannel? _likesChannel;
  RealtimeChannel? _repliesChannel;
  RealtimeChannel? _followsChannel;
  RealtimeChannel? _notificationsChannel;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _blocksChannel;
  RealtimeChannel? _mutesChannel;
  StreamSubscription<AuthState>? _supabaseAuthSub;

  DatabaseService() {
    // Listen to Supabase auth state — auto-reload when session established
    _supabaseAuthSub = _supabase.auth.onAuthStateChange.listen((data) {
      debugPrint('[DB] Supabase auth event: ${data.event}');
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed ||
          data.event == AuthChangeEvent.initialSession) {
        // Only load data if we have a valid Supabase session with UUID
        if (_supabaseSessionUid.isNotEmpty) {
          debugPrint('[DB] Supabase UID available: $_supabaseSessionUid');
          _onUserReady();
        }
      } else if (data.event == AuthChangeEvent.signedOut) {
        _clearAllData();
      }
    });

    subscribeToRealtime();
    if (_currentUid.isNotEmpty) {
      _onUserReady();
    }
  }

  /// Called on full logout
  void clearUser() {
    _clearAllData();
  }

  void _onUserReady() async {
    _isLoading = true;
    notifyListeners();
    await fetchBlockedMutedLists();
    fetchMyProfile();
    fetchFollowingList();
    fetchFeed(silent: true);
    fetchNotifications();
    fetchUnreadCounts();
    fetchSavedThreadIds();
    fetchSavedPosts();
    subscribeToRealtime();
  }

  void _clearAllData() {
    _myProfile = null;
    _feed = [];
    _myThreads = [];
    _notifications = [];
    _followingIds = {};
    _blockedUserIds = {};
    _mutedUserIds = {};
    _savedThreadIds = {};
    _savedPosts = [];
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
              fetchFeed(silent: true);
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
              fetchFeed(silent: true);
              if (_currentUid.isNotEmpty) {
                fetchMyThreads();
              }
            })
        .subscribe();

    _repliesChannel = _supabase
        .channel('public:comments')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'comments',
            callback: (payload) {
              fetchFeed(silent: true);
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
              fetchUnreadCounts();
              
              if (payload.eventType == PostgresChangeEvent.insert) {
                final newNotif = payload.newRecord;
                if (newNotif['user_id'] == _currentUid && newNotif['actor_id'] != _currentUid) {
                  _handleIncomingNotification(newNotif);
                }
              }
            })
        .subscribe();

    _messagesChannel = _supabase
        .channel('public:messages')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'messages',
            callback: (payload) {
              fetchUnreadCounts();
              
              if (payload.eventType == PostgresChangeEvent.insert) {
                final newMsg = payload.newRecord;
                if (newMsg['receiver_id'] == _currentUid && newMsg['sender_id'] != _currentUid) {
                  _handleIncomingMessage(newMsg);
                }
              }
            })
        .subscribe();

    _blocksChannel = _supabase
        .channel('public:blocks')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'blocks',
            callback: (payload) {
              fetchBlockedMutedLists();
              fetchFeed(silent: true);
            })
        .subscribe();

    _mutesChannel = _supabase
        .channel('public:mutes')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'mutes',
            callback: (payload) {
              fetchBlockedMutedLists();
              fetchFeed(silent: true);
            })
        .subscribe();
  }

  void unsubscribeRealtime() {
    if (_threadsChannel != null) _supabase.removeChannel(_threadsChannel!);
    if (_likesChannel != null) _supabase.removeChannel(_likesChannel!);
    if (_repliesChannel != null) _supabase.removeChannel(_repliesChannel!);
    if (_followsChannel != null) _supabase.removeChannel(_followsChannel!);
    if (_notificationsChannel != null) _supabase.removeChannel(_notificationsChannel!);
    if (_messagesChannel != null) _supabase.removeChannel(_messagesChannel!);
    if (_blocksChannel != null) {
      _supabase.removeChannel(_blocksChannel!);
      _blocksChannel = null;
    }
    if (_mutesChannel != null) {
      _supabase.removeChannel(_mutesChannel!);
      _mutesChannel = null;
    }
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

  Future<bool> doesUserFollowMe(String otherUserId) async {
    if (_currentUid.isEmpty) return false;
    try {
      final response = await _supabase
          .from('follows')
          .select('id')
          .eq('follower_id', otherUserId)
          .eq('following_id', _currentUid)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint("Check doesUserFollowMe error: $e");
      return false;
    }
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

  Future<void> fetchBlockedMutedLists() async {
    if (_currentUid.isEmpty) return;
    try {
      final blockedRes = await _supabase
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', _currentUid);

      final blockedMeRes = await _supabase
          .from('blocks')
          .select('blocker_id')
          .eq('blocked_id', _currentUid);

      final mutedRes = await _supabase
          .from('mutes')
          .select('muted_id')
          .eq('muter_id', _currentUid);

      _blockedUserIds = {};
      for (var row in blockedRes) {
        _blockedUserIds.add(row['blocked_id'] as String);
      }
      for (var row in blockedMeRes) {
        _blockedUserIds.add(row['blocker_id'] as String);
      }

      _mutedUserIds = {};
      for (var row in mutedRes) {
        _mutedUserIds.add(row['muted_id'] as String);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Fetch blocked/muted lists error: $e");
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
      
      // Filter out blocked profiles
      results.removeWhere((profile) => _blockedUserIds.contains(profile.id));
      
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
      final List<Profile> results = data.map((json) => Profile.fromJson(json)).toList();
      
      // Filter out blocked profiles
      results.removeWhere((profile) => _blockedUserIds.contains(profile.id));
      return results;
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
      // Both avatar and cover use the same 'avatars' bucket but with path prefixes
      // to avoid needing a separate 'covers' bucket in Supabase storage.
      final subFolder = isAvatar ? 'avatars' : 'covers';
      final path = '$subFolder/$_currentUid/img_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final publicUrl = await _uploadToStorage('avatars', path, bytes);
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

  /// Uploads a photo for a thread post. Uses the 'avatars' bucket with a
  /// 'posts/' subfolder prefix to avoid needing a separate storage bucket.
  Future<String?> uploadPostImage(Uint8List bytes) async {
    if (_currentUid.isEmpty) return null;
    try {
      final path = 'posts/$_currentUid/thread_${DateTime.now().millisecondsSinceEpoch}.jpg';
      return await _uploadToStorage('avatars', path, bytes);
    } catch (e) {
      debugPrint("Upload post image error: $e");
      return null;
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

  Future<void> fetchFeed({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // 1. Fetch normal threads
      final response = await _supabase
          .from('threads')
          .select('*, profiles(*), likes(user_id), thread_hides(user_id)')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      // 2. Fetch reposts/quotes
      final repostsRes = await _supabase
          .from('reposts')
          .select('*, profiles(*), threads(*, profiles(*), likes(user_id), thread_hides(user_id))')
          .order('created_at', ascending: false);

      final List<dynamic> repostsData = repostsRes as List<dynamic>;

      // Merge raw items
      final List<Map<String, dynamic>> combinedRaw = [];
      for (final thread in data) {
        combinedRaw.add({
          'type': 'thread',
          'created_at': thread['created_at'] as String,
          'data': thread,
        });
      }
      for (final repost in repostsData) {
        if (repost['threads'] != null) {
          combinedRaw.add({
            'type': 'repost',
            'created_at': repost['created_at'] as String,
            'data': repost,
          });
        }
      }

      // Sort combined raw by created_at descending
      combinedRaw.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));

      // Map to ThreadPost
      final List<ThreadPost> posts = [];
      for (final item in combinedRaw) {
        final type = item['type'] as String;
        final map = item['data'] as Map<String, dynamic>;
        if (type == 'thread') {
          posts.add(ThreadPost.fromJson(map, currentUid: _currentUid));
        } else {
          final threadMap = map['threads'] as Map<String, dynamic>;
          final reposterProfileMap = map['profiles'] as Map<String, dynamic>?;
          final reposterProfile = reposterProfileMap != null
              ? Profile.fromJson(reposterProfileMap)
              : Profile(id: map['user_id'] ?? '', username: 'unknown', fullName: 'Unknown User');

          final originalPost = ThreadPost.fromJson(threadMap, currentUid: _currentUid);

          posts.add(ThreadPost(
            id: map['id'] as String,
            userId: map['user_id'] as String,
            author: reposterProfile,
            content: map['quote_text'] as String? ?? '',
            createdAt: ThreadPost.formatRelativeTime(map['created_at'] as String?),
            isRepost: true,
            repostedPost: originalPost,
            quoteText: map['quote_text'] as String?,
            likesCount: 0,
            repliesCount: 0,
            repostsCount: 0,
            viewsCount: 0,
          ));
        }
      }

      _updateCache(posts);
      
      // Apply block, mute, custom hidden, and private account privacy filters
      posts.removeWhere((post) {
        // Block/Mute filter
        if (_blockedUserIds.contains(post.userId) || _mutedUserIds.contains(post.userId)) {
          return true;
        }
        // Custom friend hide filter
        if (post.isHiddenFromMe) {
          return true;
        }
        // Private account filter (only show if following or is self)
        if (post.userId != _currentUid && post.author.isPrivate) {
          return !isFollowingUser(post.userId);
        }
        return false;
      });

      _feed = posts;
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
          .select('*, profiles(*), likes(user_id), thread_hides(user_id)')
          .eq('user_id', _currentUid)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final posts = data.map((json) => ThreadPost.fromJson(json, currentUid: _currentUid)).toList();
      _updateCache(posts);
      
      // Sort pinned threads to the top
      posts.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return 0;
      });
      
      _myThreads = posts;
      notifyListeners();
    } catch (e) {
      debugPrint("Fetch my threads error: $e");
    }
  }

  Future<bool> createThread(String content, {List<String>? imageUrls, String? videoUrl, String? audience}) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('threads').insert({
        'user_id': _currentUid,
        'content': content,
        'image_urls': imageUrls,
        'video_url': videoUrl,
        if (audience != null) 'audience': audience,
      });
      await fetchFeed(silent: true);
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

    // Optimistic update cache
    final cached = _postsCache[threadId];
    if (cached != null) {
      final int countDelta = shouldLike 
          ? (cached.isLikedByMe ? 0 : 1) 
          : -1;
      _postsCache[threadId] = cached.copyWith(
        likesCount: cached.likesCount + countDelta,
        isLikedByMe: shouldLike,
        reactionType: shouldLike ? (reactionType ?? '❤️') : null,
      );
    }

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

      final response = await _supabase
          .from('threads')
          .select('*, profiles(*), likes(user_id), thread_hides(user_id)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final posts = data.map((json) => ThreadPost.fromJson(json, currentUid: _currentUid)).toList();
      
      // Filter out posts hidden from profile or hidden from me
      posts.removeWhere((post) {
        if (post.hideFromProfile && post.userId != _currentUid) {
          return true;
        }
        if (_blockedUserIds.contains(post.userId) || _mutedUserIds.contains(post.userId)) {
          return true;
        }
        if (post.isHiddenFromMe) {
          return true;
        }
        return false;
      });

      // Sort pinned threads to the top
      posts.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return 0;
      });

      _updateCache(posts);
      return posts;
    } catch (e) {
      debugPrint("Fetch user threads error: $e");
      return [];
    }
  }

  Future<List<ThreadPost>> fetchUserRepliedThreads(String userId) async {
    try {
      if (userId.startsWith('mock-')) {
        return [];
      }

      // Fetch distinct thread_ids from comments table where user_id = userId
      final commentsRes = await _supabase
          .from('comments')
          .select('thread_id')
          .eq('user_id', userId);
      
      final List<dynamic> commentsData = commentsRes as List<dynamic>;
      final threadIds = commentsData.map((c) => c['thread_id'] as String).toSet().toList();
      
      if (threadIds.isEmpty) return [];

      // Fetch those threads
      final response = await _supabase
          .from('threads')
          .select('*, profiles(*), likes(user_id), thread_hides(user_id)')
          .inFilter('id', threadIds)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final posts = data.map((json) => ThreadPost.fromJson(json, currentUid: _currentUid)).toList();
      
      // Filter out hidden posts
      posts.removeWhere((post) {
        if (post.hideFromProfile && post.userId != _currentUid) {
          return true;
        }
        if (_blockedUserIds.contains(post.userId) || _mutedUserIds.contains(post.userId)) {
          return true;
        }
        if (post.isHiddenFromMe) {
          return true;
        }
        return false;
      });

      _updateCache(posts);
      return posts;
    } catch (e) {
      debugPrint("Fetch user replied threads error: $e");
      return [];
    }
  }

  // --- Author Post Operations ---

  Future<bool> togglePinPost(String threadId, bool isPinned) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('threads').update({'is_pinned': isPinned}).eq('id', threadId);
      
      // Update cache
      final cached = _postsCache[threadId];
      if (cached != null) {
        _postsCache[threadId] = cached.copyWith(isPinned: isPinned);
      }

      // Update local feed
      final feedIdx = _feed.indexWhere((p) => p.id == threadId);
      if (feedIdx != -1) {
        _feed[feedIdx] = _feed[feedIdx].copyWith(isPinned: isPinned);
      }
      // Update local myThreads
      final myIdx = _myThreads.indexWhere((p) => p.id == threadId);
      if (myIdx != -1) {
        _myThreads[myIdx] = _myThreads[myIdx].copyWith(isPinned: isPinned);
        _myThreads.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return 0;
        });
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Toggle pin post error: $e");
      return false;
    }
  }

  Future<bool> toggleMutePostNotifications(String threadId, bool mute) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('threads').update({'mute_notifications': mute}).eq('id', threadId);
      
      // Update cache
      final cached = _postsCache[threadId];
      if (cached != null) {
        _postsCache[threadId] = cached.copyWith(muteNotifications: mute);
      }

      final feedIdx = _feed.indexWhere((p) => p.id == threadId);
      if (feedIdx != -1) {
        _feed[feedIdx] = _feed[feedIdx].copyWith(muteNotifications: mute);
      }
      final myIdx = _myThreads.indexWhere((p) => p.id == threadId);
      if (myIdx != -1) {
        _myThreads[myIdx] = _myThreads[myIdx].copyWith(muteNotifications: mute);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Toggle mute notifications error: $e");
      return false;
    }
  }

  Future<bool> toggleHidePostFromProfile(String threadId, bool hide) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('threads').update({'hide_from_profile': hide}).eq('id', threadId);
      
      // Update cache
      final cached = _postsCache[threadId];
      if (cached != null) {
        _postsCache[threadId] = cached.copyWith(hideFromProfile: hide);
      }

      final feedIdx = _feed.indexWhere((p) => p.id == threadId);
      if (feedIdx != -1) {
        _feed[feedIdx] = _feed[feedIdx].copyWith(hideFromProfile: hide);
      }
      final myIdx = _myThreads.indexWhere((p) => p.id == threadId);
      if (myIdx != -1) {
        _myThreads[myIdx] = _myThreads[myIdx].copyWith(hideFromProfile: hide);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Toggle hide from profile error: $e");
      return false;
    }
  }

  Future<bool> editPostContent(String threadId, String content) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('threads').update({'content': content}).eq('id', threadId);
      
      // Update cache
      final cached = _postsCache[threadId];
      if (cached != null) {
        _postsCache[threadId] = cached.copyWith(content: content);
      }

      final feedIdx = _feed.indexWhere((p) => p.id == threadId);
      if (feedIdx != -1) {
        _feed[feedIdx] = _feed[feedIdx].copyWith(content: content);
      }
      final myIdx = _myThreads.indexWhere((p) => p.id == threadId);
      if (myIdx != -1) {
        _myThreads[myIdx] = _myThreads[myIdx].copyWith(content: content);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Edit post content error: $e");
      return false;
    }
  }

  Future<bool> deletePost(String threadId) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('threads').delete().eq('id', threadId);
      
      _feed.removeWhere((p) => p.id == threadId);
      _myThreads.removeWhere((p) => p.id == threadId);
      _deletedPostIds.add(threadId);
      _postsCache.remove(threadId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Delete post error: $e");
      return false;
    }
  }

  Future<List<String>> fetchThreadHides(String threadId) async {
    try {
      final response = await _supabase
          .from('thread_hides')
          .select('user_id')
          .eq('thread_id', threadId);
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => json['user_id'] as String).toList();
    } catch (e) {
      debugPrint("Fetch thread hides error: $e");
      return [];
    }
  }

  Future<bool> updateThreadHides(String threadId, List<String> targetUserIds) async {
    if (_currentUid.isEmpty) return false;
    try {
      // Delete existing hides
      await _supabase.from('thread_hides').delete().eq('thread_id', threadId);
      
      // Insert new ones
      if (targetUserIds.isNotEmpty) {
        final inserts = targetUserIds.map((uid) => {
          'thread_id': threadId,
          'user_id': uid,
        }).toList();
        await _supabase.from('thread_hides').insert(inserts);
      }
      
      // Refresh feed so visibility filters take effect
      fetchFeed(silent: true);
      return true;
    } catch (e) {
      debugPrint("Update thread hides error: $e");
      return false;
    }
  }

  Future<List<Profile>> fetchFollowingProfiles() async {
    if (_currentUid.isEmpty || _followingIds.isEmpty) return [];
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', _followingIds.toList());
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Profile.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Fetch following profiles error: $e");
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
          createdAtDateTime: createdAtTime,
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

  // --- Unread Count Handlers ---

  Future<void> fetchUnreadCounts() async {
    if (_currentUid.isEmpty) return;
    try {
      final msgResponse = await _supabase
          .from('messages')
          .select('id')
          .eq('receiver_id', _currentUid)
          .eq('is_read', false);
      _unreadMessagesCount = (msgResponse as List<dynamic>).length;

      final notifResponse = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', _currentUid)
          .eq('is_read', false);
      _unreadNotificationsCount = (notifResponse as List<dynamic>).length;

      notifyListeners();
    } catch (e) {
      debugPrint("Fetch unread counts error: $e");
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> msg) async {
    final senderProfile = await fetchProfile(msg['sender_id'] as String);
    final senderName = senderProfile?.fullName ?? "Someone";
    _incomingNotificationStreamController.add({
      'title': senderName,
      'body': msg['content'] as String,
      'type': 'message',
      'sender_id': msg['sender_id'],
    });
  }

  void _handleIncomingNotification(Map<String, dynamic> notif) async {
    final actorProfile = await fetchProfile(notif['actor_id'] as String);
    final actorName = actorProfile?.fullName ?? "Someone";
    _incomingNotificationStreamController.add({
      'title': 'New Activity',
      'body': '$actorName ${notif['content']}',
      'type': 'notification',
    });
  }

  // --- Real-time Private Messaging ---

  Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    if (_currentUid.isEmpty) return const Stream.empty();
    
    // Set up a broadcast stream combining the messages table query and database change triggers
    final controller = StreamController<List<Map<String, dynamic>>>();
    
    Future<void> loadAndPush() async {
      try {
        final response = await _supabase
            .from('messages')
            .select()
            .or('and(sender_id.eq.$_currentUid,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$_currentUid)')
            .order('created_at', ascending: true);
        
        final List<dynamic> data = response as List<dynamic>;
        final messages = data.map((json) => {
          'id': json['id'] as String,
          'text': json['content'] as String,
          'isMe': json['sender_id'] == _currentUid,
          'time': _getRelativeTime(DateTime.parse(json['created_at'] as String)),
          'created_at': json['created_at'],
        }).toList();
        
        if (!controller.isClosed) {
          controller.add(messages);
        }
      } catch (e) {
        debugPrint("Error loading messages stream: $e");
        if (!controller.isClosed) {
          controller.add([]);
        }
      }
    }

    // Load initial values
    loadAndPush();

    // Listen to realtime messages table updates
    final subscription = _supabase
        .channel('messages:$otherUserId')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'messages',
            callback: (payload) {
              loadAndPush();
            })
        .subscribe();

    controller.onCancel = () {
      _supabase.removeChannel(subscription);
      controller.close();
    };

    return controller.stream;
  }

  Future<void> sendMessage(String receiverId, String content) async {
    if (_currentUid.isEmpty) return;
    try {
      await _supabase.from('messages').insert({
        'sender_id': _currentUid,
        'receiver_id': receiverId,
        'content': content,
        'is_read': false,
      });
      
      // Notify database and trigger unread counts updating
      fetchUnreadCounts();
    } catch (e) {
      debugPrint("Send message error: $e");
    }
  }

  Future<void> markMessagesAsRead(String otherUserId) async {
    if (_currentUid.isEmpty) return;
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', otherUserId)
          .eq('receiver_id', _currentUid)
          .eq('is_read', false);
      fetchUnreadCounts();
    } catch (e) {
      debugPrint("Mark messages as read error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchActiveChats() async {
    if (_currentUid.isEmpty) return [];
    try {
      final response = await _supabase
          .from('messages')
          .select('*, sender:profiles!sender_id(*), receiver:profiles!receiver_id(*)')
          .or('sender_id.eq.$_currentUid,receiver_id.eq.$_currentUid')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      final Map<String, Map<String, dynamic>> conversations = {};

      for (final json in data) {
        final senderId = json['sender_id'] as String;
        final isMeSender = senderId == _currentUid;
        final otherUserMap = isMeSender ? json['receiver'] : json['sender'];
        
        if (otherUserMap == null) continue;
        final otherProfile = Profile.fromJson(otherUserMap as Map<String, dynamic>);
        final otherId = otherProfile.id;

        if (!conversations.containsKey(otherId)) {
          conversations[otherId] = {
            'profile': otherProfile,
            'last_message': json['content'] as String,
            'last_message_time': _getRelativeTime(DateTime.parse(json['created_at'] as String)),
            'unread_count': 0,
            'timestamp': DateTime.parse(json['created_at'] as String),
          };
        }
        
        if (!isMeSender && !(json['is_read'] as bool)) {
          conversations[otherId]!['unread_count'] = (conversations[otherId]!['unread_count'] as int) + 1;
        }
      }

      final list = conversations.values.toList();
      list.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
      return list;
    } catch (e) {
      debugPrint("Fetch active chats error: $e");
      return [];
    }
  }

  // --- Comment and Nested Replies Database CRUD ---

  Future<List<Map<String, dynamic>>> fetchComments(String threadId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('*, profiles(*)')
          .eq('thread_id', threadId)
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      
      // Fetch user's comment likes for is_liked_by_me tracking
      Set<String> likedCommentIds = {};
      if (_currentUid.isNotEmpty) {
        final likesRes = await _supabase
            .from('comment_likes')
            .select('comment_id')
            .eq('user_id', _currentUid);
        final List<dynamic> likesData = likesRes as List<dynamic>;
        likedCommentIds = likesData.map((l) => l['comment_id'] as String).toSet();
      }

      return data.map((json) {
        final authorMap = json['profiles'] as Map<String, dynamic>?;
        final author = authorMap != null 
            ? Profile.fromJson(authorMap) 
            : Profile(id: json['user_id'] ?? '', username: 'unknown', fullName: 'Unknown User');
        
        return {
          'id': json['id'] as String,
          'author': author,
          'content': json['content'] as String,
          'created_at': _getRelativeTime(DateTime.parse(json['created_at'] as String)),
          'created_at_raw': json['created_at'] as String,
          'likes_count': (json['likes_count'] as int?) ?? 0,
          'parent_id': json['parent_id'] as String?,
          'is_liked_by_me': likedCommentIds.contains(json['id'] as String),
        };
      }).toList();
    } catch (e) {
      debugPrint("Fetch comments error: $e");
      return [];
    }
  }

  Future<bool> addComment(String threadId, String content, {String? parentId}) async {
    if (_currentUid.isEmpty) {
      throw Exception("User is not authenticated");
    }
    try {
      await _supabase.from('comments').insert({
        'thread_id': threadId,
        'user_id': _currentUid,
        'content': content,
        'parent_id': parentId,
      });

      // Optimistic update cache for comments count
      final cached = _postsCache[threadId];
      if (cached != null) {
        _postsCache[threadId] = cached.copyWith(
          repliesCount: cached.repliesCount + 1,
        );
      }

      fetchFeed(silent: true);
      return true;
    } catch (e) {
      debugPrint("Add comment error: $e");
      rethrow;
    }
  }

  Future<void> toggleCommentLike(String commentId, bool shouldLike) async {
    if (_currentUid.isEmpty) return;
    try {
      if (shouldLike) {
        await _supabase.from('comment_likes').insert({
          'user_id': _currentUid,
          'comment_id': commentId,
        });
        await _supabase.rpc('increment_comment_likes', params: {'comment_id': commentId});
      } else {
        await _supabase
            .from('comment_likes')
            .delete()
            .eq('user_id', _currentUid)
            .eq('comment_id', commentId);
        await _supabase.rpc('decrement_comment_likes', params: {'comment_id': commentId});
      }
    } catch (e) {
      // Fallback if RPC functions do not exist, directly update via update query
      try {
        final getComment = await _supabase.from('comments').select('likes_count').eq('id', commentId).single();
        final currentLikes = (getComment['likes_count'] as int?) ?? 0;
        final newLikes = shouldLike ? currentLikes + 1 : GREATEST(0, currentLikes - 1);
        
        await _supabase.from('comments').update({'likes_count': newLikes}).eq('id', commentId);
      } catch (inner) {
        debugPrint("Toggle comment like error: $inner");
      }
    }
  }

  Future<bool> deleteComment(String commentId, String threadId) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('comments').delete().eq('id', commentId).eq('user_id', _currentUid);
      
      final cached = _postsCache[threadId];
      if (cached != null) {
        _postsCache[threadId] = cached.copyWith(
          repliesCount: cached.repliesCount - 1 < 0 ? 0 : cached.repliesCount - 1,
        );
      }
      fetchFeed(silent: true);
      return true;
    } catch (e) {
      debugPrint("Delete comment error: $e");
      return false;
    }
  }

  Future<bool> editComment(String commentId, String content) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('comments').update({'content': content}).eq('id', commentId).eq('user_id', _currentUid);
      return true;
    } catch (e) {
      debugPrint("Edit comment error: $e");
      return false;
    }
  }

  int GREATEST(int a, int b) => a > b ? a : b;

  // --- Reposts Operation ---

  Future<bool> repostThread(String threadId, {String? quoteText}) async {
    if (_currentUid.isEmpty) return false;
    try {
      // Check if already reposted
      final existing = await _supabase
          .from('reposts')
          .select('id, quote_text')
          .eq('user_id', _currentUid)
          .eq('thread_id', threadId)
          .maybeSingle();

      if (existing != null && quoteText == null) {
        // Remove repost
        await _supabase
            .from('reposts')
            .delete()
            .eq('user_id', _currentUid)
            .eq('thread_id', threadId);
      } else if (existing != null && quoteText != null) {
        // Update quote repost
        await _supabase
            .from('reposts')
            .update({'quote_text': quoteText})
            .eq('user_id', _currentUid)
            .eq('thread_id', threadId);
      } else {
        // Create repost
        await _supabase.from('reposts').insert({
          'user_id': _currentUid,
          'thread_id': threadId,
          'quote_text': quoteText,
        });
      }
      fetchFeed(silent: true);
      return true;
    } catch (e) {
      debugPrint("Repost thread error: $e");
      return false;
    }
  }

  Future<bool> editRepost(String repostId, String newQuoteText) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase
          .from('reposts')
          .update({'quote_text': newQuoteText})
          .eq('id', repostId)
          .eq('user_id', _currentUid);
      fetchFeed(silent: true);
      return true;
    } catch (e) {
      debugPrint("Edit repost error: $e");
      return false;
    }
  }

  Future<bool> deleteRepost(String repostId, String threadId) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase
          .from('reposts')
          .delete()
          .eq('id', repostId)
          .eq('user_id', _currentUid);
      fetchFeed(silent: true);
      return true;
    } catch (e) {
      debugPrint("Delete repost error: $e");
      return false;
    }
  }

  Future<List<ThreadPost>> fetchUserReposts(String userId) async {
    try {
      final response = await _supabase
          .from('reposts')
          .select('*, profiles(*), threads(*, profiles(*), likes(user_id), thread_hides(user_id))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<dynamic> repostsData = response as List<dynamic>;
      final List<ThreadPost> repostPosts = [];
      for (final row in repostsData) {
        final threadMap = row['threads'] as Map<String, dynamic>?;
        if (threadMap != null) {
          final reposterProfileMap = row['profiles'] as Map<String, dynamic>?;
          final reposterProfile = reposterProfileMap != null
              ? Profile.fromJson(reposterProfileMap)
              : Profile(id: row['user_id'] ?? '', username: 'unknown', fullName: 'Unknown User');

          final originalPost = ThreadPost.fromJson(threadMap, currentUid: _currentUid);

          repostPosts.add(ThreadPost(
            id: row['id'] as String,
            userId: row['user_id'] as String,
            author: reposterProfile,
            content: row['quote_text'] as String? ?? '',
            createdAt: ThreadPost.formatRelativeTime(row['created_at'] as String?),
            isRepost: true,
            repostedPost: originalPost,
            quoteText: row['quote_text'] as String?,
            likesCount: 0,
            repliesCount: 0,
            repostsCount: 0,
            viewsCount: 0,
          ));
        }
      }
      return repostPosts;
    } catch (e) {
      debugPrint("Fetch user reposts error: $e");
      return [];
    }
  }

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

  Future<bool> reportProfile(String targetProfileId, String reason) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('reports').insert({
        'user_id': _currentUid,
        'reason': 'Profile Report (@$targetProfileId): $reason',
      });
      return true;
    } catch (e) {
      debugPrint("Report profile error: $e");
      return false;
    }
  }

  Future<bool> hideThreadForCurrentUser(String threadId) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('thread_hides').upsert({
        'thread_id': threadId,
        'user_id': _currentUid,
      });
      fetchFeed(silent: true);
      return true;
    } catch (e) {
      debugPrint("Hide thread for current user error: $e");
      return false;
    }
  }

  Future<bool> unhideThreadForCurrentUser(String threadId) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase
          .from('thread_hides')
          .delete()
          .eq('thread_id', threadId)
          .eq('user_id', _currentUid);
      fetchFeed(silent: true);
      return true;
    } catch (e) {
      debugPrint("Unhide thread for current user error: $e");
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


  Future<void> incrementThreadViews(String threadId) async {
    try {
      await _supabase.rpc('increment_thread_views', params: {'thread_id': threadId});
      
      // Update local cache views count optimistically
      final cached = _postsCache[threadId];
      if (cached != null) {
        _postsCache[threadId] = cached.copyWith(
          viewsCount: cached.viewsCount + 1,
        );
      }
    } catch (rpcError) {
      debugPrint("RPC increment_thread_views failed: $rpcError");
      try {
        final response = await _supabase.from('threads').select('views_count').eq('id', threadId).maybeSingle();
        if (response != null) {
          final int currentViews = response['views_count'] as int? ?? 0;
          await _supabase.from('threads').update({'views_count': currentViews + 1}).eq('id', threadId);
          
          final cached = _postsCache[threadId];
          if (cached != null) {
            _postsCache[threadId] = cached.copyWith(
              viewsCount: currentViews + 1,
            );
          }
        }
      } catch (e) {
        debugPrint("Direct update views count failed: $e");
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
