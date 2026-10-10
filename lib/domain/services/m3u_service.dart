import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';

final m3uServiceProvider = Provider<M3uService>((ref) {
  final db = ref.watch(databaseProvider);
  return M3uService(db);
});

class M3uEntry {
  final String path;
  final String? title;
  final String? artist;
  final int durationSeconds;

  const M3uEntry({
    required this.path,
    this.title,
    this.artist,
    this.durationSeconds = -1,
  });
}

class M3uService {
  final AppDatabase _db;

  M3uService(this._db);

  /// Parse M3U / M3U8 string content into a list of M3uEntry objects
  List<M3uEntry> parseM3u(String content) {
    final lines = const LineSplitter().convert(content);
    final entries = <M3uEntry>[];

    int currentDuration = -1;
    String? currentTitle;
    String? currentArtist;

    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        // Parse #EXTINF:duration,Artist - Title OR #EXTINF:duration,Title
        final infoPayload = line.substring(8).trim();
        final commaIdx = infoPayload.indexOf(',');
        if (commaIdx != -1) {
          final durStr = infoPayload.substring(0, commaIdx).trim();
          currentDuration = int.tryParse(durStr) ?? -1;

          final label = infoPayload.substring(commaIdx + 1).trim();
          if (label.contains(' - ')) {
            final parts = label.split(' - ');
            currentArtist = parts[0].trim();
            currentTitle = parts.sublist(1).join(' - ').trim();
          } else {
            currentTitle = label;
            currentArtist = null;
          }
        }
      } else if (!line.startsWith('#')) {
        // Line is a track path or URI
        entries.add(
          M3uEntry(
            path: line,
            title: currentTitle,
            artist: currentArtist,
            durationSeconds: currentDuration,
          ),
        );
        currentDuration = -1;
        currentTitle = null;
        currentArtist = null;
      }
    }

    return entries;
  }

  /// Resolve M3U entries to existing tracks in the database
  Future<List<String>> matchEntriesToTrackKeys(List<M3uEntry> entries) async {
    final allTracks = await _db.getAllTracks(includeHidden: true);
    final pathMap = <String, Track>{};
    final basenameMap = <String, Track>{};
    final titleMap = <String, Track>{};

    for (final t in allTracks) {
      pathMap[t.path.toLowerCase()] = t;
      basenameMap[p.basename(t.path).toLowerCase()] = t;
      titleMap[t.title.trim().toLowerCase()] = t;
    }

    final matchedKeys = <String>[];
    for (final entry in entries) {
      // 1. Direct path match
      final byPath = pathMap[entry.path.toLowerCase()];
      if (byPath != null) {
        matchedKeys.add(byPath.trackKey);
        continue;
      }

      // 2. Basename match
      final base = p.basename(entry.path).toLowerCase();
      final byBasename = basenameMap[base];
      if (byBasename != null) {
        matchedKeys.add(byBasename.trackKey);
        continue;
      }

      // 3. Title match
      if (entry.title != null) {
        final byTitle = titleMap[entry.title!.trim().toLowerCase()];
        if (byTitle != null) {
          matchedKeys.add(byTitle.trackKey);
          continue;
        }
      }
    }

    return matchedKeys;
  }

  /// Import an M3U file from disk into a new playlist
  Future<int?> importM3uFile(File file, {String? playlistName}) async {
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    final entries = parseM3u(content);
    final trackKeys = await matchEntriesToTrackKeys(entries);

    final name = playlistName ?? p.basenameWithoutExtension(file.path);
    final playlistId = await _db.createPlaylist(name: name);
    if (trackKeys.isNotEmpty) {
      await _db.addTracksToPlaylist(playlistId, trackKeys);
    }
    return playlistId;
  }

  /// Export a playlist's tracks to M3U8 string content
  Future<String> exportPlaylistToM3u(int playlistId) async {
    final playlist = await _db.getPlaylist(playlistId);
    final tracks = await _db.watchPlaylistTracks(playlistId).first;

    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');
    if (playlist != null) {
      buffer.writeln('#PLAYLIST:${playlist.name}');
    }

    for (final track in tracks) {
      final durSec = track.durationMs ~/ 1000;
      final artistName =
          await _db.getArtistName(track.artistId) ?? 'Unknown Artist';
      buffer.writeln('#EXTINF:$durSec,$artistName - ${track.title}');
      buffer.writeln(track.path);
    }

    return buffer.toString();
  }

  /// Export a playlist to a file on disk
  Future<File> exportPlaylistToFile(
    int playlistId,
    String targetDirectoryPath,
  ) async {
    final playlist = await _db.getPlaylist(playlistId);
    final safeName = (playlist?.name ?? 'playlist').replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );
    final targetFile = File(p.join(targetDirectoryPath, '$safeName.m3u8'));

    final content = await exportPlaylistToM3u(playlistId);
    await targetFile.parent.create(recursive: true);
    return targetFile.writeAsString(content);
  }
}
