import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/core/services/haptic_service.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/features/genre/genre_detail_screen.dart';
import 'package:sonara/features/library/library_screen.dart';
import 'package:sonara/shared/track_tile/track_tile.dart';

class FakePlaybackController extends StubPlaybackController {
  List<String> playedKeys = [];
  bool wasShuffled = false;

  @override
  Future<void> playQueue(
    List<String> trackKeys, {
    int initialIndex = 0,
    bool shuffle = false,
  }) async {
    playedKeys = List.from(trackKeys);
    wasShuffled = shuffle;
  }
}

void main() {
  group('Genre Screen & Library Tab Tests', () {
    late AppDatabase db;
    late FakePlaybackController playbackController;

    setUp(() async {
      db = AppDatabase.inMemory();
      playbackController = FakePlaybackController();

      // Populate test data
      final genreId = await db.getOrCreateGenre('Electronic');
      final artistId = await db.getOrCreateArtist('Daft Punk');
      final albumId = await db.getOrCreateAlbum(
        title: 'Discovery',
        artistId: artistId,
      );

      final trackId = await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'daft_punk_one_more_time',
              contentUri: 'content://audio/1',
              path: '/music/one_more_time.mp3',
              title: 'One More Time',
              titleSort: 'one more time',
              artistId: Value(artistId),
              albumId: Value(albumId),
              durationMs: 320000,
              sizeBytes: 8000000,
            ),
          );

      await db
          .into(db.trackGenres)
          .insert(
            TrackGenresCompanion.insert(trackId: trackId, genreId: genreId),
          );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'GenreDetailScreen renders genre header, play controls, and tracks',
      (tester) async {
        final genres = await db.select(db.genres).get();
        final genreId = genres.first.id;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              playbackControllerProvider.overrideWithValue(playbackController),
              hapticsEnabledProvider.overrideWith((ref) => false),
            ],
            child: MaterialApp(home: GenreDetailScreen(genreId: genreId)),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Electronic'), findsOneWidget);
        expect(find.textContaining('1 song'), findsOneWidget);
        expect(find.text('Play All'), findsOneWidget);
        expect(find.text('Shuffle'), findsOneWidget);
        expect(find.text('One More Time'), findsOneWidget);
        expect(find.byType(TrackTile), findsOneWidget);

        // Tap Play All
        await tester.tap(find.text('Play All'));
        await tester.pumpAndSettle();

        expect(playbackController.playedKeys, ['daft_punk_one_more_time']);
        expect(playbackController.wasShuffled, false);

        // Tap Shuffle
        await tester.tap(find.text('Shuffle'));
        await tester.pumpAndSettle();

        expect(playbackController.playedKeys, ['daft_punk_one_more_time']);
        expect(playbackController.wasShuffled, true);

        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );

    testWidgets('LibraryScreen opens requested initialTab (genres)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            playbackControllerProvider.overrideWithValue(playbackController),
            hapticsEnabledProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(home: LibraryScreen(initialTab: 'genres')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Electronic'), findsOneWidget);
      expect(find.text('1 song'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });

    testWidgets('LibraryScreen opens requested initialTab (playlists)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            playbackControllerProvider.overrideWithValue(playbackController),
            hapticsEnabledProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: LibraryScreen(initialTab: 'playlists'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Liked Songs'), findsOneWidget);
      expect(find.text('Create Playlist'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  });
}
