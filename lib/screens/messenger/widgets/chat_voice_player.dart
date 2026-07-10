import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatVoicePlayer extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const ChatVoicePlayer({
    super.key,
    required this.audioUrl,
    required this.isMe,
  });

  @override
  State<ChatVoicePlayer> createState() => _ChatVoicePlayerState();
}

class _ChatVoicePlayerState extends State<ChatVoicePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _stateSub;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          _isBuffering = false;
          if (state == PlayerState.completed) {
            _position = Duration.zero;
          }
        });
      }
    });

    try {
      await _player.setSourceUrl(widget.audioUrl);
    } catch (e) {
      debugPrint("Error setting audio source: $e");
    }
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        if (_position == _duration && _duration > Duration.zero) {
          await _player.seek(Duration.zero);
        }
        await _player.play(UrlSource(widget.audioUrl));
      }
    } catch (e) {
      debugPrint("Error toggling play: $e");
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.isMe ? Colors.white : Colors.black87;
    final iconColor = widget.isMe ? Colors.teal : Colors.blue;
    final sliderActive = widget.isMe ? Colors.white : Colors.blue;
    final sliderInactive = widget.isMe ? Colors.white38 : Colors.black12;

    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: widget.isMe ? Colors.white : Colors.blue.withValues(alpha: 0.1),
              child: _isBuffering
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: iconColor,
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: iconColor,
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 20,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      trackHeight: 2,
                    ),
                    child: Slider(
                      value: _position.inMilliseconds.toDouble().clamp(
                          0.0,
                          _duration.inMilliseconds.toDouble() > 0
                              ? _duration.inMilliseconds.toDouble()
                              : 1.0),
                      min: 0.0,
                      max: _duration.inMilliseconds.toDouble() > 0
                          ? _duration.inMilliseconds.toDouble()
                          : 1.0,
                      activeColor: sliderActive,
                      inactiveColor: sliderInactive,
                      onChanged: (val) {
                        final newPosition = Duration(milliseconds: val.toInt());
                        _player.seek(newPosition);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    _formatDuration(_position.inMilliseconds > 0 ? _position : _duration),
                    style: GoogleFonts.inter(
                      color: fgColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
