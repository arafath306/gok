import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

/// Optional Image URL and Video URL text fields.
/// Renders nothing when both [showImageInput] and [showVideoInput]
/// are false (avoids inserting unnecessary vertical space).
class UrlInputSection extends StatelessWidget {
  final TextEditingController imageUrlController;
  final TextEditingController videoUrlController;
  final bool showImageInput;
  final bool showVideoInput;

  const UrlInputSection({
    super.key,
    required this.imageUrlController,
    required this.videoUrlController,
    required this.showImageInput,
    required this.showVideoInput,
  });

  @override
  Widget build(BuildContext context) {
    if (!showImageInput && !showVideoInput) return const SizedBox.shrink();

    return Column(
      children: [
        // Custom Image URL input
        if (showImageInput) ...[
          const SizedBox(height: 12),
          TextField(
            controller: imageUrlController,
            decoration: InputDecoration(
              labelText: "Image URL",
              labelStyle: GoogleFonts.inter(
                  fontSize: 13, color: context.textSecondary),
              prefixIcon: Icon(Icons.image_outlined,
                  size: 18, color: context.textSecondary),
              isDense: true,
              filled: true,
              fillColor: context.isDarkMode
                  ? const Color(0xFF1E2030)
                  : const Color(0xFFF3F4F6),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.border),
              ),
            ),
            style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
          ),
        ],

        // Custom Video URL input
        if (showVideoInput) ...[
          const SizedBox(height: 12),
          TextField(
            controller: videoUrlController,
            decoration: InputDecoration(
              labelText: "Video URL",
              labelStyle: GoogleFonts.inter(
                  fontSize: 13, color: context.textSecondary),
              prefixIcon: Icon(Icons.video_collection_outlined,
                  size: 18, color: context.textSecondary),
              isDense: true,
              filled: true,
              fillColor: context.isDarkMode
                  ? const Color(0xFF1E2030)
                  : const Color(0xFFF3F4F6),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.border),
              ),
            ),
            style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
          ),
        ],
      ],
    );
  }
}
