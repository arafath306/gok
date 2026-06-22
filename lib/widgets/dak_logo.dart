import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// A dove logo widget that works on both dark and light themes.
/// It uses the transparent PNG assets/dak_icon.png and applies
/// a tint color based on the current theme mode.
class DakLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const DakLogo({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Image.asset(
      'assets/dak_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      color: color ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
      colorBlendMode: BlendMode.srcIn,
    );
  }
}
