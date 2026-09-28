import 'package:flutter/material.dart';

class AppColors {
  // Brand Base
  static const Color primaryNavy = Color(0xFF0F1E36);
  static const Color primaryNavyDark = Color(0xFF091322);
  static const Color primaryNavyLight = Color(0xFF1B2F4D);
  static const Color goldAccent = Color(0xFFC5A059);
  static const Color goldAccentLight = Color(0xFFE5C887);

  // Light Theme Palette
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceCard = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Dark Theme Palette
  static const Color backgroundDark = Color(0xFF090E17);
  static const Color surfaceDark = Color(0xFF131D2D);
  static const Color surfaceDarkElevated = Color(0xFF1B283D);
  static const Color borderDark = Color(0xFF23354E);
  static const Color textDarkPrimary = Color(0xFFF1F5F9);
  static const Color textDarkSecondary = Color(0xFF94A3B8);
  static const Color textDarkMuted = Color(0xFF64748B);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
}

class AppTheme {
  static const Color primaryDark = AppColors.primaryNavyDark;
  static const Color navyBlue = AppColors.primaryNavy;
  static const Color goldAccent = AppColors.goldAccent;
  static const Color surfaceDark = AppColors.surfaceDark;
  static const Color textLight = Colors.white;
  static const Color textMuted = AppColors.textMuted;
  static const Color background = AppColors.backgroundLight;

  // Context-aware color helpers
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color backgroundColor(BuildContext context) =>
      isDark(context) ? AppColors.backgroundDark : AppColors.backgroundLight;

  static Color cardColor(BuildContext context) =>
      isDark(context) ? AppColors.surfaceDark : Colors.white;

  static Color elevatedCardColor(BuildContext context) =>
      isDark(context) ? AppColors.surfaceDarkElevated : Colors.white;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? AppColors.borderDark : AppColors.borderLight;

  static Color textPrimaryColor(BuildContext context) =>
      isDark(context) ? AppColors.textDarkPrimary : AppColors.primaryNavy;

  static Color textSecondaryColor(BuildContext context) =>
      isDark(context) ? AppColors.textDarkSecondary : AppColors.textSecondary;

  static Color primaryOrGold(BuildContext context) =>
      isDark(context) ? AppColors.goldAccentLight : AppColors.primaryNavy;

  static Color appBarColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF0F1827) : Colors.white;

  static Color dividerColor(BuildContext context) =>
      isDark(context) ? AppColors.borderDark : AppColors.borderLight;

  /* ---------------- LIGHT THEME ---------------- */
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryNavy,
        secondary: AppColors.goldAccent,
        surface: AppColors.surfaceCard,
        error: AppColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryNavy,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryNavy,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.primaryNavy),
        actionsIconTheme: IconThemeData(color: AppColors.primaryNavy),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          side: const BorderSide(color: AppColors.primaryNavy, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColors.primaryNavy, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderLight, width: 0.8),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.goldAccent,
        unselectedLabelColor: Colors.white70,
        indicatorColor: AppColors.goldAccent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
      ),
      dividerColor: AppColors.borderLight,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        modalBackgroundColor: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  /* ---------------- DARK THEME ---------------- */
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.goldAccent,
        secondary: AppColors.goldAccentLight,
        surface: AppColors.surfaceDark,
        error: AppColors.danger,
        onPrimary: AppColors.primaryNavyDark,
        onSecondary: Colors.black,
        onSurface: AppColors.textDarkPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F1827),
        foregroundColor: AppColors.textDarkPrimary,
        surfaceTintColor: Color(0xFF0F1827),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textDarkPrimary,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.textDarkPrimary),
        actionsIconTheme: IconThemeData(color: AppColors.textDarkPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldAccent,
          foregroundColor: AppColors.primaryNavyDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.goldAccentLight,
          side: const BorderSide(color: AppColors.goldAccent, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.goldAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        hintStyle: const TextStyle(color: AppColors.textDarkMuted, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColors.goldAccentLight, fontSize: 13, fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderDark, width: 0.8),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.goldAccentLight,
        unselectedLabelColor: AppColors.textDarkMuted,
        indicatorColor: AppColors.goldAccentLight,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
      ),
      dividerColor: AppColors.borderDark,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: AppColors.surfaceDark,
        modalBackgroundColor: AppColors.surfaceDark,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
