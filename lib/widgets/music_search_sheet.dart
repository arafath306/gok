import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/music_track.dart';
import '../services/music_service.dart';
import '../state/music_playback_controller.dart';
import 'music_player_bar.dart';

class MusicSearchSheet extends StatefulWidget {
  const MusicSearchSheet({super.key});

  @override
  State<MusicSearchSheet> createState() => _MusicSearchSheetState();
}

class _MusicSearchSheetState extends State<MusicSearchSheet> {
  final _searchController = TextEditingController();
  List<MusicTrack> _tracks = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Default search on load to show some music right away
    _search("hits");
  }

  void _search(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _tracks = [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    MusicService.searchMusic(query).then((results) {
      if (mounted) {
        setState(() {
          _tracks = results;
          _isLoading = false;
        });
      }
    });
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _search(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playbackController = Provider.of<MusicPlaybackController>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0F1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            "Select Music",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Search input field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: "Search songs, artists...",
                hintStyle: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38),
                prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged("");
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E2030) : const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Tracks List / Loading / Empty State
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E824C)),
                    ),
                  )
                : _tracks.isEmpty
                    ? Center(
                        child: Text(
                          "No music found",
                          style: GoogleFonts.inter(color: isDark ? Colors.white38 : Colors.black38),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _tracks.length,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemBuilder: (context, index) {
                          final track = _tracks[index];
                          final isCurrent = playbackController.currentTrackId == track.trackId;
                          final isPlaying = isCurrent && playbackController.isPlaying;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? (isDark ? const Color(0xFF1E2540) : const Color(0xFFF0F4FF))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              onTap: () {
                                // Stop playback and return selected track
                                playbackController.stop();
                                Navigator.pop(context, track);
                              },
                              leading: Stack(
                                alignment: Alignment.center,
                                children: [
                                  RotatingAlbumArt(
                                    imageUrl: track.artworkUrl,
                                    isPlaying: isPlaying,
                                    size: 44,
                                  ),
                                  // Play icon overlay
                                  GestureDetector(
                                    onTap: () {
                                      playbackController.play(track.trackId, track.previewUrl);
                                    },
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.black.withValues(alpha: isPlaying ? 0.3 : 0.4),
                                      ),
                                      child: Icon(
                                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(
                                track.trackName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                track.artistName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(
                                Icons.add_circle_outline_rounded,
                                color: theme.primaryColor,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
