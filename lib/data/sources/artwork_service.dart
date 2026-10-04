import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ArtworkService {
  Directory? _cacheDir;

  Future<Directory> _getCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    final tempDir = await getApplicationDocumentsDirectory();
    final artDir = Directory(p.join(tempDir.path, 'artwork_cache'));
    if (!await artDir.exists()) {
      await artDir.create(recursive: true);
    }
    _cacheDir = artDir;
    return artDir;
  }

  /// Generates a stable key for artwork caching from content/bytes or album title
  static String generateArtworkKey(String input) {
    return md5.convert(input.codeUnits).toString();
  }

  /// Caches embedded artwork bytes to disk and returns the cached file path.
  Future<String?> cacheArtworkBytes(String key, Uint8List bytes) async {
    try {
      final dir = await _getCacheDirectory();
      final file = File(p.join(dir.path, 'art_$key.jpg'));
      if (!await file.exists()) {
        await file.writeAsBytes(bytes, flush: true);
      }
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Attempts to find artwork for a track:
  /// 1. Disk cache by key
  /// 2. Sidecar cover images in the same folder (folder.jpg, cover.jpg, front.png, etc.)
  Future<File?> resolveArtworkFile({
    required String? artworkKey,
    required String? filePath,
  }) async {
    // 1. Check disk cache
    if (artworkKey != null && artworkKey.isNotEmpty) {
      final dir = await _getCacheDirectory();
      final cachedFile = File(p.join(dir.path, 'art_$artworkKey.jpg'));
      if (await cachedFile.exists()) {
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
    final hue1 = (hash % 360).toDouble();
    final hue2 = ((hash + 60) % 360).toDouble();

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
