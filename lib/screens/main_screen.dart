import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'search_explore_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'create_thread_screen.dart';
import 'edit_profile_screen.dart';
import '../utils/routes.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  Widget _buildBottomNavItem(int tabIndex, IconData activeIcon, IconData inactiveIcon) {
    // If it's the plus button (index 2)
    if (tabIndex == 2) {
      return Expanded(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              NoTransitionPageRoute(child: const CreateThreadScreen()),
            );
          },
          child: Container(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9), // Light green background
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Color(0xFF1E824C), // Brand green color
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    // Map tab index to screen index
    final int screenIndex = tabIndex < 2 ? tabIndex : tabIndex - 1;
    final bool isSelected = _currentIndex == screenIndex;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = screenIndex;
          });
        },
        child: Container(
          alignment: Alignment.center,
          child: Icon(
            isSelected ? activeIcon : inactiveIcon,
            color: isSelected ? const Color(0xFF1E824C) : Colors.black38,
            size: 24,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const FeedScreen(),
      const SearchExploreScreen(),
      const NotificationsScreen(),
      ProfileScreenContainer(
        onNavigateToEditProfile: () {
          Navigator.push(
            context,
            NoTransitionPageRoute(child: const EditProfileScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFF1F1F1), width: 1),
          ),
        ),
        child: Row(
          children: [
            _buildBottomNavItem(0, Icons.home, Icons.home_outlined),
            _buildBottomNavItem(1, Icons.search, Icons.search_outlined),
            _buildBottomNavItem(2, Icons.add, Icons.add), // Plus button
            _buildBottomNavItem(3, Icons.favorite, Icons.favorite_outline),
            _buildBottomNavItem(4, Icons.person, Icons.person_outline),
          ],
        ),
      ),
    );
  }
}
