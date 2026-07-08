import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class VoicePostPlayer extends StatefulWidget {
  final String audioUrl;
  const VoicePostPlayer({super.key, required this.audioUrl});

  @override
  State<VoicePostPlayer> createState() => _VoicePostPlayerState();
}

class _VoicePostPlayerState extends State<VoicePostPlayer> {
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setSourceUrl(widget.audioUrl);
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });
    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _position = newPosition);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_isPlaying) {
                _audioPlayer.pause();
              } else {
                _audioPlayer.play(UrlSource(widget.audioUrl));
              }
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF1E824C),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                trackHeight: 3,
                activeTrackColor: const Color(0xFF1E824C),
                inactiveTrackColor: context.border,
                thumbColor: const Color(0xFF1E824C),
              ),
              child: Slider(
                value: _position.inMilliseconds.toDouble(),
                max: _duration.inMilliseconds.toDouble() > 0 
                     ? _duration.inMilliseconds.toDouble() 
                     : 1.0,
                onChanged: (val) {
                  _audioPlayer.seek(Duration(milliseconds: val.toInt()));
                },
              ),
            ),
          ),
          Text(
            _formatDuration(_position),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
