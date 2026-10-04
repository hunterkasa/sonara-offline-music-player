import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
      return ThemeModeNotifier();
    });

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  // PRD: "dark-first, artwork-driven color"
  ThemeModeNotifier() : super(AppThemeMode.dark);

  void setThemeMode(AppThemeMode mode) {
    state = mode;
  }
}

final accentColorProvider = StateProvider<Color>((ref) {
  return AppTheme.defaultSeedColor;
});
