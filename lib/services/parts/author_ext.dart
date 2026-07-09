part of '../database_service.dart';

extension AuthorExtension on DatabaseService {
  // --- Author Post Operations ---

  Future<bool> togglePinPost(String threadId, bool isPinned) async {
    final result = await sl<IFeedRepository>().togglePinPost(threadId, isPinned);
    return result.fold(
      (failure) {
        debugPrint("Toggle pin post error: ${failure.message}");
        return false;
      },
      (success) {
        if (success) {
          // Update cache
          final cached = _postsCache[threadId];
          if (cached != null) {
            _postsCache[threadId] = cached.copyWith(isPinned: isPinned);
          }

          // Update local feed
          final feedIdx = _feed.indexWhere((p) => p.id == threadId);
          if (feedIdx != -1) {
            _feed[feedIdx] = _feed[feedIdx].copyWith(isPinned: isPinned);
          }
          // Update local myThreads
          final myIdx = _myThreads.indexWhere((p) => p.id == threadId);
          if (myIdx != -1) {
            _myThreads[myIdx] = _myThreads[myIdx].copyWith(isPinned: isPinned);
            _myThreads.sort((a, b) {
              if (a.isPinned && !b.isPinned) return -1;
              if (!a.isPinned && b.isPinned) return 1;
              return 0;
            });
          }
          updateState();
        }
        return success;
      },
    );
  }

  Future<bool> toggleMutePostNotifications(String threadId, bool mute) async {
    final result = await sl<IFeedRepository>().toggleMutePostNotifications(threadId, mute);
    return result.fold(
      (failure) {
        debugPrint("Toggle mute notifications error: ${failure.message}");
        return false;
      },
      (success) {
        if (success) {
          // Update cache
          final cached = _postsCache[threadId];
          if (cached != null) {
            _postsCache[threadId] = cached.copyWith(muteNotifications: mute);
          }

          final feedIdx = _feed.indexWhere((p) => p.id == threadId);
          if (feedIdx != -1) {
            _feed[feedIdx] = _feed[feedIdx].copyWith(muteNotifications: mute);
          }
          final myIdx = _myThreads.indexWhere((p) => p.id == threadId);
          if (myIdx != -1) {
            _myThreads[myIdx] = _myThreads[myIdx].copyWith(muteNotifications: mute);
          }
          updateState();
        }
        return success;
      },
    );
  }

  Future<bool> toggleHidePostFromProfile(String threadId, bool hide) async {
    final result = await sl<IFeedRepository>().toggleHidePostFromProfile(threadId, hide);
    return result.fold(
      (failure) {
        debugPrint("Toggle hide from profile error: ${failure.message}");
        return false;
      },
      (success) {
        if (success) {
          // Update cache
          final cached = _postsCache[threadId];
          if (cached != null) {
            _postsCache[threadId] = cached.copyWith(hideFromProfile: hide);
          }

          final feedIdx = _feed.indexWhere((p) => p.id == threadId);
          if (feedIdx != -1) {
            _feed[feedIdx] = _feed[feedIdx].copyWith(hideFromProfile: hide);
          }
          final myIdx = _myThreads.indexWhere((p) => p.id == threadId);
          if (myIdx != -1) {
            _myThreads[myIdx] = _myThreads[myIdx].copyWith(hideFromProfile: hide);
          }
          updateState();
        }
        return success;
      },
    );
  }

  Future<bool> editPostContent(String threadId, String content, {List<String>? imageUrls}) async {
    if (_currentUid.isEmpty) return false;
    try {
      final Map<String, dynamic> updateData = {
        'content': content,
      };
      if (imageUrls != null) {
        updateData['image_urls'] = imageUrls;
      }
      await _supabase.from('threads').update(updateData).eq('id', threadId);
      
      // Update cache
      final cached = _postsCache[threadId];
      if (cached != null) {
        _postsCache[threadId] = cached.copyWith(
          content: content,
          imageUrls: imageUrls ?? cached.imageUrls,
        );
      }

      final feedIdx = _feed.indexWhere((p) => p.id == threadId);
      if (feedIdx != -1) {
        _feed[feedIdx] = _feed[feedIdx].copyWith(
          content: content,
          imageUrls: imageUrls ?? _feed[feedIdx].imageUrls,
        );
      }
      final myIdx = _myThreads.indexWhere((p) => p.id == threadId);
      if (myIdx != -1) {
        _myThreads[myIdx] = _myThreads[myIdx].copyWith(
          content: content,
          imageUrls: imageUrls ?? _myThreads[myIdx].imageUrls,
        );
      }
      updateState();
      return true;
    } catch (e) {
      debugPrint("Edit post content error: $e");
      return false;
    }
  }

  Future<bool> deletePost(String threadId) async {
    if (_currentUid.isEmpty) return false;
    try {
      await _supabase.from('threads').delete().eq('id', threadId);
      
      _feed.removeWhere((p) => p.id == threadId);
      _myThreads.removeWhere((p) => p.id == threadId);
      _deletedPostIds.add(threadId);
      _postsCache.remove(threadId);
      updateState();
      return true;
    } catch (e) {
      debugPrint("Delete post error: $e");
      return false;
    }
  }

  Future<List<String>> fetchThreadHides(String threadId) async {
    try {
      final response = await _supabase
          .from('thread_hides')
          .select('user_id')
          .eq('thread_id', threadId);
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => json['user_id'] as String).toList();
    } catch (e) {
      debugPrint("Fetch thread hides error: $e");
      return [];
    }
  }

  Future<bool> updateThreadHides(String threadId, List<String> targetUserIds) async {
    if (_currentUid.isEmpty) return false;
    try {
      // Delete existing hides
      await _supabase.from('thread_hides').delete().eq('thread_id', threadId);
      
      // Insert new ones
      if (targetUserIds.isNotEmpty) {
        final inserts = targetUserIds.map((uid) => {
          'thread_id': threadId,
          'user_id': uid,
        }).toList();
        await _supabase.from('thread_hides').insert(inserts);
      }
      
      // Refresh feed so visibility filters take effect
      fetchFeed(silent: true);
      return true;
    } catch (e) {
      debugPrint("Update thread hides error: $e");
      return false;
    }
  }

  Future<List<Profile>> fetchFollowingProfiles() async {
    if (_currentUid.isEmpty || _followingIds.isEmpty) return [];
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', _followingIds.toList());
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Profile.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Fetch following profiles error: $e");
      return [];
    }
  }

}
