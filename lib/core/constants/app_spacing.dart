/// RankX Design System - Spacing & Sizing Constants
///
/// Use these constants for ALL spacing/padding to maintain visual consistency.
/// DO NOT use hardcoded numbers elsewhere in the app.

class AppSpacing {
  // ============================================
  // SPACING SCALE (8pt grid system)
  // ============================================

  static const double xs = 4.0; // Tiny gaps (chip padding, icon margins)
  static const double sm = 8.0; // Small gaps (list item spacing)
  static const double md =
      16.0; // Default spacing (card padding, screen margins)
  static const double lg = 24.0; // Large gaps (section spacing)
  static const double xl = 32.0; // Extra large (hero padding, major sections)
  static const double xxl = 48.0; // Huge (splash screens, empty states)

  // ============================================
  // COMPONENT-SPECIFIC PADDING
  // ============================================

  // Screen Padding
  static const double screenHorizontal = 20.0;
  static const double screenVertical = 16.0;

  // Card Padding
  static const double cardPadding = 16.0;
  static const double cardPaddingLarge = 20.0;

  // Button Padding
  static const double buttonVertical = 16.0;
  static const double buttonHorizontal = 28.0;
  static const double buttonSmallVertical = 12.0;
  static const double buttonSmallHorizontal = 20.0;

  // Input Field Padding
  static const double inputVertical = 16.0;
  static const double inputHorizontal = 16.0;

  // List Item Padding
  static const double listItemVertical = 12.0;
  static const double listItemHorizontal = 16.0;

  // ============================================
  // CORNER RADIUS (Brand: Soft & Modern)
  // ============================================

  static const double radiusXs = 8.0; // Tags, chips
  static const double radiusSm = 12.0; // Small buttons, chips
  static const double radiusMd = 16.0; // Buttons, input fields
  static const double radiusLg = 20.0; // Cards, large containers
  static const double radiusXl = 24.0; // Modals, bottom sheets
  static const double radiusFull = 999.0; // Fully rounded (avatars, pills)

  // ============================================
  // ICON SIZES
  // ============================================

  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // ============================================
  // COMPONENT HEIGHTS
  // ============================================

  static const double buttonHeight = 52.0; // Primary buttons
  static const double buttonHeightSm = 42.0; // Secondary buttons
  static const double textFieldHeight = 52.0; // Text input fields
  static const double appBarHeight = 64.0; // Custom app bars
  static const double bottomNavHeight = 72.0; // Bottom navigation
  static const double chipHeight = 36.0; // Filter chips

  // ============================================
  // AVATAR SIZES
  // ============================================

  static const double avatarSm = 32.0;
  static const double avatarMd = 48.0;
  static const double avatarLg = 64.0;
  static const double avatarXl = 96.0;

  // ============================================
  // ELEVATION (Depth Hierarchy)
  // ============================================

  static const double elevationNone = 0.0; // Flat (admin UI, dividers)
  static const double elevationSm = 2.0; // Cards (light mode)
  static const double elevationMd = 4.0; // Elevated cards, dropdowns
  static const double elevationLg = 6.0; // FABs, important CTAs
  static const double elevationXl = 8.0; // Modals, dialogs

  // ============================================
  // DIVIDER THICKNESS
  // ============================================

  static const double dividerThin = 1.0;
  static const double dividerThick = 2.0;
}
