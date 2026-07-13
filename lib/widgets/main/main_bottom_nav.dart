import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

/// Glassmorphic bottom navigation bar with animated tab indicators and
/// notification badges. Uses [Consumer<DatabaseService>] internally so
/// it rebuilds only when badge counts change — the parent does not need
/// to pass badge counts explicitly.
class MainBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTabChanged;

  const MainBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  Widget _buildNavItem(
    BuildContext context, {
    required int tabIndex,
    required IconData activeIcon,
    required IconData inactiveIcon,
    int badgeCount = 0,
  }) {
    final bool isSelected = currentIndex == tabIndex;
    final Color accentColor = context.greenAccent;

    final String label = const {
      0: 'Home Tab',
      1: 'Search and Explore Tab',
      2: 'Messages Tab',
      3: 'Notifications Tab',
      4: 'Profile Tab',
    }[tabIndex] ??
        'Tab';

    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: () => onTabChanged(tabIndex),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.12)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          isSelected ? activeIcon : inactiveIcon,
                          color: isSelected
                              ? accentColor
                              : context.textPrimary.withValues(alpha: 0.75),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          "$badgeCount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DatabaseService>(
      builder: (context, dbService, _) {
        final double bottomPadding = MediaQuery.of(context).padding.bottom;
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
            child: Container(
              height: 58 + bottomPadding,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.black.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: context.isDarkMode
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    _buildNavItem(
                      context,
                      tabIndex: 0,
                      activeIcon: CupertinoIcons.house_fill,
                      inactiveIcon: CupertinoIcons.house,
                    ),
                    _buildNavItem(
                      context,
                      tabIndex: 1,
                      activeIcon: CupertinoIcons.search,
                      inactiveIcon: CupertinoIcons.search,
                    ),
                    _buildNavItem(
                      context,
                      tabIndex: 2,
                      activeIcon: CupertinoIcons.ellipses_bubble_fill,
                      inactiveIcon: CupertinoIcons.ellipses_bubble,
                      badgeCount: dbService.unreadMessagesCount,
                    ),
                    _buildNavItem(
                      context,
                      tabIndex: 3,
                      activeIcon: CupertinoIcons.bell_fill,
                      inactiveIcon: CupertinoIcons.bell,
                      badgeCount: dbService.unreadNotificationsCount,
                    ),
                    _buildNavItem(
                      context,
                      tabIndex: 4,
                      activeIcon: CupertinoIcons.person_fill,
                      inactiveIcon: CupertinoIcons.person,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
