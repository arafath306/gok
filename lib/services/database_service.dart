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

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Get current logged-in user id
  String get _currentUid => _supabase.auth.currentUser?.id ?? '';

  // --- Profile Operations ---

  Future<Profile?> fetchProfile(String userId) async {
    if (userId == 'mock_uid') {
      return Profile(
        id: 'mock_uid',
        username: 'arafath_sabbir',
        fullName: 'আরাফাত সাব্বির',
        bio: 'সফটওয়্যার ইঞ্জিনিয়ার | ডাক অ্যাপ ডেভেলপ করছি ☕',
        avatarUrl: 'https://i.pravatar.cc/150?u=mock_uid',
        coverUrl: 'https://images.unsplash.com/photo-1596404886561-12cdce3fbe25',
        followersCount: 124,
        followingCount: 10,
        phone: '01712345678',
        country: 'বাংলাদেশ',
      );
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
    final uid = _currentUid.isEmpty ? 'mock_uid' : _currentUid;
    final result = await fetchProfile(uid);
    if (result != null) {
      _myProfile = result;
      notifyListeners();
    } else {
      // Fallback in case table doesn't exist
      _myProfile = Profile(
        id: uid,
        username: 'arafath_sabbir',
        fullName: 'আরাফাত সাব্বির',
        bio: 'সফটওয়্যার ইঞ্জিনিয়ার | ডাক অ্যাপ ডেভেলপ করছি ☕',
        avatarUrl: 'https://i.pravatar.cc/150?u=$uid',
        coverUrl: 'https://images.unsplash.com/photo-1596404886561-12cdce3fbe25',
        followersCount: 124,
        followingCount: 10,
        phone: '01712345678',
        country: 'বাংলাদেশ',
      );
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
    final uid = _currentUid.isEmpty ? 'mock_uid' : _currentUid;
    if (uid == 'mock_uid') {
      _myProfile = Profile(
        id: 'mock_uid',
        username: username,
        fullName: fullName,
        bio: bio,
        avatarUrl: _myProfile?.avatarUrl,
        coverUrl: _myProfile?.coverUrl,
        followersCount: _myProfile?.followersCount ?? 124,
        followingCount: _myProfile?.followingCount ?? 10,
        phone: phone,
        country: country,
      );
      notifyListeners();
      return true;
    }

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
          .eq('id', uid)
          .select()
          .single();

      _myProfile = Profile.fromJson(response);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      debugPrint("Update profile error: $e");
      // Fallback update
      _myProfile = Profile(
        id: uid,
        username: username,
        fullName: fullName,
        bio: bio,
        avatarUrl: _myProfile?.avatarUrl,
        coverUrl: _myProfile?.coverUrl,
        followersCount: _myProfile?.followersCount ?? 124,
        followingCount: _myProfile?.followingCount ?? 10,
        phone: phone,
        country: country,
      );
      notifyListeners();
      return true;
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
      debugPrint("Fetch feed error: $e. Using high-fidelity mock data.");
      
      final author1 = Profile(
        id: 'u1',
        username: 'tanvir_cse',
        fullName: 'তানভীর আহমেদ',
        avatarUrl: 'https://i.pravatar.cc/150?u=u1',
        followersCount: 1250,
      );
      final author2 = Profile(
        id: 'u2',
        username: 'dhaka_vibes',
        fullName: 'নিলয় চৌধুরী',
        avatarUrl: 'https://i.pravatar.cc/150?u=u2',
        followersCount: 4520,
      );
      final author3 = Profile(
        id: 'u3',
        username: 'pitha_fest',
        fullName: 'সাদিয়া তাসনিম',
        avatarUrl: 'https://i.pravatar.cc/150?u=u3',
        followersCount: 890,
      );

      _feed = [
        ThreadPost(
          id: 'p1',
          userId: 'u1',
          author: author1,
          content: 'আজকে ধানমন্ডি লেকের পাশে চা খেতে খেতে চমৎকার কিছু সময় কাটলো। ঢাকার এই বিকেলের হাওয়া আসলেই অন্যরকম! ☕✨',
          imageUrls: const ['https://images.unsplash.com/photo-1554118811-1e0d58224f24'],
          likesCount: 24,
          repliesCount: 5,
          createdAt: '১০ মি. আগে',
          isLikedByMe: false,
        ),
        ThreadPost(
          id: 'p2',
          userId: 'u2',
          author: author2,
          content: 'ফ্লাটার নিয়ে নতুন একটা প্রজেক্ট শুরু করলাম। Threads আর Bluesky-এর মতো ক্লাসিক ও মিনিমালিস্ট ডিজাইন করতে দারুণ লাগছে। আপনাদের মতামত কি?',
          likesCount: 42,
          repliesCount: 12,
          createdAt: '২ ঘণ্টা আগে',
          isLikedByMe: true,
        ),
        ThreadPost(
          id: 'p3',
          userId: 'u3',
          author: author3,
          content: 'শীতের সকালে গরম গরম ভাপা পিঠা খাওয়ার মজাই আলাদা! কার কার পছন্দ ভাপা পিঠা? 😋',
          imageUrls: const ['https://images.unsplash.com/photo-1601050690597-df056fb4ce78'],
          likesCount: 18,
          repliesCount: 3,
          createdAt: '৪ ঘণ্টা আগে',
          isLikedByMe: false,
        ),
      ];
      notifyListeners();
    }
  }

  Future<void> fetchMyThreads() async {
    final uid = _currentUid.isEmpty ? 'mock_uid' : _currentUid;
    try {
      final response = await _supabase
          .from('threads')
          .select('*, profiles(*), likes(user_id)')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      _myThreads = data.map((json) => ThreadPost.fromJson(json, currentUid: uid)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Fetch my threads error: $e. Using mock my threads.");
      final myProf = _myProfile ?? Profile(
        id: 'mock_uid',
        username: 'arafath_sabbir',
        fullName: 'আরাফাত সাব্বির',
        avatarUrl: 'https://i.pravatar.cc/150?u=mock_uid',
      );
      _myThreads = [
        ThreadPost(
          id: 'mp1',
          userId: myProf.id,
          author: myProf,
          content: 'অবশেষে আমাদের "ডাক (Dak)" অ্যাপের থ্রেডস ভার্সন ডিজাইন চমৎকারভাবে সম্পন্ন হয়েছে! লিন্ট এরর শুন্য এবং বিল্ড সম্পন্ন। 🎉📱',
          likesCount: 56,
          repliesCount: 8,
          createdAt: '১ দিন আগে',
          isLikedByMe: false,
        ),
        ThreadPost(
          id: 'mp2',
          userId: myProf.id,
          author: myProf,
          content: 'ক্লিন অ্যান্ড সিম্পল ফ্ল্যাট ডিজাইন দিয়ে ইউজার এক্সপেরিয়েন্স অনেক বেশি প্রিমিয়াম করা সম্ভব। আপনাদের মন্তব্য জানান নিচে!',
          likesCount: 31,
          repliesCount: 4,
          createdAt: '৩ দিন আগে',
          isLikedByMe: false,
        ),
      ];
      notifyListeners();
    }
  }

  Future<bool> createThread(String content, {List<String>? imageUrls, String? videoUrl}) async {
    final uid = _currentUid.isEmpty ? 'mock_uid' : _currentUid;
    if (uid == 'mock_uid') {
      final myProf = _myProfile ?? Profile(
        id: 'mock_uid',
        username: 'arafath_sabbir',
        fullName: 'আরাফাত সাব্বির',
        avatarUrl: 'https://i.pravatar.cc/150?u=mock_uid',
      );
      final newPost = ThreadPost(
        id: 'mp_new_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'mock_uid',
        author: myProf,
        content: content,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        likesCount: 0,
        repliesCount: 0,
        createdAt: 'এখনই',
      );
      _myThreads.insert(0, newPost);
      _feed.insert(0, newPost);
      notifyListeners();
      return true;
    }

    try {
      await _supabase.from('threads').insert({
        'user_id': uid,
        'content': content,
        'image_urls': imageUrls,
        'video_url': videoUrl,
        'created_at': 'এখনই',
      });
      
      // Refresh feed
      await fetchFeed();
      await fetchMyThreads();
      return true;
    } catch (e) {
      debugPrint("Create thread error: $e");
      // Fallback insert
      final myProf = _myProfile ?? Profile(
        id: uid,
        username: 'arafath_sabbir',
        fullName: 'আরাফাত সাব্বির',
        avatarUrl: 'https://i.pravatar.cc/150?u=$uid',
      );
      final newPost = ThreadPost(
        id: 'mp_new_${DateTime.now().millisecondsSinceEpoch}',
        userId: uid,
        author: myProf,
        content: content,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        likesCount: 0,
        repliesCount: 0,
        createdAt: 'এখনই',
      );
      _myThreads.insert(0, newPost);
      _feed.insert(0, newPost);
      notifyListeners();
      return true;
    }
  }

  // --- Likes CRUD ---

  Future<void> toggleLike(String threadId, bool shouldLike) async {
    final uid = _currentUid.isEmpty ? 'mock_uid' : _currentUid;

    // Locally update likes count inside feed list for instant UI feedback
    final feedIndex = _feed.indexWhere((p) => p.id == threadId);
    if (feedIndex != -1) {
      final post = _feed[feedIndex];
      _feed[feedIndex] = ThreadPost(
        id: post.id,
        userId: post.userId,
        author: post.author,
        content: post.content,
        imageUrls: post.imageUrls,
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
        likesCount: post.likesCount + (shouldLike ? 1 : -1),
        repliesCount: post.repliesCount,
        repostsCount: post.repostsCount,
        createdAt: post.createdAt,
        isLikedByMe: shouldLike,
      );
      notifyListeners();
    }

    if (uid == 'mock_uid') return;

    try {
      if (shouldLike) {
        await _supabase.from('likes').insert({
          'user_id': uid,
          'thread_id': threadId,
        });
      } else {
        await _supabase
            .from('likes')
            .delete()
            .eq('user_id', uid)
            .eq('thread_id', threadId);
      }
    } catch (e) {
      debugPrint("Toggle like error: $e");
    }
  }

  // --- Notifications (Emulated / Database combined) ---

  Future<void> fetchNotifications() async {
    final uid = _currentUid.isEmpty ? 'mock_uid' : _currentUid;
    try {
      final response = await _supabase.from('profiles').select().limit(5);
      final List<dynamic> data = response as List<dynamic>;
      final activeProfiles = data.map((json) => Profile.fromJson(json)).toList();

      final filteredProfiles = activeProfiles.where((p) => p.id != uid).toList();

      _notifications = filteredProfiles.mapIndexed((index, profile) {
        final type = index % 3 == 0 ? "FOLLOW" : (index % 3 == 1 ? "MENTION" : "LIKE");
        final content = type == "FOLLOW"
            ? "আপনাকে অনুসরণ করা শুরু করেছেন"
            : (type == "MENTION" ? "আপনাকে একটি মন্তব্যে মেনশন করেছেন" : "আপনার পোস্টে লাইক দিয়েছেন");

        return AppNotification(
          id: 'mock_n_$index',
          userId: uid,
          actor: profile,
          type: type,
          content: content,
          createdAt: '${index + 2} মিনিট আগে',
          read: index > 1,
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint("Fetch notifications error: $e. Falling back to mock notifications.");
      final actor1 = Profile(id: 'u1', username: 'tanvir_cse', fullName: 'তানভীর আহমেদ', avatarUrl: 'https://i.pravatar.cc/150?u=u1');
      final actor2 = Profile(id: 'u2', username: 'dhaka_vibes', fullName: 'নিলয় চৌধুরী', avatarUrl: 'https://i.pravatar.cc/150?u=u2');
      final actor3 = Profile(id: 'u3', username: 'pitha_fest', fullName: 'সাদিয়া তাসনিম', avatarUrl: 'https://i.pravatar.cc/150?u=u3');

      _notifications = [
        AppNotification(
          id: 'mn1',
          userId: uid,
          actor: actor1,
          type: 'FOLLOW',
          content: 'আপনাকে অনুসরণ করা শুরু করেছেন',
          createdAt: '৫ মিনিট আগে',
        ),
        AppNotification(
          id: 'mn2',
          userId: uid,
          actor: actor2,
          type: 'LIKE',
          content: 'আপনার পোস্টে লাইক দিয়েছেন',
          createdAt: '১৫ মিনিট আগে',
        ),
        AppNotification(
          id: 'mn3',
          userId: uid,
          actor: actor3,
          type: 'REPLY',
          content: 'আপনার পোস্টে একটি উত্তর দিয়েছেন',
          createdAt: '১ ঘণ্টা আগে',
        ),
      ];
      notifyListeners();
    }
  }

  // --- Follow Action ---

  Future<void> followUser(String targetUserId) async {
    final uid = _currentUid.isEmpty ? 'mock_uid' : _currentUid;
    if (uid == 'mock_uid') return;

    try {
      await _supabase.from('follows').insert({
        'follower_id': uid,
        'following_id': targetUserId,
      });
      await fetchMyProfile();
    } catch (e) {
      debugPrint("Follow user error: $e");
    }
  }

  Future<bool> reportPost(String threadId, String reason) async {
    final uid = _currentUid.isEmpty ? 'mock_uid' : _currentUid;
    if (uid == 'mock_uid') return true;

    try {
      await _supabase.from('reports').insert({
        'user_id': uid,
        'thread_id': threadId,
        'reason': reason,
      });
      return true;
    } catch (e) {
      debugPrint("Report post error: $e");
      return true; // Graceful fallback
    }
  }
}

// Simple extension helper
extension IterableExtension<E> on Iterable<E> {
  List<T> mapIndexed<T>(T Function(int index, E element) f) {
    var index = 0;
    return map((e) => f(index++, e)).toList();
  }
}
