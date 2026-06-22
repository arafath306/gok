import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  bool _isActiveStatusEnabled = true;
  bool get isActiveStatusEnabled => _isActiveStatusEnabled;

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
          .select('is_private, allow_mentions, filter_adult, autoplay_videos, is_active_status_enabled')
          .eq('id', uid)
          .maybeSingle();

      if (profileRes != null) {
        _isPrivateAccount = profileRes['is_private'] as bool? ?? false;
        _allowMentionsFrom = profileRes['allow_mentions'] as String? ?? 'everyone';
        _filterAdultContent = profileRes['filter_adult'] as bool? ?? true;
        _autoplayVideos = profileRes['autoplay_videos'] as bool? ?? true;
        _isActiveStatusEnabled = profileRes['is_active_status_enabled'] as bool? ?? true;
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
            'avatar': profile['avatar_url'] as String? ?? '',
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
            'avatar': profile['avatar_url'] as String? ?? '',
          });
        }
      }
      // 4. Fetch active sessions
      await fetchActiveSessions();
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
    bool? isActiveStatusEnabled,
  }) async {
    final uid = _currentUid;
    if (uid.isEmpty) return;

    if (isPrivateAccount != null) _isPrivateAccount = isPrivateAccount;
    if (allowMentionsFrom != null) _allowMentionsFrom = allowMentionsFrom;
    if (filterAdultContent != null) _filterAdultContent = filterAdultContent;
    if (autoplayVideos != null) _autoplayVideos = autoplayVideos;
    if (isActiveStatusEnabled != null) _isActiveStatusEnabled = isActiveStatusEnabled;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (isPrivateAccount != null) updates['is_private'] = isPrivateAccount;
      if (allowMentionsFrom != null) updates['allow_mentions'] = allowMentionsFrom;
      if (filterAdultContent != null) updates['filter_adult'] = filterAdultContent;
      if (autoplayVideos != null) updates['autoplay_videos'] = autoplayVideos;
      if (isActiveStatusEnabled != null) updates['is_active_status_enabled'] = isActiveStatusEnabled;

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

  Future<void> fetchActiveSessions() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      String? cachedSessionId = prefs.getString('current_session_id');
      if (cachedSessionId == null) {
        cachedSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecondsSinceEpoch % 9000))}';
        await prefs.setString('current_session_id', cachedSessionId);
      }

      // Determine device name
      String deviceName = 'Web Client';
      if (!kIsWeb) {
        deviceName = defaultTargetPlatform == TargetPlatform.android
            ? 'Android Device'
            : (defaultTargetPlatform == TargetPlatform.iOS ? 'iOS Device' : 'Desktop App');
      }

      // Sync/Upsert this session in database
      try {
        final existing = await _supabase
            .from('user_sessions')
            .select('id')
            .eq('id', cachedSessionId)
            .maybeSingle();

        if (existing == null) {
          await _supabase.from('user_sessions').insert({
            'id': cachedSessionId,
            'user_id': uid,
            'device_name': deviceName,
            'location': 'Dhaka, Bangladesh',
            'status': 'Active now',
          });
        } else {
          await _supabase.from('user_sessions').update({
            'last_active': DateTime.now().toUtc().toIso8601String(),
            'status': 'Active now',
          }).eq('id', cachedSessionId);
        }
      } catch (dbError) {
        debugPrint('[GeneralSettings] Sync current session to DB failed (falling back): $dbError');
      }

      // Fetch all sessions
      final res = await _supabase
          .from('user_sessions')
          .select()
          .eq('user_id', uid)
          .order('last_active', ascending: false);

      final List<dynamic> data = res as List<dynamic>;
      
      // If we are logged in, but our current session is not in the fetched data, we were revoked!
      final hasCurrentSession = data.any((item) => item['id'] == cachedSessionId);
      if (!hasCurrentSession && data.isNotEmpty) {
        debugPrint('[GeneralSettings] Current session was revoked!');
        await _supabase.auth.signOut();
        return;
      }

      _activeSessions.clear();
      for (var item in data) {
        final String sessionId = item['id'] as String;
        final bool isCurrent = sessionId == cachedSessionId;
        _activeSessions.add({
          'id': sessionId,
          'device': item['device_name'] as String? ?? 'Unknown Device',
          'location': item['location'] as String? ?? 'Unknown Location',
          'status': isCurrent ? 'Active now' : _formatLastActive(item['last_active'] as String?),
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[GeneralSettings] fetchActiveSessions error: $e');
    }
  }

  String _formatLastActive(String? isoString) {
    if (isoString == null) return 'Last active unknown';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) {
        return 'Last active just now';
      } else if (diff.inMinutes < 60) {
        return 'Last active ${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return 'Last active ${diff.inHours}h ago';
      } else {
        return 'Last active ${diff.inDays}d ago';
      }
    } catch (_) {
      return 'Last active recently';
    }
  }

  Future<void> revokeSession(String id) async {
    _activeSessions.removeWhere((session) => session['id'] == id);
    notifyListeners();

    final uid = _currentUid;
    if (uid.isNotEmpty) {
      try {
        await _supabase.from('user_sessions').delete().eq('id', id);
      } catch (e) {
        debugPrint('[GeneralSettings] revokeSession error: $e');
      }
    }
  }

  // Saved Threads State
  final List<Map<String, dynamic>> _savedThreads = [
    {
      'id': 's1',
      'author_name': 'Tasnim Rahman',
      'author_username': 'tasnim_dev',
      'author_avatar': '',
      'content': 'When designing complex user interfaces with Flutter, always pay special attention to responsiveness and theming. Pigeon Social is going to be an excellent example of that!',
      'time_ago': '2 hours ago',
      'likes': 42,
      'replies': 7,
    },
    {
      'id': 's2',
      'author_name': 'Zakir Hossain',
      'author_username': 'zakir30',
      'author_avatar': '',
      'content': 'Our Pigeon app design will surpass Twitter and Bluesky, InshaAllah. We are making every feature very premium and interactive.',
      'time_ago': '5 hours ago',
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
        'avatar': searchRes['avatar_url'] as String? ?? '',
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
        'avatar': searchRes['avatar_url'] as String? ?? '',
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

  Future<List<Map<String, String>>> searchProfiles(String queryText) async {
    final uid = _currentUid;
    if (uid.isEmpty || queryText.trim().isEmpty) return [];

    try {
      final res = await _supabase
          .from('profiles')
          .select('id, full_name, username, avatar_url')
          .or('username.ilike.%${queryText.trim()}%,full_name.ilike.%${queryText.trim()}%')
          .neq('id', uid)
          .limit(20);

      final List<dynamic> data = res as List<dynamic>;
      return data.map<Map<String, String>>((item) {
        return {
          'id': item['id'] as String? ?? '',
          'name': item['full_name'] as String? ?? '',
          'username': item['username'] as String? ?? '',
          'avatar': item['avatar_url'] as String? ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('[GeneralSettings] Search profiles error: $e');
      return [];
    }
  }

  // Theme Settings
  bool _isDarkTheme = false; // Default to light (consistent with onboarding)

  bool get isDarkTheme => _isDarkTheme;

  ThemeMode get themeMode => _isDarkTheme ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme(bool val) {
    _isDarkTheme = val;
    notifyListeners();
  }
}
