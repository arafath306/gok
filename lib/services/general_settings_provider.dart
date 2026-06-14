import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeneralSettingsProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  String get _currentUid => _supabase.auth.currentUser?.id ?? '';

  // Privacy State
  bool _isPrivateAccount = false;
  bool get isPrivateAccount => _isPrivateAccount;

  String _allowMentionsFrom = 'everyone'; // 'everyone', 'people_you_follow', 'no_one'
  String get allowMentionsFrom => _allowMentionsFrom;

  bool _filterAdultContent = true;
  bool get filterAdultContent => _filterAdultContent;

  bool _autoplayVideos = true;
  bool get autoplayVideos => _autoplayVideos;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchSettings() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch privacy settings from user profile
      final profileRes = await _supabase
          .from('profiles')
          .select('is_private, allow_mentions, filter_adult, autoplay_videos')
          .eq('id', uid)
          .maybeSingle();

      if (profileRes != null) {
        _isPrivateAccount = profileRes['is_private'] as bool? ?? false;
        _allowMentionsFrom = profileRes['allow_mentions'] as String? ?? 'everyone';
        _filterAdultContent = profileRes['filter_adult'] as bool? ?? true;
        _autoplayVideos = profileRes['autoplay_videos'] as bool? ?? true;
      }

      // 2. Fetch blocked accounts
      final blockedRes = await _supabase
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', uid);

      _blockedAccounts.clear();
      if (blockedRes.isNotEmpty) {
        final List<String> blockedIds = List<String>.from(
            blockedRes.map((r) => r['blocked_id'] as String));

        final profilesRes = await _supabase
            .from('profiles')
            .select('id, full_name, username, avatar_url')
            .inFilter('id', blockedIds);

        for (var profile in profilesRes) {
          _blockedAccounts.add({
            'id': profile['id'] as String,
            'name': profile['full_name'] as String? ?? '',
            'username': profile['username'] as String? ?? '',
            'avatar': profile['avatar_url'] as String? ?? 'https://i.pravatar.cc/150?u=${profile['username']}',
          });
        }
      }

      // 3. Fetch muted accounts
      final mutedRes = await _supabase
          .from('mutes')
          .select('muted_id')
          .eq('muter_id', uid);

      _mutedAccounts.clear();
      if (mutedRes.isNotEmpty) {
        final List<String> mutedIds = List<String>.from(
            mutedRes.map((r) => r['muted_id'] as String));

        final profilesRes = await _supabase
            .from('profiles')
            .select('id, full_name, username, avatar_url')
            .inFilter('id', mutedIds);

        for (var profile in profilesRes) {
          _mutedAccounts.add({
            'id': profile['id'] as String,
            'name': profile['full_name'] as String? ?? '',
            'username': profile['username'] as String? ?? '',
            'avatar': profile['avatar_url'] as String? ?? 'https://i.pravatar.cc/150?u=${profile['username']}',
          });
        }
      }
    } catch (e) {
      debugPrint('[GeneralSettings] Fetch settings error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePrivacy({
    bool? isPrivateAccount,
    String? allowMentionsFrom,
    bool? filterAdultContent,
    bool? autoplayVideos,
  }) async {
    final uid = _currentUid;
    if (uid.isEmpty) return;

    if (isPrivateAccount != null) _isPrivateAccount = isPrivateAccount;
    if (allowMentionsFrom != null) _allowMentionsFrom = allowMentionsFrom;
    if (filterAdultContent != null) _filterAdultContent = filterAdultContent;
    if (autoplayVideos != null) _autoplayVideos = autoplayVideos;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (isPrivateAccount != null) updates['is_private'] = isPrivateAccount;
      if (allowMentionsFrom != null) updates['allow_mentions'] = allowMentionsFrom;
      if (filterAdultContent != null) updates['filter_adult'] = filterAdultContent;
      if (autoplayVideos != null) updates['autoplay_videos'] = autoplayVideos;

      if (updates.isNotEmpty) {
        await _supabase.from('profiles').update(updates).eq('id', uid);
      }
    } catch (e) {
      debugPrint('[GeneralSettings] Update privacy error: $e');
    }
  }

  // Security State
  bool _isTwoFactorEnabled = false;
  bool get isTwoFactorEnabled => _isTwoFactorEnabled;

  void toggleTwoFactor(bool val) {
    _isTwoFactorEnabled = val;
    notifyListeners();
  }

  final List<Map<String, String>> _activeSessions = [
    {'id': '1', 'device': 'Chrome (Windows 11)', 'location': 'Dhaka, Bangladesh', 'status': 'Active now'},
    {'id': '2', 'device': 'iPhone 15 Pro', 'location': 'Chittagong, Bangladesh', 'status': 'Last active 2 hours ago'},
    {'id': '3', 'device': 'Pixel 8 Pro', 'location': 'Sylhet, Bangladesh', 'status': 'Last active 1 day ago'},
  ];
  List<Map<String, String>> get activeSessions => _activeSessions;

  void revokeSession(String id) {
    _activeSessions.removeWhere((session) => session['id'] == id);
    notifyListeners();
  }

  // Saved Threads State
  final List<Map<String, dynamic>> _savedThreads = [
    {
      'id': 's1',
      'author_name': 'Tasnim Rahman',
      'author_username': 'tasnim_dev',
      'author_avatar': 'https://i.pravatar.cc/150?u=tasnim',
      'content': 'ফ্ল্যাটার দিয়ে যখন কোনো কমপ্লেক্স ইউজার ইন্টারফেস ডিজাইন করবেন, তখন রেসপন্সিভনেস এবং থিমিংয়ের দিকে সবসময় আলাদা নজর রাখা উচিত। ডাক সামাজিক যোগাযোগ মাধ্যমটি তারই একটা চমৎকার উদাহরণ হতে যাচ্ছে!',
      'time_ago': '২ ঘণ্টা আগে',
      'likes': 42,
      'replies': 7,
    },
    {
      'id': 's2',
      'author_name': 'Zakir Hossain',
      'author_username': 'zakir30',
      'author_avatar': 'https://i.pravatar.cc/150?u=zakir',
      'content': 'আমাদের ডাক অ্যাপটির ডিজাইন টুইটার এবং ব্লু-স্কাইকে ছাড়িয়ে যাবে ইনশাআল্লাহ। আমরা প্রতিটি ফিচার খুবই প্রিমিয়াম এবং ইন্টারেক্টিভ করছি।',
      'time_ago': '৫ ঘণ্টা আগে',
      'likes': 118,
      'replies': 24,
    }
  ];
  List<Map<String, dynamic>> get savedThreads => _savedThreads;

  void unsaveThread(String id) {
    _savedThreads.removeWhere((thread) => thread['id'] == id);
    notifyListeners();
  }

  // Blocked Accounts State
  final List<Map<String, String>> _blockedAccounts = [];
  List<Map<String, String>> get blockedAccounts => _blockedAccounts;

  Future<void> unblockAccount(String id) async {
    final uid = _currentUid;
    if (uid.isEmpty) return;

    try {
      await _supabase
          .from('blocks')
          .delete()
          .eq('blocker_id', uid)
          .eq('blocked_id', id);

      _blockedAccounts.removeWhere((account) => account['id'] == id);
      notifyListeners();
    } catch (e) {
      debugPrint('[GeneralSettings] Unblock user error: $e');
    }
  }

  Future<bool> blockAccount(String queryText) async {
    final uid = _currentUid;
    if (uid.isEmpty) return false;

    try {
      // Find user matching username or full name
      final searchRes = await _supabase
          .from('profiles')
          .select('id, full_name, username, avatar_url')
          .or('username.ilike.%$queryText%,full_name.ilike.%$queryText%')
          .limit(1)
          .maybeSingle();

      if (searchRes == null) {
        return false;
      }

      final targetId = searchRes['id'] as String;
      if (targetId == uid) {
        throw Exception("You cannot block yourself.");
      }

      // Add to database
      await _supabase.from('blocks').upsert({
        'blocker_id': uid,
        'blocked_id': targetId,
      });

      // Update local cache list
      _blockedAccounts.removeWhere((account) => account['id'] == targetId);
      _blockedAccounts.add({
        'id': targetId,
        'name': searchRes['full_name'] as String? ?? '',
        'username': searchRes['username'] as String? ?? '',
        'avatar': searchRes['avatar_url'] as String? ?? 'https://i.pravatar.cc/150?u=${searchRes['username']}',
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[GeneralSettings] Block account error: $e');
      rethrow;
    }
  }

  // Muted Accounts State
  final List<Map<String, String>> _mutedAccounts = [];
  List<Map<String, String>> get mutedAccounts => _mutedAccounts;

  Future<void> unmuteAccount(String id) async {
    final uid = _currentUid;
    if (uid.isEmpty) return;

    try {
      await _supabase
          .from('mutes')
          .delete()
          .eq('muter_id', uid)
          .eq('muted_id', id);

      _mutedAccounts.removeWhere((account) => account['id'] == id);
      notifyListeners();
    } catch (e) {
      debugPrint('[GeneralSettings] Unmute user error: $e');
    }
  }

  Future<bool> muteAccount(String queryText) async {
    final uid = _currentUid;
    if (uid.isEmpty) return false;

    try {
      // Find user matching username or full name
      final searchRes = await _supabase
          .from('profiles')
          .select('id, full_name, username, avatar_url')
          .or('username.ilike.%$queryText%,full_name.ilike.%$queryText%')
          .limit(1)
          .maybeSingle();

      if (searchRes == null) {
        return false;
      }

      final targetId = searchRes['id'] as String;
      if (targetId == uid) {
        throw Exception("You cannot mute yourself.");
      }

      // Add to database
      await _supabase.from('mutes').upsert({
        'muter_id': uid,
        'muted_id': targetId,
      });

      // Update local cache list
      _mutedAccounts.removeWhere((account) => account['id'] == targetId);
      _mutedAccounts.add({
        'id': targetId,
        'name': searchRes['full_name'] as String? ?? '',
        'username': searchRes['username'] as String? ?? '',
        'avatar': searchRes['avatar_url'] as String? ?? 'https://i.pravatar.cc/150?u=${searchRes['username']}',
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[GeneralSettings] Mute account error: $e');
      rethrow;
    }
  }

  Future<void> blockUserById(String targetId) async {
    final uid = _currentUid;
    if (uid.isEmpty || targetId == uid) return;

    try {
      // Add to database
      await _supabase.from('blocks').upsert({
        'blocker_id': uid,
        'blocked_id': targetId,
      });

      // Update local settings state
      await fetchSettings();
    } catch (e) {
      debugPrint('[GeneralSettings] Block user by ID error: $e');
      rethrow;
    }
  }

  Future<void> muteUserById(String targetId) async {
    final uid = _currentUid;
    if (uid.isEmpty || targetId == uid) return;

    try {
      // Add to database
      await _supabase.from('mutes').upsert({
        'muter_id': uid,
        'muted_id': targetId,
      });

      // Update local settings state
      await fetchSettings();
    } catch (e) {
      debugPrint('[GeneralSettings] Mute user by ID error: $e');
      rethrow;
    }
  }
}
