import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'feed_screen.dart';
import 'search_explore_screen.dart';
import 'notifications_screen.dart';
import 'profile/profile_screen.dart';
import '../utils/routes.dart';
import 'create_thread_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'messenger/messenger_home_screen.dart';
import 'settings/settings_screen.dart';
import 'saved_posts_screen.dart';
import '../utils/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  StreamSubscription? _notificationSubscription;
  bool _showBars = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      _notificationSubscription = dbService.incomingNotificationStream.listen((event) {
        if (mounted) {
          _showInAppNotificationBanner(event);
        }
      });
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _showInAppNotificationBanner(Map<String, dynamic> event) {
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.border, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1E824C).withOpacity(0.1),
                  child: Icon(
                    event['type'] == 'message' ? Icons.chat_bubble : Icons.notifications,
                    color: const Color(0xFF1E824C),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event['title'] as String,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event['body'] as String,
                        style: GoogleFonts.hindSiliguri(
                          fontSize: 13,
                          color: context.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: context.textMuted),
                  onPressed: () => overlayEntry.remove(),
                )
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void setTab(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _showMockFeatureDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "$feature coming soon!",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        content: Text(
          "We are actively working on building the $feature feature to match the complete social media experience. Stay tuned!",
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Dismiss",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E824C)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Submit Feedback",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Let us know your thoughts or report any issues:",
              style: GoogleFonts.inter(color: context.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
              decoration: InputDecoration(
                hintText: "Enter your feedback...",
                hintStyle: GoogleFonts.inter(color: context.textMuted),
                filled: true,
                fillColor: context.isDarkMode ? const Color(0xFF121422) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(color: context.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1E824C),
                  content: Text(
                    "Thank you for your feedback!",
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E824C),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              "Submit",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Help & Support",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        content: Text(
          "Need help? Contact our support team at support@dak.social or check our online documentation.",
          style: GoogleFonts.inter(color: context.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1E824C)),
            ),
          ),
        ],
      ),
    );
  }

  void _showModal(BuildContext context, String title, String contentText) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    contentText,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: context.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E824C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Accept",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, myProfile) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, top: 24.0, bottom: 20.0, right: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              setTab(4);
            },
            child: CircleAvatar(
              radius: 32,
              backgroundColor: context.isDarkMode ? Colors.grey[900] : Colors.grey[200],
              backgroundImage: myProfile?.avatarUrl != null && myProfile!.avatarUrl!.isNotEmpty
                  ? NetworkImage(myProfile.avatarUrl!)
                  : const NetworkImage(""),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              setTab(4);
            },
            child: Text(
              myProfile?.fullName ?? "Arafath",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
                letterSpacing: -0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "@${myProfile?.username ?? 'arafath306'}.bsky.social",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: context.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                color: context.textSecondary,
              ),
              children: [
                TextSpan(
                  text: '${myProfile?.followersCount ?? 0} ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                const TextSpan(text: 'followers  ·  '),
                TextSpan(
                  text: '${myProfile?.followingCount ?? 0} ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary),
                ),
                const TextSpan(text: 'following'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
    int badgeCount = 0,
  }) {
    return ListTile(
      tileColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      minLeadingWidth: 28,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            icon,
            color: isActive ? context.primaryAccent : context.textPrimary,
            size: 26,
          ),
          if (badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 14,
                  minHeight: 14,
                ),
                child: Text(
                  "$badgeCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          color: isActive ? context.primaryAccent : context.textPrimary,
          letterSpacing: -0.1,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildFooterLinks(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showModal(
              context,
              "Terms of Service",
              "Welcome to Dak! By using our platform, you agree to these terms:\n\n"
              "1. Content Ownership: You own the content you post, but grant us license to display it.\n\n"
              "2. Safety: Do not harass other users or post illegal content.\n\n"
              "3. Termination: We reserve the right to suspend accounts violating safety rules.\n\n"
              "For more details, visit our website.",
            ),
            child: Text(
              "Terms of Service",
              style: GoogleFonts.inter(
                color: const Color(0xFF0085FF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showModal(
              context,
              "Privacy Policy",
              "Your privacy is important to us:\n\n"
              "1. Data Collection: We collect account profile information (username, full name) and posts you publish.\n\n"
              "2. Usage: We use your data to run and secure our social network.\n\n"
              "3. Sharing: We do not sell your personal data to third parties.\n\n"
              "Read the complete policy on our documentation portal.",
            ),
            child: Text(
              "Privacy Policy",
              style: GoogleFonts.inter(
                color: const Color(0xFF0085FF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showFeedbackDialog(context),
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 16, color: context.textPrimary),
              label: Text(
                "Feedback",
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.isDarkMode ? const Color(0xFF121422) : const Color(0xFFF3F4F6),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: const StadiumBorder(),
                shadowColor: Colors.transparent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showHelpDialog(context),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.border, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: const StadiumBorder(),
              ),
              child: Text(
                "Help",
                style: GoogleFonts.inter(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(int tabIndex, IconData activeIcon, IconData inactiveIcon, {int badgeCount = 0}) {
    final bool isSelected = _currentIndex == tabIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setTab(tabIndex);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isSelected ? activeIcon : inactiveIcon,
                    color: isSelected ? const Color(0xFF1E824C) : context.textSecondary,
                    size: 22,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
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
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: isSelected ? 4 : 0,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF1E824C),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      FeedScreen(
        onNavigateToChaStation: () => setTab(2),
        onNavigateToCreate: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateThreadScreen()),
          );
        },
      ),
      const SearchExploreScreen(),
      const MessengerHomeScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      extendBody: true,
      drawer: Drawer(
        backgroundColor: context.scaffoldBg,
        child: Consumer<DatabaseService>(
          builder: (context, dbService, _) {
            final myProfile = dbService.myProfile;
            return SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileHeader(context, myProfile),
                          _buildDrawerItem(
                            icon: Icons.search_outlined,
                            title: "Explore",
                            isActive: _currentIndex == 1,
                            onTap: () {
                              Navigator.pop(context);
                              setTab(1);
                            },
                          ),
                          _buildDrawerItem(
                            icon: _currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                            title: "Home",
                            isActive: _currentIndex == 0,
                            onTap: () {
                              Navigator.pop(context);
                              setTab(0);
                            },
                          ),
                          _buildDrawerItem(
                            icon: _currentIndex == 2 ? Icons.chat_bubble : Icons.chat_bubble_outline_rounded,
                            title: "Chat",
                            isActive: _currentIndex == 2,
                            badgeCount: dbService.unreadMessagesCount,
                            onTap: () {
                              Navigator.pop(context);
                              setTab(2);
                            },
                          ),
                          _buildDrawerItem(
                            icon: _currentIndex == 3 ? Icons.notifications : Icons.notifications_outlined,
                            title: "Notifications",
                            isActive: _currentIndex == 3,
                            badgeCount: dbService.unreadNotificationsCount,
                            onTap: () {
                              Navigator.pop(context);
                              setTab(3);
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.tag_rounded,
                            title: "Feeds",
                            isActive: false,
                            onTap: () {
                              Navigator.pop(context);
                              setTab(0);
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.list_alt_rounded,
                            title: "Lists",
                            isActive: false,
                            onTap: () {
                              Navigator.pop(context);
                              _showMockFeatureDialog(context, "Lists");
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.bookmark_border_rounded,
                            title: "Saved",
                            isActive: false,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                NoTransitionPageRoute(child: const SavedPostsScreen()),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            icon: _currentIndex == 4 ? Icons.person : Icons.person_outline_rounded,
                            title: "Profile",
                            isActive: _currentIndex == 4,
                            onTap: () {
                              Navigator.pop(context);
                              setTab(4);
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.settings_outlined,
                            title: "Settings",
                            isActive: false,
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                NoTransitionPageRoute(child: const SettingsScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: context.border),
                  _buildFooterLinks(context),
                  _buildFooterButtons(context),
                ],
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            if (notification is ScrollUpdateNotification) {
              if (notification.metrics.axis == Axis.vertical) {
                final double scrollDelta = notification.scrollDelta ?? 0;
                if (scrollDelta > 5.0 && _showBars) {
                  setState(() {
                    _showBars = false;
                  });
                } else if (scrollDelta < -5.0 && !_showBars) {
                  setState(() {
                    _showBars = true;
                  });
                }
                if (notification.metrics.pixels <= 0 && !_showBars) {
                  setState(() {
                    _showBars = true;
                  });
                }
              }
            }
            return false;
          },
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              if (index != _currentIndex) {
                setState(() {
                  _currentIndex = index;
                  _showBars = true;
                });
              }
            },
            children: screens,
          ),
        ),
      ),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 4)
          ? AnimatedScale(
              scale: _showBars ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: ScaleTransition(
                scale: TweenSequence<double>([
                  TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 25),
                  TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.12), weight: 45),
                  TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 30),
                ]).animate(_fabAnimationController),
                child: FloatingActionButton(
                  heroTag: 'main_fab',
                  backgroundColor: const Color(0xFF1E824C),
                  shape: const CircleBorder(),
                  elevation: 3,
                  mini: true,
                  onPressed: () {
                    _fabAnimationController.forward(from: 0.0);
                    Future.delayed(const Duration(milliseconds: 180), () {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CreateThreadScreen()),
                        );
                      }
                    });
                  },
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            )
          : null,

      bottomNavigationBar: AnimatedSlide(
        offset: _showBars ? Offset.zero : const Offset(0, 1.2),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Consumer<DatabaseService>(
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
                  height: 52 + bottomPadding,
                  decoration: BoxDecoration(
                    color: context.isDarkMode
                        ? Colors.black.withOpacity(0.8)
                        : Colors.white.withOpacity(0.85),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: context.isDarkMode
                            ? Colors.white.withOpacity(0.12)
                            : Colors.black.withOpacity(0.08),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        _buildBottomNavItem(0, Icons.home_rounded, Icons.home_outlined),
                        _buildBottomNavItem(1, Icons.search_rounded, Icons.search_rounded),
                        _buildBottomNavItem(
                          2, 
                          Icons.chat_bubble_rounded, 
                          Icons.chat_bubble_outline_rounded,
                          badgeCount: dbService.unreadMessagesCount,
                        ),
                        _buildBottomNavItem(
                          3, 
                          Icons.notifications_rounded, 
                          Icons.notifications_outlined,
                          badgeCount: dbService.unreadNotificationsCount,
                        ),
                        _buildBottomNavItem(4, Icons.person_rounded, Icons.person_outline_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
