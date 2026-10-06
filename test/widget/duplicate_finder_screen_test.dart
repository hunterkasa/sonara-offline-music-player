import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/features/library_tools/duplicate_finder_screen.dart';

void main() {
  testWidgets(
    'DuplicateFinderScreen displays empty state when no duplicates exist',
    (tester) async {
      final db = AppDatabase.inMemory();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: DuplicateFinderScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Duplicate Finder'), findsOneWidget);
      expect(find.text('No Duplicates Found'), findsOneWidget);

      await db.close();
    },
  );

  testWidgets(
    'DuplicateFinderScreen displays clusters and tracks when duplicates exist',
    (tester) async {
      final db = AppDatabase.inMemory();

      // Insert 2 identical size/duration tracks
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'k1',
              contentUri: 'c1',
              path: '/p1.mp3',
              title: 'Twin Song',
              titleSort: 'twin song',
              durationMs: 180000,
              sizeBytes: 4000000,
            ),
          );
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'k2',
              contentUri: 'c2',
              path: '/p2.mp3',
              title: 'Twin Song',
              titleSort: 'twin song',
              durationMs: 180000,
              sizeBytes: 4000000,
            ),
          );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: DuplicateFinderScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Exact File Duplicate'), findsOneWidget);
      expect(find.text('Twin Song'), findsWidgets);

      await db.close();
    },
  );
}
