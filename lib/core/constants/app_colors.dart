import 'package:flutter/material.dart';

class AppColors {
  // ============================================
  // BRAND CORE (from RankX Logo)
  // ============================================

  // Primary Colors - Dark Blue (Logo background color)
  static const Color primary = Color(0xFF2C4A7C); // Dark blue (logo background)
  static const Color primaryLight = Color(0xFF3D5F99); // Lighter dark blue
  static const Color primaryDark = Color(0xFF1F3659); // Deeper dark blue
  static const Color primaryGradientStart = Color(0xFF3D5F99); // Lighter
  static const Color primaryGradientEnd = Color(0xFF2C4A7C); // Dark blue

  // ============================================
  // ENERGY/ACTION (Logo "X")
  // ============================================

  // Secondary Colors - Orange (Logo "X" accent)r
  static const Color secondary = Color(0xFFFF6B35); // Vibrant orange (logo X)
  static const Color secondaryLight = Color(0xFFFF8C5C); // Light orange
  static const Color secondaryDark = Color(0xFFE85A28); // Deep orange
  static const Color secondaryGradientStart = Color(0xFFFF8C5C);
  static const Color secondaryGradientEnd = Color(0xFFFF6B35); // Orange

  // Accent Colors (Orange - use sparingly)
  static const Color accent = Color(0xFFFF6B35); // Orange accent
  static const Color accentLight = Color(0xFFFF8C5C);
  static const Color accentDark = Color(0xFFE85A28);

  // ============================================
  // BACKGROUNDS - LIGHT MODE (Light with dark blue tint)
  // ============================================

  // Backgrounds - Light Mode
  static const Color bgPrimary = Color(0xFFF0F3F8); // Very light blue-gray
  static const Color bgSecondary = Color(0xFFE6ECF5); // Light blue tint
  static const Color bgCard = Color(0xFFFFFFFF); // Pure white cards
  static const Color bgGradientStart = Color(0xFFF0F3F8);
  static const Color bgGradientEnd = Color(0xFFE6ECF5); // Light blue gradient

  // ============================================
  // BACKGROUNDS - DARK MODE (Dark Blue - Logo color)
  // ============================================

  // Backgrounds - Dark Mode (Logo dark blue)
  static const Color bgPrimaryDark = Color(0xFF0F1419); // True dark background
  static const Color bgSecondaryDark = Color(0xFF1A1F2E); // Slightly lighter dark
  static const Color bgCardDark = Color(0xFF232938); // Card background - dark with subtle blue tint
  static const Color bgGradientStartDark = Color(0xFF0F1419);
  static const Color bgGradientEndDark = Color(0xFF1A1F2E); // Dark gradient

  // ============================================
  // TYPOGRAPHY COLORS
  // ============================================

  // Text Colors - Light Mode
  static const Color textPrimary = Color(
    0xFF2C4A7C,
  ); // Dark blue (readable, branded)
  static const Color textSecondary = Color(0xFF4A5F7F); // Medium blue-gray
  static const Color textTertiary = Color(0xFF7A8CA8); // Light blue-gray
  static const Color textLight = Color(0xFFFFFFFF); // On dark surfaces

  // Text Colors - Dark Mode
  static const Color textPrimaryDark = Color(0xFFFFFFFF); // Pure white for maximum contrast
  static const Color textSecondaryDark = Color(0xFFE0E6ED); // Very light gray
  static const Color textTertiaryDark = Color(0xFFB0B8C3); // Medium light gray

  // ============================================
  // SEMANTIC STATES
  // ============================================

  // Status Colors (Adjusted for better contrast)
  static const Color success = Color(0xFF0EAD78); // Emerald green
  static const Color successLight = Color(0xFF34D399);
  static const Color error = Color(0xFFE84A3F); // Soft red
  static const Color errorLight = Color(0xFFF87171);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color info = Color(0xFF3B82F6); // Blue
  static const Color infoLight = Color(0xFF60A5FA);

  // Quiz-Specific Semantic Colors
  static const Color correct = Color(0xFF0EAD78); // Emerald
  static const Color incorrect = Color(0xFFE84A3F); // Soft red
  static const Color neutral = Color(0xFF5E7A9B); // Blue-gray (branded)

  // ============================================
  // ADMIN-SPECIFIC COLORS (Analytical Tone)
  // ============================================

  // Admin uses dark blue tones (consistent with brand)
  static const Color adminPrimary = Color(0xFF2C4A7C); // Dark blue
  static const Color adminSecondary = Color(0xFF4A5F7F); // Blue-gray
  static const Color adminAccent = Color(0xFF3D5F99); // Lighter blue
  static const Color adminBgCard = Color(0xFFF0F3F8); // Light blue-gray
  static const Color adminBgCardDark = Color(0xFF232938); // Dark card for admin dark mode
  static const Color adminBorder = Color(0xFFD6E3ED); // Soft blue-gray

  // ============================================
  // DATA VISUALIZATION (Charts/Progress)
  // ============================================

  // Charts - Dark blue & Orange (logo inspired)
  static const Color chartColor1 = Color(0xFF3D5F99); // Lighter dark blue
  static const Color chartColor2 = Color(0xFF2C4A7C); // Dark blue
  static const Color chartColor3 = Color(0xFF1F3659); // Deeper dark blue
  static const Color chartColor4 = Color(0xFFFF6B35); // Orange
  static const Color chartColor5 = Color(0xFF0EAD78); // Green
  static const Color chartColor6 = Color(0xFF5E7A9B); // Blue-gray

  // ============================================
  // BORDERS & DIVIDERS
  // ============================================

  // Borders (Dark blue-tinted)
  static const Color borderLight = Color(0xFFD6E3ED); // Soft blue-gray
  static const Color borderMedium = Color(0xFFB8C8DC); // Medium blue-gray
  static const Color borderDark = Color(0xFF3D4855); // Dark border for dark mode
  static const Color borderDarkMode = Color(0xFF3D4855); // Explicit dark mode border

  // ============================================
  // GRADIENTS (USE SPARINGLY - User UI Only)
  // ============================================

  // Gradients (Dark Blue & Orange from logo)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGradientStart, primaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryGradientStart, secondaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF0EAD78), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFE84A3F), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [bgGradientStart, bgGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradientDark = LinearGradient(
    colors: [bgGradientStartDark, bgGradientEndDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
