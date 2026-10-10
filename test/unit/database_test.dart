import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.inMemory();
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase Schema & Operations', () {
    test('initializes schema v2 cleanly', () {
      expect(db.schemaVersion, equals(2));
    });

    test('can insert a track and read it back reactively', () async {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'test_key_001',
              contentUri: 'content://media/external/audio/media/1',
              path: '/storage/emulated/0/Music/test.mp3',
              title: 'Midnight City',
              titleSort: 'midnight city',
              durationMs: 243000,
              sizeBytes: 5800000,
            ),
          );

      final trackList = await db.watchAllTracks().first;
      expect(trackList.length, equals(1));
      expect(trackList.first.title, equals('Midnight City'));
      expect(trackList.first.trackKey, equals('test_key_001'));
    });

    test('can query and watch tracks by folder and root correctly', () async {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'key_rock_1',
              contentUri: 'content://audio/1',
              path: '/storage/emulated/0/Music/Rock/song1.mp3',
              relativeDir: const Value('/storage/emulated/0/Music/Rock'),
              title: 'Rock Song 1',
              titleSort: 'rock song 1',
              durationMs: 180000,
              sizeBytes: 3000000,
            ),
          );

      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'key_rock_2',
              contentUri: 'content://audio/2',
              path: '/storage/emulated/0/Music/Rock/song2.mp3',
              relativeDir: const Value('/storage/emulated/0/Music/Rock'),
              title: 'Rock Song 2',
              titleSort: 'rock song 2',
              durationMs: 200000,
              sizeBytes: 3500000,
            ),
          );

      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'key_root_1',
              contentUri: 'content://audio/3',
              path: '/storage/emulated/0/root.mp3',
              relativeDir: const Value(''),
              title: 'Root Song',
              titleSort: 'root song',
              durationMs: 220000,
              sizeBytes: 4000000,
            ),
          );

      // Query folder tracks
      final rockTracks = await db.getTracksForFolder(
        '/storage/emulated/0/Music/Rock',
      );
      expect(rockTracks.length, equals(2));
      expect(
        rockTracks.map((t) => t.title),
        containsAll(['Rock Song 1', 'Rock Song 2']),
      );

      // Watch folder tracks
      final rockStreamTracks = await db
          .watchTracksForFolder('/storage/emulated/0/Music/Rock')
          .first;
      expect(rockStreamTracks.length, equals(2));

      // Query root tracks
      final rootTracks = await db.getTracksForFolder('Root');
      expect(rootTracks.length, equals(1));
      expect(rootTracks.first.title, equals('Root Song'));
    });

    test('getTracksByKeys batches requests and supports over 1000 keys without SQLite variable limit error', () async {
      // Insert 1200 synthetic tracks
      const total = 1200;
      final keys = <String>[];
      for (var i = 0; i < total; i++) {
        final key = 'batch_key_${i.toString().padLeft(5, '0')}';
        keys.add(key);
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: key,
                contentUri: 'content://audio/$i',
                path: '/storage/test_$i.mp3',
                title: 'Track $i',
                titleSort: 'track $i',
                durationMs: 120000,
                sizeBytes: 1000000,
              ),
            );
      }

      // Query all 1200 keys
      final result = await db.getTracksByKeys(keys);
      expect(result.length, equals(total));
      expect(result.first.trackKey, equals(keys.first));
      expect(result.last.trackKey, equals(keys.last));
    });

    test('searchTrackKeysFts gracefully handles special characters without syntax error', () async {
      // Search with quotes, parentheses, dashes, asterisks, colons
      final terms = [
        'queen (live)',
        'ac/dc',
        'foo - bar',
        '***',
        '"unclosed quote',
        'artist:name',
        ':',
        '-',
        '(',
        ')',
      ];

      for (final term in terms) {
        final results = await db.searchTrackKeysFts(term);
        expect(results, isA<List<String>>());
      }
    });

    test('playlist tracks allow duplicate songs, preserves positions, and reorders cleanly', () async {
      final playlistId = await db.createPlaylist(name: 'Favorites Mix');
      const trackKeyA = 'track_A';
      const trackKeyB = 'track_B';

      // Add track A, track B, and track A again
      await db.addTracksToPlaylist(playlistId, [trackKeyA, trackKeyB]);
      await db.addTracksToPlaylist(playlistId, [trackKeyA]);

      var keys = await db.getPlaylistTrackKeys(playlistId);
      expect(keys.length, equals(3));
      expect(keys, equals([trackKeyA, trackKeyB, trackKeyA]));

      // Reorder index 0 (A) to index 1 (between B and A)
      await db.reorderPlaylistTracks(playlistId, 0, 1);
      keys = await db.getPlaylistTrackKeys(playlistId);
      expect(keys, equals([trackKeyB, trackKeyA, trackKeyA]));

      // Remove first occurrence of track A
      await db.removeTrackFromPlaylist(playlistId, trackKeyA);
      keys = await db.getPlaylistTrackKeys(playlistId);
      expect(keys, equals([trackKeyB, trackKeyA]));
    });

    test(
      'getOrCreateAlbum reuses existing Various Artists compilation albums',
      () async {
        final variousArtistId = await db.getOrCreateArtist('Various Artists');
        final albumId1 = await db.getOrCreateAlbum(
          title: 'Guardians Soundtrack',
          artistId: variousArtistId,
        );

        final artist2Id = await db.getOrCreateArtist('David Bowie');
        final albumId2 = await db.getOrCreateAlbum(
          title: 'Guardians Soundtrack',
          artistId: artist2Id,
        );

        // Should reuse the Various Artists album instead of splitting
        expect(albumId2, equals(albumId1));
      },
    );

    test('getAllTrackKeys and getMediaStoreTrackIds return targeted data without full objects', () async {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'key_1',
              mediaStoreId: const Value(501),
              contentUri: 'content://m/1',
              path: '/Music/Rock/s1.mp3',
              title: 'Rock Song',
              titleSort: 'rock song',
              relativeDir: const Value('Rock'),
              durationMs: 180000,
              sizeBytes: 1000,
            ),
          );
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'key_2',
              mediaStoreId: const Value(502),
              contentUri: 'content://m/2',
              path: '/Music/Pop/s2.mp3',
              title: 'Pop Song',
              titleSort: 'pop song',
              relativeDir: const Value('Pop'),
              durationMs: 200000,
              sizeBytes: 2000,
            ),
          );

      final keys = await db.getAllTrackKeys();
      expect(keys, containsAll(['key_1', 'key_2']));

      final pairs = await db.getMediaStoreTrackIds();
      expect(pairs.map((p) => p.$2), containsAll([501, 502]));
    });

    test(
      'watchFolderSummaries groups tracks by folder and emits counts',
      () async {
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'folder_key_1',
                contentUri: 'content://m/f1',
                path: '/Music/Jazz/s1.mp3',
                title: 'Jazz 1',
                titleSort: 'jazz 1',
                relativeDir: const Value('Jazz'),
                durationMs: 180000,
                sizeBytes: 1000,
              ),
            );
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'folder_key_2',
                contentUri: 'content://m/f2',
                path: '/Music/Jazz/s2.mp3',
                title: 'Jazz 2',
                titleSort: 'jazz 2',
                relativeDir: const Value('Jazz'),
                durationMs: 190000,
                sizeBytes: 1100,
              ),
            );

        final summaries = await db.watchFolderSummaries().first;
        final jazzFolder = summaries.firstWhere((f) => f.path == 'Jazz');
        expect(jazzFolder.trackCount, equals(2));
      },
    );

    test('watchAlbum, watchAlbumTracks, watchArtist, watchArtistTracks stream correctly', () async {
      final artId = await db.getOrCreateArtist('Pink Floyd');
      final albId = await db.getOrCreateAlbum(
        title: 'The Dark Side of the Moon',
        artistId: artId,
        year: 1973,
      );

      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'dsotm_1',
              contentUri: 'content://m/pf1',
              path: '/Music/PF/time.mp3',
              title: 'Time',
              titleSort: 'time',
              artistId: Value(artId),
              albumId: Value(albId),
              durationMs: 420000,
              sizeBytes: 5000000,
              trackNo: const Value(4),
              discNo: const Value(1),
            ),
          );

      final album = await db.watchAlbum(albId).first;
      expect(album?.title, equals('The Dark Side of the Moon'));

      final albumTracks = await db.watchAlbumTracks(albId).first;
      expect(albumTracks.length, equals(1));
      expect(albumTracks.first.title, equals('Time'));

      final artist = await db.watchArtist(artId).first;
      expect(artist?.name, equals('Pink Floyd'));

      final artistTracks = await db.watchArtistTracks(artId).first;
      expect(artistTracks.length, equals(1));

      final artistAlbums = await db.watchArtistAlbums(artId).first;
      expect(artistAlbums.length, equals(1));
      expect(artistAlbums.first.title, equals('The Dark Side of the Moon'));
    });

    test(
      'setFavoriteTracks and deleteTracks perform batch updates and deletions',
      () async {
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'batch_1',
                contentUri: 'content://m/b1',
                path: '/Music/b1.mp3',
                title: 'Batch 1',
                titleSort: 'batch 1',
                durationMs: 180000,
                sizeBytes: 1000,
              ),
            );
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'batch_2',
                contentUri: 'content://m/b2',
                path: '/Music/b2.mp3',
                title: 'Batch 2',
                titleSort: 'batch 2',
                durationMs: 180000,
                sizeBytes: 1000,
              ),
            );

        // Verify batch favorite
        await db.setFavoriteTracks(['batch_1', 'batch_2'], true);
        var t1 = await db.getTrackByKey('batch_1');
        var t2 = await db.getTrackByKey('batch_2');
        expect(t1?.isFavorite, isTrue);
        expect(t2?.isFavorite, isTrue);

        // Verify batch unfavorite
        await db.setFavoriteTracks(['batch_1'], false);
        t1 = await db.getTrackByKey('batch_1');
        expect(t1?.isFavorite, isFalse);

        // Verify batch delete
        await db.deleteTracks(['batch_1', 'batch_2']);
        t1 = await db.getTrackByKey('batch_1');
        t2 = await db.getTrackByKey('batch_2');
        expect(t1, isNull);
        expect(t2, isNull);
      },
    );
  });
}
