import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// App-wide visual theme for Everything Passport.
///
/// Uses the teal from `assets/logo.svg` as the seed color; light and dark
/// [ColorScheme]s are generated from it via Material 3 `fromSeed`. Default
/// text renders in the theme's primary color.
abstract final class AppTheme {
  /// Seed color used to generate the light and dark color schemes. Matches
  /// the teal in `assets/logo.svg`.
  static const Color seedColor = Color(0xFF286671);

  /// Cream scaffold background shared with the native splash screen.
  static const Color scaffoldBackground = Color(0xFFFBF8F0);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ).copyWith(primary: seedColor, onPrimary: Colors.white);
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme.primary),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: seedColor,
        surfaceTintColor: Colors.transparent,
      ),
      // ListTile resolves title/subtitle/icon colors via listTileTheme,
      // ignoring the textTheme color applied above.
      listTileTheme: ListTileThemeData(
        textColor: seedColor,
        iconColor: seedColor,
      ),
      inputDecorationTheme: _inputDecorationTheme(seedColor),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme.primary),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        textColor: colorScheme.primary,
        iconColor: colorScheme.primary,
      ),
      inputDecorationTheme: _inputDecorationTheme(colorScheme.primary),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(Color color) {
    return InputDecorationTheme(
      labelStyle: TextStyle(color: color),
      prefixIconColor: color,
      suffixIconColor: color,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: color, width: 2),
      ),
    );
  }

  static TextTheme _textTheme(Color color) {
    final typography = Typography.material2021(platform: defaultTargetPlatform);
    return typography.black.apply(bodyColor: color, displayColor: color);
  }
}
