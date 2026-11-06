import 'package:flutter/material.dart';

/// The login page palette (masarat/public/css/masarat-login.css).
class Brand {
  static const navy = Color(0xFF0B1F3A);
  static const navy2 = Color(0xFF143766);
  static const blue = Color(0xFF1D4E89);
  static const cream = Color(0xFFF7F4EF);
  static const muted = Color(0xFF5B6B7D);

  static ThemeData theme() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: navy, primary: navy, secondary: blue),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: null,
  );
}
