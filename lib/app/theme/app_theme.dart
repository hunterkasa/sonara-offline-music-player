import 'package:flutter/material.dart';

enum AppThemeMode { system, light, dark, amoled }

class AppTheme {
  const AppTheme._();

  static const Color defaultSeedColor = Color(0xFF6750A4);

  static ThemeData light({Color seedColor = defaultSeedColor}) {
    final baseLightScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final lightScheme = baseLightScheme.copyWith(
      surface: Colors.white,
      surfaceDim: const Color(0xFFF8F9FA),
      surfaceBright: Colors.white,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF7F8FA),
      surfaceContainer: const Color(0xFFF1F3F5),
      surfaceContainerHigh: const Color(0xFFE9ECEF),
      surfaceContainerHighest: const Color(0xFFDEE2E6),
      onSurface: const Color(0xFF191C1E),
      onSurfaceVariant: const Color(0xFF44474E),
    );
    return _buildTheme(lightScheme, isAmoled: false, isLight: true);
  }

  static ThemeData dark({Color seedColor = defaultSeedColor}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return _buildTheme(colorScheme, isAmoled: false, isLight: false);
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
    return _buildTheme(amoledScheme, isAmoled: true, isLight: false);
  }

  static ThemeData _buildTheme(
    ColorScheme colorScheme, {
    required bool isAmoled,
    required bool isLight,
  }) {
    final scaffoldBg = isAmoled
        ? Colors.black
        : (isLight ? Colors.white : colorScheme.surface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      canvasColor: scaffoldBg,
      cardColor: isAmoled
          ? const Color(0xFF121212)
          : (isLight ? Colors.white : colorScheme.surfaceContainer),
      dividerColor: isLight
          ? const Color(0xFFE8E8E8)
          : (isAmoled ? Colors.white12 : null),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isLight ? Colors.white : scaffoldBg,
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
            : (isLight ? Colors.white : colorScheme.surfaceContainerHigh),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
      ),
      cardTheme: CardThemeData(
        color: isAmoled
            ? const Color(0xFF121212)
            : (isLight ? Colors.white : colorScheme.surfaceContainer),
        elevation: isLight ? 1 : 0,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isAmoled
            ? const Color(0xFF161616)
            : (isLight ? Colors.white : colorScheme.surfaceContainerHigh),
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isAmoled
            ? const Color(0xFF161616)
            : (isLight ? Colors.white : colorScheme.surfaceContainerHigh),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
