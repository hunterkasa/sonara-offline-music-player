import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';

class StorageInfo {
  final int databaseSizeBytes;
  final int artworkCacheSizeBytes;
  final int artworkCachedFilesCount;
  final int totalTracksCount;
  final int totalAlbumsCount;
  final int totalArtistsCount;
  final int totalPlaylistsCount;

  const StorageInfo({
    required this.databaseSizeBytes,
    required this.artworkCacheSizeBytes,
    required this.artworkCachedFilesCount,
    required this.totalTracksCount,
    required this.totalAlbumsCount,
    required this.totalArtistsCount,
    required this.totalPlaylistsCount,
  });

  int get totalSizeBytes => databaseSizeBytes + artworkCacheSizeBytes;
}

class StorageInspectorService {
  final AppDatabase db;
  final Future<Directory> Function()? docDirGetter;
  final Future<Directory> Function()? tempDirGetter;

  StorageInspectorService(this.db, {this.docDirGetter, this.tempDirGetter});

  /// Inspects current disk usage and record counts
  Future<StorageInfo> getStorageInfo() async {
    // 1. Database size
    var dbSize = 0;
    try {
      final docDir = docDirGetter != null
          ? await docDirGetter!()
          : await getApplicationDocumentsDirectory();
      final files = ['sonara.sqlite', 'sonara.sqlite-wal', 'sonara.sqlite-shm'];
      for (final name in files) {
        final f = File('${docDir.path}/$name');
        if (await f.exists()) {
          dbSize += await f.length();
        }
      }
    } catch (_) {}

    // 2. Artwork cache size
    var artCacheSize = 0;
    var artCacheCount = 0;
    try {
      final cacheDir = tempDirGetter != null
          ? await tempDirGetter!()
          : await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            artCacheSize += await entity.length();
            artCacheCount++;
          }
        }
      }
    } catch (_) {}

    // 3. Database counts
    final trackCount = await db.getTrackCount();
    final allPlaylists = await db.getAllPlaylists();
    final allAlbums = await db.searchAlbums('', limit: 100000);
    final allArtists = await db.searchArtists('', limit: 100000);

    return StorageInfo(
      databaseSizeBytes: dbSize,
      artworkCacheSizeBytes: artCacheSize,
      artworkCachedFilesCount: artCacheCount,
      totalTracksCount: trackCount,
      totalAlbumsCount: allAlbums.length,
      totalArtistsCount: allArtists.length,
      totalPlaylistsCount: allPlaylists.length,
    );
  }

  /// Clears artwork cache directory
  Future<int> clearArtworkCache() async {
    var bytesFreed = 0;
    try {
      final cacheDir = tempDirGetter != null
          ? await tempDirGetter!()
          : await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: false)) {
          if (entity is File) {
            bytesFreed += await entity.length();
            await entity.delete();
          } else if (entity is Directory) {
            await entity.delete(recursive: true);
          }
        }
      }
    } catch (_) {}
    return bytesFreed;
  }

  /// Vacuums SQLite database to compact space
  Future<void> vacuumDatabase() async {
    await db.customStatement('VACUUM;');
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

final storageInspectorServiceProvider = Provider<StorageInspectorService>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return StorageInspectorService(db);
});
