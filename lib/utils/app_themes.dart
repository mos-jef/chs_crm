import 'package:flutter/material.dart';

class AppThemes {
  // Athlete Light Theme Colors
  static const Color _athleteLightBackground = Color(0xFFFFF4E3);
  static const Color _athleteLightSurface = Color(0xFFFFF4E3);
  static const Color _athleteLightPrimary = Color(0xFFCB3920);
  static const Color _athleteLightOnPrimary = Color(0xFFFFF4E3);
  static const Color _athleteLightSecondary = Color(0xFF881593);
  static const Color _athleteLightText = Color(0xFF3C3836);
  static const Color _athleteLightTextSecondary = Color(0xFF881593);
  static const Color _athleteLightFileNumber = Color(0xFF148D80);

  // Athlete Dark Theme Colors
  static const Color _athleteDarkBackground = Color(0xFF373737);
  static const Color _athleteDarkSurface = Color(0xFF373737);
  static const Color _athleteDarkPrimary = Color(0xFFFE8019);
  static const Color _athleteDarkOnPrimary = Color(0xFF373737);
  static const Color _athleteDarkSecondary = Color(0xFF6A8F8A);
  static const Color _athleteDarkText = Color(0xFFFFFFFF);
  static const Color _athleteDarkTextSecondary = Color(0xFFCBD5E1);
  static const Color _athleteDarkFileNumber = Color(0xFFD8BD2F);

  // Ninja Light Theme Colors
  static const Color _ninjaLightBackground = Color(0xFFF8F8F8);
  static const Color _ninjaLightSurface = Color(0xFFF8F8F8);
  static const Color _ninjaLightPrimary = Color(0xFF046252);
  static const Color _ninjaLightOnPrimary = Color(0xFFF8F8F8);
  static const Color _ninjaLightSecondary = Color(0xFFC74600);
  static const Color _ninjaLightText = Color(0xFF3C3836);
  static const Color _ninjaLightTextSecondary = Color(0xFFC74600);
  static const Color _ninjaLightFileNumber = Color(0xFF931535);

  // Ninja Dark Theme Colors
  static const Color _ninjaDarkBackground = Color(0xFF233d4d);
  static const Color _ninjaDarkSurface = Color(0xFF233d4d);
  static const Color _ninjaDarkPrimary = Color(0xFFD8FA69);
  static const Color _ninjaDarkOnPrimary = Color(0xFF233d4d);
  static const Color _ninjaDarkSecondary = Color(0xFFf5BC74);
  static const Color _ninjaDarkText = Color(0xFFCAD0D3);
  static const Color _ninjaDarkTextSecondary = Color(0xFFf5BC74);
  static const Color _ninjaDarkFileNumber = Color(0xFFF4A15D);

  // Financial Colors - Athlete Light
  static const Color _athleteLightLoanAmount = Color(0xFF2E7D32); // Green
  static const Color _athleteLightAmountOwed = Color(0xFF850D8F); 
  static const Color _athleteLightArrears = Color(0xFFC74600); // Orange

  // Financial Colors - Athlete Dark
  static const Color _athleteDarkLoanAmount = Color(0xFFF40BBA); // Bright Green
  static const Color _athleteDarkAmountOwed = Color(0xFF60D417); 
  static const Color _athleteDarkArrears = Color(0xFFF4BE0B); 

  // Financial Colors - Ninja Light
  static const Color _ninjaLightLoanAmount = Color(0xFF1976D2); // Blue
  static const Color _ninjaLightAmountOwed = Color(0xFFEB0C10); 
  static const Color _ninjaLightArrears = Color(0xFF388E3C); // Forest Green

  // Financial Colors - Ninja Dark
  static const Color _ninjaDarkLoanAmount = Color(0xFF42A5F5); // Light Blue
  static const Color _ninjaDarkAmountOwed = Color(0xFFF4BE0B); 
  static const Color _ninjaDarkArrears = Color(0xFF88F06E); // Light Green

  static ThemeData athleteLightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: const ColorScheme.light(
      surface: _athleteLightSurface, // Changed from background
      primary: _athleteLightPrimary,
      onPrimary: _athleteLightOnPrimary,
      secondary: _athleteLightSecondary,
      onSecondary: Colors.white,
    ),

    scaffoldBackgroundColor: _athleteLightBackground,

    appBarTheme: const AppBarTheme(
      backgroundColor: _athleteLightPrimary,
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: TextStyle(
        fontFamily: 'SFPro',
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1.5,
      ),
    ),

    cardTheme: const CardThemeData( // Changed from CardTheme
      color: _athleteLightSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _athleteLightText,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: _athleteLightText,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: _athleteLightText,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: _athleteLightText),
      bodyMedium: TextStyle(color: _athleteLightText),
      bodySmall: TextStyle(color: _athleteLightTextSecondary),
      labelLarge: TextStyle(color: _athleteLightText),
      labelMedium: TextStyle(color: _athleteLightTextSecondary),
    ),

    iconTheme: const IconThemeData(color: _athleteLightPrimary, size: 24),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: _athleteLightPrimary,
      unselectedItemColor: Colors.grey,
      backgroundColor: _athleteLightSurface,
    ),
    tabBarTheme: const TabBarThemeData( // Changed from TabBarTheme
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _athleteLightPrimary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _athleteLightPrimary,
        foregroundColor: Colors.white,
      ),
    ),
  );

  static ThemeData athleteDarkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: const ColorScheme.dark(
      surface: _athleteDarkSurface, // Changed from background
      primary: _athleteDarkPrimary,
      onPrimary: _athleteDarkOnPrimary,
      secondary: _athleteDarkSecondary,
      onSecondary: _athleteDarkBackground,
    ),

    scaffoldBackgroundColor: _athleteDarkBackground,

    appBarTheme: const AppBarTheme(
      backgroundColor: _athleteDarkBackground,
      foregroundColor: _athleteDarkPrimary,
      elevation: 2,
      titleTextStyle: TextStyle(
        fontFamily: 'SFPro',
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: _athleteDarkPrimary,
        letterSpacing: 1.5,
      ),
    ),

    cardTheme: const CardThemeData( // Changed from CardTheme
      color: _athleteDarkSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _athleteDarkText,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: _athleteDarkText,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: _athleteDarkText,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: _athleteDarkText),
      bodyMedium: TextStyle(color: _athleteDarkText),
      bodySmall: TextStyle(color: _athleteDarkTextSecondary),
      labelLarge: TextStyle(color: _athleteDarkText),
      labelMedium: TextStyle(color: _athleteDarkTextSecondary),
    ),

    iconTheme: const IconThemeData(color: _athleteDarkPrimary, size: 24),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: _athleteDarkPrimary,
      unselectedItemColor: _athleteDarkTextSecondary,
      backgroundColor: _athleteDarkSurface,
    ),
    tabBarTheme: const TabBarThemeData( // Changed from TabBarTheme
      labelColor: _athleteDarkPrimary,
      unselectedLabelColor: _athleteDarkTextSecondary,
      indicatorColor: _athleteDarkPrimary,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _athleteDarkPrimary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _athleteDarkPrimary,
        foregroundColor: _athleteDarkOnPrimary,
      ),
    ),
  );

  static ThemeData ninjaLightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: const ColorScheme.light(
      surface: _ninjaLightSurface, // Changed from background
      primary: _ninjaLightPrimary,
      onPrimary: _ninjaLightOnPrimary,
      secondary: _ninjaLightSecondary,
      onSecondary: Colors.white,
    ),

    scaffoldBackgroundColor: _ninjaLightBackground,

    appBarTheme: const AppBarTheme(
      backgroundColor: _ninjaLightPrimary,
      foregroundColor: Colors.white,
      elevation: 2,
      titleTextStyle: TextStyle(
        fontFamily: 'SFPro',
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1.5,
      ),
    ),

    cardTheme: const CardThemeData( // Changed from CardTheme
      color: _ninjaLightSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _ninjaLightText,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: _ninjaLightText,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: _ninjaLightText,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: _ninjaLightText),
      bodyMedium: TextStyle(color: _ninjaLightText),
      bodySmall: TextStyle(color: _ninjaLightTextSecondary),
      labelLarge: TextStyle(color: _ninjaLightText),
      labelMedium: TextStyle(color: _ninjaLightTextSecondary),
    ),

    iconTheme: const IconThemeData(color: _ninjaLightPrimary, size: 24),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: _ninjaLightPrimary,
      unselectedItemColor: Colors.grey,
      backgroundColor: _ninjaLightSurface,
    ),
    tabBarTheme: const TabBarThemeData( // Changed from TabBarTheme
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: Colors.white,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _ninjaLightPrimary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _ninjaLightPrimary,
        foregroundColor: Colors.white,
      ),
    ),
  );

  static ThemeData ninjaDarkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: const ColorScheme.dark(
      surface: _ninjaDarkSurface, // Changed from background
      primary: _ninjaDarkPrimary,
      onPrimary: _ninjaDarkOnPrimary,
      secondary: _ninjaDarkSecondary,
      onSecondary: _ninjaDarkBackground,
    ),

    scaffoldBackgroundColor: _ninjaDarkBackground,

    appBarTheme: const AppBarTheme(
      backgroundColor: _ninjaDarkBackground,
      foregroundColor: _ninjaDarkPrimary,
      elevation: 2,
      titleTextStyle: TextStyle(
        fontFamily: 'SFPro',
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: _ninjaDarkPrimary,
        letterSpacing: 1.5,
      ),
    ),

    cardTheme: const CardThemeData( // Changed from CardTheme
      color: _ninjaDarkSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8))
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: _ninjaDarkText,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: _ninjaDarkText,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: TextStyle(
        color: _ninjaDarkText,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: _ninjaDarkText),
      bodyMedium: TextStyle(color: _ninjaDarkText),
      bodySmall: TextStyle(color: _ninjaDarkTextSecondary),
      labelLarge: TextStyle(color: _ninjaDarkText),
      labelMedium: TextStyle(color: _ninjaDarkTextSecondary),
    ),

    iconTheme: const IconThemeData(color: _ninjaDarkPrimary, size: 24),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: _ninjaDarkPrimary,
      unselectedItemColor: _ninjaDarkTextSecondary,
      backgroundColor: _ninjaDarkSurface,
    ),
    tabBarTheme: const TabBarThemeData( // Changed from TabBarTheme
      labelColor: _ninjaDarkPrimary,
      unselectedLabelColor: _ninjaDarkTextSecondary,
      indicatorColor: _ninjaDarkPrimary,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _ninjaDarkPrimary, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _ninjaDarkPrimary,
        foregroundColor: _ninjaDarkOnPrimary,
      ),
    ),
  );

  // Helper methods to get current theme colors
  static Color getFileNumberColor(String themeName) {
    switch (themeName) {
      case 'athlete_light':
        return _athleteLightFileNumber;
      case 'athlete_dark':
        return _athleteDarkFileNumber;
      case 'ninja_light':
        return _ninjaLightFileNumber;
      case 'ninja_dark':
        return _ninjaDarkFileNumber;
      default:
        return _athleteDarkFileNumber; // Default
    }
  }

  // Financial Color Helper Methods
  static Color getLoanAmountColor(String themeName) {
    switch (themeName) {
      case 'athlete_light':
        return _athleteLightLoanAmount;
      case 'athlete_dark':
        return _athleteDarkLoanAmount;
      case 'ninja_light':
        return _ninjaLightLoanAmount;
      case 'ninja_dark':
        return _ninjaDarkLoanAmount;
      default:
        return _athleteDarkLoanAmount;
    }
  }

  static Color getAmountOwedColor(String themeName) {
    switch (themeName) {
      case 'athlete_light':
        return _athleteLightAmountOwed;
      case 'athlete_dark':
        return _athleteDarkAmountOwed;
      case 'ninja_light':
        return _ninjaLightAmountOwed;
      case 'ninja_dark':
        return _ninjaDarkAmountOwed;
      default:
        return _athleteDarkAmountOwed;
    }
  }

  static Color getArrearsColor(String themeName) {
    switch (themeName) {
      case 'athlete_light':
        return _athleteLightArrears;
      case 'athlete_dark':
        return _athleteDarkArrears;
      case 'ninja_light':
        return _ninjaLightArrears;
      case 'ninja_dark':
        return _ninjaDarkArrears;
      default:
        return _athleteDarkArrears;
    }
  }

  static Color getTotalOwedColor(String themeName) {
    switch (themeName) {
      case 'athlete_light':
        return const Color.fromRGBO(27, 103, 173, 1);
      case 'athlete_dark':
        return const Color.fromARGB(255, 206, 173, 83);
      case 'ninja_light':
        return const Color.fromARGB(255, 97, 80, 3);
      case 'ninja_dark':
        return const Color.fromARGB(255, 224, 160, 41);
      default:
        return const Color(0xFFE91E63);
    }
  }

  static ThemeData getTheme(String themeName) {
    switch (themeName) {
      case 'athlete_light':
        return athleteLightTheme;
      case 'athlete_dark':
        return athleteDarkTheme;
      case 'ninja_light':
        return ninjaLightTheme;
      case 'ninja_dark':
        return ninjaDarkTheme;
      default:
        return athleteDarkTheme; // Default to Athlete Dark
    }
  }

  static Color getCityStateColor(String themeName) {
    switch (themeName) {
      case 'athlete_light':
        return const Color(0xFF666666);
      case 'athlete_dark':
        return const Color(0xFF999999);
      case 'ninja_light':
        return const Color(0xFF555555);
      case 'ninja_dark':
        return const Color(0xFF888888);
      default:
        return const Color(0xFF777777);
    }
  }
}