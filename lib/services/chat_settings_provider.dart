import 'package:flutter/material.dart';

enum DMPermission { everyone, followed, none }

class ChatSettingsProvider with ChangeNotifier {
  static final ChatSettingsProvider _instance = ChatSettingsProvider._internal();

  factory ChatSettingsProvider() {
    return _instance;
  }

  ChatSettingsProvider._internal();

  DMPermission _dmPermission = DMPermission.everyone;
  bool _notificationSounds = true;

  DMPermission get dmPermission => _dmPermission;
  bool get notificationSounds => _notificationSounds;

  void setDMPermission(DMPermission val) {
    _dmPermission = val;
    notifyListeners();
  }

  void setNotificationSounds(bool val) {
    _notificationSounds = val;
    notifyListeners();
  }
}
