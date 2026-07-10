part of '../custom_thread_card.dart';

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required bool isActive,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
            child: Icon(icon, color: color, size: 18),
          ),
          if (count > 0) ...[
            const SizedBox(width: 2),
            Text(
              '$count',
              style: GoogleFonts.inter(fontSize: 12, color: context.textPrimary.withValues(alpha: 0.75)),
            ),
          ]
        ],
      ),
    );
  }


  Widget _buildMusicImageStack({
    required BuildContext context,
    required List<String> imageUrls,
    required double height,
    required MusicTrack? musicTrack,
    required String postId,
  }) {
    if (musicTrack == null) {
      return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ThreadImageCarousel(imageUrls: imageUrls, height: height),
        ],
      );
    }

    return VisibilityDetector(
      key: Key('music_post_$postId'),
      onVisibilityChanged: (info) {
        final controller = Provider.of<MusicPlaybackController>(
          context,
          listen: false,
        );
        controller.onPostVisibilityChanged(
          postId,
          musicTrack,
          info.visibleFraction,
        );
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ThreadImageCarousel(imageUrls: imageUrls, height: height),
          _buildSmallPlayButton(context, musicTrack, postId),
        ],
      ),
    );
  }

Widget _buildSmallPlayButton(BuildContext context, MusicTrack track, String postId) {
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
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
