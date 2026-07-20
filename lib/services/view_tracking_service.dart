import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewTrackingService with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  // Keep track of posts viewed in this session so we don't count them again
  final Set<String> _viewedInSession = {};
  
  // Queue of views waiting to be sent to the database
  final Set<String> _pendingViews = {};
  
  Timer? _timer;

  ViewTrackingService() {
    _startTimer();
  }

  void _startTimer() {
    // Process the queue every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _flushViews();
    });
  }

  void trackView(String postId) {
    if (_viewedInSession.contains(postId)) return;
    
    _viewedInSession.add(postId);
    _pendingViews.add(postId);
  }

  Future<void> _flushViews() async {
    if (_pendingViews.isEmpty) return;

    // Create a copy of the queue to process, then clear the original
    final Set<String> viewsToProcess = Set.from(_pendingViews);
    _pendingViews.clear();

    try {
      // Send multiple views asynchronously.
      // Supabase does not have a built-in multiple increment RPC without custom SQL,
      // so we use Future.wait to execute them in parallel from the background.
      await Future.wait(
        viewsToProcess.map(
          (id) => _supabase.rpc('increment_thread_views', params: {'thread_id': id})
        )
      );
      debugPrint('[ViewTrackingService] Successfully processed ${viewsToProcess.length} views.');
    } catch (e) {
      debugPrint('[ViewTrackingService] Error flushing views: $e');
      // In a robust implementation, you might want to add them back to _pendingViews if it failed,
      // but for view counts, it's usually acceptable to drop them on failure to prevent memory leaks.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flushViews(); // Attempt to flush any remaining before disposing
    super.dispose();
  }
}
