import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF3F51B5), // Indigo 500
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF3F51B5), // Indigo 500
      elevation: 4,
      titleTextStyle: GoogleFonts.lato(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF3F51B5), // Indigo 500
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3F51B5), // Indigo 500
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.lato(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
      hintStyle: GoogleFonts.lato(color: Colors.grey[500]),
      labelStyle: GoogleFonts.lato(color: const Color(0xFF3F51B5)), // Indigo 500
      prefixIconColor: Colors.grey[500],
      suffixIconColor: Colors.grey[500],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3F51B5), width: 2), // Indigo 500
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.lato(
          color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 32),
      displayMedium: GoogleFonts.lato(
          color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 28),
      bodyLarge: GoogleFonts.lato(color: Colors.black87, fontSize: 16),
      bodyMedium: GoogleFonts.lato(color: Colors.black54, fontSize: 14),
      titleMedium: GoogleFonts.lato(
          color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
      titleSmall: GoogleFonts.lato(
          color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF3F51B5), // Indigo 500
      onPrimary: Colors.white,
      secondary: Color(0xFF3F51B5), // Indigo 500
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black87,
      background: Colors.white,
      onBackground: Colors.black87,
      error: Color(0xFFEF5350), // Red
      onError: Colors.white,
    ),
    iconTheme: const IconThemeData(color: Color(0xFF3F51B5)), // Indigo 500
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF3F51B5), // Indigo 500
      unselectedItemColor: Colors.grey,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF303F9F), // Indigo 700
    scaffoldBackgroundColor: const Color(0xFF1A202C), // Deep Navy Blue
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF2D3748), // Darker Grey Blue
      elevation: 4,
      titleTextStyle: GoogleFonts.lato(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF303F9F), // Indigo 700
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF303F9F), // Indigo 700
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.lato(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2D3748), // Darker Grey Blue
      hintStyle: GoogleFonts.lato(color: Colors.grey[600]),
      labelStyle: GoogleFonts.lato(color: const Color(0xFF303F9F)), // Indigo 700
      prefixIconColor: Colors.grey[600],
      suffixIconColor: Colors.grey[600],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF303F9F), width: 2), // Indigo 700
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.lato(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
      displayMedium: GoogleFonts.lato(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
      bodyLarge: GoogleFonts.lato(color: Colors.white70, fontSize: 16),
      bodyMedium: GoogleFonts.lato(color: Colors.white54, fontSize: 14),
      titleMedium: GoogleFonts.lato(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
      titleSmall: GoogleFonts.lato(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF303F9F), // Indigo 700
      onPrimary: Colors.white,
      secondary: Color(0xFF303F9F), // Indigo 700
      onSecondary: Colors.white,
      surface: Color(0xFF2D3748), // Darker Grey Blue
      onSurface: Colors.white,
      background: Color(0xFF1A202C), // Deep Navy Blue
      onBackground: Colors.white,
      error: Color(0xFFEF5350), // Red
      onError: Colors.white,
    ),
    iconTheme: const IconThemeData(color: Color(0xFF303F9F)), // Indigo 700
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF2D3748), // Darker Grey Blue
      selectedItemColor: Color(0xFF303F9F), // Indigo 700
      unselectedItemColor: Colors.grey,
      elevation: 8,
    ),
    cardTheme: CardThemeData(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}