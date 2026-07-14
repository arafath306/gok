import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MonetizationController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool isEnabledGlobally = false;
  
  bool isLoadingDashboard = true;
  Map<String, dynamic>? creatorSettings;
  int activeSubscribers = 0;
  
  List<String> mySubscribedCreatorIds = [];

  bool isSubscribedTo(String creatorId) {
    return mySubscribedCreatorIds.contains(creatorId);
  }
  
  Future<void> fetchGlobalStatus({String? uid, String? badgeType}) async {
    try {
      final res = await _supabase.from('system_settings').select('value').eq('key', 'enable_monetization').maybeSingle();
      if (res != null) {
        final val = res['value'] as String?;
        bool isEnabled = false;
        
        if (val != null) {
          try {
            final parsed = jsonDecode(val);
            if (parsed is Map) {
              final access = parsed['access'];
              if (access == 'global') {
                isEnabled = true;
              } else if (access == 'verified' && badgeType != null && badgeType != 'none') {
                isEnabled = true;
              } else if (access == 'specific') {
                final users = parsed['users'];
                if (users is List && uid != null && users.contains(uid)) {
                  isEnabled = true;
                }
              }
            }
          } catch (e) {
            isEnabled = val == 'true'; // Fallback
          }
        }
        
        isEnabledGlobally = isEnabled;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching monetization global status: $e");
    }
  }

  Future<void> fetchCreatorDashboard(String userId) async {
    isLoadingDashboard = true;
    notifyListeners();
    try {
      // Fetch settings
      final res = await _supabase.from('creator_settings').select().eq('creator_id', userId).maybeSingle();
      creatorSettings = res;
      
      // Fetch subscribers count
      final subs = await _supabase.from('creator_subscriptions').select('id').eq('creator_id', userId).eq('status', 'active');
      activeSubscribers = (subs as List).length;
    } catch (e) {
      debugPrint("Error fetching creator dashboard: $e");
    } finally {
      isLoadingDashboard = false;
      notifyListeners();
    }
  }

  Future<void> fetchMySubscriptions(String myUserId) async {
    try {
      final subs = await _supabase
          .from('creator_subscriptions')
          .select('creator_id')
          .eq('subscriber_id', myUserId)
          .eq('status', 'active');
      
      mySubscribedCreatorIds = (subs as List).map((e) => e['creator_id'] as String).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching my subscriptions: $e");
    }
  }

  Future<void> saveCreatorPrice(String userId, double newPrice) async {
    try {
      await _supabase.from('creator_settings').upsert({
        'creator_id': userId,
        'monthly_price': newPrice,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await fetchCreatorDashboard(userId);
    } catch (e) {
      debugPrint("Error saving price: $e");
      rethrow;
    }
  }

  Future<void> submitSubscription(String subscriberId, String creatorId, String bkashSender, String trxId, double planPrice) async {
    try {
      await _supabase.from('creator_subscriptions').insert({
        'subscriber_id': subscriberId,
        'creator_id': creatorId,
        'bkash_sender': bkashSender,
        'bkash_trx_id': trxId,
        'status': 'pending',
        'plan_price': planPrice,
      });
    } catch (e) {
      debugPrint("Error submitting subscription: $e");
      rethrow;
    }
  }
}
