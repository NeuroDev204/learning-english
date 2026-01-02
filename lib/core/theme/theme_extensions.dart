import 'package:flutter/material.dart';

/// Extension methods để dễ dàng access theme colors
extension ThemeExtensions on BuildContext {
  // Color shortcuts
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // Commonly used colors
  Color get surfaceColor => colors.surface;
  Color get backgroundColor => colors.background;
  Color get primaryColor => colors.primary;
  Color get textColor => colors.onSurface;
  Color get subtitleColor => textStyles.bodyMedium?.color ?? Colors.grey;

  // Adaptive colors - automatically switch based on theme
  Color get cardColor => isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get borderColor =>
      isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade300;

  // Text colors
  Color get primaryTextColor =>
      isDarkMode ? const Color(0xFFE3E3E3) : const Color(0xFF2D3748);
  Color get secondaryTextColor =>
      isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF94A3B8);
}

/// Helper function to get adaptive color
Color getAdaptiveColor(
  BuildContext context, {
  required Color lightColor,
  required Color darkColor,
}) {
  return Theme.of(context).brightness == Brightness.dark
      ? darkColor
      : lightColor;
}
