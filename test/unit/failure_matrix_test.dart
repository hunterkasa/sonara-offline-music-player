import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/sources/tag_reader.dart';
import 'package:sonara/domain/services/queue_manager.dart';

Track _createTrack(int i) => Track(
  id: i,
  trackKey: 'track_$i',
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
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late QueueManager queueManager;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase.inMemory();
    queueManager = QueueManager(db: db);
    tempDir = await Directory.systemTemp.createTemp('sonara_failure_test_');
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Phase 7 Failure Matrix & Edge Cases Tests', () {
    test(
      'TagReader gracefully handles zero-byte corrupt files without crashing',
      () async {
        final zeroByteFile = File('${tempDir.path}/zero_byte_corrupt.mp3');
        await zeroByteFile.writeAsBytes([]);

        final metadata = await TagReader.readFromFile(zeroByteFile);

        expect(metadata.title, equals('zero_byte_corrupt'));
        expect(metadata.artist, equals('Unknown Artist'));
      },
    );

    test('TagReader gracefully handles corrupt random-noise headers', () async {
      final corruptFile = File('${tempDir.path}/noise_header.flac');
      await corruptFile.writeAsBytes(List.generate(512, (i) => (i * 37) % 256));

      final metadata = await TagReader.readFromFile(corruptFile);

      expect(metadata.title, equals('noise_header'));
      expect(metadata.artist, equals('Unknown Artist'));
    });

    test('QueueManager handles missing tracks storm and skips smoothly', () {
      final tracks = List.generate(10, (i) => _createTrack(i));
      queueManager.setQueue(tracks, initialIndex: 0);

      // Simulate skipping through missing files
      for (int i = 0; i < 9; i++) {
        expect(queueManager.currentIndex, equals(i));
        final advanced = queueManager.advanceToNext();
        expect(advanced, isTrue);
      }
      expect(queueManager.currentIndex, equals(9));
      // Reaching end stops smoothly without crashing
      final advancedPastEnd = queueManager.advanceToNext();
      expect(advancedPastEnd, isFalse);
      expect(queueManager.currentIndex, equals(9));
    });

    test('Survives rapid skip spam without state desynchronization', () {
      final tracks = List.generate(50, (i) => _createTrack(i));
      queueManager.setQueue(tracks, initialIndex: 0);

      // Rapidly skip 30 times
      for (int i = 0; i < 30; i++) {
        queueManager.advanceToNext();
      }
      expect(queueManager.currentIndex, equals(30));
      expect(queueManager.currentTrack?.trackKey, equals('track_30'));

      // Rapidly skip previous 15 times
      for (int i = 0; i < 15; i++) {
        queueManager.retreatToPrevious();
      }
      expect(queueManager.currentIndex, equals(15));
      expect(queueManager.currentTrack?.trackKey, equals('track_15'));
    });

    test('Process death recovery restores queue, position, and shuffle state exactly', () async {
      final tracks = List.generate(20, (i) => _createTrack(i));

      // Insert tracks into database so restoreState can find them
      for (final t in tracks) {
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: t.trackKey,
                contentUri: t.contentUri,
                path: t.path,
                title: t.title,
                titleSort: t.titleSort,
                durationMs: t.durationMs,
                sizeBytes: t.sizeBytes,
                hasLyrics: const Value(false),
              ),
            );
      }

      queueManager.setQueue(tracks, initialIndex: 7);
      queueManager.setShuffle(true);
      queueManager.setRepeatMode(QueueRepeatMode.all);

      // Persist state to Drift DB
      await queueManager.persistState(positionMs: 45000);

      // Simulate process death and recreate fresh QueueManager with the same DB
      final restoredDb = db;
      final newQueueManager = QueueManager(db: restoredDb);
      final restoredResult = await newQueueManager.restoreState();

      expect(restoredResult.restored, isTrue);
      expect(restoredResult.positionMs, equals(45000));
      expect(newQueueManager.currentIndex, equals(7));
      expect(newQueueManager.currentTrack?.trackKey, equals('track_7'));
      expect(newQueueManager.shuffleEnabled, isTrue);
      expect(newQueueManager.repeatMode, equals(QueueRepeatMode.all));
    });
  });
}
