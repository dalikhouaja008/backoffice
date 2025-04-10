import 'package:flutter/material.dart';

class GlobalTheme {
  // Couleurs primaires et d'accentuation
  static const Color _primaryLight = Colors.deepPurple;
  static const Color _primaryDark = Colors.deepPurpleAccent;
  static const Color _accentLight = Colors.blue;
  static const Color _accentDark = Colors.lightBlueAccent;

  // Méthode pour obtenir le padding adaptatif sans dépendre de Get.width
  static EdgeInsets getAdaptivePadding(bool isSmallScreen) {
    return isSmallScreen
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  }

  // Thème clair
  static ThemeData get lightThemeData {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: _primaryLight,
      colorScheme: ColorScheme.light(
        primary: _primaryLight,
        secondary: _accentLight,
      ),
      scaffoldBackgroundColor: Colors.white,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _primaryLight,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: _primaryLight,
          // Ne pas utiliser Get.width ici !
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        // Ne pas utiliser Get.width ici !
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: false,
      ),
    );
  }

  // Thème sombre
  static ThemeData get darkThemeData {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: _primaryDark,
      colorScheme: ColorScheme.dark(
        primary: _primaryDark,
        secondary: _accentDark,
      ),
      scaffoldBackgroundColor: Colors.grey[900],
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: _primaryDark,
          // Ne pas utiliser Get.width ici !
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        color: Colors.grey[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        // Ne pas utiliser Get.width ici !
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: false,
      ),
    );
  }
}