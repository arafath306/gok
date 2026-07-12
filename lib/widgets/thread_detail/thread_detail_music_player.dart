import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../models/music_track.dart';
import '../../state/music_playback_controller.dart';
import '../thread_image_carousel.dart';

class ThreadDetailMusicPlayer extends StatelessWidget {
  final MusicTrack track;
  final String postId;

  const ThreadDetailMusicPlayer({
    super.key,
    required this.track,
    required this.postId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlaybackController>(
      builder: (context, controller, child) {
        final isCurrent = controller.currentTrackId == track.trackId;
        final isPlaying = isCurrent && controller.isPlaying;

        return Positioned(
          right: 8,
          bottom: 8,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              controller.play(track.trackId, track.previewUrl);
            },
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MusicImageStack extends StatelessWidget {
  final List<String> imageUrls;
  final double height;
  final MusicTrack? musicTrack;
  final String postId;

  const MusicImageStack({
    super.key,
    required this.imageUrls,
    required this.height,
    required this.musicTrack,
    required this.postId,
  });

  @override
  Widget build(BuildContext context) {
    if (musicTrack == null) {
      return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ThreadImageCarousel(imageUrls: imageUrls, height: height),
        ],
      );
    }

    return VisibilityDetector(
      key: Key('detail_music_$postId'),
      onVisibilityChanged: (info) {
        final controller = Provider.of<MusicPlaybackController>(
          context,
          listen: false,
        );
        controller.onPostVisibilityChanged(
          postId,
          musicTrack!,
          info.visibleFraction,
        );
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ThreadImageCarousel(imageUrls: imageUrls, height: height),
          ThreadDetailMusicPlayer(track: musicTrack!, postId: postId),
        ],
      ),
    );
  }
}
