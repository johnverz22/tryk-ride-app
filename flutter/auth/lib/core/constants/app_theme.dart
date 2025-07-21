import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData themeData = ThemeData(
    primaryColor: Colors.pink,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.pink,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.pink,
    ).copyWith(secondary: Colors.pinkAccent),
  );
} 