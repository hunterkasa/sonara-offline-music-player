import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ArtworkService {
  ArtworkService([this._cacheDir]);

  Directory? _cacheDir;

  static const int defaultMaxFiles = 300;
  static const int defaultMaxSizeBytes = 50 * 1024 * 1024; // 50 MB

  Future<Directory> _getCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    final tempDir = await getApplicationDocumentsDirectory();
    final artDir = Directory(p.join(tempDir.path, 'artwork_cache'));
    if (!artDir.existsSync()) {
      artDir.createSync(recursive: true);
    }
    _cacheDir = artDir;
    return artDir;
  }

  /// Generates a stable key for artwork caching from content/bytes or album title
  static String generateArtworkKey(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  /// Caches embedded artwork bytes to disk and returns the cached file path.
  /// Enforces disk LRU bounds by pruning oldest files when limits are reached.
  Future<String?> cacheArtworkBytes(String key, Uint8List bytes) async {
    try {
      final dir = await _getCacheDirectory();
      final file = File(p.join(dir.path, 'art_$key.jpg'));
      if (!file.existsSync()) {
        file.writeAsBytesSync(bytes, flush: true);
        _pruneCacheInternal(dir);
      } else {
        try {
          file.setLastModifiedSync(DateTime.now());
        } catch (_) {}
      }
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Prunes the artwork disk cache so that it does not exceed [maxFiles] or [maxSizeBytes].
  /// Evicts the least recently accessed files first based on [lastModified].
  Future<int> pruneCache({
    int maxFiles = defaultMaxFiles,
    int maxSizeBytes = defaultMaxSizeBytes,
  }) async {
    try {
      final dir = await _getCacheDirectory();
      return _pruneCacheInternal(
        dir,
        maxFiles: maxFiles,
        maxSizeBytes: maxSizeBytes,
      );
    } catch (e) {
      debugPrint('Error pruning artwork cache: $e');
      return 0;
    }
  }

  static int _pruneCacheInternal(
    Directory dir, {
    int maxFiles = defaultMaxFiles,
    int maxSizeBytes = defaultMaxSizeBytes,
  }) {
    if (!dir.existsSync()) return 0;
    final entities = dir
        .listSync()
        .whereType<File>()
        .where((f) => p.basename(f.path).startsWith('art_'))
        .toList();

    if (entities.isEmpty) return 0;

    final fileStats = entities.map((file) {
      try {
        final stat = file.statSync();
        return (file: file, modified: stat.modified, size: stat.size);
      } catch (_) {
        return (
          file: file,
          modified: DateTime.fromMillisecondsSinceEpoch(0),
          size: 0,
        );
      }
    }).toList();

    // Sort by modified ascending (oldest first for LRU eviction)
    fileStats.sort((a, b) => a.modified.compareTo(b.modified));

    var totalCount = fileStats.length;
    var totalSize = fileStats.fold<int>(0, (sum, f) => sum + f.size);
    var deletedCount = 0;

    for (final item in fileStats) {
      if (totalCount <= maxFiles && totalSize <= maxSizeBytes) {
        break;
      }
      try {
        item.file.deleteSync();
        totalCount--;
        totalSize -= item.size;
        deletedCount++;
      } catch (_) {}
    }

    return deletedCount;
  }

  /// Attempts to find artwork for a track:
  /// 1. Disk cache by key
  /// 2. Sidecar cover images in the same folder (folder.jpg, cover.jpg, front.png, etc.)
  Future<File?> resolveArtworkFile({
    required String? artworkKey,
    required String? filePath,
  }) async {
    // If artworkKey is a preset identifier, it is rendered directly via widgets (not a file)
    if (artworkKey != null && artworkKey.startsWith('preset:')) {
      return null;
    }

    // 1. Check direct file path (custom gallery image) or disk cache
    if (artworkKey != null && artworkKey.isNotEmpty) {
      try {
        final directFile = File(artworkKey);
        if (await directFile.exists()) {
          return directFile;
        }
      } catch (_) {}

      final dir = await _getCacheDirectory();
      final cachedFile = File(p.join(dir.path, 'art_$artworkKey.jpg'));
      if (await cachedFile.exists()) {
        try {
          await cachedFile.setLastModified(DateTime.now());
        } catch (_) {}
        return cachedFile;
      }
    }

    // 2. Check sidecar file in the directory
    if (filePath != null && filePath.isNotEmpty) {
      try {
        final folder = Directory(p.dirname(filePath));
        if (await folder.exists()) {
          final sidecarNames = [
            'cover.jpg',
            'cover.png',
            'folder.jpg',
            'folder.png',
            'front.jpg',
            'front.png',
            'album.jpg',
            'album.png',
          ];
          for (final name in sidecarNames) {
            final sidecar = File(p.join(folder.path, name));
            if (await sidecar.exists()) {
              return sidecar;
            }
          }
        }
      } catch (_) {}
    }

    return null;
  }

  /// Generates a deterministic gradient placeholder for missing artwork
  static LinearGradient generateGradientFallback(String seed) {
    final hash = seed.hashCode.abs();
    final hue1 = ((hash % 360) + 360) % 360.0;
    final hue2 = (((hash + 60) % 360) + 360) % 360.0;

    final color1 = HSLColor.fromAHSL(1.0, hue1, 0.65, 0.40).toColor();
    final color2 = HSLColor.fromAHSL(1.0, hue2, 0.70, 0.25).toColor();

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color1, color2],
    );
  }
}

final artworkServiceProvider = Provider<ArtworkService>((ref) {
  return ArtworkService();
});
