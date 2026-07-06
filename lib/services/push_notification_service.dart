import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

// This function must be a top-level function for background execution.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Request Permission (Required for iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted push notification permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // 2. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Foreground Messages Listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }
    });

    // 4. Update Token in Supabase
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _syncToken();
      // Listen for token refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        _saveTokenToDatabase(newToken, user.id);
      });
    }

    _initialized = true;
  }

  Future<void> _syncToken() async {
    try {
      String? token;
      
      // APNS for iOS is required before fetching FCM token
      if (!kIsWeb && Platform.isIOS) {
        String? apnsToken = await _fcm.getAPNSToken();
        if (apnsToken != null) {
          token = await _fcm.getToken();
        } else {
          await Future<void>.delayed(const Duration(seconds: 3));
          apnsToken = await _fcm.getAPNSToken();
          if (apnsToken != null) token = await _fcm.getToken();
        }
      } else {
        token = await _fcm.getToken();
      }

      if (token != null) {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          await _saveTokenToDatabase(token, userId);
        }
      }
    } catch (e) {
      debugPrint("Error fetching FCM token: $e");
    }
  }

  Future<void> _saveTokenToDatabase(String token, String userId) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
      debugPrint("FCM token saved successfully");
    } catch (e) {
      debugPrint("Error saving FCM token to Supabase: $e");
    }
  }
}
