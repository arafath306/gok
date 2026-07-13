import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

/// Shimmer placeholder for the Profile screen while data is loading.
/// Mirrors the real profile header + tab section skeleton.
class ProfileShimmer extends StatefulWidget {
  const ProfileShimmer({super.key});

  @override
  State<ProfileShimmer> createState() => _ProfileShimmerState();
}

class _ProfileShimmerState extends State<ProfileShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final baseColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final blockColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) =>
          Opacity(opacity: _opacityAnimation.value, child: child),
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        body: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cover image skeleton ──────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(height: 130, color: baseColor),

                  // Avatar skeleton
                  Positioned(
                    left: 16,
                    top: 130 - 55, // avatarHeightOffset
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: blockColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.scaffoldBg, width: 4),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 62), // space for avatar overflow

              // ── Name + username + bio ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _box(width: 140, height: 18, color: baseColor),
                    const SizedBox(height: 8),
                    _box(width: 100, height: 13, color: baseColor),
                    const SizedBox(height: 12),
                    _box(width: double.infinity, height: 12, color: baseColor),
                    const SizedBox(height: 6),
                    _box(width: 220, height: 12, color: baseColor),
                    const SizedBox(height: 16),

                    // Followers row skeleton
                    Row(
                      children: [
                        _box(width: 60, height: 12, color: baseColor),
                        const SizedBox(width: 16),
                        _box(width: 60, height: 12, color: baseColor),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action buttons skeleton
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ── Tab bar skeleton ──────────────────────────────────
              Container(
                height: 44,
                color: context.cardBg,
                child: Row(
                  children: List.generate(3, (i) => Expanded(
                    child: Center(
                      child: _box(width: 40, height: 12, color: baseColor),
                    ),
                  )),
                ),
              ),
              const Divider(height: 1, thickness: 0.5),

              // ── Thread card skeletons ─────────────────────────────
              ...List.generate(4, (_) => _buildThreadSkeleton(baseColor, blockColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _box({required double width, required double height, required Color color}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildThreadSkeleton(Color baseColor, Color blockColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
                BoxDecoration(color: baseColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(width: 90, height: 11, color: baseColor),
                const SizedBox(height: 8),
                _box(width: double.infinity, height: 10, color: baseColor),
                const SizedBox(height: 6),
                _box(width: 200, height: 10, color: baseColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
