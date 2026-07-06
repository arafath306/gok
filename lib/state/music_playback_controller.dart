import 'package:flutter/widgets.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/music_track.dart';

/// Manages music playback globally.
/// Visibility-based autoplay: whichever visible post has the highest
/// visibility fraction gets priority. When a post scrolls off screen
/// it is paused automatically.
class MusicPlaybackController with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentTrackId;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _autoplayMusic = true;
  bool get autoplayMusic => _autoplayMusic;

  // Maps postId -> (visibilityFraction, MusicTrack)
  final Map<String, _VisiblePost> _visiblePosts = {};

  MusicPlaybackController() {
    _loadAutoplaySetting();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });
    _audioPlayer.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
    });
    _audioPlayer.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _position = Duration.zero;
      notifyListeners();
    });
  }

  Future<void> _loadAutoplaySetting() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoplayMusic = prefs.getBool('autoplay_music') ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setAutoplayMusic(bool value) async {
    _autoplayMusic = value;
    notifyListeners();
    if (!value) {
      // Stop playing if user disables autoplay
      await stop();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autoplay_music', value);
    } catch (_) {}
  }

  /// Called by VisibilityDetector when a post's visibility changes.
  /// [visibilityFraction] is between 0.0 (hidden) and 1.0 (fully visible).
  void onPostVisibilityChanged(
      String postId, MusicTrack track, double visibilityFraction) {
    if (!_autoplayMusic) return;

    if (visibilityFraction > 0.0) {
      _visiblePosts[postId] = _VisiblePost(
        postId: postId,
        track: track,
        fraction: visibilityFraction,
      );
    } else {
      _visiblePosts.remove(postId);
    }

    _evaluateBestPost();
  }

  void _evaluateBestPost() {
    if (_visiblePosts.isEmpty) {
      // Nothing visible – pause
      if (_isPlaying) {
        _audioPlayer.pause();
      }
      return;
    }

    // Find the post with the highest visibility fraction
    _VisiblePost? best;
    for (final vp in _visiblePosts.values) {
      if (best == null || vp.fraction > best.fraction) {
        best = vp;
      }
    }

    if (best == null) return;

    final bestTrackId = best.track.trackId;

    if (_currentTrackId == bestTrackId) {
      // Same track: resume if paused
      if (!_isPlaying) {
        _audioPlayer.resume();
      }
    } else {
      // Different best post: switch to it
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _audioPlayer.stop().then((_) {
          _currentTrackId = bestTrackId;
          _audioPlayer.play(UrlSource(best!.track.previewUrl));
          notifyListeners();
        });
      });
    }
  }

  String? get currentTrackId => _currentTrackId;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;

  /// Manual tap play/pause toggle.
  Future<void> play(String trackId, String url) async {
    if (_currentTrackId == trackId) {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(url));
      }
    } else {
      await _audioPlayer.stop();
      _currentTrackId = trackId;
      await _audioPlayer.play(UrlSource(url));
    }
    notifyListeners();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentTrackId = null;
    _isPlaying = false;
    _position = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

class _VisiblePost {
  final String postId;
  final MusicTrack track;
  final double fraction;
  _VisiblePost({
    required this.postId,
    required this.track,
    required this.fraction,
  });
}
