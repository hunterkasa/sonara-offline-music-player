import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/queue_manager.dart';

Track _createDummyTrack(int id, {String? title}) {
  return Track(
    id: id,
    trackKey: 'track_$id',
    contentUri: 'content://media/external/audio/media/$id',
    path: '/storage/emulated/0/Music/track_$id.mp3',
    relativeDir: 'Music',
    title: title ?? 'Track $id',
    titleSort: (title ?? 'Track $id').toLowerCase(),
    durationMs: 180000,
    sizeBytes: 4000000,
    hasLyrics: false,
    playCount: 0,
    skipCount: 0,
    isFavorite: false,
    isHidden: false,
    isMissing: false,
    rating: 0,
  );
}

void main() {
  group('QueueManager Logic & Mutations', () {
    test('initializes empty and sets queue', () {
      final manager = QueueManager();
      expect(manager.queue, isEmpty);
      expect(manager.currentIndex, equals(-1));
      expect(manager.currentTrack, isNull);

      final tracks = List.generate(5, (i) => _createDummyTrack(i));
      manager.setQueue(tracks, initialIndex: 2);

      expect(manager.queue.length, equals(5));
      expect(manager.currentIndex, equals(2));
      expect(manager.currentTrack?.trackKey, equals('track_2'));
    });

    test(
      'playNow jumps to existing track or inserts immediately after current',
      () {
        final manager = QueueManager();
        final tracks = List.generate(3, (i) => _createDummyTrack(i));
        manager.setQueue(tracks, initialIndex: 0);

        // Jump to track 2
        final existingTrack = tracks[2];
        manager.playNow(existingTrack);
        expect(manager.currentIndex, equals(2));
        expect(manager.queue.length, equals(3));

        // Play brand new track
        final newTrack = _createDummyTrack(99);
        manager.playNow(newTrack);
        expect(manager.currentIndex, equals(3));
        expect(manager.currentTrack?.trackKey, equals('track_99'));
        expect(manager.queue.length, equals(4));
      },
    );

    test('playNext inserts track directly after active index', () {
      final manager = QueueManager();
      final tracks = List.generate(3, (i) => _createDummyTrack(i));
      manager.setQueue(tracks, initialIndex: 0);

      final nextTrack = _createDummyTrack(100);
      manager.playNext(nextTrack);

      expect(manager.queue.length, equals(4));
      expect(manager.queue[1].trackKey, equals('track_100'));
      expect(manager.currentIndex, equals(0)); // Still playing track 0
    });

    test('addToQueue appends track to the end', () {
      final manager = QueueManager();
      final tracks = List.generate(3, (i) => _createDummyTrack(i));
      manager.setQueue(tracks, initialIndex: 0);

      final endTrack = _createDummyTrack(200);
      manager.addToQueue(endTrack);

      expect(manager.queue.length, equals(4));
      expect(manager.queue.last.trackKey, equals('track_200'));
    });

    test('removeAt updates currentIndex and queue contents correctly', () {
      final manager = QueueManager();
      final tracks = List.generate(4, (i) => _createDummyTrack(i));
      manager.setQueue(tracks, initialIndex: 2);

      // Remove item before active track
      manager.removeAt(0);
      expect(manager.queue.length, equals(3));
      expect(manager.currentIndex, equals(1));
      expect(manager.currentTrack?.trackKey, equals('track_2'));

      // Remove currently active track
      manager.removeAt(1);
      expect(manager.queue.length, equals(2));
      expect(manager.currentTrack?.trackKey, equals('track_3'));
    });

    test('reorder updates list structure and active track pointer', () {
      final manager = QueueManager();
      final tracks = List.generate(5, (i) => _createDummyTrack(i));
      manager.setQueue(tracks, initialIndex: 1); // track_1 is active

      manager.reorder(1, 3);
      expect(manager.currentIndex, equals(3));
      expect(manager.currentTrack?.trackKey, equals('track_1'));
    });

    test('clear resets state', () {
      final manager = QueueManager();
      manager.setQueue(List.generate(3, (i) => _createDummyTrack(i)));
      expect(manager.queue.length, equals(3));

      manager.clear();
      expect(manager.queue, isEmpty);
      expect(manager.currentIndex, equals(-1));
      expect(manager.currentTrack, isNull);
    });
  });

  group('QueueManager Repeat & Shuffle Navigation', () {
    test('sequential advance and wrap on RepeatAll', () {
      final manager = QueueManager();
      final tracks = List.generate(3, (i) => _createDummyTrack(i));
      manager.setQueue(tracks, initialIndex: 1);

      // Advance to 2
      expect(manager.advanceToNext(), isTrue);
      expect(manager.currentIndex, equals(2));

      // Repeat off: stops at end
      expect(manager.advanceToNext(), isFalse);
      expect(manager.currentIndex, equals(2));

      // Repeat all: wraps to 0
      manager.setRepeatMode(QueueRepeatMode.all);
      expect(manager.advanceToNext(), isTrue);
      expect(manager.currentIndex, equals(0));

      // Retreat backwards from 0 with RepeatAll: wraps to 2
      expect(manager.retreatToPrevious(), isTrue);
      expect(manager.currentIndex, equals(2));
    });

    test('repeat one stays on the same track', () {
      final manager = QueueManager();
      final tracks = List.generate(3, (i) => _createDummyTrack(i));
      manager.setQueue(tracks, initialIndex: 1);
      manager.setRepeatMode(QueueRepeatMode.one);

      expect(manager.advanceToNext(), isTrue);
      expect(manager.currentIndex, equals(1));
      expect(manager.retreatToPrevious(), isTrue);
      expect(manager.currentIndex, equals(1));
    });

    test('shuffled mode preserves active track and exhausts before repeat', () {
      final manager = QueueManager();
      final tracks = List.generate(5, (i) => _createDummyTrack(i));
      manager.setQueue(tracks, initialIndex: 3);

      manager.setShuffle(true);
      expect(manager.shuffleEnabled, isTrue);
      expect(manager.currentTrack?.trackKey, equals('track_3'));

      // Traverse all shuffled items
      final visited = <String>{manager.currentTrack!.trackKey};
      while (manager.advanceToNext()) {
        visited.add(manager.currentTrack!.trackKey);
      }

      // Must have visited every track in the queue exactly once
      expect(visited.length, equals(5));
      for (final t in tracks) {
        expect(visited.contains(t.trackKey), isTrue);
      }
    });

    test('getSlidingWindow generates bounded window of upcoming items', () {
      final manager = QueueManager();
      final tracks = List.generate(20, (i) => _createDummyTrack(i));
      manager.setQueue(tracks, initialIndex: 0);

      final window = manager.getSlidingWindow(windowSize: 5);
      expect(window.length, equals(5));
      expect(window[0].trackKey, equals('track_0'));
      expect(window[1].trackKey, equals('track_1'));
      expect(window[4].trackKey, equals('track_4'));
    });
  });

  group('QueueManager Persistence & Restoration', () {
    test('persists queue state to Drift DB and restores on launch', () async {
      final db = AppDatabase.inMemory();

      // Seed 3 tracks in DB
      for (var i = 0; i < 3; i++) {
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'track_$i',
                contentUri: 'content://media/external/audio/media/$i',
                path: '/storage/emulated/0/Music/track_$i.mp3',
                title: 'Track $i',
                titleSort: 'track $i',
                durationMs: 200000,
                sizeBytes: 5000000,
              ),
            );
      }

      final manager1 = QueueManager(db: db);
      final tracks = await db.watchAllTracks().first;
      manager1.setQueue(tracks, initialIndex: 1);
      manager1.setRepeatMode(QueueRepeatMode.all);

      // Persist state
      await manager1.persistState(positionMs: 45000);

      // New QueueManager instance simulating app relaunch
      final manager2 = QueueManager(db: db);
      final result = await manager2.restoreState();

      expect(result.restored, isTrue);
      expect(result.positionMs, equals(45000));
      expect(manager2.queue.length, equals(3));
      expect(manager2.currentIndex, equals(1));
      expect(manager2.currentTrack?.trackKey, equals('track_1'));
      expect(manager2.repeatMode, equals(QueueRepeatMode.all));

      await db.close();
    });
  });
}
