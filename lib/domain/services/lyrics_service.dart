import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';
import '../../data/sources/tag_reader.dart';
import 'lrc_parser.dart';

class LyricsService {
  LyricsService({required this.db});

  final AppDatabase db;
  final Map<String, SongLyrics> _cache = {};

  /// Loads lyrics for a given track, checking sidecar .lrc files first, then embedded tags.
  Future<SongLyrics> loadLyrics(Track track) async {
    if (_cache.containsKey(track.trackKey)) {
      return _cache[track.trackKey]!;
    }

    // 1. Check sidecar .lrc file in the same directory
    final sidecarLyrics = await _findSidecarLrc(track.path);
    if (sidecarLyrics != null && sidecarLyrics.isNotEmpty) {
      final parsed = LrcParser.parse(sidecarLyrics);
      _cache[track.trackKey] = parsed;
      return parsed;
    }

    // 2. Check embedded lyrics via TagReader
    try {
      final file = File(track.path);
      if (await file.exists()) {
        final meta = await TagReader.readFromFile(file);
        if (meta.lyrics != null && meta.lyrics!.trim().isNotEmpty) {
          final parsed = LrcParser.parse(meta.lyrics!);
          _cache[track.trackKey] = parsed;
          return parsed;
        }
      }
    } catch (_) {
      // Safe fallback on read error
    }

    _cache[track.trackKey] = SongLyrics.empty;
    return SongLyrics.empty;
  }

  Future<String?> _findSidecarLrc(String audioPath) async {
    try {
      final withoutExt = p.withoutExtension(audioPath);
      final lrcPath = '$withoutExt.lrc';
      final lrcFile = File(lrcPath);
      if (await lrcFile.exists()) {
        return await lrcFile.readAsString();
      }

      // Check uppercase extension
      final upperLrcFile = File('$withoutExt.LRC');
      if (await upperLrcFile.exists()) {
        return await upperLrcFile.readAsString();
      }
    } catch (_) {
      // Ignore I/O errors
    }
    return null;
  }

  void clearCache() {
    _cache.clear();
  }
}

final lyricsServiceProvider = Provider<LyricsService>((ref) {
  final db = ref.watch(databaseProvider);
  return LyricsService(db: db);
});

final currentTrackLyricsProvider = FutureProvider.family<SongLyrics, Track?>((
  ref,
  track,
) async {
  if (track == null) return SongLyrics.empty;
  final service = ref.watch(lyricsServiceProvider);
  return service.loadLyrics(track);
});
