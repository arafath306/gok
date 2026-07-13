import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Shimmer skeleton loader specifically designed for the SearchExploreScreen layout.
/// Mimics the Trending, Rising, and Recommended User sections.
class SearchShimmer extends StatefulWidget {
  const SearchShimmer({super.key});

  @override
  State<SearchShimmer> createState() => _SearchShimmerState();
}

class _SearchShimmerState extends State<SearchShimmer>
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
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Section 1: Trending Now ─────────────────────────────
          _buildSectionHeaderSkeleton(baseColor),
          ...List.generate(
              3, (_) => _buildTrendingItemSkeleton(baseColor, blockColor)),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.border.withValues(alpha: 0.5)),

          // ── Section 2: Rising Topics ────────────────────────────
          _buildSectionHeaderSkeleton(baseColor),
          ...List.generate(
              2, (_) => _buildRisingItemSkeleton(baseColor, blockColor)),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.border.withValues(alpha: 0.5)),

          // ── Section 3: Recommended for you ──────────────────────
          _buildSectionHeaderSkeleton(baseColor),
          ...List.generate(
              3, (_) => _buildUserRowSkeleton(baseColor, blockColor)),
        ],
      ),
    );
  }

  Widget _box(
      {required double width, required double height, required Color color}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildSectionHeaderSkeleton(Color baseColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          _box(width: 120, height: 14, color: baseColor),
        ],
      ),
    );
  }

  Widget _buildTrendingItemSkeleton(Color baseColor, Color blockColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _box(width: 24, height: 24, color: baseColor), // Number rank
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(width: 150, height: 12, color: baseColor),
                const SizedBox(height: 6),
                _box(width: 80, height: 9, color: baseColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRisingItemSkeleton(Color baseColor, Color blockColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: blockColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(width: 130, height: 12, color: baseColor),
              const SizedBox(height: 6),
              _box(width: 60, height: 9, color: baseColor),
            ],
          ),
          _box(width: 50, height: 16, color: baseColor), // growth percentage badge
        ],
      ),
    );
  }

  Widget _buildUserRowSkeleton(Color baseColor, Color blockColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(width: 100, height: 12, color: baseColor),
                const SizedBox(height: 6),
                _box(width: 70, height: 9, color: baseColor),
              ],
            ),
          ),
          Container(
            width: 70,
            height: 28,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(14),
            ),
          ), // Follow button skeleton
        ],
      ),
    );
  }
}
