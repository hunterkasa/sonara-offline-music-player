import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/features/settings/settings_screen.dart';

void main() {
  testWidgets(
    'SettingsScreen allows changing theme and triggering synthetic seeder',
    (WidgetTester tester) async {
      final inMemoryDb = AppDatabase.inMemory();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(inMemoryDb)],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      // Initial state
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // Open theme selection dialog
      await tester.tap(find.text('Theme Mode'));
      await tester.pumpAndSettle();

      expect(find.text('Select Theme'), findsOneWidget);
      expect(find.text('AMOLED Dark (Pure Black)'), findsOneWidget);

      // Select AMOLED Dark
      await tester.tap(find.text('AMOLED Dark (Pure Black)'));
      await tester.pumpAndSettle();

      expect(find.text('AMOLED Dark (Pure Black)'), findsOneWidget);

      // Verify library tools section
      final storageTile = find.text('Storage Inspector & Cache');
      await tester.scrollUntilVisible(storageTile, 100);
      expect(storageTile, findsOneWidget);
      expect(find.text('Backup & Restore'), findsOneWidget);

      // Tap Seed Synthetic Tracks
      final seedButton = find.text('Seed 20,000 Synthetic DB Tracks');
      await tester.scrollUntilVisible(seedButton, 200);
      await tester.pumpAndSettle();
      await tester.tap(seedButton);
      await tester.pump(); // Starts action
      await tester.pump(
        const Duration(seconds: 1),
      ); // Wait for async seeder and snackbar

      expect(find.byType(SnackBar), findsWidgets);

      // Open theme selection dialog again and switch to Light (White Mode)
      await tester.scrollUntilVisible(find.text('Theme Mode'), -100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Theme Mode'));
      await tester.pumpAndSettle();

      expect(find.text('Light (White Mode)'), findsOneWidget);
      await tester.tap(find.text('Light (White Mode)'));
      await tester.pumpAndSettle();

      expect(find.text('Light (White Mode)'), findsOneWidget);

      await inMemoryDb.close();
    },
  );
}
