import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' as d;
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/features/library/library_screen.dart';
import 'package:sonara/features/playlist/add_to_playlist_sheet.dart';
import 'package:sonara/features/playlist/playlist_detail_screen.dart';

void main() {
  d.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  Future<AppDatabase> createTestDb() async {
    final db = AppDatabase.inMemory();
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'track_test_1',
            contentUri: 'content://audio/1',
            path: '/music/track1.mp3',
            relativeDir: const d.Value('music'),
            title: 'Playlist Flow Song 1',
            titleSort: 'playlist flow song 1',
            durationMs: 180000,
            sizeBytes: 3000000,
            isFavorite: const d.Value(true),
          ),
        );
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'track_test_2',
            contentUri: 'content://audio/2',
            path: '/music/track2.mp3',
            relativeDir: const d.Value('music'),
            title: 'Playlist Flow Song 2',
            titleSort: 'playlist flow song 2',
            durationMs: 240000,
            sizeBytes: 4000000,
            isFavorite: const d.Value(false),
          ),
        );
    final plId = await db
        .into(db.playlists)
        .insert(
          PlaylistsCompanion.insert(
            name: 'Roadtrip 2026',
            createdAt: 1700000000,
            updatedAt: 1700000000,
          ),
        );
    await db.addTracksToPlaylist(plId, ['track_test_1']);
    return db;
  }

  group('Playlist Flow Widget Tests', () {
    testWidgets('LibraryScreen Playlists tab shows Liked Songs and playlists', (
      WidgetTester tester,
    ) async {
      final db = await createTestDb();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: Scaffold(body: LibraryScreen())),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'Playlists' filter chip
      await tester.tap(find.text('Playlists'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Liked Songs'), findsOneWidget);
      expect(find.text('Create Playlist'), findsOneWidget);
      expect(find.text('Roadtrip 2026'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
      'AddToPlaylistSheet renders existing playlists and allows adding',
      (WidgetTester tester) async {
        final db = await createTestDb();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: const MaterialApp(
              home: Scaffold(
                body: AddToPlaylistSheet(trackKeys: ['track_test_2']),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Add to Playlist'), findsOneWidget);
        expect(find.text('Roadtrip 2026'), findsOneWidget);

        // Tap on Roadtrip 2026 to add track
        await tester.tap(find.text('Roadtrip 2026'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify track was added to database
        final playlist = await db.getPlaylist(1);
        final tracks = await db.getPlaylistTrackKeys(playlist!.id);
        expect(tracks, contains('track_test_2'));

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'PlaylistDetailScreen renders title, action buttons, and tracks',
      (WidgetTester tester) async {
        final db = await createTestDb();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: const MaterialApp(
              home: Scaffold(body: PlaylistDetailScreen(playlistId: 1)),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Roadtrip 2026'), findsWidgets);
        expect(find.text('Play All'), findsOneWidget);
        expect(find.text('Shuffle'), findsOneWidget);
        expect(find.text('Playlist Flow Song 1'), findsOneWidget);

        // Verify inline delete button is removed from list rows
        expect(find.byIcon(Icons.remove_circle_outline_rounded), findsNothing);

        // Verify '=' drag handle is wrapped in ReorderableDragStartListener
        expect(find.byIcon(Icons.drag_handle_rounded), findsOneWidget);
        expect(find.byType(ReorderableDragStartListener), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
