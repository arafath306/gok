import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playPop() async {
    try {
      // audioplayers package uses AssetSource relative to the assets folder (i.e. assets/sounds/pop.mp3)
      await _player.play(AssetSource('sounds/pop.mp3'));
    } catch (e) {
      debugPrint('Sound play pop error: $e');
    }
  }

  static Future<void> playChime() async {
    try {
      await _player.play(AssetSource('sounds/chime.wav'));
    } catch (e) {
      debugPrint('Sound play chime error: $e');
    }
  }

  static Future<void> playSend() async {
    try {
      await _player.play(AssetSource('sounds/send.wav'));
    } catch (e) {
      debugPrint('Sound play send error: $e');
    }
  }

  static Future<void> playLike() async {
    try {
      await _player.play(AssetSource('sounds/pop.mp3'));
    } catch (e) {
      debugPrint('Sound play like error: $e');
    }
  }

  static Future<void> playComment() async {
    try {
      await _player.play(AssetSource('sounds/ping.mp3'));
    } catch (e) {
      debugPrint('Sound play comment error: $e');
    }
  }
}
