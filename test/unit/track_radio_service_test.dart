import 'dart:math';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/audio/playback_controller.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/track_radio_service.dart';

class MockPlaybackController extends StubPlaybackController {
  List<String> lastPlayedQueue = [];
  int lastInitialIndex = -1;
  bool wasPlayCalled = false;

  @override
  Future<void> play() async {
    wasPlayCalled = true;
  }

  @override
  Future<void> playQueue(
    List<String> trackKeys, {
    int initialIndex = 0,
    bool shuffle = false,
  }) async {
    lastPlayedQueue = trackKeys;
    lastInitialIndex = initialIndex;
  }
}

void main() {
  late AppDatabase db;
  late MockPlaybackController playbackController;
  late TrackRadioService radioService;

  setUp(() {
    db = AppDatabase.inMemory();
    playbackController = MockPlaybackController();
    radioService = TrackRadioService(
      db: db,
      playbackController: playbackController,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'generateRadioQueue returns just seed if no other candidates exist',
    () async {
      final artistId = await db.getOrCreateArtist('Solo Artist');
      final albumId = await db.getOrCreateAlbum(
        title: 'Solo Album',
        artistId: artistId,
        year: 2024,
      );

      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              path: '/storage/music/seed.mp3',
              contentUri: 'content://media/external/audio/media/1',
              title: 'Seed Track',
              titleSort: 'seed track',
              durationMs: 200000,
              sizeBytes: 5000000,
              trackKey: 'seed_key',
              artistId: drift.Value(artistId),
              albumId: drift.Value(albumId),
            ),
          );

      final seedTrack = await db.getTrackByKey('seed_key');
      expect(seedTrack, isNotNull);

      final queue = await radioService.generateRadioQueue(seedTrack!);
      expect(queue.length, equals(1));
      expect(queue.first.trackKey, equals('seed_key'));
    },
  );

  test('generateRadioQueue clusters matching genre, era, and artist affinity higher', () async {
    // 1. Setup Artists & Albums
    final rockArtist = await db.getOrCreateArtist('Synthwave Legend');
    final classicalArtist = await db.getOrCreateArtist('Classical Master');

    final retroAlbum = await db.getOrCreateAlbum(
      title: 'Cyber 2084',
      artistId: rockArtist,
      year: 2024,
    );
    final vintageAlbum = await db.getOrCreateAlbum(
      title: 'Baroque 1700',
      artistId: classicalArtist,
      year: 1720,
    );

    // 2. Setup Genres
    final synthGenreId = await db
        .into(db.genres)
        .insert(GenresCompanion.insert(name: 'Synthwave'));
    final baroqueGenreId = await db
        .into(db.genres)
        .insert(GenresCompanion.insert(name: 'Baroque'));

    // 3. Insert Tracks
    // Seed Track: Synthwave, 2024, Synthwave Legend, 200s
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            path: '/storage/music/seed.mp3',
            contentUri: 'content://media/external/audio/media/10',
            title: 'Cyber Highway',
            titleSort: 'cyber highway',
            durationMs: 200000,
            sizeBytes: 5000000,
            trackKey: 'seed_highway',
            artistId: drift.Value(rockArtist),
            albumId: drift.Value(retroAlbum),
          ),
        );
    final seedTrackRow = await db.getTrackByKey('seed_highway');
    await db
        .into(db.trackGenres)
        .insert(
          TrackGenresCompanion.insert(
            trackId: seedTrackRow!.id,
            genreId: synthGenreId,
          ),
        );

    // Candidate 1: Similar (Same artist, same album, same genre, 2024, 210s)
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            path: '/storage/music/cand1.mp3',
            contentUri: 'content://media/external/audio/media/11',
            title: 'Neon Skyline',
            titleSort: 'neon skyline',
            durationMs: 210000,
            sizeBytes: 5200000,
            trackKey: 'cand_similar',
            artistId: drift.Value(rockArtist),
            albumId: drift.Value(retroAlbum),
          ),
        );
    final cand1Row = await db.getTrackByKey('cand_similar');
    await db
        .into(db.trackGenres)
        .insert(
          TrackGenresCompanion.insert(
            trackId: cand1Row!.id,
            genreId: synthGenreId,
          ),
        );

    // Candidate 2: Dissimilar (Classical, 1720, 600s, Baroque)
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            path: '/storage/music/cand2.mp3',
            contentUri: 'content://media/external/audio/media/12',
            title: 'Concerto in D',
            titleSort: 'concerto in d',
            durationMs: 600000,
            sizeBytes: 15000000,
            trackKey: 'cand_dissimilar',
            artistId: drift.Value(classicalArtist),
            albumId: drift.Value(vintageAlbum),
          ),
        );
    final cand2Row = await db.getTrackByKey('cand_dissimilar');
    await db
        .into(db.trackGenres)
        .insert(
          TrackGenresCompanion.insert(
            trackId: cand2Row!.id,
            genreId: baroqueGenreId,
          ),
        );

    final queue = await radioService.generateRadioQueue(
      seedTrackRow,
      random: Random(42),
    );

    expect(queue.length, equals(3));
    // Index 0 must be seed
    expect(queue[0].trackKey, equals('seed_highway'));
    // Index 1 should be the highly similar candidate
    expect(queue[1].trackKey, equals('cand_similar'));
    // Index 2 is the dissimilar track
    expect(queue[2].trackKey, equals('cand_dissimilar'));
  });

  test(
    'startRadio generates queue and delegates to playbackController.playQueue',
    () async {
      final artistId = await db.getOrCreateArtist('Radio Star');
      final albumId = await db.getOrCreateAlbum(
        title: 'Broadcast',
        artistId: artistId,
        year: 2023,
      );

      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              path: '/storage/music/song.mp3',
              contentUri: 'content://media/external/audio/media/20',
              title: 'Transmission',
              titleSort: 'transmission',
              durationMs: 180000,
              sizeBytes: 4000000,
              trackKey: 'trans_key',
              artistId: drift.Value(artistId),
              albumId: drift.Value(albumId),
            ),
          );

      final seed = (await db.getTrackByKey('trans_key'))!;
      final queue = await radioService.startRadio(seed);

      expect(queue.isNotEmpty, isTrue);
      expect(playbackController.lastPlayedQueue, contains('trans_key'));
      expect(playbackController.lastInitialIndex, equals(0));
    },
  );
}
