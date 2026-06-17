import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DMPermission { everyone, followed, none }

class ChatSettingsProvider with ChangeNotifier {
  static final ChatSettingsProvider _instance = ChatSettingsProvider._internal();

  factory ChatSettingsProvider() {
    return _instance;
  }

  ChatSettingsProvider._internal() {
    _loadFromPrefs();
  }

  DMPermission _dmPermission = DMPermission.everyone;
  bool _notificationSounds = true;

  DMPermission get dmPermission => _dmPermission;
  bool get notificationSounds => _notificationSounds;

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dmIndex = prefs.getInt('chat_dm_permission');
      if (dmIndex != null) {
        _dmPermission = DMPermission.values[dmIndex];
      }
      _notificationSounds = prefs.getBool('chat_notification_sounds') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading chat settings: $e');
    }
  }

  Future<void> setDMPermission(DMPermission val) async {
    _dmPermission = val;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('chat_dm_permission', val.index);
    } catch (e) {
      debugPrint('Error saving chat dm permission: $e');
    }
  }

  Future<void> setNotificationSounds(bool val) async {
    _notificationSounds = val;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('chat_notification_sounds', val);
    } catch (e) {
      debugPrint('Error saving chat notification sounds: $e');
    }
  }
}
