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
    test('initializes schema v1 cleanly', () {
      expect(db.schemaVersion, equals(1));
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

    test('can seed synthetic tracks and verify track count', () async {
      // Seed a subset in unit test to verify batch pipeline
      await db.seedSyntheticData(count: 100);

      final count = await db.getTrackCount();
      expect(count, equals(100));

      final allTracks = await db.watchAllTracks().first;
      expect(allTracks.length, equals(100));
      expect(allTracks.first.title, startsWith('Synthetic Track'));
    });
  });
}
