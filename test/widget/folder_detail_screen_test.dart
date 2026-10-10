import 'package:drift/drift.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/core/services/haptic_service.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/features/folder/folder_detail_screen.dart';
import 'package:sonara/features/library/library_screen.dart';

class FakePlaybackController extends StubPlaybackController {
  List<String> playedKeys = [];
  int initialPlayedIndex = 0;
  bool wasShuffled = false;

  @override
  Future<void> playQueue(
    List<String> trackKeys, {
    int initialIndex = 0,
    bool shuffle = false,
  }) async {
    playedKeys = List.from(trackKeys);
    initialPlayedIndex = initialIndex;
    wasShuffled = shuffle;
  }
}

void main() {
  d.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<AppDatabase> createTestDb() async {
    final db = AppDatabase.inMemory();
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'track_hiphop_1',
            contentUri: 'content://audio/1',
            path: '/storage/emulated/0/Music/HipHop/song1.mp3',
            relativeDir: const d.Value('/storage/emulated/0/Music/HipHop'),
            title: 'HipHop Beat 1',
            titleSort: 'hiphop beat 1',
            durationMs: 195000,
            sizeBytes: 3500000,
          ),
        );
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'track_hiphop_2',
            contentUri: 'content://audio/2',
            path: '/storage/emulated/0/Music/HipHop/song2.mp3',
            relativeDir: const d.Value('/storage/emulated/0/Music/HipHop'),
            title: 'HipHop Beat 2',
            titleSort: 'hiphop beat 2',
            durationMs: 210000,
            sizeBytes: 4200000,
          ),
        );
    return db;
  }

  group('FolderDetailScreen & Folder Flow Widget Tests', () {
    testWidgets(
      'FolderDetailScreen renders folder title, tracks, and triggers play',
      (WidgetTester tester) async {
        final db = await createTestDb();
        final mockPlayback = FakePlaybackController();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              playbackControllerProvider.overrideWithValue(mockPlayback),
              hapticsEnabledProvider.overrideWith((ref) => false),
            ],
            child: const MaterialApp(
              home: FolderDetailScreen(
                folderPath: '/storage/emulated/0/Music/HipHop',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Folder display name (basename)
        expect(find.text('HipHop'), findsWidgets);
        // Full path breadcrumb
        expect(find.text('/storage/emulated/0/Music/HipHop'), findsOneWidget);
        // Song count
        expect(find.textContaining('2 songs'), findsOneWidget);
        // Buttons
        expect(find.text('Play All'), findsOneWidget);
        expect(find.text('Shuffle'), findsOneWidget);
        // Track titles
        expect(find.text('HipHop Beat 1'), findsOneWidget);
        expect(find.text('HipHop Beat 2'), findsOneWidget);

        // Tap Play All
        await tester.tap(find.text('Play All'));
        await tester.pumpAndSettle();
        expect(
          mockPlayback.playedKeys,
          equals(['track_hiphop_1', 'track_hiphop_2']),
        );
        expect(mockPlayback.initialPlayedIndex, equals(0));
        expect(mockPlayback.wasShuffled, isFalse);

        // Tap Shuffle
        await tester.tap(find.text('Shuffle'));
        await tester.pumpAndSettle();
        expect(mockPlayback.wasShuffled, isTrue);

        // Tap song 2 directly
        await tester.tap(find.text('HipHop Beat 2'));
        await tester.pumpAndSettle();
        expect(mockPlayback.initialPlayedIndex, equals(1));

        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );

    testWidgets('LibraryScreen Folders tab displays folder with track count', (
      WidgetTester tester,
    ) async {
      final db = await createTestDb();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            hapticsEnabledProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(home: LibraryScreen(initialTab: 'folders')),
        ),
      );

      await tester.pumpAndSettle();

      // Should display folder path and track count
      expect(find.text('/storage/emulated/0/Music/HipHop'), findsOneWidget);
      expect(find.textContaining('2 songs'), findsOneWidget);
      expect(find.byIcon(Icons.folder_rounded), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
