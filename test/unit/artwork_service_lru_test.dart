import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sonara/data/sources/artwork_service.dart';

void main() {
  group('ArtworkService LRU Cache Tests', () {
    late Directory tempCacheDir;
    late ArtworkService artworkService;

    setUp(() async {
      tempCacheDir = await Directory.systemTemp.createTemp('artwork_lru_test');
      artworkService = ArtworkService(tempCacheDir);
    });

    tearDown(() async {
      if (await tempCacheDir.exists()) {
        await tempCacheDir.delete(recursive: true);
      }
    });

    test(
      'pruneCache evicts oldest files when exceeding maxFiles limit',
      () async {
        // Create 5 cached artwork files with staggered modification times
        final files = <File>[];
        for (var i = 1; i <= 5; i++) {
          final file = File(p.join(tempCacheDir.path, 'art_key_$i.jpg'));
          await file.writeAsBytes(Uint8List.fromList([1, 2, 3, 4, i]));
          await file.setLastModified(
            DateTime.now().subtract(Duration(hours: 10 - i)),
          );
          files.add(file);
        }

        expect(tempCacheDir.listSync().length, equals(5));

        // Prune down to maxFiles = 3
        final evicted = await artworkService.pruneCache(maxFiles: 3);
        expect(evicted, equals(2));

        // Check remaining files
        final remaining = tempCacheDir
            .listSync()
            .whereType<File>()
            .map((f) => p.basename(f.path))
            .toSet();

        expect(remaining.length, equals(3));
        // key_1 and key_2 were the oldest, so they should be evicted
        expect(remaining.contains('art_key_1.jpg'), isFalse);
        expect(remaining.contains('art_key_2.jpg'), isFalse);
        expect(remaining.contains('art_key_3.jpg'), isTrue);
        expect(remaining.contains('art_key_4.jpg'), isTrue);
        expect(remaining.contains('art_key_5.jpg'), isTrue);
      },
    );

    test('pruneCache evicts oldest files when exceeding maxSizeBytes limit', () async {
      // Create 3 files of 100 bytes each
      for (var i = 1; i <= 3; i++) {
        final file = File(p.join(tempCacheDir.path, 'art_big_$i.jpg'));
        await file.writeAsBytes(Uint8List(100));
        await file.setLastModified(
          DateTime.now().subtract(Duration(minutes: 10 - i)),
        );
      }

      // 300 bytes total, prune down to 150 bytes max
      final evicted = await artworkService.pruneCache(
        maxFiles: 10,
        maxSizeBytes: 150,
      );

      // Should evict 2 oldest files (200 bytes removed, 100 bytes left <= 150)
      expect(evicted, equals(2));
      final remaining = tempCacheDir.listSync().whereType<File>().toList();
      expect(remaining.length, equals(1));
      expect(p.basename(remaining.first.path), equals('art_big_3.jpg'));
    });

    test('cacheArtworkBytes automatically triggers LRU eviction and updates timestamp', () async {
      // Cache 3 files directly via cacheArtworkBytes
      await artworkService.cacheArtworkBytes(
        'alpha',
        Uint8List.fromList([1, 2, 3]),
      );
      await artworkService.cacheArtworkBytes(
        'beta',
        Uint8List.fromList([4, 5, 6]),
      );

      final fileAlpha = File(p.join(tempCacheDir.path, 'art_alpha.jpg'));
      expect(await fileAlpha.exists(), isTrue);

      // Resolving artwork file updates its lastModified timestamp
      final resolved = await artworkService.resolveArtworkFile(
        artworkKey: 'alpha',
        filePath: null,
      );
      expect(resolved, isNotNull);
      expect(resolved!.path, equals(fileAlpha.path));
    });
  });
}
