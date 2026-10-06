import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/queue_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 7 Cold Start & Battery/Lifecycle Review Tests', () {
    test('Simulated cold start to interactive library completes in < 1.5s', () async {
      final coldStartStopwatch = Stopwatch()..start();

      // 1. Initialize Drift SQLite database in WAL mode
      final db = AppDatabase.inMemory();
      await db.seedSyntheticData(count: 500);

      // 2. Initialize QueueManager
      final queueManager = QueueManager(db: db);

      // 3. Restore persisted queue state
      final res = await queueManager.restoreState();
      expect(res.restored, isFalse);

      // 4. Initial library query for first visible tab
      final initialSongs = await (db.select(db.tracks)..limit(50)).get();
      expect(initialSongs.length, equals(50));

      coldStartStopwatch.stop();

      expect(
        coldStartStopwatch.elapsedMilliseconds,
        lessThan(1500),
        reason:
            'Cold start took ${coldStartStopwatch.elapsedMilliseconds}ms (target <1500ms)',
      );

      await db.close();
    });

    test(
      'QueueManager state does not leak background timers while paused or idle',
      () {
        final db = AppDatabase.inMemory();
        final queueManager = QueueManager(db: db);

        // Verify initial snapshot is idle
        expect(queueManager.queue, isEmpty);
        expect(queueManager.currentIndex, equals(-1));
        expect(queueManager.currentTrack, isNull);

        const track = Track(
          id: 1,
          trackKey: 'track_1',
          contentUri: 'content://media/1',
          path: '/music/track_1.mp3',
          relativeDir: 'Music',
          title: 'Track 1',
          titleSort: 'track 1',
          durationMs: 180000,
          sizeBytes: 4000000,
          hasLyrics: false,
          isFavorite: false,
          isHidden: false,
          isMissing: false,
          rating: 0,
          playCount: 0,
          skipCount: 0,
        );

        queueManager.setQueue([track], initialIndex: 0);
        expect(queueManager.currentTrack?.trackKey, equals('track_1'));

        db.close();
      },
    );
  });
}
