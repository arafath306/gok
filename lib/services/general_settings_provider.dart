import 'package:flutter/material.dart';

class GeneralSettingsProvider with ChangeNotifier {
  // Privacy State
  bool _isPrivateAccount = false;
  bool get isPrivateAccount => _isPrivateAccount;

  String _allowMentionsFrom = 'everyone'; // 'everyone', 'people_you_follow', 'no_one'
  String get allowMentionsFrom => _allowMentionsFrom;

  bool _filterAdultContent = true;
  bool get filterAdultContent => _filterAdultContent;

  bool _autoplayVideos = true;
  bool get autoplayVideos => _autoplayVideos;

  void updatePrivacy({
    bool? isPrivateAccount,
    String? allowMentionsFrom,
    bool? filterAdultContent,
    bool? autoplayVideos,
  }) {
    if (isPrivateAccount != null) _isPrivateAccount = isPrivateAccount;
    if (allowMentionsFrom != null) _allowMentionsFrom = allowMentionsFrom;
    if (filterAdultContent != null) _filterAdultContent = filterAdultContent;
    if (autoplayVideos != null) _autoplayVideos = autoplayVideos;
    notifyListeners();
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
  final List<Map<String, String>> _blockedAccounts = [
    {'id': 'b1', 'name': 'Spam Bot 01', 'username': 'spambot01', 'avatar': 'https://i.pravatar.cc/150?u=spam1'},
    {'id': 'b2', 'name': 'Ad Promoter', 'username': 'ad_promoter', 'avatar': 'https://i.pravatar.cc/150?u=ad'},
  ];
  List<Map<String, String>> get blockedAccounts => _blockedAccounts;

  void unblockAccount(String id) {
    _blockedAccounts.removeWhere((account) => account['id'] == id);
    notifyListeners();
  }

  void blockAccount(String name, String username, String avatar) {
    _blockedAccounts.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'username': username,
      'avatar': avatar,
    });
    notifyListeners();
  }

  // Muted Accounts State
  final List<Map<String, String>> _mutedAccounts = [
    {'id': 'm1', 'name': 'Annoying User', 'username': 'annoying_123', 'avatar': 'https://i.pravatar.cc/150?u=annoying'},
    {'id': 'm2', 'name': 'Meme Daily', 'username': 'memes_daily', 'avatar': 'https://i.pravatar.cc/150?u=meme'},
  ];
  List<Map<String, String>> get mutedAccounts => _mutedAccounts;

  void unmuteAccount(String id) {
    _mutedAccounts.removeWhere((account) => account['id'] == id);
    notifyListeners();
  }

  void muteAccount(String name, String username, String avatar) {
    _mutedAccounts.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'username': username,
      'avatar': avatar,
    });
    notifyListeners();
  }
}
