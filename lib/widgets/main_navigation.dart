import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

// Pages
import '../pages/home_page.dart';
import '../pages/reports_page.dart';
import '../pages/categories_page.dart';
import '../pages/chat_page.dart';
import '../pages/about_page.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _selectedIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pages = const [
      HomePage(),
      ReportsPage(),
      CategoriesPage(),
      ChatPage(),
      AboutPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      // FAB central eliminado (solo queda el FAB dentro de HomePage)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.06),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GNav(
              rippleColor: scheme.primary.withOpacity(isDark ? 0.12 : 0.1),
              hoverColor: scheme.primary.withOpacity(isDark ? 0.10 : 0.08),
              haptic: true,
              tabBorderRadius: 16,
              tabActiveBorder: Border.all(
                color: scheme.primary.withOpacity(isDark ? 0.25 : 0.15),
                width: 1,
              ),
              curve: Curves.easeInOut,
              duration: const Duration(milliseconds: 300),
              gap: 0,
              color: scheme.onSurfaceVariant,
              activeColor: scheme.primary,
              iconSize: 24,
              tabBackgroundColor:
              scheme.primary.withOpacity(isDark ? 0.12 : 0.07),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              selectedIndex: _selectedIndex,
              onTabChange: (index) => setState(() => _selectedIndex = index),
              tabs: const <GButton>[
                GButton(icon: Icons.home_rounded),
                GButton(icon: Icons.analytics_rounded),
                GButton(icon: Icons.category_rounded),
                GButton(icon: Icons.chat_bubble_outline_rounded),
                GButton(icon: Icons.person_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}