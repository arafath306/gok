part of '../database_service.dart';

extension LikesExtension on DatabaseService {
  // --- Likes CRUD ---

  Future<void> toggleLike(String threadId, bool shouldLike, {String? reactionType}) async {
    if (_currentUid.isEmpty) return;

    if (shouldLike) {
      sl<PlaySoundUseCase>().call(SoundType.pop);
    }

    // Optimistic update cache
    final cached = _postsCache[threadId];
    if (cached != null) {
      final int countDelta = shouldLike 
          ? (cached.isLikedByMe ? 0 : 1) 
          : -1;
      _postsCache[threadId] = cached.copyWith(
        likesCount: cached.likesCount + countDelta,
        isLikedByMe: shouldLike,
        reactionType: shouldLike ? (reactionType ?? '❤️') : null,
      );
    }

    // Local state optimistic update
    final feedIndex = _feed.indexWhere((p) => p.id == threadId);
    if (feedIndex != -1) {
      final post = _feed[feedIndex];
      final int countDelta = shouldLike 
          ? (post.isLikedByMe ? 0 : 1) 
          : -1;
      _feed[feedIndex] = post.copyWith(
        likesCount: post.likesCount + countDelta,
        isLikedByMe: shouldLike,
        reactionType: shouldLike ? (reactionType ?? '❤️') : null,
      );
      updateState();
    }

    final myThreadsIndex = _myThreads.indexWhere((p) => p.id == threadId);
    if (myThreadsIndex != -1) {
      final post = _myThreads[myThreadsIndex];
      final int countDelta = shouldLike 
          ? (post.isLikedByMe ? 0 : 1) 
          : -1;
      _myThreads[myThreadsIndex] = post.copyWith(
        likesCount: post.likesCount + countDelta,
        isLikedByMe: shouldLike,
        reactionType: shouldLike ? (reactionType ?? '❤️') : null,
      );
      updateState();
    }

    final aiFeedIndex = _personalizedFeed.indexWhere((p) => p.id == threadId);
    if (aiFeedIndex != -1) {
      final post = _personalizedFeed[aiFeedIndex];
      final int countDelta = shouldLike 
          ? (post.isLikedByMe ? 0 : 1) 
          : -1;
      _personalizedFeed[aiFeedIndex] = post.copyWith(
        likesCount: post.likesCount + countDelta,
        isLikedByMe: shouldLike,
        reactionType: shouldLike ? (reactionType ?? '❤️') : null,
      );
      updateState();
    }

    final result = await sl<ToggleLikeUseCase>()(threadId, shouldLike);
    result.fold(
      (failure) {
        debugPrint("Toggle like error: ${failure.message}");
        // Optimistic rollback is not strictly enforced in legacy flow, but error is caught
      },
      (_) {
        logUserInteraction(threadId, shouldLike ? 'like' : 'scroll_away');
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchThreadReactors(String threadId) async {
    final result = await sl<IFeedRepository>().fetchThreadReactors(threadId);
    return result.fold(
      (failure) {
        debugPrint("Fetch thread reactors error: ${failure.message}");
        return [];
      },
      (reactors) {
        final List<Map<String, dynamic>> reactorList = [];
        for (final item in reactors) {
          reactorList.add({
            'id': item['id'],
            'name': item['name'],
            'handle': item['handle'],
            'avatar': item['avatar'],
            'isFollowing': isFollowingUser(item['id'] as String),
          });
        }

        // If current user liked it, make sure they are in the list
        final feedIndex = _feed.indexWhere((p) => p.id == threadId);
        final isLikedByMe = feedIndex != -1 ? _feed[feedIndex].isLikedByMe : false;
        if (isLikedByMe && _myProfile != null) {
          if (!reactorList.any((r) => r['id'] == _myProfile!.id)) {
            reactorList.insert(0, {
              'id': _myProfile!.id,
              'name': _myProfile!.fullName,
              'handle': '@${_myProfile!.username}',
              'avatar': _myProfile!.avatarUrl ?? '',
              'isFollowing': false,
            });
          }
        }
        return reactorList;
      },
    );
  }

  Future<List<ThreadPost>> fetchUserThreads(String userId) async {
    final result = await sl<IFeedRepository>().fetchUserThreads(userId);
    return result.fold(
      (failure) {
        debugPrint("Fetch user threads error: ${failure.message}");
        return [];
      },
      (entities) {
        final posts = entities.map((e) => _entityToModel(e)).toList();
        
        // Filter out posts hidden from profile or hidden from me
        posts.removeWhere((post) {
          if (post.hideFromProfile && post.userId != _currentUid) {
            return true;
          }
          if (_blockedUserIds.contains(post.userId) || _mutedUserIds.contains(post.userId)) {
            return true;
          }
          if (post.isHiddenFromMe) {
            return true;
          }
          return false;
        });

        // Sort pinned threads to the top
        posts.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return 0;
        });

        _updateCache(posts);
        return posts;
      },
    );
  }

  Future<List<ThreadPost>> fetchUserRepliedThreads(String userId) async {
    if (userId.startsWith('mock-')) {
      return [];
    }
    final result = await sl<IFeedRepository>().fetchUserRepliedThreads(userId);
    return result.fold(
      (failure) {
        debugPrint("Fetch user replied threads error: ${failure.message}");
        return [];
      },
      (entities) {
        final posts = entities.map((e) => _entityToModel(e)).toList();
        
        // Filter out hidden posts
        posts.removeWhere((post) {
          if (post.hideFromProfile && post.userId != _currentUid) {
            return true;
          }
          if (_blockedUserIds.contains(post.userId) || _mutedUserIds.contains(post.userId)) {
            return true;
          }
          if (post.isHiddenFromMe) {
            return true;
          }
          return false;
        });

        _updateCache(posts);
        return posts;
      },
    );
  }

}
