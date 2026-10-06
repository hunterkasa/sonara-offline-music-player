import 'dart:io';

import 'package:drift/drift.dart';
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
      if (file.existsSync()) {
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
      if (lrcFile.existsSync()) {
        return lrcFile.readAsStringSync();
      }

      // Check uppercase extension
      final upperLrcFile = File('$withoutExt.LRC');
      if (upperLrcFile.existsSync()) {
        return upperLrcFile.readAsStringSync();
      }
    } catch (_) {
      // Ignore I/O errors
    }
    return null;
  }

  /// Saves lyrics to sidecar .lrc file, updates the database hasLyrics state, and refreshes the in-memory cache.
  Future<bool> saveLyrics(Track track, String lrcContent) async {
    try {
      final withoutExt = p.withoutExtension(track.path);
      final lrcFile = File('$withoutExt.lrc');
      lrcFile.writeAsStringSync(lrcContent, flush: true);

      // Parse and update in-memory cache
      final parsed = LrcParser.parse(lrcContent);
      _cache[track.trackKey] = parsed;

      // Update database hasLyrics flag
      await (db.update(db.tracks)
            ..where((t) => t.trackKey.equals(track.trackKey)))
          .write(const TracksCompanion(hasLyrics: Value(true)));

      return true;
    } catch (_) {
      return false;
    }
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
