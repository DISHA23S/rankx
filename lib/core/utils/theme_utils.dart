import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Utility class for theme-aware colors and styles
class ThemeUtils {
  /// Get primary color based on current theme
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.primaryLight
        : AppColors.primary;
  }

  /// Get text primary color based on current theme
  static Color getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
  }

  /// Get text secondary color based on current theme
  static Color getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
  }

  /// Get text tertiary color based on current theme
  static Color getTextTertiaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiary;
  }

  /// Get border color based on current theme
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.borderDark
        : AppColors.borderLight;
  }

  /// Get background color based on current theme
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.bgPrimaryDark
        : AppColors.bgPrimary;
  }

  /// Get card background color based on current theme
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.bgCardDark
        : AppColors.bgCard;
  }

  /// Check if current theme is dark
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
