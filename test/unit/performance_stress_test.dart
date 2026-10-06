import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/queue_manager.dart';
import 'package:sonara/domain/services/shuffle_strategy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late QueueManager queueManager;

  setUp(() {
    db = AppDatabase.inMemory();
    queueManager = QueueManager(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 7 Performance & Stress Benchmarks (20,000 Tracks)', () {
    test('Seeds 20,000 tracks and executes instant queries under 100ms', () async {
      // 1. Seed 20,000 synthetic tracks
      final seedWatch = Stopwatch()..start();
      await db.seedSyntheticData(count: 20000);
      seedWatch.stop();
      expect(await db.getTrackCount(), equals(20000));

      // 2. Query all tracks count and watch query
      final queryWatch = Stopwatch()..start();
      final tracks = await db.getAllTracks();
      queryWatch.stop();

      expect(tracks.length, equals(20000));
      // SQLite query across 20k rows in in-memory WAL DB must be under 1000ms
      expect(
        queryWatch.elapsedMilliseconds,
        lessThan(1000),
        reason: 'Querying 20k tracks took ${queryWatch.elapsedMilliseconds}ms',
      );

      // 3. FTS5 Instant Search benchmark (<100ms exit requirement)
      for (var i = 1; i <= 1000; i++) {
        await db.customStatement(
          'INSERT OR REPLACE INTO tracks_fts(track_key, title, artist, album, genre) VALUES (?, ?, ?, ?, ?)',
          [
            'synthetic_track_key_${i.toString().padLeft(6, '0')}',
            'Synthetic Track $i',
            'Synthetic Artist',
            'Synthetic Album',
            'Electronic',
          ],
        );
      }

      final searchWatch = Stopwatch()..start();
      final searchResults = await db.searchTracksFts('Synthetic Track 100');
      searchWatch.stop();

      expect(searchResults, isNotEmpty);
      expect(
        searchWatch.elapsedMilliseconds,
        lessThan(100),
        reason:
            'FTS5 search took ${searchWatch.elapsedMilliseconds}ms (target <100ms)',
      );
    });

    test('Fisher-Yates shuffle shuffles 20,000 track keys in < 50ms', () {
      final stopwatch = Stopwatch()..start();
      final perm = ShuffleStrategy.generatePermutation(
        count: 20000,
        firstIndex: 500,
        seed: 42,
      );
      stopwatch.stop();

      expect(perm.length, equals(20000));
      expect(perm.first, equals(500));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason:
            'Shuffling 20,000 tracks took ${stopwatch.elapsedMilliseconds}ms',
      );
    });

    test('QueueManager sliding window slicing on 20,000 tracks executes in < 5ms', () {
      final tracks = List.generate(
        20000,
        (i) => Track(
          id: i,
          trackKey: 'track_key_$i',
          contentUri: 'content://media/$i',
          path: '/music/track_$i.mp3',
          relativeDir: 'Music',
          title: 'Track $i',
          titleSort: 'track $i',
          durationMs: 180000,
          sizeBytes: 4000000,
          hasLyrics: false,
          isFavorite: false,
          isHidden: false,
          isMissing: false,
          rating: 0,
          playCount: 0,
          skipCount: 0,
        ),
      );
      queueManager.setQueue(tracks, initialIndex: 10000);

      final stopwatch = Stopwatch()..start();
      final upcomingWindow = queueManager.getSlidingWindow(windowSize: 5);
      stopwatch.stop();

      expect(upcomingWindow.length, equals(5));
      expect(upcomingWindow.first.trackKey, equals('track_key_10000'));
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(5),
        reason:
            'Sliding window calculation took ${stopwatch.elapsedMilliseconds}ms',
      );
    });
  });
}
