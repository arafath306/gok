import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/thread_post.dart';
import '../models/notification.dart';

import '../core/injection.dart';
import '../features/feed/domain/usecases/get_feed_use_case.dart';
import '../features/feed/domain/usecases/create_thread_use_case.dart';
import '../features/feed/domain/usecases/toggle_like_use_case.dart';
import '../features/feed/domain/usecases/toggle_save_thread_use_case.dart';
import '../features/feed/domain/usecases/fetch_comments_use_case.dart';
import '../features/feed/domain/usecases/add_comment_use_case.dart';
import '../features/feed/domain/entities/thread_post_entity.dart';
import '../features/feed/domain/repositories/feed_repository.dart';
import '../features/chat/domain/repositories/chat_repository.dart';
import '../features/chat/domain/usecases/get_active_chats_use_case.dart';
import '../features/chat/domain/usecases/get_messages_stream_use_case.dart';
import '../features/chat/domain/usecases/send_message_use_case.dart';
import '../features/chat/domain/usecases/mark_messages_as_read_use_case.dart';
import '../features/chat/domain/usecases/delete_conversation_use_case.dart';
import '../features/chat/domain/usecases/upload_chat_media_use_case.dart';
import '../features/profile/domain/usecases/submit_verification_use_case.dart';
import '../features/profile/domain/usecases/get_verification_status_use_case.dart';
import '../features/profile/domain/usecases/update_profile_use_case.dart';
import '../features/profile/domain/usecases/upload_verification_image_use_case.dart';
import '../features/profile/domain/usecases/update_profile_image_use_case.dart';
import '../features/profile/domain/usecases/fetch_verification_plans_use_case.dart';
import '../features/profile/domain/usecases/update_verification_plan_price_use_case.dart';
import '../features/profile/domain/usecases/fetch_admin_verification_requests_use_case.dart';
import '../features/profile/domain/usecases/update_verification_request_status_use_case.dart';
import '../features/notifications/domain/usecases/show_notification_use_case.dart';
import '../features/notifications/domain/usecases/play_sound_use_case.dart';

class DatabaseService with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  ThreadPost _entityToModel(ThreadPostEntity entity) {
    return ThreadPost(
      id: entity.id,
      userId: entity.userId,
      author: entity.author,
      content: entity.content,
      imageUrls: entity.imageUrls,
      videoUrl: entity.videoUrl,
      likesCount: entity.likesCount,
      repliesCount: entity.repliesCount,
      repostsCount: entity.repostsCount,
      savesCount: entity.savesCount,
      sharesCount: entity.sharesCount,
      viewsCount: entity.viewsCount,
      createdAt: entity.createdAt,
      isLikedByMe: entity.isLikedByMe,
      reactionType: entity.reactionType,
      isPinned: entity.isPinned,
      muteNotifications: entity.muteNotifications,
      hideFromProfile: entity.hideFromProfile,
      isHiddenFromMe: entity.isHiddenFromMe,
      isRepost: entity.isRepost,
      repostedPost: entity.repostedPost != null ? _entityToModel(entity.repostedPost!) : null,
      quoteText: entity.quoteText,
      pollOptions: entity.pollOptions,
      pollExpiresAt: entity.pollExpiresAt,
      hasVotedPoll: entity.hasVotedPoll,
      votedOptionId: entity.votedOptionId,
      musicTrack: entity.musicTrack,
    );
  }

  // Cache variables
  Profile? _myProfile;
  Profile? get myProfile => _myProfile;

  List<ThreadPost> _feed = [];
  List<ThreadPost> get feed => _feed;

  List<ThreadPost> _personalizedFeed = [];
  List<ThreadPost> get personalizedFeed => _personalizedFeed;

  int _aiFeedPage = 0;
  bool _aiFeedHasMore = true;
  bool get aiFeedHasMore => _aiFeedHasMore;

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

  void _updatePostInLists(String threadId, ThreadPost updatedPost) {
    _postsCache[threadId] = updatedPost;
    void updateInList(List<ThreadPost> list) {
      final idx = list.indexWhere((p) => p.id == threadId);
      if (idx != -1) {
        list[idx] = updatedPost;
      }
    }
    updateInList(_feed);
    updateInList(_myThreads);
    updateInList(_personalizedFeed);
    updateInList(_myReplies);
    updateInList(_savedPosts);
  }

  void _removePostFromLists(String threadId) {
    _postsCache.remove(threadId);
    _deletedPostIds.add(threadId);
    _feed.removeWhere((p) => p.id == threadId);
    _myThreads.removeWhere((p) => p.id == threadId);
    _personalizedFeed.removeWhere((p) => p.id == threadId);
    _myReplies.removeWhere((p) => p.id == threadId);
    _savedPosts.removeWhere((p) => p.id == threadId);
  }

  void _handleLikeRealtimeUpdate(String threadId, String userId, PostgresChangeEvent eventType) {
    final cached = _postsCache[threadId];
    if (cached == null) return;

    final isMe = userId == _currentUid;
    int likeDelta = 0;
    bool newIsLikedByMe = cached.isLikedByMe;

    if (eventType == PostgresChangeEvent.insert) {
      if (isMe) {
        if (!cached.isLikedByMe) {
          likeDelta = 1;
          newIsLikedByMe = true;
        }
      } else {
        likeDelta = 1;
      }
    } else if (eventType == PostgresChangeEvent.delete) {
      if (isMe) {
        if (cached.isLikedByMe) {
          likeDelta = -1;
          newIsLikedByMe = false;
        }
      } else {
        likeDelta = -1;
      }
    }

    if (likeDelta != 0 || newIsLikedByMe != cached.isLikedByMe) {
      final updatedPost = cached.copyWith(
        likesCount: (cached.likesCount + likeDelta).clamp(0, 999999),
        isLikedByMe: newIsLikedByMe,
        reactionType: newIsLikedByMe ? (cached.reactionType ?? '❤️') : null,
      );
      _updatePostInLists(threadId, updatedPost);
      notifyListeners();
    }
  }

  Future<void> _reloadThread(String threadId, {bool isNew = false}) async {
    try {
      final response = await _supabase
          .from('threads')
          .select('*, profiles!user_id(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*)')
          .eq('id', threadId)
          .maybeSingle();

      if (response != null) {
        final updatedPost = ThreadPost.fromJson(response, currentUid: _currentUid);
        
        if (isNew) {
          final alreadyInFeed = _feed.any((p) => p.id == threadId);
          if (!alreadyInFeed) {
            _feed.insert(0, updatedPost);
          }
          final isAuthorMe = updatedPost.userId == _currentUid;
          if (isAuthorMe) {
            final alreadyInMyThreads = _myThreads.any((p) => p.id == threadId);
            if (!alreadyInMyThreads) {
              _myThreads.insert(0, updatedPost);
            }
          }
          _postsCache[threadId] = updatedPost;
        } else {
          _updatePostInLists(threadId, updatedPost);
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error reloading/inserting thread: $e');
    }
  }

  void _updateReplyCountInCache(String threadId, PostgresChangeEvent eventType) {
    final cached = _postsCache[threadId];
    if (cached != null) {
      int change = 0;
      if (eventType == PostgresChangeEvent.insert) {
        change = 1;
      } else if (eventType == PostgresChangeEvent.delete) {
        change = -1;
      }
      if (change != 0) {
        final newRepliesCount = (cached.repliesCount + change).clamp(0, 999999);
        final updatedPost = cached.copyWith(repliesCount: newRepliesCount);
        _updatePostInLists(threadId, updatedPost);
        notifyListeners();
      }
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

  Set<String> _blockedByMeIds = {};
  Set<String> get blockedByMeIds => _blockedByMeIds;

  Set<String> _mutedUserIds = {};
  Set<String> get mutedUserIds => _mutedUserIds;

  Set<String> _savedThreadIds = {};
  Set<String> get savedThreadIds => _savedThreadIds;

  List<ThreadPost> _savedPosts = [];
  List<ThreadPost> get savedPosts => _savedPosts;

  Set<String> _savedCommentIds = {};
  Set<String> get savedCommentIds => _savedCommentIds;

  List<Map<String, dynamic>> _savedComments = [];
  List<Map<String, dynamic>> get savedComments => _savedComments;

  Set<String> _repostedThreadIds = {};
  Set<String> get repostedThreadIds => _repostedThreadIds;
  bool isReposted(String threadId) => _repostedThreadIds.contains(threadId);

  Future<void> fetchRepostedThreadIds() async {
    if (_currentUid.isEmpty) return;
    try {
      final response = await _supabase
          .from('reposts')
          .select('thread_id')
          .eq('user_id', _currentUid)
          .isFilter('quote_text', null);
      final List<dynamic> data = response as List<dynamic>;
      _repostedThreadIds = data.map((json) => json['thread_id'] as String).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch reposted thread ids error: $e');
    }
  }

  bool isBlocked(String targetUserId) => _blockedUserIds.contains(targetUserId);
  bool isBlockedByMe(String targetUserId) => _blockedByMeIds.contains(targetUserId);
  bool isMuted(String targetUserId) => _mutedUserIds.contains(targetUserId);
  bool isSaved(String threadId) => _savedThreadIds.contains(threadId);
  bool isCommentSaved(String commentId) => _savedCommentIds.contains(commentId);

  Future<void> toggleSaveThread(String threadId) async {
    final wasAlreadySaved = _savedThreadIds.contains(threadId);
    // Optimistic update
    if (wasAlreadySaved) {
      _savedThreadIds.remove(threadId);
      _savedPosts.removeWhere((p) => p.id == threadId);
    } else {
      _savedThreadIds.add(threadId);
    }

    final cached = _postsCache[threadId];
    if (cached != null) {
      final int countDelta = wasAlreadySaved ? -1 : 1;
      _postsCache[threadId] = cached.copyWith(
        savesCount: (cached.savesCount + countDelta).clamp(0, 999999),
      );
    }

    void updatePostSavesCount(List<ThreadPost> list) {
      final idx = list.indexWhere((p) => p.id == threadId);
      if (idx != -1) {
        final post = list[idx];
        final int countDelta = wasAlreadySaved ? -1 : 1;
        list[idx] = post.copyWith(
          savesCount: (post.savesCount + countDelta).clamp(0, 999999),
        );
      }
    }
    updatePostSavesCount(_feed);
    updatePostSavesCount(_myThreads);
    updatePostSavesCount(_personalizedFeed);

    notifyListeners();

    if (_currentUid.isEmpty) return;
    final result = await sl<ToggleSaveThreadUseCase>()(threadId, wasAlreadySaved);
    await result.fold(
      (failure) async {
        debugPrint('Toggle save thread error: ${failure.message}');
        // Rollback optimistic update
        if (wasAlreadySaved) {
          _savedThreadIds.add(threadId);
        } else {
          _savedThreadIds.remove(threadId);
        }

        final cachedRollback = _postsCache[threadId];
        if (cachedRollback != null) {
          final int countDelta = wasAlreadySaved ? 1 : -1;
          _postsCache[threadId] = cachedRollback.copyWith(
            savesCount: (cachedRollback.savesCount + countDelta).clamp(0, 999999),
          );
        }

        void updatePostSavesCountRollback(List<ThreadPost> list) {
          final idx = list.indexWhere((p) => p.id == threadId);
          if (idx != -1) {
            final post = list[idx];
            final int countDelta = wasAlreadySaved ? 1 : -1;
            list[idx] = post.copyWith(
              savesCount: (post.savesCount + countDelta).clamp(0, 999999),
            );
          }
        }
        updatePostSavesCountRollback(_feed);
        updatePostSavesCountRollback(_myThreads);
        updatePostSavesCountRollback(_personalizedFeed);

        notifyListeners();
      },
      (_) async {
        if (!wasAlreadySaved) {
          await fetchSavedPosts();
          logUserInteraction(threadId, 'save');
        }
      },
    );
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
          .select('thread_id, threads(*, profiles!user_id(*), likes(user_id), thread_hides(user_id))')
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

  // Cached UID — set on signIn/tokenRefresh, cleared only on signOut.
  // This prevents empty-UUID errors during Supabase token refresh windows
  // where auth.currentUser briefly returns null.
  String _cachedUid = '';

  // Supabase session UID — used for all database operations (UUID format)
  String get _supabaseSessionUid => _supabase.auth.currentUser?.id ?? _cachedUid;

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
  RealtimeChannel? _pollVotesChannel;
  StreamSubscription<AuthState>? _supabaseAuthSub;
  Timer? _lastSeenTimer;

  DatabaseService() {
    // Initialize _cachedUid from existing session (app restart after login)
    _cachedUid = _supabase.auth.currentUser?.id ?? '';

    // Listen to Supabase auth state — auto-reload when session established
    _supabaseAuthSub = _supabase.auth.onAuthStateChange.listen((data) {
      debugPrint('[DB] Supabase auth event: ${data.event}');
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed ||
          data.event == AuthChangeEvent.initialSession) {
        // Cache the UID so it survives brief token refresh windows
        final uid = data.session?.user.id ?? _supabase.auth.currentUser?.id ?? '';
        if (uid.isNotEmpty) {
          _cachedUid = uid;
          debugPrint('[DB] Supabase UID cached: $_cachedUid');
          _onUserReady();
        }
      } else if (data.event == AuthChangeEvent.signedOut) {
        _cachedUid = '';
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
    fetchAIFeed(silent: true);
    fetchNotifications();
    fetchUnreadCounts();
    fetchSavedThreadIds();
    fetchSavedCommentIds();
    fetchSavedPosts();
    fetchSavedComments();
    fetchRepostedThreadIds();
    subscribeToRealtime();

    // Periodically update active status
    updateLastSeen();
    _lastSeenTimer?.cancel();
    _lastSeenTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      updateLastSeen();
    });
  }

  void _clearAllData() {
    _myProfile = null;
    _feed = [];
    _personalizedFeed = [];
    _aiFeedPage = 0;
    _aiFeedHasMore = true;
    _myThreads = [];
    _notifications = [];
    _followingIds = {};
    _blockedUserIds = {};
    _blockedByMeIds = {};
    _mutedUserIds = {};
    _savedThreadIds = {};
    _savedCommentIds = {};
    _savedPosts = [];
    _savedComments = [];
    _repostedThreadIds = {};
    _lastSeenTimer?.cancel();
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
              final threadId = (payload.newRecord['id'] ?? payload.oldRecord['id']) as String?;
              if (threadId != null) {
                if (payload.eventType == PostgresChangeEvent.insert) {
                  _reloadThread(threadId, isNew: true);
                } else if (payload.eventType == PostgresChangeEvent.update) {
                  _reloadThread(threadId, isNew: false);
                } else if (payload.eventType == PostgresChangeEvent.delete) {
                  _removePostFromLists(threadId);
                  notifyListeners();
                }
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
              final threadId = (payload.newRecord['thread_id'] ?? payload.oldRecord['thread_id']) as String?;
              final userId = (payload.newRecord['user_id'] ?? payload.oldRecord['user_id']) as String?;
              if (threadId != null && userId != null) {
                _handleLikeRealtimeUpdate(threadId, userId, payload.eventType);
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
              // Only update the reply count in the feed cache — do NOT call fetchFeed()
              // because that triggers notifyListeners() which rebuilds CommentsSheet and
              // can cause the nested comment system to appear to revert.
              final threadId = (payload.newRecord['thread_id'] ?? payload.oldRecord['thread_id']) as String?;
              final parentId = (payload.newRecord['parent_id'] ?? payload.oldRecord['parent_id']) as String?;
              if (threadId != null && parentId == null) {
                _updateReplyCountInCache(threadId, payload.eventType);
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
                if (newNotif['user_id'] == _currentUid && (newNotif['actor_id'] != _currentUid || newNotif['type'] == 'mention')) {
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

    _pollVotesChannel = _supabase
        .channel('public:poll_votes')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'poll_votes',
            callback: (payload) {
              final threadId = (payload.newRecord['thread_id'] ?? payload.oldRecord['thread_id']) as String?;
              if (threadId != null) {
                _reloadThread(threadId);
              }
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
    if (_pollVotesChannel != null) {
      _supabase.removeChannel(_pollVotesChannel!);
      _pollVotesChannel = null;
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

  /// Fetches a single thread by ID. Used for notification tap navigation.
  Future<ThreadPost?> fetchSingleThread(String threadId) async {
    try {
      final response = await _supabase
          .from('threads')
          .select('*, profiles!user_id(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*)')
          .eq('id', threadId)
          .maybeSingle();
      if (response == null) return null;
      return ThreadPost.fromJson(response, currentUid: _currentUid);
    } catch (e) {
      debugPrint('fetchSingleThread error: $e');
      return null;
    }
  }

  Future<void> fetchMyProfile() async {
    if (_currentUid.isEmpty) return;
    final result = await fetchProfile(_currentUid);
    if (result != null) {
      _myProfile = result;
      _checkBadgeExpiration();
      notifyListeners();
    }
  }

  void _checkBadgeExpiration() {
    if (_myProfile?.isVerified == true && _myProfile?.verifiedExpiresAt != null) {
      final expiresAt = _myProfile!.verifiedExpiresAt!;
      final now = DateTime.now();
      final diff = expiresAt.difference(now);
      
      // If within 12 hours of expiration and not already expired
      if (diff.inHours <= 12 && diff.isNegative == false) {
        sl<ShowNotificationUseCase>().call(
          type: NotificationType.generic,
          id: 9999,
          title: 'Badge Expiring Soon',
          body: 'Your Pigeon Blue Badge expires in ${diff.inHours} hours. Tap to renew!',
          payload: 'badge_renewal',
        );
      }
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
      final res = await sl<UpdateProfileUseCase>().call(
        fullName: fullName,
        username: username,
        bio: bio,
        phone: phone,
        country: country,
        division: division,
        city: city,
        village: village,
        zip: zip,
        gender: gender,
        birthdate: birthdate,
      );

      final success = res.fold((l) => false, (r) => r);
      if (success) {
        await fetchMyProfile();
      }
      _isLoading = false;
      notifyListeners();
      return success;
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

  /// Fetch list of profiles who follow [userId]
  Future<List<Profile>> fetchUserFollowers(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('profiles!follower_id(id, username, full_name, avatar_url, bio, followers_count, following_count)')
          .eq('following_id', userId);
      final data = response as List<dynamic>;
      return data
          .map((row) => Profile.fromJson(row['profiles'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Fetch user followers error: $e");
      return [];
    }
  }

  /// Fetch list of profiles that [userId] follows
  Future<List<Profile>> fetchUserFollowing(String userId) async {
    try {
      final response = await _supabase
          .from('follows')
          .select('profiles!following_id(id, username, full_name, avatar_url, bio, followers_count, following_count)')
          .eq('follower_id', userId);
      final data = response as List<dynamic>;
      return data
          .map((row) => Profile.fromJson(row['profiles'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Fetch user following error: $e");
      return [];
    }
  }

  /// Remove a follower (the [followerId] who follows the current user)
  Future<void> removeFollower(String followerId) async {
    if (_currentUid.isEmpty) return;
    try {
      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', _currentUid);
      await fetchMyProfile();
    } catch (e) {
      debugPrint("Remove follower error: $e");
    }
  }

  /// Report a user
  Future<bool> reportUser(String reportedUserId, String reason) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('reports').insert({
        'user_id': _currentUid,
        'reason': 'User Report (@$reportedUserId): $reason',
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint("Report user error: $e");
      return false;
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
      _blockedByMeIds = {};
      for (var row in blockedRes) {
        final id = row['blocked_id'] as String;
        _blockedUserIds.add(id);
        _blockedByMeIds.add(id);
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

  Future<List<ThreadPost>> searchThreads(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await _supabase
          .from('threads')
          .select('*, profiles!user_id(*), likes(user_id), thread_hides(user_id)')
          .ilike('content', '%$query%')
          .limit(20);

      final List<dynamic> data = response as List<dynamic>;
      final List<ThreadPost> results = data.map((json) => ThreadPost.fromJson(json, currentUid: _currentUid)).toList();
      
      // Filter out blocked/muted users, private users we don't follow, and posts hidden from current user
      results.removeWhere((post) {
        if (_blockedUserIds.contains(post.userId) || _mutedUserIds.contains(post.userId)) {
          return true;
        }
        if (post.isHiddenFromMe) {
          return true;
        }
        if (post.userId != _currentUid && post.author.isPrivate) {
          return !isFollowingUser(post.userId);
        }
        return false;
      });

      _updateCache(results);
      return results;
    } catch (e) {
      debugPrint("Search threads error: $e");
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
      final res = await sl<UpdateProfileImageUseCase>().call(bytes, isAvatar);
      final success = res.fold((l) => false, (r) => r);
      if (success) {
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

    final result = await sl<GetFeedUseCase>()(silent: silent);
    result.fold(
      (failure) {
        _isLoading = false;
        notifyListeners();
        debugPrint("Fetch feed error: ${failure.message}");
      },
      (entities) {
        _feed = entities.map((e) => _entityToModel(e)).toList();
        _updateCache(_feed);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> fetchMyThreads() async {
    if (_currentUid.isEmpty) return;
    final result = await sl<IFeedRepository>().fetchMyThreads();
    result.fold(
      (failure) => debugPrint("Fetch my threads error: ${failure.message}"),
      (entities) {
        _myThreads = entities.map((e) => _entityToModel(e)).toList();
        _updateCache(_myThreads);
        notifyListeners();
      },
    );
  }

  Future<bool> createThread(
    String content, {
    List<String>? imageUrls,
    String? videoUrl,
    String? audience,
    List<String>? pollOptions,
    Duration? pollDuration,
    String? communityId,
  }) async {
    DateTime? pollExpiresAt;
    if (pollDuration != null) {
      pollExpiresAt = DateTime.now().add(pollDuration);
    }
    final result = await sl<CreateThreadUseCase>()(
      content,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      audience: audience,
      pollOptions: pollOptions,
      pollExpiresAt: pollExpiresAt,
      communityId: communityId,
    );
    return result.fold(
      (failure) {
        debugPrint("Create thread error: ${failure.message}");
        return false;
      },
      (success) async {
        await fetchFeed(silent: true);
        await fetchAIFeed(silent: true);
        await fetchMyThreads();
        return success;
      },
    );
  }


  Future<void> votePoll(String threadId, String optionId) async {
    if (_currentUid.isEmpty) return;
    
    // Play haptic/pop sound
    sl<PlaySoundUseCase>().call(SoundType.pop);

    // Optimistically update local state so the transition is instant
    final cached = _postsCache[threadId];
    if (cached != null && !cached.hasVotedPoll && !cached.isPollExpired) {
      // Find the option and increment its vote count
      final updatedOptions = cached.pollOptions?.map((opt) {
        if (opt.id == optionId) {
          return opt.copyWith(votesCount: opt.votesCount + 1);
        }
        return opt;
      }).toList();
      
      final updatedPost = cached.copyWith(
        hasVotedPoll: true,
        votedOptionId: optionId,
        pollOptions: updatedOptions,
      );
      
      _postsCache[threadId] = updatedPost;
      
      void updateInList(List<ThreadPost> list) {
        final idx = list.indexWhere((p) => p.id == threadId);
        if (idx != -1) {
          list[idx] = updatedPost;
        }
      }
      updateInList(_feed);
      updateInList(_myThreads);
      updateInList(_personalizedFeed);
      updateInList(_savedPosts);
      
      notifyListeners();
    }

    try {
      await _supabase.from('poll_votes').insert({
        'user_id': _currentUid,
        'thread_id': threadId,
        'poll_option_id': optionId,
      });
      
      logUserInteraction(threadId, 'vote');
    } catch (e) {
      debugPrint('Error casting vote: $e');
      // Rollback on failure
      await _reloadThread(threadId);
    }
  }

  // --- Likes CRUD ---

  Future<void> toggleLike(String threadId, bool shouldLike, {String? reactionType}) async {
    if (_currentUid.isEmpty) return;

    if (shouldLike) {
      sl<PlaySoundUseCase>().call(SoundType.pop);
    }

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

    // Local state optimistic update
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

    final aiFeedIndex = _personalizedFeed.indexWhere((p) => p.id == threadId);
    if (aiFeedIndex != -1) {
      final post = _personalizedFeed[aiFeedIndex];
      final int countDelta = shouldLike 
          ? (post.isLikedByMe ? 0 : 1) 
          : -1;
      _personalizedFeed[aiFeedIndex] = post.copyWith(
        likesCount: post.likesCount + countDelta,
        isLikedByMe: shouldLike,
        reactionType: shouldLike ? (reactionType ?? '❤️') : null,
      );
      notifyListeners();
    }

    final result = await sl<ToggleLikeUseCase>()(threadId, shouldLike);
    result.fold(
      (failure) {
        debugPrint("Toggle like error: ${failure.message}");
        // Optimistic rollback is not strictly enforced in legacy flow, but error is caught
      },
      (_) {
        logUserInteraction(threadId, shouldLike ? 'like' : 'scroll_away');
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchThreadReactors(String threadId) async {
    final result = await sl<IFeedRepository>().fetchThreadReactors(threadId);
    return result.fold(
      (failure) {
        debugPrint("Fetch thread reactors error: ${failure.message}");
        return [];
      },
      (reactors) {
        final List<Map<String, dynamic>> reactorList = [];
        for (final item in reactors) {
          reactorList.add({
            'id': item['id'],
            'name': item['name'],
            'handle': item['handle'],
            'avatar': item['avatar'],
            'isFollowing': isFollowingUser(item['id'] as String),
          });
        }

        // If current user liked it, make sure they are in the list
        final feedIndex = _feed.indexWhere((p) => p.id == threadId);
        final isLikedByMe = feedIndex != -1 ? _feed[feedIndex].isLikedByMe : false;
        if (isLikedByMe && _myProfile != null) {
          if (!reactorList.any((r) => r['id'] == _myProfile!.id)) {
            reactorList.insert(0, {
              'id': _myProfile!.id,
              'name': _myProfile!.fullName,
              'handle': '@${_myProfile!.username}',
              'avatar': _myProfile!.avatarUrl ?? '',
              'isFollowing': false,
            });
          }
        }
        return reactorList;
      },
    );
  }

  Future<List<ThreadPost>> fetchUserThreads(String userId) async {
    final result = await sl<IFeedRepository>().fetchUserThreads(userId);
    return result.fold(
      (failure) {
        debugPrint("Fetch user threads error: ${failure.message}");
        return [];
      },
      (entities) {
        final posts = entities.map((e) => _entityToModel(e)).toList();
        
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
      },
    );
  }

  Future<List<ThreadPost>> fetchUserRepliedThreads(String userId) async {
    if (userId.startsWith('mock-')) {
      return [];
    }
    final result = await sl<IFeedRepository>().fetchUserRepliedThreads(userId);
    return result.fold(
      (failure) {
        debugPrint("Fetch user replied threads error: ${failure.message}");
        return [];
      },
      (entities) {
        final posts = entities.map((e) => _entityToModel(e)).toList();
        
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
      },
    );
  }

  // --- Author Post Operations ---

  Future<bool> togglePinPost(String threadId, bool isPinned) async {
    final result = await sl<IFeedRepository>().togglePinPost(threadId, isPinned);
    return result.fold(
      (failure) {
        debugPrint("Toggle pin post error: ${failure.message}");
        return false;
      },
      (success) {
        if (success) {
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
        }
        return success;
      },
    );
  }

  Future<bool> toggleMutePostNotifications(String threadId, bool mute) async {
    final result = await sl<IFeedRepository>().toggleMutePostNotifications(threadId, mute);
    return result.fold(
      (failure) {
        debugPrint("Toggle mute notifications error: ${failure.message}");
        return false;
      },
      (success) {
        if (success) {
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
        }
        return success;
      },
    );
  }

  Future<bool> toggleHidePostFromProfile(String threadId, bool hide) async {
    final result = await sl<IFeedRepository>().toggleHidePostFromProfile(threadId, hide);
    return result.fold(
      (failure) {
        debugPrint("Toggle hide from profile error: ${failure.message}");
        return false;
      },
      (success) {
        if (success) {
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
        }
        return success;
      },
    );
  }

  Future<bool> editPostContent(String threadId, String content, {List<String>? imageUrls}) async {
    if (_currentUid.isEmpty) return false;
    try {
      final Map<String, dynamic> updateData = {
        'content': content,
      };
      if (imageUrls != null) {
        updateData['image_urls'] = imageUrls;
      }
      await _supabase.from('threads').update(updateData).eq('id', threadId);
      
      // Update cache
      final cached = _postsCache[threadId];
      if (cached != null) {
        _postsCache[threadId] = cached.copyWith(
          content: content,
          imageUrls: imageUrls ?? cached.imageUrls,
        );
      }

      final feedIdx = _feed.indexWhere((p) => p.id == threadId);
      if (feedIdx != -1) {
        _feed[feedIdx] = _feed[feedIdx].copyWith(
          content: content,
          imageUrls: imageUrls ?? _feed[feedIdx].imageUrls,
        );
      }
      final myIdx = _myThreads.indexWhere((p) => p.id == threadId);
      if (myIdx != -1) {
        _myThreads[myIdx] = _myThreads[myIdx].copyWith(
          content: content,
          imageUrls: imageUrls ?? _myThreads[myIdx].imageUrls,
        );
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
    final body = (msg['content'] as String?)?.isNotEmpty == true
        ? msg['content'] as String
        : '📷 Photo';

    // Play chime sound
    sl<PlaySoundUseCase>().call(SoundType.chime);

    // Typed push notification — goes to Messages channel with grouping
    await sl<ShowNotificationUseCase>().call(
      type: NotificationType.message,
      id: msg['id'].hashCode,
      senderName: senderName,
      message: body,
      payload: 'message:${msg['sender_id']}',
    );

    _incomingNotificationStreamController.add({
      'title': senderName,
      'body': body,
      'type': 'message',
      'sender_id': msg['sender_id'],
    });
  }

  void _handleIncomingNotification(Map<String, dynamic> notif) async {
    final actorProfile = await fetchProfile(notif['actor_id'] as String);
    final actorName = actorProfile?.fullName ?? "Someone";
    final type = (notif['type'] as String? ?? '').toLowerCase();
    final content = notif['content'] as String? ?? '';
    final threadId = notif['thread_id'] as String?;

    // Play chime sound
    sl<PlaySoundUseCase>().call(SoundType.chime);

    // Route to typed notification helper for proper OS grouping
    final id = notif['id'].hashCode;
    final payload = threadId != null ? 'thread:$threadId' : 'notification';

    switch (type) {
      case 'follow':
        await sl<ShowNotificationUseCase>().call(
          type: NotificationType.follow,
          id: id,
          actorName: actorName,
          payload: 'profile:${notif['actor_id']}',
        );
        break;
      case 'like':
        await sl<ShowNotificationUseCase>().call(
          type: NotificationType.like,
          id: id,
          actorName: actorName,
          postSnippet: content.isNotEmpty ? content : 'your post',
          payload: payload,
        );
        break;
      case 'mention':
        await sl<ShowNotificationUseCase>().call(
          type: NotificationType.mention,
          id: id,
          actorName: actorName,
          snippet: content,
          payload: payload,
        );
        break;
      default: // comment, repost, reply, etc.
        await sl<ShowNotificationUseCase>().call(
          type: NotificationType.activity,
          id: id,
          actorName: actorName,
          action: content,
          payload: payload,
        );
    }

    _incomingNotificationStreamController.add({
      'title': actorName,
      'body': content,
      'type': type,
    });
  }

  // --- Real-time Private Messaging ---

  Stream<List<Map<String, dynamic>>> getMessagesStream(String otherUserId) {
    return sl<GetMessagesStreamUseCase>()(otherUserId).map((list) {
      return list.map((msg) => {
        'id': msg.id,
        'text': msg.text,
        'isMe': msg.isMe,
        'time': msg.time,
        'created_at': msg.createdAt,
        'media_url': msg.mediaUrl,
        'media_type': msg.mediaType,
        'is_read': msg.isRead,
        'reply_to_id': msg.replyToId,
        'reply_to_text': msg.replyToText,
        'reply_to_sender': msg.replyToSender,
      }).toList();
    });
  }

  Future<void> sendMessage(String receiverId, String content, {String? mediaUrl, String? mediaType}) async {
    if (_blockedUserIds.contains(receiverId)) {
      debugPrint("Cannot send message: User is blocked");
      return;
    }
    final result = await sl<SendMessageUseCase>()(receiverId, content, mediaUrl: mediaUrl, mediaType: mediaType);
    result.fold(
      (failure) => debugPrint("Send message error: ${failure.message}"),
      (_) => fetchUnreadCounts(),
    );
  }

  Future<void> markMessagesAsRead(String otherUserId) async {
    final result = await sl<MarkMessagesAsReadUseCase>()(otherUserId);
    result.fold(
      (failure) => debugPrint("Mark messages as read error: ${failure.message}"),
      (_) => fetchUnreadCounts(),
    );
  }

  Future<List<Map<String, dynamic>>> fetchActiveChats() async {
    final result = await sl<GetActiveChatsUseCase>()();
    return result.fold(
      (failure) {
        debugPrint("Fetch active chats error: ${failure.message}");
        return [];
      },
      (chats) {
        final List<Map<String, dynamic>> list = [];
        for (final chat in chats) {
          final profile = chat['profile'] as Profile;
          if (_blockedUserIds.contains(profile.id)) continue;
          list.add({
            'profile': profile,
            'last_message': chat['lastMessage'],
            'last_message_time': chat['lastMessageTime'],
            'unread_count': chat['unreadCount'],
            'timestamp': DateTime.parse(chat['timeRaw'] as String),
          });
        }
        list.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
        return list;
      },
    );
  }

  Future<String?> uploadChatMedia(Uint8List bytes) async {
    final result = await sl<UploadChatMediaUseCase>()(bytes);
    return result.fold(
      (failure) {
        debugPrint("Upload chat media error: ${failure.message}");
        return null;
      },
      (url) => url,
    );
  }

  Future<void> updateLastSeen() async {
    if (_currentUid.isEmpty) return;
    try {
      await _supabase.from('profiles').update({
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', _currentUid);
    } catch (e) {
      debugPrint("Update last seen error: $e");
    }
  }

  Future<bool> deleteConversation(String otherUserId) async {
    final result = await sl<DeleteConversationUseCase>()(otherUserId);
    return result.fold(
      (failure) {
        debugPrint("Delete conversation error: ${failure.message}");
        return false;
      },
      (success) => success,
    );
  }

  Future<bool> editMessage(String messageId, String receiverId, String newContent) async {
    final result = await sl<IChatRepository>().editMessage(messageId, receiverId, newContent);
    return result.fold(
      (failure) {
        debugPrint("Edit message error: ${failure.message}");
        return false;
      },
      (_) => true,
    );
  }

  Future<bool> deleteMessage(String messageId) async {
    final result = await sl<IChatRepository>().deleteMessage(messageId);
    return result.fold(
      (failure) {
        debugPrint("Delete message error: ${failure.message}");
        return false;
      },
      (_) => true,
    );
  }

  // --- Comment and Nested Replies Database CRUD ---

  Future<List<Map<String, dynamic>>> fetchComments(String threadId) async {
    final result = await sl<FetchCommentsUseCase>()(threadId);
    return result.fold(
      (failure) {
        debugPrint("Fetch comments error: ${failure.message}");
        return [];
      },
      (comments) => comments,
    );
  }

  Future<List<Map<String, dynamic>>> fetchCommentReplies(String commentId) async {
    final result = await sl<IFeedRepository>().fetchCommentReplies(commentId);
    return result.fold(
      (failure) {
        debugPrint("Fetch comment replies error: ${failure.message}");
        return [];
      },
      (replies) => replies,
    );
  }

  Future<bool> addComment(String threadId, String content, {String? parentId, String? imageUrl}) async {
    final result = await sl<AddCommentUseCase>()(threadId, content, parentId: parentId, imageUrl: imageUrl);
    return result.fold(
      (failure) {
        debugPrint("Add comment error: ${failure.message}");
        return false;
      },
      (success) async {
        if (parentId == null) {
          final cached = _postsCache[threadId];
          if (cached != null) {
            _postsCache[threadId] = cached.copyWith(
              repliesCount: cached.repliesCount + 1,
            );
          }
        }
        await fetchFeed(silent: true);
        logUserInteraction(threadId, 'reply');
        return success;
      },
    );
  }

  Future<void> toggleSaveComment(String commentId) async {
    final wasAlreadySaved = _savedCommentIds.contains(commentId);
    if (wasAlreadySaved) {
      _savedCommentIds.remove(commentId);
      _savedComments.removeWhere((c) => c['id'] == commentId);
    } else {
      _savedCommentIds.add(commentId);
    }
    notifyListeners();

    final result = await sl<IFeedRepository>().toggleSaveComment(commentId);
    result.fold(
      (failure) {
        debugPrint('Toggle save comment error: ${failure.message}');
        if (wasAlreadySaved) {
          _savedCommentIds.add(commentId);
        } else {
          _savedCommentIds.remove(commentId);
        }
        notifyListeners();
      },
      (_) async {
        await fetchSavedComments();
      },
    );
  }

  Future<void> fetchSavedCommentIds() async {
    if (_currentUid.isEmpty) return;
    try {
      final response = await _supabase
          .from('saved_comments')
          .select('comment_id')
          .eq('user_id', _currentUid);
      final List<dynamic> data = response as List<dynamic>;
      _savedCommentIds = data.map((json) => json['comment_id'] as String).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch saved comment ids error: $e');
    }
  }

  Future<void> fetchSavedComments() async {
    if (_currentUid.isEmpty) return;
    try {
      final response = await _supabase
          .from('saved_comments')
          .select('*, comments(*, profiles(*))')
          .eq('user_id', _currentUid)
          .order('created_at', ascending: false);
          
      final List<dynamic> data = response as List<dynamic>;
      
      // Fetch user's comment likes for is_liked_by_me tracking
      Set<String> likedCommentIds = {};
      final likesRes = await _supabase
          .from('comment_likes')
          .select('comment_id')
          .eq('user_id', _currentUid);
      final List<dynamic> likesData = likesRes as List<dynamic>;
      likedCommentIds = likesData.map((l) => l['comment_id'] as String).toSet();

      final List<Map<String, dynamic>> comments = [];
      for (final row in data) {
        final commentMap = row['comments'] as Map<String, dynamic>?;
        if (commentMap != null) {
          final authorMap = commentMap['profiles'] as Map<String, dynamic>?;
          final author = authorMap != null 
              ? Profile.fromJson(authorMap) 
              : Profile(id: commentMap['user_id'] ?? '', username: 'unknown', fullName: 'Unknown User');
          
          comments.add({
            'id': commentMap['id'] as String,
            'thread_id': commentMap['thread_id'] as String,
            'author': author,
            'content': commentMap['content'] as String,
            'image_url': commentMap['image_url'] as String?,
            'created_at': _getRelativeTime(DateTime.parse(commentMap['created_at'] as String)),
            'created_at_raw': commentMap['created_at'] as String,
            'likes_count': (commentMap['likes_count'] as int?) ?? 0,
            'saves_count': (commentMap['saves_count'] as int?) ?? 0,
            'shares_count': (commentMap['shares_count'] as int?) ?? 0,
            'replies_count': (commentMap['replies_count'] as int?) ?? 0,
            'parent_id': commentMap['parent_id'] as String?,
            'is_liked_by_me': likedCommentIds.contains(commentMap['id'] as String),
            'is_saved_by_me': true,
          });
        }
      }
      _savedComments = comments;
      _savedCommentIds = comments.map((c) => c['id'] as String).toSet();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch saved comments error: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchSingleComment(String commentId) async {
    try {
      final response = await _supabase
          .from('comments')
          .select('*, profiles(*)')
          .eq('id', commentId)
          .single();
      final json = response;
      
      // Check if liked
      bool isLiked = false;
      if (_currentUid.isNotEmpty) {
        final likeRes = await _supabase
            .from('comment_likes')
            .select('comment_id')
            .eq('user_id', _currentUid)
            .eq('comment_id', commentId)
            .maybeSingle();
        isLiked = likeRes != null;
      }
      
      final authorMap = json['profiles'] as Map<String, dynamic>?;
      final author = authorMap != null 
          ? Profile.fromJson(authorMap) 
          : Profile(id: json['user_id'] ?? '', username: 'unknown', fullName: 'Unknown User');

      return {
        'id': json['id'] as String,
        'author': author,
        'content': json['content'] as String,
        'image_url': json['image_url'] as String?,
        'created_at': _getRelativeTime(DateTime.parse(json['created_at'] as String)),
        'created_at_raw': json['created_at'] as String,
        'likes_count': (json['likes_count'] as int?) ?? 0,
        'saves_count': (json['saves_count'] as int?) ?? 0,
        'shares_count': (json['shares_count'] as int?) ?? 0,
        'replies_count': (json['replies_count'] as int?) ?? 0,
        'parent_id': json['parent_id'] as String?,
        'is_liked_by_me': isLiked,
        'is_saved_by_me': isCommentSaved(json['id'] as String),
      };
    } catch (e) {
      debugPrint("Fetch single comment error: $e");
      return null;
    }
  }

  Future<void> incrementCommentShareCount(String commentId) async {
    try {
      await _supabase.rpc('increment_comment_shares_count', params: {'c_id': commentId});
    } catch (e) {
      debugPrint("Error incrementing comment share count RPC: $e");
      // Fallback
      try {
        final currentRes = await _supabase.from('comments').select('shares_count').eq('id', commentId).single();
        final currentShares = (currentRes['shares_count'] as int?) ?? 0;
        await _supabase.from('comments').update({'shares_count': currentShares + 1}).eq('id', commentId);
      } catch (err) {
        debugPrint("Error manually updating comment shares count: $err");
      }
    }
  }

  Future<void> incrementShareCount(String threadId) async {
    try {
      await _supabase.rpc('increment_shares_count', params: {'thread_id': threadId});
      // Also update cached post if exists
      final cached = _postsCache[threadId];
      if (cached != null) {
        _postsCache[threadId] = cached.copyWith(
          sharesCount: cached.sharesCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error incrementing share count RPC: $e");
      // Fallback: manually update if RPC is missing
      try {
        final cached = _postsCache[threadId];
        if (cached != null) {
          final newShares = cached.sharesCount + 1;
          await _supabase.from('threads').update({'shares_count': newShares}).eq('id', threadId);
          _postsCache[threadId] = cached.copyWith(sharesCount: newShares);
          notifyListeners();
        }
      } catch (err) {
        debugPrint("Error manually updating shares count: $err");
      }
    }
  }

  Future<void> toggleCommentLike(String commentId, bool shouldLike) async {
    final result = await sl<IFeedRepository>().toggleCommentLike(commentId, shouldLike);
    result.fold(
      (failure) => debugPrint("Toggle comment like error: ${failure.message}"),
      (_) => null,
    );
  }

  Future<bool> deleteComment(String commentId, String threadId, {String? parentId}) async {
    final result = await sl<IFeedRepository>().deleteComment(commentId);
    return result.fold(
      (failure) {
        debugPrint("Delete comment error: ${failure.message}");
        return false;
      },
      (success) {
        if (success) {
          if (parentId == null) {
            final cached = _postsCache[threadId];
            if (cached != null) {
              _postsCache[threadId] = cached.copyWith(
                repliesCount: cached.repliesCount - 1 < 0 ? 0 : cached.repliesCount - 1,
              );
            }
          }
          fetchFeed(silent: true);
        }
        return success;
      },
    );
  }

  Future<bool> editComment(String commentId, String content) async {
    final result = await sl<IFeedRepository>().editComment(commentId, content);
    return result.fold(
      (failure) {
        debugPrint("Edit comment error: ${failure.message}");
        return false;
      },
      (success) => success,
    );
  }


  // --- Reposts Operation ---

  Future<bool> repostThread(String threadId, {String? quoteText}) async {
    if (_currentUid.isEmpty) return false;

    final wasReposted = _repostedThreadIds.contains(threadId);

    // Optimistic toggle for simple reposts (quoteText == null)
    if (quoteText == null) {
      if (wasReposted) {
        _repostedThreadIds.remove(threadId);
      } else {
        _repostedThreadIds.add(threadId);
      }

      // Update cache
      final cached = _postsCache[threadId];
      if (cached != null) {
        final delta = wasReposted ? -1 : 1;
        _postsCache[threadId] = cached.copyWith(
          repostsCount: (cached.repostsCount + delta).clamp(0, 999999),
        );
      }

      void updatePostRepostsCount(List<ThreadPost> list) {
        final idx = list.indexWhere((p) => p.id == threadId);
        if (idx != -1) {
          final post = list[idx];
          final delta = wasReposted ? -1 : 1;
          list[idx] = post.copyWith(
            repostsCount: (post.repostsCount + delta).clamp(0, 999999),
          );
        }
      }
      updatePostRepostsCount(_feed);
      updatePostRepostsCount(_myThreads);
      updatePostRepostsCount(_personalizedFeed);
      notifyListeners();
    }

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
      fetchAIFeed(silent: true);
      return true;
    } catch (e) {
      debugPrint("Repost thread error: $e");
      // Rollback optimistic update if simple repost failed
      if (quoteText == null) {
        if (wasReposted) {
          _repostedThreadIds.add(threadId);
        } else {
          _repostedThreadIds.remove(threadId);
        }

        final cached = _postsCache[threadId];
        if (cached != null) {
          final delta = wasReposted ? 1 : -1;
          _postsCache[threadId] = cached.copyWith(
            repostsCount: (cached.repostsCount + delta).clamp(0, 999999),
          );
        }

        void updatePostRepostsCount(List<ThreadPost> list) {
          final idx = list.indexWhere((p) => p.id == threadId);
          if (idx != -1) {
            final post = list[idx];
            final delta = wasReposted ? 1 : -1;
            list[idx] = post.copyWith(
              repostsCount: (post.repostsCount + delta).clamp(0, 999999),
            );
          }
        }
        updatePostRepostsCount(_feed);
        updatePostRepostsCount(_myThreads);
        updatePostRepostsCount(_personalizedFeed);
        notifyListeners();
      }
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
          .select('*, profiles!user_id(*), threads(*, profiles!user_id(*), likes(user_id), thread_hides(user_id))')
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
      logUserInteraction(threadId, 'report');
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

  Future<bool> reportCommunity(String communityId, String communityName, String reason) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('reports').insert({
        'user_id': _currentUid,
        'reason': 'Community Report ($communityName, ID: $communityId): $reason',
      });
      return true;
    } catch (e) {
      debugPrint("Report community error: $e");
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
      logUserInteraction(threadId, 'hide');
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
      logUserInteraction(threadId, 'click');
      
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

  // --- Topic System Fetch Methods ---

  Future<List<Map<String, dynamic>>> fetchTrendingTopics() async {
    try {
      final response = await _supabase.rpc('get_trending_topics', params: {'limit_val': 10});
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint("Fetch trending topics error: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchRisingTopics() async {
    try {
      final response = await _supabase.rpc('get_rising_topics', params: {'limit_val': 10});
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint("Fetch rising topics error: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchMostDiscussedTopics() async {
    try {
      final response = await _supabase.rpc('get_most_discussed_topics', params: {'limit_val': 10});
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint("Fetch most discussed topics error: $e");
      return [];
    }
  }

  Future<List<ThreadPost>> fetchTopicThreads(String topicName) async {
    try {
      final response = await _supabase.rpc('get_topic_threads', params: {'topic_name': topicName.replaceAll('#', '')});
      final List<dynamic> data = response as List<dynamic>;
      
      final List<String> threadIds = data.map((json) => json['id'] as String).toList();
      if (threadIds.isEmpty) return [];

      final threadsRes = await _supabase
          .from('threads')
          .select('*, profiles!user_id(*), likes(user_id), thread_hides(user_id)')
          .inFilter('id', threadIds);
      
      final List<dynamic> threadsData = threadsRes as List<dynamic>;
      final posts = threadsData.map((json) => ThreadPost.fromJson(json, currentUid: _currentUid)).toList();
      
      posts.sort((a, b) => threadIds.indexOf(a.id).compareTo(threadIds.indexOf(b.id)));
      
      _updateCache(posts);
      return posts;
    } catch (e) {
      debugPrint("Fetch topic threads error: $e");
      return [];
    }
  }

  // ── Beta Center & Admin Control Panel State & Methods ──

  bool get isAdmin => myProfile != null && ['admin', 'test', 'pigeon', 'system'].contains(myProfile!.username.toLowerCase());

  Future<bool> submitBetaBug({
    required String title,
    required String desc,
    required String severity,
    required String screen,
    String? screenshotUrl,
  }) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('beta_bugs').insert({
        'user_id': _currentUid,
        'title': title,
        'description': desc,
        'severity': severity,
        'screen_name': screen,
        'screenshot_url': screenshotUrl,
      });
      return true;
    } catch (e) {
      debugPrint("DB Beta bug insert failed: $e");
      return false;
    }
  }

  Future<bool> submitBetaFeature({
    required String title,
    required String desc,
    required String expectedBenefit,
  }) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('beta_features').insert({
        'user_id': _currentUid,
        'title': title,
        'description': desc,
        'expected_benefit': expectedBenefit,
      });
      return true;
    } catch (e) {
      debugPrint("DB Beta feature insert failed: $e");
      return false;
    }
  }

  Future<bool> submitBetaFeedback({
    required int rating,
    required String liked,
    required String improved,
  }) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('beta_feedback').insert({
        'user_id': _currentUid,
        'rating': rating,
        'liked': liked,
        'improved': improved,
      });
      return true;
    } catch (e) {
      debugPrint("DB Beta feedback insert failed: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchBetaKnownIssues() async {
    try {
      final response = await _supabase.from('beta_known_issues').select('*').order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint("DB Fetch known issues failed: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchBetaChangelogs() async {
    try {
      final response = await _supabase.from('beta_changelogs').select('*').order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint("DB Fetch changelogs failed: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyBetaReports() async {
    if (_currentUid.isEmpty) return [];
    List<Map<String, dynamic>> results = [];

    // Bugs
    try {
      final bugRes = await _supabase.from('beta_bugs').select('*').eq('user_id', _currentUid);
      for (var r in (bugRes as List)) {
        var m = Map<String, dynamic>.from(r);
        m['type'] = 'Bug';
        results.add(m);
      }
    } catch (e) {
      debugPrint("DB Fetch my bugs error: $e");
    }

    // Features
    try {
      final featRes = await _supabase.from('beta_features').select('*').eq('user_id', _currentUid);
      for (var r in (featRes as List)) {
        var m = Map<String, dynamic>.from(r);
        m['type'] = 'Feature';
        results.add(m);
      }
    } catch (e) {
      debugPrint("DB Fetch my features error: $e");
    }

    // Sort by created_at descending
    results.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return results;
  }

  Future<List<Map<String, dynamic>>> fetchAdminBetaReports() async {
    List<Map<String, dynamic>> results = [];

    // Fetch bugs
    try {
      final bugRes = await _supabase.from('beta_bugs').select('*, profiles(id, username, full_name, avatar_url)');
      for (var r in (bugRes as List)) {
        var m = Map<String, dynamic>.from(r);
        m['type'] = 'Bug';
        m['user'] = r['profiles'];
        results.add(m);
      }
    } catch (e) {
      debugPrint("DB Admin fetch bugs error: $e");
    }

    // Fetch features
    try {
      final featRes = await _supabase.from('beta_features').select('*, profiles(id, username, full_name, avatar_url)');
      for (var r in (featRes as List)) {
        var m = Map<String, dynamic>.from(r);
        m['type'] = 'Feature';
        m['user'] = r['profiles'];
        results.add(m);
      }
    } catch (e) {
      debugPrint("DB Admin fetch features error: $e");
    }

    // Fetch feedback
    try {
      final feedRes = await _supabase.from('beta_feedback').select('*, profiles(id, username, full_name, avatar_url)');
      for (var r in (feedRes as List)) {
        var m = Map<String, dynamic>.from(r);
        m['type'] = 'Feedback';
        m['user'] = r['profiles'];
        results.add(m);
      }
    } catch (e) {
      debugPrint("DB Admin fetch feedback error: $e");
    }

    results.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
    return results;
  }

  Future<bool> updateBetaReportStatus(String reportId, String type, String newStatus) async {
    try {
      final table = type == 'Bug' ? 'beta_bugs' : 'beta_features';
      await _supabase.from(table).update({'status': newStatus}).eq('id', reportId);
      return true;
    } catch (e) {
      debugPrint("DB Update status error: $e");
      return false;
    }
  }

  Future<bool> addBetaKnownIssue(String title, String desc, String status) async {
    try {
      await _supabase.from('beta_known_issues').insert({
        'title': title,
        'description': desc,
        'status': status,
      });
      return true;
    } catch (e) {
      debugPrint("DB Add known issue error: $e");
      return false;
    }
  }

  Future<bool> updateBetaKnownIssue(String issueId, String newStatus) async {
    try {
      await _supabase.from('beta_known_issues').update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()}).eq('id', issueId);
      return true;
    } catch (e) {
      debugPrint("DB Update known issue status error: $e");
      return false;
    }
  }

  Future<bool> addBetaChangelog(String version, String newFeatures, String improvements, String bugFixes) async {
    try {
      await _supabase.from('beta_changelogs').insert({
        'version': version,
        'new_features': newFeatures,
        'improvements': improvements,
        'bug_fixes': bugFixes,
      });
      return true;
    } catch (e) {
      debugPrint("DB Add changelog error: $e");
      return false;
    }
  }

  Future<bool> notifyBetaTester({
    required String targetUserId,
    required String title,
    required String body,
  }) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('notifications').insert({
        'user_id': targetUserId,
        'actor_id': _currentUid,
        'type': 'SYSTEM',
        'content': '$title: $body',
        'is_read': false,
      });
      return true;
    } catch (e) {
      debugPrint("DB Send notification error: $e");
      return false;
    }
  }

  @override
  void dispose() {
    _supabaseAuthSub?.cancel();
    _lastSeenTimer?.cancel();
    unsubscribeRealtime();
    super.dispose();
  }

  // --- Algorithmic Personalized Feed Operations ---

  Future<void> fetchAIFeed({bool silent = false, int limit = 15, bool loadMore = false}) async {
    if (_currentUid.isEmpty) return;
    if (loadMore && !_aiFeedHasMore) return;

    if (!loadMore) {
      _aiFeedPage = 0;
      _aiFeedHasMore = true;
    }

    if (!silent && !loadMore) {
      _isLoading = true;
      notifyListeners();
    }

    final offset = _aiFeedPage * limit;
    final List<ThreadPost> fetchedPosts = [];

    try {
      final response = await _supabase.rpc(
        'get_personalized_feed',
        params: {
          'p_user_id': _currentUid,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      final List<dynamic> data = response as List<dynamic>;

      if (data.isNotEmpty) {
        final List<String> threadIds = data.map((json) => json['id'] as String).toList();
        
        final threadsRes = await _supabase
            .from('threads')
            .select('*, profiles!user_id(*), communities(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*)')
            .inFilter('id', threadIds);

        final List<dynamic> threadsData = threadsRes as List<dynamic>;
        final List<ThreadPost> posts = threadsData.map((json) => ThreadPost.fromJson(json, currentUid: _currentUid)).toList();
        
        // Sort posts back into the ranked order returned by get_personalized_feed
        posts.sort((a, b) => threadIds.indexOf(a.id).compareTo(threadIds.indexOf(b.id)));
        fetchedPosts.addAll(posts);
      }

      // Also fetch reposts from users we follow so they appear in the "For You" feed
      try {
        final repostsRes = await _supabase
            .from('reposts')
            .select('*, profiles!user_id(*), threads(*, profiles!user_id(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*))' )
            .order('created_at', ascending: false)
            .limit(20);

        final List<dynamic> repostsData = repostsRes as List<dynamic>;
        for (final repost in repostsData) {
          if (repost['threads'] != null) {
            final threadMap = repost['threads'] as Map<String, dynamic>;
            final reposterProfileMap = repost['profiles'] as Map<String, dynamic>?;
            final reposterProfile = reposterProfileMap != null
                ? Profile.fromJson(reposterProfileMap)
                : Profile(id: repost['user_id'] ?? '', username: 'unknown', fullName: 'Unknown User');

            final originalPost = ThreadPost.fromJson(threadMap, currentUid: _currentUid);
            final repostPost = ThreadPost(
              id: repost['id'] as String,
              userId: repost['user_id'] as String,
              author: reposterProfile,
              content: repost['quote_text'] as String? ?? '',
              createdAt: ThreadPost.formatRelativeTime(repost['created_at'] as String?),
              isRepost: true,
              repostedPost: originalPost,
              quoteText: repost['quote_text'] as String?,
              likesCount: 0,
              repliesCount: 0,
              repostsCount: 0,
              viewsCount: 0,
            );
            // Only add if not already in fetched posts
            if (!fetchedPosts.any((p) => p.id == repostPost.id)) {
              fetchedPosts.add(repostPost);
            }
          }
        }
      } catch (e) {
        debugPrint('Fetch reposts for AI feed error: $e');
      }
    } catch (e) {
      debugPrint("Fetch personalized AI feed RPC error: $e. Falling back to direct fetch.");
    }

    // Fallback: If we couldn't load any posts from RPC (due to error or empty result), fetch directly from threads
    if (fetchedPosts.isEmpty) {
      try {
        final response = await _supabase
            .from('threads')
            .select('*, profiles!user_id(*), likes(user_id), thread_hides(user_id), poll_options(*), poll_votes(*)')
            .order('created_at', ascending: false)
            .limit(limit)
            .range(offset, offset + limit - 1);
        
        final List<dynamic> threadsData = response as List<dynamic>;
        final List<ThreadPost> posts = threadsData.map((json) => ThreadPost.fromJson(json, currentUid: _currentUid)).toList();
        fetchedPosts.addAll(posts);
      } catch (fallbackError) {
        debugPrint("AI Feed fallback direct query failed: $fallbackError");
      }
    }

    // Apply privacy/mute/block filters
    fetchedPosts.removeWhere((post) {
      if (_blockedUserIds.contains(post.userId) || _mutedUserIds.contains(post.userId)) {
        return true;
      }
      if (post.isHiddenFromMe) {
        return true;
      }
      if (post.userId != _currentUid && post.author.isPrivate) {
        return !isFollowingUser(post.userId);
      }
      return false;
    });

    if (loadMore) {
      final existingIds = _personalizedFeed.map((p) => p.id).toSet();
      fetchedPosts.removeWhere((p) => existingIds.contains(p.id));
      _personalizedFeed.addAll(fetchedPosts);
    } else {
      _personalizedFeed = fetchedPosts;
    }

    _updateCache(fetchedPosts);

    if (fetchedPosts.length < limit) {
      _aiFeedHasMore = false;
    } else {
      _aiFeedPage++;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logUserInteraction(String threadId, String type, {int duration = 0}) async {
    if (_currentUid.isEmpty) return;
    try {
      await _supabase.rpc('log_user_interaction', params: {
        'p_user_id': _currentUid,
        'p_thread_id': threadId,
        'p_type': type,
        'p_duration': duration,
      });
    } catch (e) {
      debugPrint('Log user interaction error: $e');
    }
  }

  // --- Profile Verification Operations ---

  List<Map<String, dynamic>> _verificationPlans = [];
  List<Map<String, dynamic>> get verificationPlans => _verificationPlans;

  Future<void> fetchVerificationPlans() async {
    try {
      final res = await sl<FetchVerificationPlansUseCase>().call();
      _verificationPlans = res.fold((l) => [], (r) => r);
      notifyListeners();
    } catch (e) {
      debugPrint("Fetch verification plans failed: $e. Using fallback values.");
      _verificationPlans = [
        {'id': 'weekly', 'name': 'Weekly Plan', 'price': 59.0, 'discount_price': null, 'interval_unit': 'week'},
        {'id': 'monthly', 'name': 'Monthly Plan', 'price': 199.0, 'discount_price': null, 'interval_unit': 'month'},
        {'id': 'yearly', 'name': 'Yearly Plan', 'price': 1999.0, 'discount_price': null, 'interval_unit': 'year'},
        {'id': 'lifetime', 'name': 'Lifetime Plan', 'price': 4999.0, 'discount_price': null, 'interval_unit': 'lifetime'},
      ];
      notifyListeners();
    }
  }

  Future<bool> updateVerificationPlanPrice(String planId, double price, {double? discountPrice}) async {
    try {
      final res = await sl<UpdateVerificationPlanPriceUseCase>().call(planId, price, discountPrice: discountPrice);
      final success = res.fold((l) => false, (r) => r);
      if (success) {
        await fetchVerificationPlans();
      }
      return success;
    } catch (e) {
      debugPrint("Update verification plan price failed: $e");
      return false;
    }
  }

  Future<String?> uploadVerificationImage(Uint8List bytes, String filename) async {
    if (_currentUid.isEmpty) return null;
    try {
      final res = await sl<UploadVerificationImageUseCase>().call(bytes, filename);
      return res.fold((l) => null, (r) => r);
    } catch (e) {
      debugPrint("Upload verification image error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchUserVerificationRequest() async {
    if (_currentUid.isEmpty) return null;
    try {
      final res = await sl<GetVerificationStatusUseCase>().call();
      return res.fold((l) => null, (r) => r);
    } catch (e) {
      debugPrint("DB Fetch user verification request failed: $e");
      return null;
    }
  }

  Future<bool> submitVerificationRequest(Map<String, dynamic> requestData) async {
    if (_currentUid.isEmpty) return false;
    try {
      final res = await sl<SubmitVerificationUseCase>().call(requestData);
      final success = res.fold((l) => false, (r) => r);
      if (success) {
        await fetchMyProfile();
      }
      return success;
    } catch (e) {
      debugPrint("DB Submit verification request failed: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAdminVerificationRequests() async {
    try {
      final res = await sl<FetchAdminVerificationRequestsUseCase>().call();
      return res.fold((l) => [], (r) => r);
    } catch (e) {
      debugPrint("DB Admin fetch verification requests error: $e");
      return [];
    }
  }

  Future<bool> updateVerificationRequestStatus(String requestId, String status, {String? reason}) async {
    try {
      final res = await sl<UpdateVerificationRequestStatusUseCase>().call(requestId, status, reason: reason);
      final success = res.fold((l) => false, (r) => r);
      if (success) {
        await fetchMyProfile();
      }
      return success;
    } catch (e) {
      debugPrint("DB Update verification status error: $e");
      return false;
    }
  }
}

extension IterableExtension<E> on Iterable<E> {
  List<T> mapIndexed<T>(T Function(int index, E element) f) {
    var index = 0;
    return map((e) => f(index++, e)).toList();
  }
}
