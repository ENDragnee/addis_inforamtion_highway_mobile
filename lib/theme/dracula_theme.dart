import 'package:flutter/material.dart';

// Dracula Color Palette
const Color draculaBackground = Color(0xFF282A36);
const Color draculaCurrentLine = Color(0xFF44475A);
const Color draculaForeground = Color(0xFFF8F8F2);
const Color draculaComment = Color(0xFF6272A4);
const Color draculaCyan = Color(0xFF8BE9FD);
const Color draculaGreen = Color(0xFF50FA7B);
const Color draculaOrange = Color(0xFFFFB86C);
const Color draculaPink = Color(0xFFFF79C6);
const Color draculaPurple = Color(0xFFBD93F9);
const Color draculaRed = Color(0xFFFF5555);
const Color draculaYellow = Color(0xFFF1FA8C);

// Main ThemeData object
final draculaTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: draculaPurple,
  scaffoldBackgroundColor: draculaBackground,

  // App Bar Theme
  appBarTheme: const AppBarTheme(
    backgroundColor: draculaBackground,
    elevation: 0,
    foregroundColor: draculaForeground,
  ),

  // Text Theme
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: draculaForeground, fontWeight: FontWeight.bold),
    displayMedium: TextStyle(color: draculaForeground, fontWeight: FontWeight.bold),
    displaySmall: TextStyle(color: draculaForeground, fontWeight: FontWeight.bold),
    headlineLarge: TextStyle(color: draculaForeground, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(color: draculaForeground, fontWeight: FontWeight.bold),
    headlineSmall: TextStyle(color: draculaForeground, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(color: draculaForeground, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(color: draculaForeground, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(color: draculaForeground, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: draculaForeground),
    bodyMedium: TextStyle(color: draculaForeground),
    bodySmall: TextStyle(color: draculaComment),
    labelLarge: TextStyle(color: draculaBackground, fontWeight: FontWeight.bold), // For buttons
    labelMedium: TextStyle(color: draculaForeground),
    labelSmall: TextStyle(color: draculaForeground),
  ),

  // Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: draculaPink,
      foregroundColor: draculaBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),

  // Input Decoration Theme for TextFields (if needed)
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: draculaCurrentLine,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide.none,
    ),
    hintStyle: TextStyle(color: draculaComment),
  ),

  // Card Theme
  cardTheme: CardThemeData(
    color: draculaCurrentLine,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
);