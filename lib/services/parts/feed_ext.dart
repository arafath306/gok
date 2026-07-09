part of '../database_service.dart';

extension FeedExtension on DatabaseService {
  // --- Feed / Threads Operations ---

  Future<void> fetchFeed({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      updateState();
    }

    final result = await sl<GetFeedUseCase>()(silent: silent);
    result.fold(
      (failure) {
        if (!silent) {
          _isLoading = false;
        }
        updateState();
        debugPrint("Fetch feed error: ${failure.message}");
      },
      (entities) {
        _feed = entities.map((e) => _entityToModel(e)).toList();
        _updateCache(_feed);
        if (!silent) {
          _isLoading = false;
        }
        updateState();
      },
    );
  }

  Future<void> fetchMyThreads() async {
    if (_currentUid.isEmpty) return;
    final result = await sl<IFeedRepository>().fetchMyThreads();
    result.fold(
      (failure) => debugPrint("Fetch my threads error: ${failure.message}"),
      (entities) {
        _myThreads = entities.map((e) => _entityToModel(e)).toList();
        _updateCache(_myThreads);
        updateState();
      },
    );
  }

  Future<bool> createThread(
    String content, {
    List<String>? imageUrls,
    String? videoUrl,
    String? audioUrl,
    String? audience,
    List<String>? pollOptions,
    Duration? pollDuration,
    String? communityId,
    bool isSubscriberOnly = false,
  }) async {
    DateTime? pollExpiresAt;
    if (pollDuration != null) {
      pollExpiresAt = DateTime.now().add(pollDuration);
    }
    final result = await sl<CreateThreadUseCase>()(
      content,
      imageUrls: imageUrls,
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      audience: audience,
      pollOptions: pollOptions,
      pollExpiresAt: pollExpiresAt,
      communityId: communityId,
      isSubscriberOnly: isSubscriberOnly,
    );
    return result.fold(
      (failure) {
        debugPrint("Create thread error: ${failure.message}");
        return false;
      },
      (success) async {
        await fetchFeed(silent: true);
        await fetchAIFeed(silent: true);
        await fetchMyThreads();
        return success;
      },
    );
  }


  Future<void> votePoll(String threadId, String optionId) async {
    if (_currentUid.isEmpty) return;
    
    // Play haptic/pop sound
    sl<PlaySoundUseCase>().call(SoundType.pop);

    // Optimistically update local state so the transition is instant
    final cached = _postsCache[threadId];
    if (cached != null && !cached.hasVotedPoll && !cached.isPollExpired) {
      // Find the option and increment its vote count
      final updatedOptions = cached.pollOptions?.map((opt) {
        if (opt.id == optionId) {
          return opt.copyWith(votesCount: opt.votesCount + 1);
        }
        return opt;
      }).toList();
      
      final updatedPost = cached.copyWith(
        hasVotedPoll: true,
        votedOptionId: optionId,
        pollOptions: updatedOptions,
      );
      
      _postsCache[threadId] = updatedPost;
      
      void updateInList(List<ThreadPost> list) {
        final idx = list.indexWhere((p) => p.id == threadId);
        if (idx != -1) {
          list[idx] = updatedPost;
        }
      }
      updateInList(_feed);
      updateInList(_myThreads);
      updateInList(_personalizedFeed);
      updateInList(_savedPosts);
      
      updateState();
    }

    try {
      await _supabase.from('poll_votes').insert({
        'user_id': _currentUid,
        'thread_id': threadId,
        'poll_option_id': optionId,
      });
      
      logUserInteraction(threadId, 'vote');
    } catch (e) {
      debugPrint('Error casting vote: $e');
      // Rollback on failure
      await _reloadThread(threadId);
    }
  }

}
