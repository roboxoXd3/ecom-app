import 'package:flutter/material.dart';

class AppTheme {
  // PRIMARY COLORS (60% usage - Green for actions, CTAs, highlights)
  static const Color primaryColor = Color(
    0xFF10B981,
  ); // Emerald Green - Main CTAs
  static const Color primaryVariant = Color(
    0xFF059669,
  ); // Deeper Green - Hover states
  static const Color successColor = Color(
    0xFF10B981,
  ); // Use same green for success

  // SECONDARY COLORS (30% usage - Black for text, icons, navigation)
  static const Color textPrimary = Color(0xFF1F2937); // Soft Black - Main text
  static const Color textSecondary = Color(0xFF6B7280); // Gray - Secondary text
  static const Color iconColor = Color(0xFF1F2937); // Soft Black - Icons
  static const Color navigationColor = Color(
    0xFF1F2937,
  ); // Soft Black - Navigation

  // ACCENT COLORS (10% usage - Golden for special elements ONLY)
  static const Color goldenAccent = Color(
    0xFFD97706,
  ); // Rich Gold - Special badges, ratings
  static const Color goldenLight = Color(0xFFFBBF24); // Light Gold - Sale tags

  // NEUTRAL COLORS
  static const Color scaffoldLightColor = Color(0xFFF8F8F8);
  static const Color scaffoldDarkColor = Color(0xFF1F2937); // Soft Black
  static const Color errorColor = Color(0xFFEF4444); // Keep red for errors

  // Extended Color Palette
  // Neutral Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Category Colors (aligned with Green, Black, Golden theme)
  static const Color categoryEmerald = Color(0xFF10B981); // Primary Green
  static const Color categoryGold = Color(0xFFD97706); // Rich Gold
  static const Color categoryDarkGreen = Color(0xFF059669); // Deeper Green
  static const Color categoryAmber = Color(0xFFF59E0B); // Lighter Gold
  static const Color categoryForest = Color(0xFF047857); // Forest Green
  static const Color categoryBronze = Color(0xFFB45309); // Bronze Gold
  static const Color categoryTeal = Color(0xFF0D9488); // Teal Green
  static const Color categoryCharcoal = Color(
    0xFF374151,
  ); // Charcoal (complementary)

  // Semantic Colors (following 60-30-10 strategy)
  static const Color warning = Color(
    0xFFF59E0B,
  ); // Orange for warnings (not golden)
  static const Color info = Color(0xFF0D9488); // Teal green for info
  static const Color transparent = Colors.transparent;

  // Size Chart Specific Colors
  static const Color sizeChartBackground = Color(0xFFFAFAFA); // grey50
  static const Color sizeChartBorder = Color(0xFFE0E0E0); // grey300
  static const Color sizeChartHeader = Color(0xFFEEEEEE); // grey200
  static const Color sizeChartHeaderText = Color(0xFF424242); // grey800
  static const Color sizeChartSecondaryText = Color(0xFF757575); // grey600
  static const Color sizeChartBodyText = Color(0xFF616161); // grey700
  static const Color sizeChartDisabled = Color(0xFFBDBDBD); // grey400
  static const Color sizeChartAvailable = Color(0xFFFFFFFF); // white
  static const Color sizeChartUnavailable = Color(0xFFFAFAFA); // grey50

  // Info/Help Colors (Blue theme)
  static const Color infoBackground = Color(0xFFEFF6FF); // blue50
  static const Color infoBorder = Color(0xFFBFDBFE); // blue200
  static const Color infoText = Color(0xFF1D4ED8); // blue700
  static const Color infoTextSecondary = Color(0xFF2563EB); // blue600

  // Warning/Note Colors (Orange theme)
  static const Color warningBackground = Color(0xFFFFF7ED); // orange50
  static const Color warningBorder = Color(0xFFFED7AA); // orange200
  static const Color warningText = Color(0xFFC2410C); // orange700

  // Special Elements (Golden - use sparingly!)
  static const Color ratingStars = goldenAccent; // Golden for star ratings
  static const Color premiumBadge = goldenAccent; // Golden for premium features
  static const Color saleTag = goldenLight; // Light golden for sale tags

  // Background Colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textInverse = Colors.white;

  // Category Colors Array (for easy access)
  static const List<Color> categoryColors = [
    categoryEmerald,
    categoryGold,
    categoryDarkGreen,
    categoryAmber,
    categoryForest,
    categoryBronze,
    categoryTeal,
    categoryCharcoal,
  ];

  // Additional Theme Colors
  static const Color surface = Color(0xFFFFFFFF); // Clean white surface
  static const Color onSurface = Color(0xFF1F2937); // Soft black on surface

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: scaffoldLightColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: primaryVariant,
      error: errorColor,
      surface: surfaceLight,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: grey300,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: navigationColor),
      titleTextStyle: TextStyle(
        color: navigationColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: scaffoldDarkColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryVariant,
      error: errorColor,
      surface: surfaceDark,
      onSurface: Colors.white,
      onSurfaceVariant: Color(0xFFBDBDBD),
      outline: Color(0xFF424242),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  // Helper Methods for Strategic Color Usage (60-30-10 Rule)

  // GREEN (60%) - Use for primary actions and highlights
  static Color get ctaButton => primaryColor;
  static Color get addToCartButton => primaryColor;
  static Color get buyNowButton => primaryColor;
  static Color get activeTab => primaryColor;
  static Color get successMessage => successColor;

  // BLACK (30%) - Use for text, icons, navigation
  static Color get mainText => textPrimary;
  static Color get secondaryText => textSecondary;
  static Color get icons => iconColor;
  static Color get navigation => navigationColor;

  // GOLDEN (10%) - Use sparingly for special elements only!
  static Color get starRating => ratingStars;
  static Color get premiumFeature => premiumBadge;
  static Color get salePrice => saleTag;

  // Theme-aware color helpers (NEW)
  // Use these methods to get colors that automatically adapt to light/dark mode
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  static Color getSurface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getBackground(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getBorder(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }

  static Color getDisabledText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.38);
  }

  static Color getHintText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7);
  }

  static Color getOutline(BuildContext context) {
    return Theme.of(context).colorScheme.outline;
  }
}
