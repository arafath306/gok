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
    };
  }
}
