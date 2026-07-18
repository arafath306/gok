import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';

class AuthGlassCard extends StatelessWidget {
  final Widget child;

  const AuthGlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      context.authAccent1.withValues(alpha: 0.25),
                      context.authAccent2.withValues(alpha: 0.10),
                      context.authAccent1.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      context.authPrimary.withValues(alpha: 0.12),
                      context.authSecondary.withValues(alpha: 0.05),
                      context.authPrimary.withValues(alpha: 0.09),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(1.2),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(23),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

