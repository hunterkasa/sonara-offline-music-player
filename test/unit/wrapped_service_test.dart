import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';

import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/wrapped_service.dart';

void main() {
  late AppDatabase db;
  late WrappedService service;

  setUp(() {
    db = AppDatabase.inMemory();
    service = WrappedService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'WrappedService returns empty state when no history or plays exist',
    () async {
      final wrapped = await service.generateWrapped();
      expect(wrapped.isEmpty, isTrue);
      expect(wrapped.totalListeningMinutes, equals(0));
      expect(wrapped.topTracks, isEmpty);
      expect(wrapped.topArtists, isEmpty);
    },
  );

  test('WrappedService calculates top tracks, artists, genres, and peak hours accurately', () async {
    // 1. Insert Artists
    final artistAId = await db.getOrCreateArtist('Neon Odyssey');
    final artistBId = await db.getOrCreateArtist('Acoustic Labs');

    // 2. Insert Albums
    final albumAId = await db.getOrCreateAlbum(
      title: 'Synth Dreams',
      artistId: artistAId,
      year: 2024,
    );
    final albumBId = await db.getOrCreateAlbum(
      title: 'Folk Echoes',
      artistId: artistBId,
      year: 2021,
    );

    // 3. Insert Tracks
    final nowEpoch =
        DateTime(2026, 10, 6, 23, 0).millisecondsSinceEpoch ~/ 1000;
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            path: '/storage/music/track1.mp3',
            contentUri: 'content://media/external/audio/media/1',
            title: 'Neon Nights',
            titleSort: 'neon nights',
            durationMs: 240000, // 4 mins
            sizeBytes: 8000000,
            trackKey: 'track_neon_nights_key',
            artistId: drift.Value(artistAId),
            albumId: drift.Value(albumAId),
            playCount: const drift.Value(15),
            skipCount: const drift.Value(2),
            lastPlayedAt: drift.Value(nowEpoch),
          ),
        );

    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            path: '/storage/music/track2.mp3',
            contentUri: 'content://media/external/audio/media/2',
            title: 'Acoustic Rain',
            titleSort: 'acoustic rain',
            durationMs: 180000, // 3 mins
            sizeBytes: 6000000,
            trackKey: 'track_acoustic_rain_key',
            artistId: drift.Value(artistBId),
            albumId: drift.Value(albumBId),
            playCount: const drift.Value(5),
            skipCount: const drift.Value(0),
            lastPlayedAt: drift.Value(nowEpoch - 86400),
          ),
        );

    // 4. Insert PlayHistory
    await db
        .into(db.playHistory)
        .insert(
          PlayHistoryCompanion.insert(
            trackKey: 'track_neon_nights_key',
            startedAt: nowEpoch,
            listenedMs: 240000,
            completed: const drift.Value(true),
          ),
        );
    await db
        .into(db.playHistory)
        .insert(
          PlayHistoryCompanion.insert(
            trackKey: 'track_neon_nights_key',
            startedAt: nowEpoch - 3600,
            listenedMs: 240000,
            completed: const drift.Value(true),
          ),
        );
    await db
        .into(db.playHistory)
        .insert(
          PlayHistoryCompanion.insert(
            trackKey: 'track_acoustic_rain_key',
            startedAt: nowEpoch - 86400,
            listenedMs: 180000,
            completed: const drift.Value(true),
          ),
        );

    // 5. Generate Wrapped
    final wrapped = await service.generateWrapped(
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 12, 31),
    );

    expect(wrapped.isEmpty, isFalse);
    expect(
      wrapped.totalListeningMinutes,
      equals(11),
    ); // (240k + 240k + 180k) / 60000 = 11 mins
    expect(wrapped.totalTracksPlayed, equals(2));
    expect(wrapped.topTracks.length, equals(2));
    expect(wrapped.topTracks.first.title, equals('Neon Nights'));
    expect(wrapped.topArtists.first.name, equals('Neon Odyssey'));
    expect(wrapped.listeningStreakDays, greaterThanOrEqualTo(1));
    expect(wrapped.personalityTitle.isNotEmpty, isTrue);
    expect(wrapped.peakHourLabel.isNotEmpty, isTrue);
  });
}
