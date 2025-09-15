// lib/widgets/custom_beam_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../config/button_theme_config.dart'; // Import the config

enum CustomButtonStyle {
  primary,
  secondary,
  custom,
}

class CustomBeamButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final CustomButtonStyle buttonStyle;

  // 🎯 These now default to global config values
  final double? borderRadius;
  final Duration? animationDuration;
  final Duration? pressAnimationDuration;
  final double? scaleOnPress;
  final double? hoverOpacity;
  final bool? enableShadows;
  final double? shadowBlurRadius;
  final double? shadowSpreadRadius;
  final Offset? shadowOffset;
  final double? pressedShadowBlurRadius;
  final Offset? pressedShadowOffset;
  final double? borderWidth;

  const CustomBeamButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.buttonStyle = CustomButtonStyle.primary,

    // 🎯 All these now pull from global config if not specified
    this.borderRadius, // Uses ButtonThemeConfig.globalBorderRadius if null
    this.animationDuration, // Uses ButtonThemeConfig.globalAnimationDuration if null
    this.pressAnimationDuration, // Uses ButtonThemeConfig.globalPressAnimationDuration if null
    this.scaleOnPress, // Uses ButtonThemeConfig.globalScaleOnPress if null
    this.hoverOpacity, // Uses ButtonThemeConfig.globalHoverOpacity if null
    this.enableShadows, // Uses config based on button style if null
    this.shadowBlurRadius, // Uses config based on button style if null
    this.shadowSpreadRadius, // Uses config based on button style if null
    this.shadowOffset, // Uses config based on button style if null
    this.pressedShadowBlurRadius, // Uses config based on button style if null
    this.pressedShadowOffset, // Uses config based on button style if null
    this.borderWidth, // Uses ButtonThemeConfig.secondaryBorderWidth if null
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

  // 🎯 Get effective values (widget override or global config)
  double get effectiveWidth => widget.width ?? ButtonThemeConfig.defaultWidth;
  double get effectiveHeight =>
      widget.height ?? ButtonThemeConfig.defaultHeight;
  double get effectiveBorderRadius =>
      widget.borderRadius ?? ButtonThemeConfig.globalBorderRadius;
  Duration get effectiveAnimationDuration =>
      widget.animationDuration ?? ButtonThemeConfig.globalAnimationDuration;
  Duration get effectivePressAnimationDuration =>
      widget.pressAnimationDuration ??
      ButtonThemeConfig.globalPressAnimationDuration;
  double get effectiveScaleOnPress =>
      widget.scaleOnPress ?? ButtonThemeConfig.globalScaleOnPress;
  double get effectiveHoverOpacity =>
      widget.hoverOpacity ?? ButtonThemeConfig.globalHoverOpacity;
  double get effectiveBorderWidth =>
      widget.borderWidth ?? ButtonThemeConfig.secondaryBorderWidth;

  bool get effectiveEnableShadows {
    if (widget.enableShadows != null) return widget.enableShadows!;
    return widget.buttonStyle == CustomButtonStyle.primary
        ? ButtonThemeConfig.primaryEnableShadows
        : ButtonThemeConfig.secondaryEnableShadows;
  }

  double get effectiveShadowBlurRadius {
    if (widget.shadowBlurRadius != null) return widget.shadowBlurRadius!;
    return widget.buttonStyle == CustomButtonStyle.primary
        ? ButtonThemeConfig.primaryShadowBlurRadius
        : ButtonThemeConfig.secondaryShadowBlurRadius;
  }

  double get effectiveShadowSpreadRadius {
    if (widget.shadowSpreadRadius != null) return widget.shadowSpreadRadius!;
    return widget.buttonStyle == CustomButtonStyle.primary
        ? ButtonThemeConfig.primaryShadowSpreadRadius
        : ButtonThemeConfig.secondaryShadowSpreadRadius;
  }

  Offset get effectiveShadowOffset {
    if (widget.shadowOffset != null) return widget.shadowOffset!;
    return widget.buttonStyle == CustomButtonStyle.primary
        ? ButtonThemeConfig.primaryShadowOffset
        : ButtonThemeConfig.secondaryShadowOffset;
  }

  double get effectivePressedShadowBlurRadius {
    if (widget.pressedShadowBlurRadius != null)
      return widget.pressedShadowBlurRadius!;
    return widget.buttonStyle == CustomButtonStyle.primary
        ? ButtonThemeConfig.primaryPressedShadowBlurRadius
        : ButtonThemeConfig.secondaryPressedShadowBlurRadius;
  }

  Offset get effectivePressedShadowOffset {
    if (widget.pressedShadowOffset != null) return widget.pressedShadowOffset!;
    return widget.buttonStyle == CustomButtonStyle.primary
        ? ButtonThemeConfig.primaryPressedShadowOffset
        : ButtonThemeConfig.secondaryPressedShadowOffset;
  }

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: effectivePressAnimationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: effectiveScaleOnPress,
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
      setState(() => _isPressed = true);
      _pressController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _pressController.reverse();
      if (widget.onPressed != null && !widget.isLoading) {
        widget.onPressed!();
      }
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  List<BoxShadow> _generateShadows(ThemeProvider themeProvider) {
    if (!effectiveEnableShadows) return [];

    final shadowColor = widget.buttonStyle == CustomButtonStyle.primary
        ? ButtonThemeConfig.getPrimaryShadowColor(
            themeProvider.isAthleteTheme, themeProvider.isDarkMode)
        : ButtonThemeConfig.getSecondaryShadowColor(
            themeProvider.isAthleteTheme, themeProvider.isDarkMode);

    return [
      BoxShadow(
        color: shadowColor.withOpacity(_isPressed ? 0.6 : 0.8),
        offset:
            _isPressed ? effectivePressedShadowOffset : effectiveShadowOffset,
        blurRadius: _isPressed
            ? effectivePressedShadowBlurRadius
            : effectiveShadowBlurRadius,
        spreadRadius: _isPressed ? 0 : effectiveShadowSpreadRadius,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(_isPressed ? 0.15 : 0.3),
        offset: _isPressed ? const Offset(0, 1) : const Offset(0, 3),
        blurRadius: _isPressed ? 3 : 6,
        spreadRadius: 0,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final primaryColor = Theme.of(context).colorScheme.primary;
        final surfaceColor = Theme.of(context).colorScheme.surface;
        final scaffoldBackground = Theme.of(context).scaffoldBackgroundColor;

        Color backgroundColor;
        Color textColor;
        Color borderColor;

        switch (widget.buttonStyle) {
          case CustomButtonStyle.primary:
            backgroundColor = primaryColor;
            textColor = surfaceColor;
            borderColor = Colors.transparent;
            break;
          case CustomButtonStyle.secondary:
            backgroundColor =
                scaffoldBackground; // 🎯 This fixes the shadow issue!
            textColor = primaryColor;
            borderColor = primaryColor;
            break;
          case CustomButtonStyle.custom:
            if (themeProvider.isAthleteTheme) {
              if (themeProvider.isDarkMode) {
                backgroundColor = const Color(0xFF373737);
                textColor = Colors.white;
              } else {
                backgroundColor = const Color(0xFFFFF4E3);
                textColor = const Color(0xFF3C3836);
              }
            } else {
              if (themeProvider.isDarkMode) {
                backgroundColor = const Color(0xFF233d4d);
                textColor = const Color(0xFFCAD0D3);
              } else {
                backgroundColor = const Color(0xFFF8F8F8);
                textColor = const Color(0xFF3C3836);
              }
            }
            borderColor = Colors.transparent;
            break;
        }

        if (widget.onPressed == null || widget.isLoading) {
          textColor = textColor.withAlpha(127);
          borderColor = borderColor.withAlpha(127);
          backgroundColor = backgroundColor.withAlpha(200);
        }

        return MouseRegion(
          cursor: (widget.onPressed != null && !widget.isLoading)
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) {
            if (widget.onPressed != null && !widget.isLoading) {
              setState(() => _isHovered = true);
            }
          },
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              final radius = BorderRadius.circular(effectiveBorderRadius);

              return Transform.scale(
                scale: _scaleAnimation.value,
                child: AnimatedContainer(
                  duration: effectiveAnimationDuration,
                  decoration: BoxDecoration(
                    boxShadow: _generateShadows(themeProvider),
                    borderRadius: radius,
                  ),
                  child: GestureDetector(
                    onTapDown: _handleTapDown,
                    onTapUp: _handleTapUp,
                    onTapCancel: _handleTapCancel,
                    child: Container(
                      width: effectiveWidth,
                      height: effectiveHeight,
                      decoration: BoxDecoration(
                        color: _isHovered
                            ? backgroundColor.withOpacity(effectiveHoverOpacity)
                            : backgroundColor,
                        border:
                            widget.buttonStyle == CustomButtonStyle.secondary
                                ? Border.all(
                                    color: borderColor,
                                    width: effectiveBorderWidth)
                                : null,
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
              );
            },
          ),
        );
      },
    );
  }
}
