import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingItem {
  final String id;
  final String title;
  final IconData icon;
  final bool hasFromOption;

  bool inApp;
  bool push;
  String from; // 'everyone', 'people_you_follow', 'off'

  NotificationSettingItem({
    required this.id,
    required this.title,
    required this.icon,
    this.hasFromOption = true,
    this.inApp = true,
    this.push = true,
    this.from = 'everyone',
  });

  String get subtext {
    if (hasFromOption && from == 'off') {
      return 'Off';
    }
    final List<String> parts = [];
    if (inApp) parts.add('In-app');
    if (push) parts.add('push');
    
    if (parts.isEmpty) return 'Off';

    if (hasFromOption) {
      if (from == 'everyone') {
        parts.add('everyone');
      } else if (from == 'people_you_follow') {
        parts.add('people you follow');
      }
    }
    
    // Format: first word capitalized, rest lowercase
    final String combined = parts.join(', ');
    if (combined.isEmpty) return 'Off';
    return combined[0].toUpperCase() + combined.substring(1);
  }
}

class NotificationSettingsProvider with ChangeNotifier {
  static final NotificationSettingsProvider _instance = NotificationSettingsProvider._internal();

  factory NotificationSettingsProvider() {
    return _instance;
  }

  NotificationSettingsProvider._internal() {
    _loadFromPrefs();
  }

  final Map<String, NotificationSettingItem> _settings = {
    'likes': NotificationSettingItem(
      id: 'likes',
      title: 'Likes',
      icon: Icons.favorite_border,
      inApp: true,
      push: true,
      from: 'everyone',
    ),
    'new_followers': NotificationSettingItem(
      id: 'new_followers',
      title: 'New followers',
      icon: Icons.person_add_outlined,
      inApp: true,
      push: false,
      from: 'everyone',
    ),
    'replies': NotificationSettingItem(
      id: 'replies',
      title: 'Replies',
      icon: Icons.chat_bubble_outline,
      inApp: true,
      push: true,
      from: 'everyone',
    ),
    'mentions': NotificationSettingItem(
      id: 'mentions',
      title: 'Mentions',
      icon: Icons.alternate_email,
      inApp: true,
      push: true,
      from: 'everyone',
    ),
    'quotes': NotificationSettingItem(
      id: 'quotes',
      title: 'Quotes',
      icon: Icons.format_quote,
      inApp: true,
      push: true,
      from: 'everyone',
    ),
    'reposts': NotificationSettingItem(
      id: 'reposts',
      title: 'Reposts',
      icon: Icons.repeat,
      inApp: true,
      push: true,
      from: 'everyone',
    ),
    'activity_from_others': NotificationSettingItem(
      id: 'activity_from_others',
      title: 'Activity from others',
      icon: Icons.notifications_none,
      inApp: true,
      push: true,
      hasFromOption: false,
    ),
    'likes_reposts': NotificationSettingItem(
      id: 'likes_reposts',
      title: 'Likes of your reposts',
      icon: Icons.favorite_border,
      inApp: true,
      push: true,
      from: 'everyone',
    ),
    'reposts_reposts': NotificationSettingItem(
      id: 'reposts_reposts',
      title: 'Reposts of your reposts',
      icon: Icons.repeat,
      inApp: true,
      push: true,
      from: 'everyone',
    ),
    'everything_else': NotificationSettingItem(
      id: 'everything_else',
      title: 'Everything else',
      icon: Icons.widgets_outlined,
      inApp: true,
      push: true,
      hasFromOption: false,
    ),
  };

  List<NotificationSettingItem> get settingsList => _settings.values.toList();

  NotificationSettingItem? getSetting(String id) => _settings[id];

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _settings.keys) {
        final item = _settings[key]!;
        item.inApp = prefs.getBool('notif_${key}_inApp') ?? item.inApp;
        item.push = prefs.getBool('notif_${key}_push') ?? item.push;
        item.from = prefs.getString('notif_${key}_from') ?? item.from;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  Future<void> updateSetting({
    required String id,
    bool? inApp,
    bool? push,
    String? from,
  }) async {
    final item = _settings[id];
    if (item != null) {
      if (inApp != null) item.inApp = inApp;
      if (push != null) item.push = push;
      if (from != null) item.from = from;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        if (inApp != null) await prefs.setBool('notif_${id}_inApp', inApp);
        if (push != null) await prefs.setBool('notif_${id}_push', push);
        if (from != null) await prefs.setString('notif_${id}_from', from);
      } catch (e) {
        debugPrint('Error saving notification setting $id: $e');
      }
    }
  }
}
