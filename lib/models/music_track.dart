import 'dart:convert';

class MusicTrack {
  final String trackId;
  final String trackName;
  final String artistName;
  final String previewUrl;
  final String artworkUrl;

  MusicTrack({
    required this.trackId,
    required this.trackName,
    required this.artistName,
    required this.previewUrl,
    required this.artworkUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'trackId': trackId,
      'trackName': trackName,
      'previewUrl': previewUrl,
      'artworkUrl': artworkUrl,
    };
  }

  factory MusicTrack.fromMap(Map<String, dynamic> map) {
    return MusicTrack(
      trackId: map['trackId']?.toString() ?? '',
      trackName: map['trackName']?.toString() ?? '',
      artistName: map['artistName']?.toString() ?? '',
      previewUrl: map['previewUrl']?.toString() ?? '',
      artworkUrl: map['artworkUrl']?.toString() ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory MusicTrack.fromJson(String source) => MusicTrack.fromMap(json.decode(source));
}
