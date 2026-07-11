import 'package:flutter/material.dart';
import '../../../utils/app_theme.dart';

class AuthGlassCard extends StatelessWidget {
  final Widget child;

  const AuthGlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [
                  context.authAccent1.withValues(alpha: 0.55),
                  context.authAccent2.withValues(alpha: 0.25),
                  context.authAccent1.withValues(alpha: 0.35),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  context.authPrimary.withValues(alpha: 0.18),
                  context.authSecondary.withValues(alpha: 0.08),
                  context.authPrimary.withValues(alpha: 0.14),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        margin: const EdgeInsets.all(1.2),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: context.customCardBg,
          borderRadius: BorderRadius.circular(23),
        ),
        child: child,
      ),
    );
  }
}
