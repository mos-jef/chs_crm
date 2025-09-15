// lib/config/button_theme_config.dart
import 'package:flutter/material.dart'; // 🎯 This import was missing!

class ButtonThemeConfig {
  // 🎨 GLOBAL BUTTON STYLING - Change these values to affect ALL buttons

  // Dimensions & Shape
  static const double defaultWidth = 100.0;
  static const double defaultHeight = 40.0;
  static const double globalBorderRadius = 40.0; // 🎯 Change this to affect ALL buttons

  // Animation Settings
  static const Duration globalAnimationDuration = Duration(milliseconds: 200);
  static const Duration globalPressAnimationDuration = Duration(milliseconds: 150);
  static const double globalScaleOnPress = 0.80; // 🎯 Change this to affect ALL buttons
  static const double globalHoverOpacity = 0.8;

  // Shadow Settings for Primary Buttons
  static const bool primaryEnableShadows = true;
  static const double primaryShadowBlurRadius = 2.0; // 🎯 Change this to affect ALL primary buttons
  static const double primaryShadowSpreadRadius = 1.0;
  static const Offset primaryShadowOffset = Offset(0, 2);
  static const double primaryPressedShadowBlurRadius = 2.0;
  static const Offset primaryPressedShadowOffset = Offset(0, 2);

  // Shadow Settings for Secondary Buttons
  static const bool secondaryEnableShadows = true;
  static const double secondaryShadowBlurRadius = 2.0; // 🎯 Change this to affect ALL secondary buttons
  static const double secondaryShadowSpreadRadius = 0.5;
  static const Offset secondaryShadowOffset = Offset(0, 2);
  static const double secondaryPressedShadowBlurRadius = 4.0;
  static const Offset secondaryPressedShadowOffset = Offset(0, 2);

  // Border Settings
  static const double secondaryBorderWidth = 3.5; // 🎯 Change this to affect ALL secondary button borders

  // 🎨 THEME-SPECIFIC SHADOW COLORS
  static Color getPrimaryShadowColor(bool isAthleteTheme, bool isDarkMode) {
    if (isAthleteTheme) {
      return isDarkMode
          ? const Color(0xFF1A1A1A).withOpacity(0.8)
          : const Color(0xFF3D3D3D).withOpacity(0.8);
    } else {
      return isDarkMode
          ? const Color(0xFF0F1419).withOpacity(0.8)
          : const Color(0xFF2D2D2D).withOpacity(0.8);
    }
  }

  static Color getSecondaryShadowColor(bool isAthleteTheme, bool isDarkMode) {
    if (isAthleteTheme) {
      return isDarkMode
          ? const Color(0xFF1A1A1A).withOpacity(0.6)
          : const Color(0xFF3D3D3D).withOpacity(0.6);
    } else {
      return isDarkMode
          ? const Color(0xFF0F1419).withOpacity(0.6)
          : const Color(0xFF2D2D2D).withOpacity(0.6);
    }
  }
}
