import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1D3A5F); // Azul Marino
  static const Color secondary = Color(0xFFE8A44D); // Ocre Suave
  static const Color background = Color(0xFFF2F2F2); // Gris Perla
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onBackground = Color(0xFF1D3A5F);
  static const Color onSurface = Color(0xFF1D3A5F);
  static const Color error = Colors.redAccent;
  static const Color success = Colors.green;

  static const Color beigeArena = Color(0xFFD9BFA3);
  static const Color verdeAguaSuave = Color(0xFF6DB2A0);
  static const Color marronClaro = Color(0xFFA97448);
  static const Color turquesaClaro = Color(0xFF55CBCD);

  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFF7B9EBF); // Lighter blue for dark mode
  static const Color darkSecondary = Color(0xFFF7C27D); // Lighter ocre for dark mode
  static const Color darkBackground = Color(0xFF121212); // Very dark grey
  static const Color darkSurface = Color(0xFF1E1E1E); // Slightly lighter dark grey for surfaces
  static const Color onDarkPrimary = Colors.black;
  static const Color onDarkSecondary = Colors.black; // If secondary is light
  static const Color onDarkBackground = Colors.white;
  static const Color onDarkSurface = Colors.white;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
        onSurface: onSurface,
        error: error,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        centerTitle: true,
        elevation: 4,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: onPrimary,
        ),
      ),
      textTheme: TextTheme( // Ensure all text colors are dynamic based on ColorScheme
        displayLarge: const TextStyle(
          fontSize: 57.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onBackground), // Use apply to inherit from ColorScheme
        displayMedium: const TextStyle(
          fontSize: 45.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onBackground),
        displaySmall: const TextStyle(
          fontSize: 36.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onBackground),
        headlineLarge: const TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onBackground),
        headlineMedium: const TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onBackground),
        headlineSmall: const TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onBackground),
        titleLarge: const TextStyle(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onBackground),
        titleMedium: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ).apply(color: onBackground),
        titleSmall: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
        ).apply(color: onBackground),
        bodyLarge: const TextStyle(fontSize: 16.0).apply(color: onBackground),
        bodyMedium: const TextStyle(fontSize: 14.0).apply(color: onBackground),
        bodySmall: const TextStyle(fontSize: 12.0).apply(color: onBackground),
        labelLarge: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onPrimary),
        labelMedium: const TextStyle(fontSize: 12.0).apply(color: onBackground),
        labelSmall: const TextStyle(fontSize: 11.0).apply(color: onBackground),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: onPrimary,
          backgroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: marronClaro),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: marronClaro),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 20,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: beigeArena,
        selectedColor: primary,
        labelStyle: const TextStyle(color: onBackground),
        secondaryLabelStyle: const TextStyle(color: onPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkSurface, // Use surface instead of deprecated background
        onPrimary: onDarkPrimary,
        onSecondary: onDarkSecondary,
        onSurface: onDarkSurface, // Use onSurface instead of deprecated onBackground
        error: error, // Error color can remain the same
        onError: Colors.white,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPrimary,
        foregroundColor: onDarkPrimary,
        centerTitle: true,
        elevation: 4,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: onDarkPrimary,
        ),
      ),
      textTheme: TextTheme( // Ensure all text colors are dynamic based on ColorScheme
        displayLarge: const TextStyle(
          fontSize: 57.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onDarkBackground),
        displayMedium: const TextStyle(
          fontSize: 45.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onDarkBackground),
        displaySmall: const TextStyle(
          fontSize: 36.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onDarkBackground),
        headlineLarge: const TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onDarkBackground),
        headlineMedium: const TextStyle(
          fontSize: 28.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onDarkBackground),
        headlineSmall: const TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onDarkBackground),
        titleLarge: const TextStyle(
          fontSize: 22.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onDarkBackground),
        titleMedium: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
        ).apply(color: onDarkBackground),
        titleSmall: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
        ).apply(color: onDarkBackground),
        bodyLarge: const TextStyle(fontSize: 16.0).apply(color: onDarkBackground),
        bodyMedium: const TextStyle(fontSize: 14.0).apply(color: onDarkBackground),
        bodySmall: const TextStyle(fontSize: 12.0).apply(color: onDarkBackground),
        labelLarge: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
        ).apply(color: onDarkPrimary),
        labelMedium: const TextStyle(fontSize: 12.0).apply(color: onDarkBackground),
        labelSmall: const TextStyle(fontSize: 11.0).apply(color: onDarkBackground),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: onDarkPrimary,
          backgroundColor: darkPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: marronClaro), // Keep original or dark variant
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        labelStyle: const TextStyle(color: marronClaro), // Keep original or dark variant
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 20,
        ),
        filled: true,
        fillColor: darkSurface, // Use dark surface for filled input
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        color: darkSurface, // Use dark surface for cards
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSecondary, // Use dark secondary or a suitable dark chip color
        selectedColor: darkPrimary,
        labelStyle: const TextStyle(color: onDarkPrimary),
        secondaryLabelStyle: const TextStyle(color: onDarkPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
