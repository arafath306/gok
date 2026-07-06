class Community {
  final String id;
  final String name;
  final String? handle;
  final String? topic;
  final String? description;
  final String? avatarUrl;
  final String? bannerUrl;
  final String privacy;
  final String ownerId;
  final int memberCount;
  final bool isVerified;
  final String createdAt;
  final String? myRole;

  Community({
    required this.id,
    required this.name,
    this.handle,
    this.topic,
    this.description,
    this.avatarUrl,
    this.bannerUrl,
    this.privacy = 'public',
    required this.ownerId,
    this.memberCount = 1,
    this.isVerified = false,
    required this.createdAt,
    this.myRole,
  });

  factory Community.fromJson(Map<String, dynamic> json, {String? myRole}) {
    return Community(
      id: json['id'] as String,
      name: json['name'] as String,
      handle: json['handle'] as String?,
      topic: json['topic'] as String?,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      privacy: json['privacy'] as String? ?? 'public',
      ownerId: json['owner_id'] as String,
      memberCount: (json['member_count'] as int?) ?? 1,
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] as String,
      myRole: myRole,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'handle': handle,
      'topic': topic,
      'description': description,
      'avatar_url': avatarUrl,
      'banner_url': bannerUrl,
      'privacy': privacy,
      'owner_id': ownerId,
      'member_count': memberCount,
      'is_verified': isVerified,
      'created_at': createdAt,
    };
  }

  Community copyWith({
    String? id,
    String? name,
    String? handle,
    String? topic,
    String? description,
    String? avatarUrl,
    String? bannerUrl,
    String? privacy,
    String? ownerId,
    int? memberCount,
    bool? isVerified,
    String? createdAt,
    String? myRole,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      privacy: privacy ?? this.privacy,
      ownerId: ownerId ?? this.ownerId,
      memberCount: memberCount ?? this.memberCount,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      myRole: myRole ?? this.myRole,
    );
  }
}
