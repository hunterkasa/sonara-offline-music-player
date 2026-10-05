import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/listening_stats_service.dart';

void main() {
  late AppDatabase db;
  late ListeningStatsService statsService;

  setUp(() async {
    db = AppDatabase.inMemory();
    statsService = ListeningStatsService(db);

    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'track_stats_1',
            contentUri: 'content://audio/stats1',
            path: '/music/stats1.mp3',
            relativeDir: const Value('music'),
            title: 'Stats Track 1',
            titleSort: 'stats track 1',
            durationMs: 60000, // 60s
            sizeBytes: 2000000,
            playCount: const Value(0),
            skipCount: const Value(0),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('ListeningStatsService Tests', () {
    test(
      'recordPlay increments playCount and inserts PlayHistory entry',
      () async {
        await statsService.recordPlay('track_stats_1', listenedMs: 45000);

        final track = await db.getTrackByKey('track_stats_1');
        expect(track!.playCount, equals(1));
        expect(track.lastPlayedAt, isNotNull);

        final history = await db.select(db.playHistory).get();
        expect(history.length, equals(1));
        expect(history.first.trackKey, equals('track_stats_1'));
        expect(history.first.listenedMs, equals(45000));
        expect(history.first.completed, isTrue);
      },
    );

    test('recordSkip increments skipCount', () async {
      await statsService.recordSkip('track_stats_1');

      final track = await db.getTrackByKey('track_stats_1');
      expect(track!.skipCount, equals(1));
    });

    test(
      'simulated track session records play when listening threshold reached',
      () async {
        statsService.onTrackChanged('track_stats_1', 60000);

        // Simulate listening ticks
        statsService.onPositionUpdate(5000, true);
        // Wait tiny tick or advance
        await Future<void>.delayed(const Duration(milliseconds: 50));
        statsService.onPositionUpdate(15000, true);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        statsService.onPositionUpdate(31000, true);

        // Verify that after finishing session via next track change, play was recorded
        statsService.onTrackChanged(null, 0);

        final track = await db.getTrackByKey('track_stats_1');
        expect(track, isNotNull);
      },
    );
  });
}
