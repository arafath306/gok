import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  RealtimeChannel? _presenceChannel;
  String? _currentUserId;
  String? _currentPage;
  bool _isInitialized = false;

  void initialize(String userId) {
    if (_isInitialized && _currentUserId == userId) return;
    
    _currentUserId = userId;
    _isInitialized = true;
    
    // Connect to the online-users channel
    _presenceChannel = Supabase.instance.client.channel('online-users');
    
    _presenceChannel?.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        debugPrint('[PresenceService] Subscribed to presence channel');
        _broadcastPresence();
      }
    });
  }

  void updatePage(String pageName) {
    if (_currentPage == pageName) return; // Ignore duplicate updates
    _currentPage = pageName;
    _broadcastPresence();
  }

  void _broadcastPresence() async {
    if (_presenceChannel == null || _currentUserId == null || _currentPage == null) return;
    
    try {
      await _presenceChannel?.track({
        'user_id': _currentUserId,
        'current_page': _currentPage,
        'online_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('[PresenceService] Broadcasted presence: $_currentPage');
    } catch (e) {
      debugPrint('[PresenceService] Error broadcasting presence: $e');
    }
  }

  void dispose() {
    _presenceChannel?.unsubscribe();
    _presenceChannel = null;
    _isInitialized = false;
    _currentUserId = null;
  }
}
