import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

// Páginas
import '../pages/home_page.dart';
import '../pages/add_transaction_page.dart';
import '../pages/reports_page.dart';
import '../pages/categories_page.dart';
import '../pages/chat_page.dart';
import '../pages/about_page.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 0});

  static const int chatTabIndex = 4;

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
      AddTransactionPage(),
      ReportsPage(),
      CategoriesPage(),
      ChatPage(),
      AboutPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GNav(
              rippleColor: scheme.primary.withOpacity(0.1),
              hoverColor: scheme.primary.withOpacity(0.1),
              haptic: true,
              tabBorderRadius: 12,
              tabActiveBorder: Border.all(
                color: scheme.primary.withOpacity(0.2),
                width: 1,
              ),
              curve: Curves.easeInOut,
              duration: const Duration(milliseconds: 300),
              gap: 0, // solo íconos
              color: scheme.onSurfaceVariant,
              activeColor: scheme.primary,
              iconSize: 24,
              tabBackgroundColor: scheme.primary.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              selectedIndex: _selectedIndex,
              onTabChange: (index) => setState(() => _selectedIndex = index),
              tabs: const <GButton>[
                GButton(icon: Icons.home_rounded),
                GButton(icon: Icons.add_circle_outline_rounded),
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