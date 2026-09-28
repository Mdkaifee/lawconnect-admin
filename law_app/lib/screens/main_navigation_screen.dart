import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/services/notification_service.dart';
import '../core/theme/app_theme.dart';
import '../core/translations/translation.dart';
import '../repositories/auth_repository.dart';
import 'home/home_screen.dart';
import 'cases/case_search_screen.dart';
import 'community/community_feed_screen.dart';
import 'profile/bookmarks_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    HomeScreen(),
    CaseSearchScreen(),
    CommunityFeedScreen(showBackButton: false),
    BookmarksScreen(showBackButton: false),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NotificationService.instance.requestPermissionAndRegister(context.read<AuthRepository>());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final navBgColor = isDark ? const Color(0xFF0F1827) : Colors.white;
    final navBorderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final selectedColor = isDark ? AppColors.goldAccentLight : AppColors.primaryNavy;
    final unselectedColor = isDark ? AppColors.textDarkMuted : AppColors.textMuted;

    return ListenableBuilder(
      listenable: Translation.instance,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: navBgColor,
              border: Border(top: BorderSide(color: navBorderColor, width: 1)),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (idx) {
                setState(() {
                  _currentIndex = idx;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: navBgColor,
              selectedItemColor: selectedColor,
              unselectedItemColor: unselectedColor,
              elevation: 0,
              iconSize: 22,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10.5),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home_rounded),
                  label: Translation.t('home'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.search_rounded),
                  activeIcon: const Icon(Icons.search_rounded),
                  label: Translation.t('search'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.forum_outlined),
                  activeIcon: const Icon(Icons.forum_rounded),
                  label: Translation.t('posts'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.bookmark_border_rounded),
                  activeIcon: const Icon(Icons.bookmark_rounded),
                  label: Translation.t('bookmarks'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline_rounded),
                  activeIcon: const Icon(Icons.person_rounded),
                  label: Translation.t('profile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
