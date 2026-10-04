import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/app/theme/app_theme.dart';
import 'package:sonara/app/theme/theme_provider.dart';

void main() {
  group('Theme System', () {
    test('ThemeModeNotifier updates state correctly', () {
      final notifier = ThemeModeNotifier();
      expect(notifier.state, equals(AppThemeMode.dark));

      notifier.setThemeMode(AppThemeMode.amoled);
      expect(notifier.state, equals(AppThemeMode.amoled));

      notifier.setThemeMode(AppThemeMode.light);
      expect(notifier.state, equals(AppThemeMode.light));

      notifier.setThemeMode(AppThemeMode.system);
      expect(notifier.state, equals(AppThemeMode.system));
    });

    test('AppTheme creates valid theme definitions', () {
      final light = AppTheme.light();
      expect(light.brightness, equals(Brightness.light));

      final dark = AppTheme.dark();
      expect(dark.brightness, equals(Brightness.dark));

      final amoled = AppTheme.amoled();
      expect(amoled.brightness, equals(Brightness.dark));
      expect(amoled.scaffoldBackgroundColor, equals(Colors.black));
    });
  });
}
