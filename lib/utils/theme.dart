// utils/theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color.fromARGB(255, 33, 243, 114);
  static const Color accentColor = Colors.amber;
  static const Color backgroundLightColor = Colors.white;
  static const Color backgroundDarkColor = Color(0xFF121212);
  static const Color textLightColor = Colors.black87;
  static const Color textDarkColor = Colors.white;

  // Tema chiaro
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundLightColor,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontFamily: 'NeueHaasDisplay',
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: textLightColor,
        fontFamily: 'NeueHaasDisplay',
      ),
      bodyMedium: TextStyle(
        color: textLightColor,
        fontFamily: 'NeueHaasDisplay',
      ),
      titleLarge: TextStyle(
        color: textLightColor,
        fontFamily: 'NeueHaasDisplay',
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: textLightColor,
        fontFamily: 'NeueHaasDisplay',
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: accentColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accentColor,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[200]!,
      disabledColor: Colors.grey[300]!,
      selectedColor: accentColor.withOpacity(0.7),
      secondarySelectedColor: accentColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelStyle: const TextStyle(
        color: textLightColor,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
    ),
  );

  // Tema scuro (opzionale, per futuro supporto del tema scuro)
  static final ThemeData darkTheme = ThemeData(
    primarySwatch: Colors.blue,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDarkColor,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontFamily: 'NeueHaasDisplay',
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: textDarkColor,
        fontFamily: 'NeueHaasDisplay',
      ),
      bodyMedium: TextStyle(
        color: textDarkColor,
        fontFamily: 'NeueHaasDisplay',
      ),
      titleLarge: TextStyle(
        color: textDarkColor,
        fontFamily: 'NeueHaasDisplay',
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: textDarkColor,
        fontFamily: 'NeueHaasDisplay',
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: accentColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: accentColor,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2E2E2E),
      disabledColor: const Color(0xFF3E3E3E),
      selectedColor: accentColor.withOpacity(0.7),
      secondarySelectedColor: accentColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      labelStyle: const TextStyle(
        color: textDarkColor,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
    ),
  );
}
