import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/chat_themes.dart';
import '../utils/app_theme.dart';

class ThemePickerSheet extends StatelessWidget {
  final String currentThemeId;
  final Function(String themeId) onThemeSelected;
  final Function(XFile image) onCustomWallpaperSelected;
  final VoidCallback onRemoveWallpaper;

  const ThemePickerSheet({
    super.key,
    required this.currentThemeId,
    required this.onThemeSelected,
    required this.onCustomWallpaperSelected,
    required this.onRemoveWallpaper,
  });

  Future<void> _pickCustomImage(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        if (!context.mounted) return;
        Navigator.pop(context);
        onCustomWallpaperSelected(image);
      }
    } catch (e) {
      debugPrint('Error picking custom wallpaper: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Customize Chat',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Predefined Themes
          SizedBox(
            height: 240, // Height for 2 rows of themes approx
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availableChatThemes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemBuilder: (context, index) {
                final theme = availableChatThemes[index];
                final isSelected = theme.id == currentThemeId;

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onThemeSelected(theme.id);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.gradientColors == null ? theme.primaryColor : null,
                          gradient: theme.gradientColors != null
                              ? LinearGradient(
                                  colors: theme.gradientColors!,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          border: isSelected
                              ? Border.all(color: context.textPrimary, width: 3)
                              : Border.all(color: Colors.transparent, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: theme.isDark ? Colors.white : Colors.black)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        theme.name,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: context.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),

            // Custom Wallpaper Button
            ListTile(
              onTap: () => _pickCustomImage(context),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.primaryAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library_outlined, color: context.primaryAccent),
              ),
              title: Text(
                'Custom Wallpaper',
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Choose from your gallery',
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: Icon(Icons.chevron_right, color: context.textMuted),
            ),
            
            // Remove Wallpaper Button
            ListTile(
              onTap: () {
                Navigator.pop(context);
                onRemoveWallpaper();
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hide_image_outlined, color: Colors.red),
              ),
              title: Text(
                'Remove Wallpaper',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Reset to theme background',
                style: GoogleFonts.inter(
                  color: context.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
        ],
      ),
    );
  }
}
