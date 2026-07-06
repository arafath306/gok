import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/music_track.dart';
import '../state/music_playback_controller.dart';

class RotatingAlbumArt extends StatefulWidget {
  final String imageUrl;
  final bool isPlaying;
  final double size;

  const RotatingAlbumArt({
    super.key,
    required this.imageUrl,
    required this.isPlaying,
    this.size = 36,
  });

  @override
  State<RotatingAlbumArt> createState() => _RotatingAlbumArtState();
}

class _RotatingAlbumArtState extends State<RotatingAlbumArt> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(RotatingAlbumArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.white60, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.size / 2),
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.black54,
              child: const Icon(Icons.music_note, color: Colors.white70),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.black54,
              child: const Icon(Icons.music_note, color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}

class MusicPlayerBar extends StatelessWidget {
  final MusicTrack musicTrack;
  final bool miniMode;

  const MusicPlayerBar({
    super.key,
    required this.musicTrack,
    this.miniMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MusicPlaybackController>(context);
    final isCurrent = controller.currentTrackId == musicTrack.trackId;
    final isPlaying = isCurrent && controller.isPlaying;
    final progress = isCurrent ? controller.progress : 0.0;

    return Container(
      height: miniMode ? 44 : 54,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white24, width: 0.8),
      ),
      child: Stack(
        children: [
          // Audio progress indicator at the very bottom
          Positioned(
            left: 12,
            right: 12,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 2,
              ),
            ),
          ),
          Row(
            children: [
              // Spinning Vinyl Art
              RotatingAlbumArt(
                imageUrl: musicTrack.artworkUrl,
                isPlaying: isPlaying,
                size: miniMode ? 28 : 36,
              ),
              const SizedBox(width: 10),
              // Track name and artist info
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      musicTrack.trackName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: miniMode ? 11 : 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      musicTrack.artistName,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: miniMode ? 9 : 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Play/Pause icon button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  controller.play(musicTrack.trackId, musicTrack.previewUrl);
                },
                child: CircleAvatar(
                  radius: miniMode ? 14 : 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: miniMode ? 16 : 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

