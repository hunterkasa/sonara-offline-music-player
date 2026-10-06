import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/duplicate_finder_service.dart';

void main() {
  late AppDatabase db;
  late DuplicateFinderService service;

  setUp(() {
    db = AppDatabase.inMemory();
    service = DuplicateFinderService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DuplicateFinderService', () {
    test('returns empty clusters when no tracks exist', () async {
      final duplicates = await service.findDuplicates();
      expect(duplicates, isEmpty);
    });

    test('detects exact file duplicates by size and duration', () async {
      // Insert two tracks with same size and duration
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'key_1',
              contentUri: 'content://media/1',
              path: '/music/song1.mp3',
              title: 'Song One',
              titleSort: 'song one',
              durationMs: 200000,
              sizeBytes: 4096000,
            ),
          );

      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'key_2',
              contentUri: 'content://media/2',
              path: '/download/song1_copy.mp3',
              title: 'Song One',
              titleSort: 'song one',
              durationMs: 200000,
              sizeBytes: 4096000,
            ),
          );

      final clusters = await service.findDuplicates();
      expect(clusters.length, equals(1));
      expect(clusters.first.matchType, equals(DuplicateMatchType.exactFile));
      expect(clusters.first.tracks.length, equals(2));
      expect(
        clusters.first.tracks.map((t) => t.trackKey),
        containsAll(['key_1', 'key_2']),
      );
    });

    test('detects metadata duplicates with normalized title and duration within 2s', () async {
      // Insert two tracks with different file sizes but same title and duration
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'meta_1',
              contentUri: 'content://media/3',
              path: '/music/song_flac.flac',
              title: 'Bohemian Rhapsody',
              titleSort: 'bohemian rhapsody',
              durationMs: 354000,
              sizeBytes: 25000000,
            ),
          );

      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'meta_2',
              contentUri: 'content://media/4',
              path: '/music/song_mp3.mp3',
              title: ' Bohemian Rhapsody ',
              titleSort: 'bohemian rhapsody',
              durationMs: 354500,
              sizeBytes: 8000000,
            ),
          );

      final clusters = await service.findDuplicates();
      expect(clusters.length, equals(1));
      expect(
        clusters.first.matchType,
        equals(DuplicateMatchType.metadataAndDuration),
      );
      expect(clusters.first.tracks.length, equals(2));
    });

    test('can hide and unhide duplicate tracks', () async {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'hide_1',
              contentUri: 'content://media/5',
              path: '/music/hide.mp3',
              title: 'Track to Hide',
              titleSort: 'track to hide',
              durationMs: 180000,
              sizeBytes: 3000000,
            ),
          );

      await service.hideTrack('hide_1');
      var track = await db.getTrackByKey('hide_1');
      expect(track?.isHidden, isTrue);

      await service.unhideTrack('hide_1');
      track = await db.getTrackByKey('hide_1');
      expect(track?.isHidden, isFalse);
    });

    test('calculates cluster totalSize properly', () async {
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'sz_1',
              contentUri: 'c_sz_1',
              path: '/p_sz_1',
              title: 'Size Song',
              titleSort: 'size song',
              durationMs: 120000,
              sizeBytes: 1024,
            ),
          );
      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'sz_2',
              contentUri: 'c_sz_2',
              path: '/p_sz_2',
              title: 'Size Song',
              titleSort: 'size song',
              durationMs: 120000,
              sizeBytes: 1024,
            ),
          );

      final clusters = await service.findDuplicates();
      expect(clusters.length, equals(1));
      expect(clusters.first.totalSize, equals(2048));
    });

    test('can delete duplicate track from database and unlink file', () async {
      final tempFile = File(
        '${Directory.systemTemp.path}/test_duplicate_audio.mp3',
      );
      await tempFile.writeAsBytes([1, 2, 3]);

      await db
          .into(db.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'del_1',
              contentUri: 'content://media/6',
              path: tempFile.path,
              title: 'Track to Delete',
              titleSort: 'track to delete',
              durationMs: 180000,
              sizeBytes: 3000000,
            ),
          );

      final track = (await db.getTrackByKey('del_1'))!;
      await service.deleteTrack(track, deleteFile: true);

      final queryResult = await db.getTrackByKey('del_1');
      expect(queryResult, isNull);
      expect(await tempFile.exists(), isFalse);
    });
  });
}
