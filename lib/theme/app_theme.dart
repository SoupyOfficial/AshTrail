import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme(Color accentColor) {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: accentColor,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.light(
        primary: accentColor,
        secondary: accentColor.withOpacity(0.8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: accentColor,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shadowColor: Colors.grey[300],
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
      ),
    );
  }

  static ThemeData darkTheme(Color accentColor) {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentColor,
      scaffoldBackgroundColor: Colors.grey[900],
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor.withOpacity(0.8),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[800],
      ),
      cardTheme: CardThemeData(
        color: Colors.grey[800],
        shadowColor: Colors.black45,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
      ),
    );
  }

  // Legacy getters for backward compatibility
  static ThemeData get defaultLightTheme => AppTheme.lightTheme(Colors.blue);
  static ThemeData get defaultDarkTheme => AppTheme.darkTheme(Colors.blue);
}
