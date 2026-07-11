import 'package:flutter/material.dart';

class ChatTheme {
  final String id;
  final String name;
  final Color primaryColor;
  final List<Color>? gradientColors; // If null, use solid primaryColor
  final bool isDark; // Indicates if text on these colors should be white (true) or black (false)

  const ChatTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    this.gradientColors,
    this.isDark = true,
  });
}

const List<ChatTheme> availableChatThemes = [
  // Solid Colors
  ChatTheme(
    id: 'default',
    name: 'App Default',
    primaryColor: Color(0xFF7C4DFF), // Brand Color (Purple)
  ),
  ChatTheme(
    id: 'coral',
    name: 'Coral Pink',
    primaryColor: Color(0xFFFF5E7E),
  ),
  ChatTheme(
    id: 'forest',
    name: 'Forest Green',
    primaryColor: Color(0xFF2E7D32),
  ),
  ChatTheme(
    id: 'purple_solid',
    name: 'Royal Purple',
    primaryColor: Color(0xFF9C27B0),
  ),
  ChatTheme(
    id: 'dark_mode',
    name: 'Monochrome',
    primaryColor: Color(0xFF303030),
  ),

  // Gradients
  ChatTheme(
    id: 'instagram',
    name: 'Instagram',
    primaryColor: Color(0xFFE1306C),
    gradientColors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFF56040)],
  ),
  ChatTheme(
    id: 'ocean',
    name: 'Ocean Depth',
    primaryColor: Color(0xFF2193b0),
    gradientColors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
  ),
  ChatTheme(
    id: 'sunset',
    name: 'Sunset Glow',
    primaryColor: Color(0xFFff7e5f),
    gradientColors: [Color(0xFFff7e5f), Color(0xFFfeb47b)],
  ),
  ChatTheme(
    id: 'cyberpunk',
    name: 'Cyberpunk',
    primaryColor: Color(0xFFFF007F),
    gradientColors: [Color(0xFFFF007F), Color(0xFF00F0FF)],
  ),
  ChatTheme(
    id: 'mango',
    name: 'Mango Pulp',
    primaryColor: Color(0xFFf12711),
    gradientColors: [Color(0xFFf12711), Color(0xFFf5af19)],
  ),
  ChatTheme(
    id: 'emerald',
    name: 'Emerald Water',
    primaryColor: Color(0xFF348F50),
    gradientColors: [Color(0xFF348F50), Color(0xFF56B4D3)],
  ),
  ChatTheme(
    id: 'lavender',
    name: 'Lavender Dusk',
    primaryColor: Color(0xFF654ea3),
    gradientColors: [Color(0xFF654ea3), Color(0xFFeaafc8)],
  ),
  ChatTheme(
    id: 'northern_lights',
    name: 'Northern Lights',
    primaryColor: Color(0xFF43C6AC),
    gradientColors: [Color(0xFF43C6AC), Color(0xFF191654)],
  ),
  ChatTheme(
    id: 'cherry',
    name: 'Cherry Blossom',
    primaryColor: Color(0xFFee9ca7),
    gradientColors: [Color(0xFFee9ca7), Color(0xFFffdde1)],
    isDark: false, // light text isn't good on this
  ),
];

// Helper to get theme by ID
ChatTheme getChatThemeById(String? id) {
  if (id == null || id.isEmpty) return availableChatThemes.first;
  
  // Check if it's a custom wallpaper URL
  if (id.startsWith('custom:')) return availableChatThemes.first;

  try {
    return availableChatThemes.firstWhere((theme) => theme.id == id);
  } catch (e) {
    return availableChatThemes.first;
  }
}
