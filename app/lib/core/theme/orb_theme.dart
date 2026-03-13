import 'package:flutter/material.dart';
import 'orb_colors.dart';
import 'orb_typography.dart';

class OrbTheme {
  OrbTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: OrbColors.bgBase,
      colorScheme: const ColorScheme.dark(
        primary: OrbColors.calm,
        secondary: OrbColors.calmLight,
        surface: OrbColors.bgCard,
        error: OrbColors.excited,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: OrbColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: OrbTypography.displayLarge,
        displayMedium: OrbTypography.displayMedium,
        headlineLarge: OrbTypography.headlineLarge,
        headlineMedium: OrbTypography.headlineMedium,
        headlineSmall: OrbTypography.headlineSmall,
        titleLarge: OrbTypography.titleLarge,
        titleMedium: OrbTypography.titleMedium,
        bodyLarge: OrbTypography.bodyLarge,
        bodyMedium: OrbTypography.bodyMedium,
        bodySmall: OrbTypography.bodySmall,
        labelLarge: OrbTypography.labelLarge,
        labelMedium: OrbTypography.labelMedium,
        labelSmall: OrbTypography.labelSmall,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: OrbTypography.titleLarge,
        iconTheme: IconThemeData(color: OrbColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: OrbColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: OrbColors.borderSubtle),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: OrbColors.bgCard,
        selectedItemColor: OrbColors.calm,
        unselectedItemColor: OrbColors.textTertiary,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OrbColors.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: OrbColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: OrbColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: OrbColors.calm),
        ),
        hintStyle: OrbTypography.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: OrbColors.calm,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: OrbTypography.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: OrbColors.bgElevated,
        selectedColor: OrbColors.calmGlow,
        labelStyle: OrbTypography.labelMedium,
        side: const BorderSide(color: OrbColors.borderSubtle),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: OrbColors.borderSubtle,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(
        color: OrbColors.textSecondary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return OrbColors.calm;
          return OrbColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return OrbColors.calmGlow;
          return OrbColors.bgOverlay;
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: OrbColors.calm,
        inactiveTrackColor: OrbColors.bgOverlay,
        thumbColor: OrbColors.calm,
      ),
    );
  }
}
