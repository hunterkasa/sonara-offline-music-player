import 'package:drift/drift.dart' as d;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';
import 'package:sonara/features/album/album_detail_screen.dart';
import 'package:sonara/features/artist/artist_detail_screen.dart';
import 'package:sonara/features/library/library_screen.dart';

void main() {
  late AppDatabase inMemoryDb;

  setUp(() async {
    inMemoryDb = AppDatabase.inMemory();

    // Seed test artist
    final artistId = await inMemoryDb
        .into(inMemoryDb.artists)
        .insert(
          const ArtistsCompanion(
            name: d.Value('Queen'),
            nameSort: d.Value('Queen'),
          ),
        );

    // Seed test album
    final albumId = await inMemoryDb
        .into(inMemoryDb.albums)
        .insert(
          AlbumsCompanion(
            title: const d.Value('A Night at the Opera'),
            titleSort: const d.Value('Night at the Opera'),
            albumArtistId: d.Value(artistId),
            year: const d.Value(1975),
          ),
        );

    // Seed test track
    await inMemoryDb
        .into(inMemoryDb.tracks)
        .insert(
          TracksCompanion(
            trackKey: const d.Value('queen_bohemian_rhapsody'),
            contentUri: const d.Value('content://test/1'),
            path: const d.Value('/music/bohemian.mp3'),
            relativeDir: const d.Value('/music'),
            title: const d.Value('Bohemian Rhapsody'),
            titleSort: const d.Value('Bohemian Rhapsody'),
            artistId: d.Value(artistId),
            albumId: d.Value(albumId),
            trackNo: const d.Value(11),
            year: const d.Value(1975),
            durationMs: const d.Value(354000),
            sizeBytes: const d.Value(8000000),
          ),
        );
  });

  tearDown(() async {
    await inMemoryDb.close();
  });

  testWidgets('LibraryScreen renders tabs and switches views', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(inMemoryDb)],
        child: const MaterialApp(home: LibraryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your Library'), findsOneWidget);
    expect(find.text('Songs'), findsOneWidget);
    expect(find.text('Albums'), findsOneWidget);
    expect(find.text('Artists'), findsOneWidget);
    expect(find.text('Genres'), findsOneWidget);
    expect(find.text('Folders'), findsOneWidget);

    // Songs view shows Bohemian Rhapsody
    expect(find.text('Bohemian Rhapsody'), findsOneWidget);

    // Switch to Albums tab
    await tester.tap(find.text('Albums'));
    await tester.pumpAndSettle();
    expect(find.text('A Night at the Opera'), findsOneWidget);

    // Switch to Artists tab
    await tester.tap(find.text('Artists'));
    await tester.pumpAndSettle();
    expect(find.text('Queen'), findsOneWidget);

    // Switch to Genres tab
    await tester.tap(find.text('Genres'));
    await tester.pumpAndSettle();

    // Switch to Folders tab
    await tester.tap(find.text('Folders'));
    await tester.pumpAndSettle();
    expect(find.text('/music'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('AlbumDetailScreen displays header, actions, and tracks', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(inMemoryDb)],
        child: const MaterialApp(home: AlbumDetailScreen(albumId: 1)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A Night at the Opera'), findsWidgets);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Shuffle'), findsOneWidget);
    expect(find.text('Bohemian Rhapsody'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('ArtistDetailScreen displays circular header and shelves', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(inMemoryDb)],
        child: const MaterialApp(home: ArtistDetailScreen(artistId: 1)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Queen'), findsWidgets);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Shuffle'), findsOneWidget);
    expect(find.text('Albums'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Songs'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
