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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151738) : Colors.white,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: GNav(
                  rippleColor: scheme.primary.withValues(alpha: isDark ? 0.12 : 0.10),
                  hoverColor: scheme.primary.withValues(alpha: isDark ? 0.10 : 0.08),
                  haptic: true,
                  tabBorderRadius: 16,
                  tabActiveBorder: Border.all(
                    color: scheme.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                    width: 1,
                  ),
                  curve: Curves.easeInOut,
                  duration: const Duration(milliseconds: 300),
                  gap: 6,
                  color: scheme.onSurfaceVariant,
                  activeColor: scheme.primary,
                  iconSize: 22,
                  tabBackgroundColor: scheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  selectedIndex: _selectedIndex,
                  onTabChange: (index) => setState(() => _selectedIndex = index),
                  tabs: const <GButton>[
                    GButton(icon: Icons.home_rounded, text: 'Inicio'),
                    GButton(icon: Icons.analytics_rounded, text: 'Reportes'),
                    GButton(icon: Icons.category_rounded, text: 'Categorías'),
                    GButton(icon: Icons.chat_bubble_outline_rounded, text: 'Asistente'),
                    GButton(icon: Icons.person_rounded, text: 'Acerca'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}