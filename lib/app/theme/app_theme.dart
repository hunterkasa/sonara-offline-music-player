import 'package:flutter/material.dart';

enum AppThemeMode { system, light, dark, amoled }

class AppTheme {
  const AppTheme._();

  static const Color defaultSeedColor = Color(0xFF6750A4);

  static ThemeData light({Color seedColor = defaultSeedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    return _buildTheme(colorScheme, isAmoled: false);
  }

  static ThemeData dark({Color seedColor = defaultSeedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return _buildTheme(colorScheme, isAmoled: false);
  }

  static ThemeData amoled({Color seedColor = defaultSeedColor}) {
    final baseDarkScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    final amoledScheme = baseDarkScheme.copyWith(
      surface: Colors.black,
      surfaceDim: Colors.black,
      surfaceBright: const Color(0xFF161616),
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: const Color(0xFF0A0A0A),
      surfaceContainer: const Color(0xFF121212),
      surfaceContainerHigh: const Color(0xFF1E1E1E),
      surfaceContainerHighest: const Color(0xFF282828),
      onSurface: Colors.white,
    );
    return _buildTheme(amoledScheme, isAmoled: true);
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme, {
    required bool isAmoled,
  }) {
    final scaffoldBg = isAmoled ? Colors.black : colorScheme.surface;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      cardColor: isAmoled
          ? const Color(0xFF121212)
          : colorScheme.surfaceContainer,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        indicatorColor: isAmoled
            ? Colors.white12
            : colorScheme.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isAmoled ? Colors.white : colorScheme.onSecondaryContainer,
            );
          }
          return IconThemeData(
            color: isAmoled ? Colors.white60 : colorScheme.onSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isAmoled ? Colors.white : colorScheme.onSurface,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isAmoled ? Colors.white54 : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isAmoled
            ? const Color(0xFF101010)
            : colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
      ),
    );
  }
}
