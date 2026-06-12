import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'search_explore_screen.dart';
import 'notifications_screen.dart';
import 'profile/profile_screen.dart';
import 'profile/edit_profile_screen.dart';
import '../utils/routes.dart';
import 'new_post_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildBottomNavItem(int tabIndex, IconData activeIcon, IconData inactiveIcon) {
    // If it's the plus button (index 2)
    if (tabIndex == 2) {
      return Expanded(
        child: InkWell(
          onTap: () {
            _showCreateOptionsBottomSheet();
          },
          child: Container(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF1E824C), // Solid brand green background
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white, // White plus icon
                size: 22,
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

  void _showCreateOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_outlined, color: Color(0xFF1E824C)),
                ),
                title: Text(
                  "পোস্ট করুন",
                  style: GoogleFonts.hindSiliguri(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  "নতুন ডাক তৈরি করুন এবং ছবি/ভিডিও শেয়ার করুন।",
                  style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.black54),
                ),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.push(
                    context,
                    NoTransitionPageRoute(child: const NewPostScreen()),
                  );
                },
              ),
              const Divider(height: 24, color: Color(0xFFF1F1F1)),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCE4EC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sensors, color: Color(0xFFD81B60)),
                ),
                title: Text(
                  "গো লাইভ",
                  style: GoogleFonts.hindSiliguri(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                subtitle: Text(
                  "আপনার বন্ধুদের সাথে সরাসরি লাইভে যুক্ত হোন।",
                  style: GoogleFonts.hindSiliguri(fontSize: 12, color: Colors.black54),
                ),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF1E824C),
                      content: Text(
                        "লাইভ স্ট্রিমিং ফিচারটি শীঘ্রই আসছে!",
                        style: GoogleFonts.hindSiliguri(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
