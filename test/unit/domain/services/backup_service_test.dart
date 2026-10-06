import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/backup_service.dart';

void main() {
  late AppDatabase db1;
  late AppDatabase db2;
  late BackupService service1;
  late BackupService service2;

  setUp(() {
    db1 = AppDatabase.inMemory();
    db2 = AppDatabase.inMemory();
    service1 = BackupService(db1);
    service2 = BackupService(db2);
  });

  tearDown(() async {
    await db1.close();
    await db2.close();
  });

  group('BackupService', () {
    test('exports full backup bundle as valid JSON', () async {
      // 1. Seed tracks, playlist, favorites in db1
      await db1
          .into(db1.tracks)
          .insert(
            TracksCompanion.insert(
              trackKey: 'track_alpha',
              contentUri: 'content://media/10',
              path: '/music/alpha.mp3',
              title: 'Alpha Song',
              titleSort: 'alpha song',
              durationMs: 210000,
              sizeBytes: 5000000,
              isFavorite: const Value(true),
              playCount: const Value(15),
              skipCount: const Value(2),
            ),
          );

      final plId = await db1.createPlaylist(name: 'My Roadtrip');
      await db1.addTracksToPlaylist(plId, ['track_alpha']);
      await db1.setSetting('theme_mode', '"amoled"');

      // 2. Export JSON
      final jsonStr = await service1.createBackupJson();
      expect(jsonStr, isNotEmpty);

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(data['version'], equals(1));
      expect(data['playlists'], isNotEmpty);
      expect(data['favorites'], isNotEmpty);
      expect(data['listeningStats'], isNotEmpty);
      expect(data['settings']['theme_mode'], equals('"amoled"'));
    });

    test(
      'restores playlists, favorites, stats, and settings with relinking',
      () async {
        // 1. Seed db1
        await db1
            .into(db1.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'key_synth_01',
                contentUri: 'content://media/20',
                path: '/storage/music/synthwave.mp3',
                title: 'Nightcall',
                titleSort: 'nightcall',
                durationMs: 250000,
                sizeBytes: 6000000,
                isFavorite: const Value(true),
                playCount: const Value(42),
                skipCount: const Value(3),
              ),
            );
        final plId = await db1.createPlaylist(name: 'Synth Essentials');
        await db1.addTracksToPlaylist(plId, ['key_synth_01']);
        await db1.setSetting('equalizer_preset', '"Rock"');

        final backupJson = await service1.createBackupJson();

        // 2. Seed db2 with the track (simulating re-indexed library on fresh install)
        await db2
            .into(db2.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'key_synth_01',
                contentUri: 'content://media/fresh/20',
                path: '/storage/music/synthwave.mp3',
                title: 'Nightcall',
                titleSort: 'nightcall',
                durationMs: 250000,
                sizeBytes: 6000000,
              ),
            );

        // 3. Restore into db2
        final result = await service2.restoreBackupJson(backupJson);
        expect(result.playlistsRestored, equals(1));
        expect(result.favoritesRestored, equals(1));
        expect(result.statsRestored, equals(1));
        expect(result.settingsRestored, equals(1));

        // 4. Verify db2 state
        final pl2 = await db2.getAllPlaylists();
        expect(pl2.length, equals(1));
        expect(pl2.first.name, equals('Synth Essentials'));

        final plTracks = await db2.getPlaylistTrackKeys(pl2.first.id);
        expect(plTracks, contains('key_synth_01'));

        final trackInDb2 = await db2.getTrackByKey('key_synth_01');
        expect(trackInDb2?.isFavorite, isTrue);
        expect(trackInDb2?.playCount, equals(42));
        expect(trackInDb2?.skipCount, equals(3));

        final restoredSetting = await db2.getSetting('equalizer_preset');
        expect(restoredSetting, equals('"Rock"'));
      },
    );
  });
}
