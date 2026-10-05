import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/search_service.dart';

void main() {
  late AppDatabase db;
  late SearchService searchService;

  setUp(() async {
    db = AppDatabase.inMemory();
    searchService = SearchService(db);

    // Insert artist
    final artistId = await db
        .into(db.artists)
        .insert(ArtistsCompanion.insert(name: 'Queen', nameSort: 'queen'));

    // Insert album
    final albumId = await db
        .into(db.albums)
        .insert(
          AlbumsCompanion.insert(
            title: 'A Night at the Opera',
            titleSort: 'a night at the opera',
            albumArtistId: Value(artistId),
            year: const Value(1975),
          ),
        );

    // Insert track
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'track_search_1',
            contentUri: 'content://audio/queen1',
            path: '/music/bohemian.mp3',
            relativeDir: const Value('music'),
            title: 'Bohemian Rhapsody',
            titleSort: 'bohemian rhapsody',
            artistId: Value(artistId),
            albumId: Value(albumId),
            durationMs: 354000,
            sizeBytes: 8000000,
          ),
        );

    // Insert playlist
    await db
        .into(db.playlists)
        .insert(
          PlaylistsCompanion.insert(
            name: 'Classic Rock Favorites',
            createdAt: 1700000000,
            updatedAt: 1700000000,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('SearchService Tests', () {
    test('search returns empty group for empty query', () async {
      final res = await searchService.search('   ');
      expect(res.isEmpty, isTrue);
    });

    test(
      'search finds matching artists, albums, songs, and playlists',
      () async {
        final res = await searchService.search('Queen');
        expect(res.artists.length, equals(1));
        expect(res.artists.first.name, equals('Queen'));
        expect(res.topResult, isA<Artist>());

        final albumRes = await searchService.search('Opera');
        expect(albumRes.albums.length, equals(1));
        expect(albumRes.albums.first.title, equals('A Night at the Opera'));

        final playlistRes = await searchService.search('Rock');
        expect(playlistRes.playlists.length, equals(1));
        expect(
          playlistRes.playlists.first.name,
          equals('Classic Rock Favorites'),
        );
      },
    );

    test(
      'recent search history saves, retrieves, removes, and clears correctly',
      () async {
        expect(await searchService.getRecentSearches(), isEmpty);

        await searchService.addRecentSearch('Queen');
        await searchService.addRecentSearch('The Beatles');
        await searchService.addRecentSearch('Queen'); // Deduplicates to front

        var recents = await searchService.getRecentSearches();
        expect(recents, equals(['Queen', 'The Beatles']));

        await searchService.removeRecentSearch('The Beatles');
        recents = await searchService.getRecentSearches();
        expect(recents, equals(['Queen']));

        await searchService.clearRecentSearches();
        expect(await searchService.getRecentSearches(), isEmpty);
      },
    );
  });
}
