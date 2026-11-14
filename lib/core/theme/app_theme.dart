import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Obsidian Clinical Dark Color Scheme
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF00E5A3), // Emerald Clinical
    onPrimary: Color(0xFF003824),
    primaryContainer: Color(0xFF005237),
    onPrimaryContainer: Color(0xFF5FFFC2),
    secondary: Color(0xFF00D2FF), // Cyan Telemetry
    onSecondary: Color(0xFF003544),
    secondaryContainer: Color(0xFF004D62),
    onSecondaryContainer: Color(0xFFBCE9FF),
    tertiary: Color(0xFF9D84FF), // Amethyst Diagnostic
    onTertiary: Color(0xFF260867),
    tertiaryContainer: Color(0xFF3F2580),
    onTertiaryContainer: Color(0xFFEADBFF),
    error: Color(0xFFFF5252),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF0C1017), // Deep Obsidian
    onSurface: Color(0xFFE2E7EE),
    surfaceContainerLowest: Color(0xFF070A0F),
    surfaceContainerLow: Color(0xFF111721),
    surfaceContainer: Color(0xFF161E2B),
    surfaceContainerHigh: Color(0xFF1C2636),
    surfaceContainerHighest: Color(0xFF232E42),
    onSurfaceVariant: Color(0xFF94A3B8),
    outline: Color(0xFF334155),
    outlineVariant: Color(0xFF1E293B),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE2E7EE),
    onInverseSurface: Color(0xFF161E2B),
    inversePrimary: Color(0xFF006C4A),
  );

  // Crisp Sterile Light Color Scheme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF007A54),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF95F7D0),
    onPrimaryContainer: Color(0xFF002114),
    secondary: Color(0xFF00687A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFB5EBFF),
    onSecondaryContainer: Color(0xFF001F26),
    tertiary: Color(0xFF5B45A0),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFE7DEFF),
    onTertiaryContainer: Color(0xFF1A004D),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    surface: Color(0xFFF8FAFC),
    onSurface: Color(0xFF0F172A),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF1F5F9),
    surfaceContainer: Color(0xFFE2E8F0),
    surfaceContainerHigh: Color(0xFFCBD5E1),
    surfaceContainerHighest: Color(0xFF94A3B8),
    onSurfaceVariant: Color(0xFF475569),
    outline: Color(0xFF94A3B8),
    outlineVariant: Color(0xFFE2E8F0),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF1E293B),
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: Color(0xFF00E5A3),
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: darkColorScheme.surface,
      canvasColor: darkColorScheme.surface,
      cardColor: darkColorScheme.surfaceContainer,
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.surface,
        foregroundColor: darkColorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkColorScheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: darkColorScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      cardTheme: CardThemeData(
        color: darkColorScheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: darkColorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkColorScheme.error),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: lightColorScheme.surface,
      canvasColor: lightColorScheme.surface,
      cardColor: lightColorScheme.surfaceContainerLowest,
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.surface,
        foregroundColor: lightColorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: lightColorScheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(color: lightColorScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      cardTheme: CardThemeData(
        color: lightColorScheme.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: lightColorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightColorScheme.error),
        ),
      ),
    );
  }
}
