import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/storage_inspector_service.dart';

void main() {
  late AppDatabase db;
  late Directory tempDocDir;
  late Directory tempCacheDir;
  late StorageInspectorService service;

  setUp(() async {
    db = AppDatabase.inMemory();
    tempDocDir = await Directory.systemTemp.createTemp('sonara_doc_');
    tempCacheDir = await Directory.systemTemp.createTemp('sonara_cache_');

    service = StorageInspectorService(
      db,
      docDirGetter: () async => tempDocDir,
      tempDirGetter: () async => tempCacheDir,
    );
  });

  tearDown(() async {
    await db.close();
    try {
      if (await tempDocDir.exists()) {
        await tempDocDir.delete(recursive: true);
      }
      if (await tempCacheDir.exists()) {
        await tempCacheDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('StorageInspectorService', () {
    test('formats byte sizes cleanly', () {
      expect(StorageInspectorService.formatBytes(512), equals('512 B'));
      expect(StorageInspectorService.formatBytes(1536), equals('1.5 KB'));
      expect(StorageInspectorService.formatBytes(5242880), equals('5.0 MB'));
    });

    test(
      'calculates storage info from files and database accurately',
      () async {
        // 1. Create a dummy db file in tempDocDir
        final dbFile = File('${tempDocDir.path}/sonara.sqlite');
        await dbFile.writeAsBytes(List.filled(2048, 0));

        // 2. Create dummy cache thumbnails in tempCacheDir
        final cacheFile1 = File('${tempCacheDir.path}/thumb1.jpg');
        await cacheFile1.writeAsBytes(List.filled(1024, 0));
        final cacheFile2 = File('${tempCacheDir.path}/thumb2.jpg');
        await cacheFile2.writeAsBytes(List.filled(1024, 0));

        // 3. Add DB records
        await db
            .into(db.tracks)
            .insert(
              TracksCompanion.insert(
                trackKey: 'k1',
                contentUri: 'c1',
                path: '/p1',
                title: 'Song 1',
                titleSort: 'song 1',
                durationMs: 100000,
                sizeBytes: 1024,
              ),
            );
        await db.createPlaylist(name: 'Inspector Playlist');

        final info = await service.getStorageInfo();
        expect(info.totalTracksCount, equals(1));
        expect(info.totalPlaylistsCount, equals(1));
        expect(info.databaseSizeBytes, equals(2048));
        expect(info.artworkCacheSizeBytes, equals(2048));
        expect(info.artworkCachedFilesCount, equals(2));
        expect(info.totalSizeBytes, equals(4096));
      },
    );

    test('clears artwork cache and returns freed bytes', () async {
      final cacheFile = File('${tempCacheDir.path}/art.jpg');
      await cacheFile.writeAsBytes(List.filled(4096, 0));

      final freed = await service.clearArtworkCache();
      expect(freed, equals(4096));
      expect(await cacheFile.exists(), isFalse);
    });

    test('vacuumDatabase executes without error', () async {
      expect(service.vacuumDatabase(), completes);
    });
  });
}
