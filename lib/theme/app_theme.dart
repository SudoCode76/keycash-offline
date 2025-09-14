import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_system.dart';

class AppTheme {
  static ThemeData themeFor(DesignStyle style, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (style) {
      case DesignStyle.ios18:
        return _iosTheme(isDark);
      case DesignStyle.oneui7:
        return _oneUiTheme(isDark);
    }
  }

  // ===== iOS 18-like =====
  static ThemeData _iosTheme(bool dark) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorSchemeSeed: const Color(0xFF0A84FF),
    );

    final bg = dark ? const Color(0xFF0F1122) : const Color(0xFFF2F3F7); // menos blanco
    final card = dark ? const Color(0xFF171936) : const Color(0xFFFFFFFF);
    final borderColor = (dark ? Colors.white : Colors.black).withValues(alpha: 0.06);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: dark ? Colors.white : Colors.black87,
        ),
        // Fuerza visibilidad de iconos de la barra de estado/nav según tema
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: bg,
          systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        color: MaterialStatePropertyAll(dark ? const Color(0xFF171936) : Colors.white),
        side: BorderSide(color: borderColor),
      ),
    );
  }

  // ===== One UI 7-like =====
  static ThemeData _oneUiTheme(bool dark) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorSchemeSeed: const Color(0xFF6C63FF),
    );

    final bg = dark ? const Color(0xFF0B0E19) : const Color(0xFFEFF1F6); // menos blanco
    final card = dark ? const Color(0xFF121430) : const Color(0xFFFFFFFF);
    final borderColor = (dark ? Colors.white : Colors.black).withValues(alpha: 0.07);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: dark ? Colors.white : Colors.black87,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: bg,
          systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        color: MaterialStatePropertyAll(dark ? const Color(0xFF171936) : Colors.white),
        side: BorderSide(color: borderColor),
      ),
    );
  }
}