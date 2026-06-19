class Profile {
  final String id;
  final String username;
  final String fullName;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final int followersCount;
  final int followingCount;
  final String? phone;
  final String? country;
  final String? division;
  final String? city;
  final String? village;
  final String? zip;
  final String? gender;
  final String? birthdate;
  final bool isPrivate;
  final String allowMentions;
  final bool filterAdult;
  final bool autoplayVideos;
  final bool isVerified;
  final bool verificationRequested;

  Profile({
    required this.id,
    required this.username,
    required this.fullName,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    this.followersCount = 0,
    this.followingCount = 0,
    this.phone,
    this.country,
    this.division,
    this.city,
    this.village,
    this.zip,
    this.gender,
    this.birthdate,
    this.isPrivate = false,
    this.allowMentions = 'everyone',
    this.filterAdult = true,
    this.autoplayVideos = true,
    this.isVerified = false,
    this.verificationRequested = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: (json['username'] as String?) ?? 'anonymous',
      fullName: (json['full_name'] as String?) ?? 'Anonymous User',
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      followersCount: (json['followers_count'] as int?) ?? 0,
      followingCount: (json['following_count'] as int?) ?? 0,
      phone: json['phone'] as String?,
      country: json['country'] as String?,
      division: json['division'] as String?,
      city: json['city'] as String?,
      village: json['village'] as String?,
      zip: json['zip'] as String?,
      gender: json['gender'] as String?,
      birthdate: json['birthdate'] as String?,
      isPrivate: json['is_private'] as bool? ?? false,
      allowMentions: json['allow_mentions'] as String? ?? 'everyone',
      filterAdult: json['filter_adult'] as bool? ?? true,
      autoplayVideos: json['autoplay_videos'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      verificationRequested: json['verification_requested'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'followers_count': followersCount,
      'following_count': followingCount,
      'phone': phone,
      'country': country,
      'division': division,
      'city': city,
      'village': village,
      'zip': zip,
      'gender': gender,
      'birthdate': birthdate,
      'is_private': isPrivate,
      'allow_mentions': allowMentions,
      'filter_adult': filterAdult,
      'autoplay_videos': autoplayVideos,
      'is_verified': isVerified,
      'verification_requested': verificationRequested,
    };
  }
}
