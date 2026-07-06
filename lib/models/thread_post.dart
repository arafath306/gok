import 'package:flutter/foundation.dart';
import 'profile.dart';
import 'poll_option.dart';
import 'music_track.dart';
import 'community.dart';

class ThreadPost {
  final String id;
  final String userId;
  final Profile author;
  final String content;
  final List<String>? imageUrls;
  final String? videoUrl;
  final int likesCount;
  final int repliesCount;
  final int repostsCount;
  final int savesCount;
  final int sharesCount;
  final String createdAt;
  final bool isLikedByMe;
  final String? reactionType;
  final bool isPinned;
  final bool muteNotifications;
  final bool hideFromProfile;
  final bool isHiddenFromMe;
  final int viewsCount;
  final String? communityId;
  final Community? community;

  final bool isRepost;
  final ThreadPost? repostedPost;
  final String? quoteText;

  // Poll Fields
  final List<PollOption>? pollOptions;
  final DateTime? pollExpiresAt;
  final bool hasVotedPoll;
  final String? votedOptionId;

  // Music Field
  final MusicTrack? musicTrack;

  ThreadPost({
    required this.id,
    required this.userId,
    required this.author,
    required this.content,
    this.imageUrls,
    this.videoUrl,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.repostsCount = 0,
    this.savesCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.communityId,
    this.community,
    required this.createdAt,
    this.isLikedByMe = false,
    this.reactionType,
    this.isPinned = false,
    this.muteNotifications = false,
    this.hideFromProfile = false,
    this.isHiddenFromMe = false,
    this.isRepost = false,
    this.repostedPost,
    this.quoteText,
    this.pollOptions,
    this.pollExpiresAt,
    this.hasVotedPoll = false,
    this.votedOptionId,
    this.musicTrack,
  });

  int get totalPollVotes {
    if (pollOptions == null) return 0;
    return pollOptions!.fold(0, (sum, option) => sum + option.votesCount);
  }

  bool get isPollExpired {
    if (pollExpiresAt == null) return false;
    return DateTime.now().isAfter(pollExpiresAt!);
  }

  static String formatRelativeTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'now';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'now';
    }
  }

  factory ThreadPost.fromJson(Map<String, dynamic> json, {String? currentUid}) {
    final authorMap = json['profiles'] as Map<String, dynamic>?;
    final authorProfile = authorMap != null 
        ? Profile.fromJson(authorMap) 
        : Profile(id: json['user_id'] ?? '', username: 'unknown', fullName: 'Unknown User');

    // Likes check logic
    final likesList = json['likes'] as List<dynamic>?;
    final isLiked = currentUid != null && likesList != null && 
        likesList.any((like) => like['user_id'] == currentUid);

    // Hidden visibility check logic
    final hidesList = json['thread_hides'] as List<dynamic>?;
    final isHidden = currentUid != null && hidesList != null &&
        hidesList.any((hide) => hide['user_id'] == currentUid);

    // Dynamic Image URLs mapping (Supabase stores it as text[] or string)
    List<String>? parsedImages;
    if (json['image_urls'] != null) {
      if (json['image_urls'] is List) {
        parsedImages = (json['image_urls'] as List).map((e) => e.toString()).toList();
      } else if (json['image_urls'] is String) {
        final str = json['image_urls'] as String;
        if (str.startsWith('{') && str.endsWith('}')) {
          parsedImages = str.substring(1, str.length - 1).split(',').map((e) => e.trim()).toList();
        } else {
          parsedImages = [str];
        }
      }
    }

    // Parse Poll Votes
    final votesList = json['poll_votes'] as List<dynamic>?;
    final isVoted = currentUid != null && votesList != null &&
        votesList.any((vote) => vote['user_id'] == currentUid);
    final votedOptId = isVoted
        ? votesList.firstWhere((vote) => vote['user_id'] == currentUid)['poll_option_id'] as String?
        : null;

    // Parse Poll Options
    List<PollOption>? parsedPollOptions;
    if (json['poll_options'] != null) {
      parsedPollOptions = (json['poll_options'] as List)
          .map((opt) => PollOption.fromJson(opt as Map<String, dynamic>, votesList: votesList))
          .toList();
    }

    final expiresAtStr = json['poll_expires_at'] as String?;
    final expiresAt = expiresAtStr != null ? DateTime.parse(expiresAtStr).toLocal() : null;

    // Parse Music Suffix from Content
    String cleanContent = json['content'] as String? ?? '';
    MusicTrack? parsedMusicTrack;
    if (cleanContent.contains('🎵DakMusic🎵')) {
      final parts = cleanContent.split('🎵DakMusic🎵');
      cleanContent = parts[0];
      if (parts.length > 1) {
        try {
          parsedMusicTrack = MusicTrack.fromJson(parts[1].trim());
        } catch (e) {
          debugPrint("Error parsing music track from post JSON: $e");
        }
      }
    }

    Community? parsedCommunity;
    if (json['communities'] != null) {
      parsedCommunity = Community.fromJson(json['communities'] as Map<String, dynamic>);
    }

    return ThreadPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      author: authorProfile,
      content: cleanContent,
      imageUrls: parsedImages,
      videoUrl: json['video_url'] as String?,
      likesCount: (json['likes_count'] as int?) ?? 0,
      repliesCount: (json['replies_count'] as int?) ?? 0,
      repostsCount: (json['reposts_count'] as int?) ?? 0,
      savesCount: (json['saves_count'] as int?) ?? 0,
      sharesCount: (json['shares_count'] as int?) ?? 0,
      viewsCount: (json['views_count'] as int?) ?? 0,
      communityId: json['community_id'] as String?,
      community: parsedCommunity,
      createdAt: formatRelativeTime(json['created_at'] as String?),
      isLikedByMe: isLiked,
      reactionType: isLiked ? '❤️' : null,
      isPinned: json['is_pinned'] as bool? ?? false,
      muteNotifications: json['mute_notifications'] as bool? ?? false,
      hideFromProfile: json['hide_from_profile'] as bool? ?? false,
      isHiddenFromMe: isHidden,
      isRepost: json['is_repost'] as bool? ?? false,
      repostedPost: json['reposted_post'] != null 
          ? ThreadPost.fromJson(json['reposted_post'] as Map<String, dynamic>, currentUid: currentUid)
          : null,
      quoteText: json['quote_text'] as String?,
      pollOptions: parsedPollOptions,
      pollExpiresAt: expiresAt,
      hasVotedPoll: isVoted,
      votedOptionId: votedOptId,
      musicTrack: parsedMusicTrack,
    );
  }

  ThreadPost copyWith({
    String? id,
    String? userId,
    Profile? author,
    String? content,
    List<String>? imageUrls,
    String? videoUrl,
    int? likesCount,
    int? repliesCount,
    int? repostsCount,
    int? savesCount,
    int? sharesCount,
    int? viewsCount,
    String? communityId,
    Community? community,
    String? createdAt,
    bool? isLikedByMe,
    String? reactionType,
    bool? isPinned,
    bool? muteNotifications,
    bool? hideFromProfile,
    bool? isHiddenFromMe,
    bool? isRepost,
    ThreadPost? repostedPost,
    String? quoteText,
    List<PollOption>? pollOptions,
    DateTime? pollExpiresAt,
    bool? hasVotedPoll,
    String? votedOptionId,
    MusicTrack? musicTrack,
  }) {
    return ThreadPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      author: author ?? this.author,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      repostsCount: repostsCount ?? this.repostsCount,
      savesCount: savesCount ?? this.savesCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      communityId: communityId ?? this.communityId,
      community: community ?? this.community,
      createdAt: createdAt ?? this.createdAt,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      reactionType: reactionType ?? this.reactionType,
      isPinned: isPinned ?? this.isPinned,
      muteNotifications: muteNotifications ?? this.muteNotifications,
      hideFromProfile: hideFromProfile ?? this.hideFromProfile,
      isHiddenFromMe: isHiddenFromMe ?? this.isHiddenFromMe,
      isRepost: isRepost ?? this.isRepost,
      repostedPost: repostedPost ?? this.repostedPost,
      quoteText: quoteText ?? this.quoteText,
      pollOptions: pollOptions ?? this.pollOptions,
      pollExpiresAt: pollExpiresAt ?? this.pollExpiresAt,
      hasVotedPoll: hasVotedPoll ?? this.hasVotedPoll,
      votedOptionId: votedOptionId ?? this.votedOptionId,
      musicTrack: musicTrack ?? this.musicTrack,
    );
  }
}

