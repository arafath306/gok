import 'profile.dart';

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
  final String createdAt;
  final bool isLikedByMe;
  final String? reactionType;

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
    required this.createdAt,
    this.isLikedByMe = false,
    this.reactionType,
  });

  static String _formatRelativeTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'এখনই';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'এখনই';
      if (diff.inMinutes < 60) return '${diff.inMinutes}মি';
      if (diff.inHours < 24) return '${diff.inHours}ঘ';
      if (diff.inDays < 7) return '${diff.inDays}দ';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'এখনই';
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

    // Dynamic Image URLs mapping (Supabase stores it as text[] or string)
    List<String>? parsedImages;
    if (json['image_urls'] != null) {
      if (json['image_urls'] is List) {
        parsedImages = (json['image_urls'] as List).map((e) => e.toString()).toList();
      } else if (json['image_urls'] is String) {
        // sometimes returned as a string literal or comma separated values
        final str = json['image_urls'] as String;
        if (str.startsWith('{') && str.endsWith('}')) {
          parsedImages = str.substring(1, str.length - 1).split(',').map((e) => e.trim()).toList();
        } else {
          parsedImages = [str];
        }
      }
    }

    return ThreadPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      author: authorProfile,
      content: json['content'] as String,
      imageUrls: parsedImages,
      videoUrl: json['video_url'] as String?,
      likesCount: (json['likes_count'] as int?) ?? 0,
      repliesCount: (json['replies_count'] as int?) ?? 0,
      repostsCount: (json['reposts_count'] as int?) ?? 0,
      createdAt: _formatRelativeTime(json['created_at'] as String?),
      isLikedByMe: isLiked,
      reactionType: isLiked ? '❤️' : null,
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
    String? createdAt,
    bool? isLikedByMe,
    String? reactionType,
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
      createdAt: createdAt ?? this.createdAt,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      reactionType: reactionType ?? this.reactionType,
    );
  }
}
