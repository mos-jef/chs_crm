// lib/widgets/custom_beam_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'border_beam.dart';

enum CustomButtonStyle {
  primary,   // Uses primary color for background, surface color for text
  secondary, // Uses secondary color for background, surface color for text
  custom,    // Uses default theme-responsive colors (original behavior)
}

class CustomBeamButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final CustomButtonStyle buttonStyle;

  const CustomBeamButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height = 48.0,
    this.buttonStyle = CustomButtonStyle.primary,
  });

  @override
  State<CustomBeamButton> createState() => _CustomBeamButtonState();
}

class _CustomBeamButtonState extends State<CustomBeamButton> 
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
      _pressController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _pressController.reverse();
      if (widget.onPressed != null && !widget.isLoading) {
        widget.onPressed!();
      }
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() {
        _isPressed = false;
      });
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Get theme-responsive colors
        final isDark = themeProvider.isDarkMode;
        final isAthlete = themeProvider.isAthleteTheme;
        
        // Define colors based on theme and button style
        Color beamColorFrom;
        Color beamColorTo;
        Color staticBorderColor;
        Color backgroundColor;
        Color textColor;
        
        // Get theme colors from the current context
        final primaryColor = Theme.of(context).colorScheme.primary;
        final secondaryColor = Theme.of(context).colorScheme.secondary;
        final surfaceColor = Theme.of(context).colorScheme.surface;
        
        // Set colors based on button style
        switch (widget.buttonStyle) {
          case CustomButtonStyle.primary:
            backgroundColor =
                primaryColor; // keep the fill from your ColorScheme
            textColor = surfaceColor;

            // default (fallback) – in case no theme check matches
            beamColorFrom = primaryColor.withAlpha(204);
            beamColorTo = primaryColor;
            staticBorderColor = primaryColor.withAlpha(0);

            // 🔶 ATHLETE — LIGHT: red-orange -> purple
            if (themeProvider.isAthleteTheme && !themeProvider.isDarkMode) {
              // Primary: #CB3920, Accent Purple: #881593
              beamColorFrom = const Color(0xFFCB3920); // red-orange
              beamColorTo = const Color(0xFF881593); // purple
              staticBorderColor = const Color(0xFFDDDDDD).withAlpha(0);
            }
            // 🔶 ATHLETE — DARK: peach -> purple
            else if (themeProvider.isAthleteTheme && themeProvider.isDarkMode) {
              // Primary: #FE8019 (orange), Accent Purple: #881593
              beamColorFrom = const Color(0xFFF5BC74); // peach
              beamColorTo = const Color(0xFF881593); // purple
              staticBorderColor = const Color(0xFF555555).withAlpha(0);
            }
            // 🟩 NINJA — LIGHT: teal -> deep orange
            else if (themeProvider.isNinjaTheme && !themeProvider.isDarkMode) {
              // Primary: #046252 (teal), Secondary: #C74600 (deep orange)
              beamColorFrom = const Color(0xFF046252); // teal
              beamColorTo = const Color(0xFFC74600); // deep orange
              staticBorderColor = const Color(0xFFDDDDDD).withAlpha(0);
            }
            // 🟩 NINJA — DARK: lime -> peach
            else if (themeProvider.isNinjaTheme && themeProvider.isDarkMode) {
              // Primary: #D8FA69 (lime), Secondary-ish accent: #F5BC74 (peach)
              beamColorFrom = const Color(0xFFD8FA69); // lime
              beamColorTo = const Color(0xFF881593); // purple
              staticBorderColor = const Color(0xFF555555).withAlpha(0);
            }

            break;

          // CANCEL BUTTONS
            
          case CustomButtonStyle.secondary:
            // Button fill stays your theme secondary color
            final cs = Theme.of(context).colorScheme;
            backgroundColor = cs.secondary;
            // Better contrast token than 'surface' for buttons:
            textColor = cs.onSecondary;

            // Fallback (in case no theme check matches)
            beamColorFrom = backgroundColor.withAlpha(204);
            beamColorTo = backgroundColor;
            staticBorderColor = backgroundColor.withAlpha(76);

            // 🔶 ATHLETE — LIGHT (secondary is Purple): purple -> red-orange
            if (themeProvider.isAthleteTheme && !themeProvider.isDarkMode) {
              // Purple: #881593, Red-Orange: #CB3920
              beamColorFrom = const Color(0xFF881593); // purple head
              beamColorTo = const Color(0xFFCB3920); // red-orange core
              staticBorderColor = const Color(0xFFDDDDDD).withAlpha(0);
            }
            // 🔶 ATHLETE — DARK (secondary is desaturated teal): teal-gray -> orange
            else if (themeProvider.isAthleteTheme && themeProvider.isDarkMode) {
              // Secondary: #6A8F8A (teal-gray), Accent: #FE8019 (orange)
              beamColorFrom = const Color(0xFF6A8F8A); // teal-gray head
              beamColorTo = const Color(0xFFFE8019); // orange core
              staticBorderColor = const Color(0xFF555555).withAlpha(0);
            }
            // 🟩 NINJA — LIGHT (secondary is Deep Orange): deep orange -> teal
            else if (themeProvider.isNinjaTheme && !themeProvider.isDarkMode) {
              // Secondary: #C74600 (deep orange), Accent: #046252 (teal)
              beamColorFrom = const Color(0xFFC74600); // deep orange head
              beamColorTo = const Color(0xFF046252); // teal core
              staticBorderColor = const Color(0xFFDDDDDD).withAlpha(0);
            }
            // 🟩 NINJA — DARK (secondary is Peach): peach -> lime
            else if (themeProvider.isNinjaTheme && themeProvider.isDarkMode) {
              // Secondary: #F5BC74 (peach), Accent: #D8FA69 (lime)
              beamColorFrom = const Color(0xFFF5BC74); // peach head
              beamColorTo = const Color(0xFFD8FA69); // lime core
              staticBorderColor = const Color(0xFF555555).withAlpha(0);
            }

            break;

            
          case CustomButtonStyle.custom:
            // Original theme-responsive behavior
            if (isAthlete) {
              if (isDark) {
                beamColorFrom = const Color(0xFFFE8019);
                beamColorTo = const Color(0xFFCB3920);
                staticBorderColor = const Color(0xFF555555).withAlpha(0);
                backgroundColor = const Color(0xFF373737);
                textColor = Colors.white;
              } else {
                beamColorFrom = const Color(0xFFCB3920);
                beamColorTo = const Color(0xFF881593);
                staticBorderColor = const Color(0xFFDDDDDD).withAlpha(0);
                backgroundColor = const Color(0xFFFFF4E3);
                textColor = const Color(0xFF3C3836);
              }
            } else {
              // Ninja theme
              if (isDark) {
                beamColorFrom = const Color(0xFFD8FA69);
                beamColorTo = const Color(0xFFf5BC74);
                staticBorderColor = const Color(0xFF555555).withAlpha(0);
                backgroundColor = const Color(0xFF233d4d);
                textColor = const Color(0xFFCAD0D3);
              } else {
                beamColorFrom = const Color(0xFF046252);
                beamColorTo = const Color(0xFFC74600);
                staticBorderColor = const Color(0xFFDDDDDD).withAlpha(0);
                backgroundColor = const Color(0xFFF8F8F8);
                textColor = const Color(0xFF3C3836);
              }
            }
            break;
        }

        // Adjust colors when disabled
        if (widget.onPressed == null || widget.isLoading) {
          beamColorFrom = beamColorFrom.withAlpha(76); // 0.3 alpha
          beamColorTo = beamColorTo.withAlpha(76); // 0.3 alpha
          staticBorderColor = staticBorderColor.withAlpha(0); // 0.5 alpha
          textColor = textColor.withAlpha(127); // 0.5 alpha
        }

        return MouseRegion(
          cursor: (widget.onPressed != null && !widget.isLoading) 
              ? SystemMouseCursors.click 
              : SystemMouseCursors.basic,
          onEnter: (_) {
            if (widget.onPressed != null && !widget.isLoading) {
              setState(() {
                _isHovered = true;
              });
            }
          },
          onExit: (_) {
            setState(() {
              _isHovered = false;
            });
          },
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              final radius = BorderRadius.circular(10); // 🔷 one shape everywhere
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    // Always use dark grey shadow regardless of theme
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D2D2D).withAlpha(204), // 0.8 alpha
                        offset: Offset(0, _isPressed ? 2 : 4),
                        blurRadius: _isPressed ? 4 : 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: BorderBeam(
                    duration: 8, // Faster animation for button
                    borderWidth: 4.5,
                    colorFrom: beamColorFrom,
                    colorTo: beamColorTo,
                    staticBorderColor: staticBorderColor,
                    borderRadius: radius,
                    child: GestureDetector(
                      onTapDown: _handleTapDown,
                      onTapUp: _handleTapUp,
                      onTapCancel: _handleTapCancel,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: _isHovered 
                              ? backgroundColor.withAlpha(229) // 0.9 alpha
                              : backgroundColor,
                          borderRadius: radius,
                        ),
                        child: Center(
                          child: widget.isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: textColor,
                                  ),
                                )
                              : Text(
                                  widget.text,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}