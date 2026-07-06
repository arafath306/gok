import 'dart:convert';
import 'music_track.dart';

class DraftPost {
  final String id;
  final String content;
  final List<String> imagePaths;
  final String? videoUrl;
  final String audience;
  final String? location;
  final List<String>? pollOptions;
  final int? pollDurationHours;
  final DateTime updatedAt;
  final MusicTrack? musicTrack;

  DraftPost({
    required this.id,
    required this.content,
    this.imagePaths = const [],
    this.videoUrl,
    required this.audience,
    this.location,
    this.pollOptions,
    this.pollDurationHours,
    required this.updatedAt,
    this.musicTrack,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'imagePaths': imagePaths,
      'videoUrl': videoUrl,
      'audience': audience,
      'location': location,
      'pollOptions': pollOptions,
      'pollDurationHours': pollDurationHours,
      'updatedAt': updatedAt.toIso8601String(),
      'musicTrack': musicTrack?.toMap(),
    };
  }

  factory DraftPost.fromMap(Map<String, dynamic> map) {
    return DraftPost(
      id: map['id'],
      content: map['content'] ?? '',
      imagePaths: List<String>.from(map['imagePaths'] ?? []),
      videoUrl: map['videoUrl'],
      audience: map['audience'] ?? 'Public',
      location: map['location'],
      pollOptions: map['pollOptions'] != null ? List<String>.from(map['pollOptions']) : null,
      pollDurationHours: map['pollDurationHours'],
      updatedAt: DateTime.parse(map['updatedAt']),
      musicTrack: map['musicTrack'] != null ? MusicTrack.fromMap(map['musicTrack']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory DraftPost.fromJson(String source) => DraftPost.fromMap(json.decode(source));
}

