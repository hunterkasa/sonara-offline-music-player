import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/db/database_provider.dart';

class BackupRestoreResult {
  final int playlistsRestored;
  final int favoritesRestored;
  final int statsRestored;
  final int settingsRestored;

  const BackupRestoreResult({
    required this.playlistsRestored,
    required this.favoritesRestored,
    required this.statsRestored,
    required this.settingsRestored,
  });
}

class BackupService {
  final AppDatabase db;

  BackupService(this.db);

  /// Exports full library metadata, playlists, favorites, stats, and settings to JSON
  Future<String> createBackupJson() async {
    final playlists = await db.getAllPlaylists();
    final allTracks = await db.getAllTracks(includeHidden: true);
    final trackMap = {for (final t in allTracks) t.trackKey: t};

    // 1. Playlists with track metadata for resilient relinking
    final playlistList = <Map<String, dynamic>>[];
    for (final pl in playlists) {
      final keys = await db.getPlaylistTrackKeys(pl.id);
      final tracksData = <Map<String, dynamic>>[];
      for (final key in keys) {
        final t = trackMap[key];
        tracksData.add({
          'trackKey': key,
          'title': t?.title ?? '',
          'path': t?.path ?? '',
          'durationMs': t?.durationMs ?? 0,
        });
      }

      playlistList.add({
        'name': pl.name,
        'description': pl.description,
        'isSmart': pl.isSmart,
        'rulesJson': pl.rulesJson,
        'coverUri': pl.coverUri,
        'tracks': tracksData,
      });
    }

    // 2. Favorites
    final favorites = allTracks
        .where((t) => t.isFavorite)
        .map(
          (t) => {
            'trackKey': t.trackKey,
            'title': t.title,
            'path': t.path,
            'durationMs': t.durationMs,
          },
        )
        .toList();

    // 3. Listening Stats
    final stats = allTracks
        .where((t) => t.playCount > 0 || t.skipCount > 0)
        .map(
          (t) => {
            'trackKey': t.trackKey,
            'title': t.title,
            'playCount': t.playCount,
            'skipCount': t.skipCount,
            'lastPlayedAt': t.lastPlayedAt,
          },
        )
        .toList();

    // 4. App Settings
    final settingsList = await db.getAllSettings();
    final settingsMap = {for (final s in settingsList) s.key: s.valueJson};

    final bundle = {
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'playlists': playlistList,
      'favorites': favorites,
      'listeningStats': stats,
      'settings': settingsMap,
    };

    return const JsonEncoder.withIndent('  ').convert(bundle);
  }

  /// Restores library from JSON string, relinking tracks by key, title, or path
  Future<BackupRestoreResult> restoreBackupJson(String jsonStr) async {
    final Map<String, dynamic> data =
        jsonDecode(jsonStr) as Map<String, dynamic>;
    final allTracks = await db.getAllTracks(includeHidden: true);
    final keyMap = {for (final t in allTracks) t.trackKey: t};
    final pathMap = {for (final t in allTracks) t.path: t};
    final titleMap = {
      for (final t in allTracks)
        '${t.title.trim().toLowerCase()}_${t.durationMs ~/ 1000}': t,
    };

    Track? resolveTrack(String key, String title, String path, int durationMs) {
      if (keyMap.containsKey(key)) return keyMap[key];
      if (path.isNotEmpty && pathMap.containsKey(path)) return pathMap[path];
      final titleKey = '${title.trim().toLowerCase()}_${durationMs ~/ 1000}';
      if (titleMap.containsKey(titleKey)) return titleMap[titleKey];
      return null;
    }

    var playlistsRestored = 0;
    var favoritesRestored = 0;
    var statsRestored = 0;
    var settingsRestored = 0;

    // 1. Restore Playlists
    final rawPlaylists = data['playlists'] as List<dynamic>? ?? [];
    for (final raw in rawPlaylists) {
      final pMap = raw as Map<String, dynamic>;
      final name = pMap['name'] as String? ?? 'Restored Playlist';
      final desc = pMap['description'] as String?;
      final isSmart = pMap['isSmart'] as bool? ?? false;
      final rules = pMap['rulesJson'] as String?;
      final cover = pMap['coverUri'] as String?;

      final plId = await db.createPlaylist(
        name: name,
        description: desc,
        isSmart: isSmart,
        rulesJson: rules,
        coverUri: cover,
      );

      final rawTracks = pMap['tracks'] as List<dynamic>? ?? [];
      final resolvedKeys = <String>[];
      for (final item in rawTracks) {
        final tMap = item as Map<String, dynamic>;
        final key = tMap['trackKey'] as String? ?? '';
        final title = tMap['title'] as String? ?? '';
        final path = tMap['path'] as String? ?? '';
        final duration = tMap['durationMs'] as int? ?? 0;

        final matched = resolveTrack(key, title, path, duration);
        if (matched != null) {
          resolvedKeys.add(matched.trackKey);
        }
      }

      if (resolvedKeys.isNotEmpty) {
        await db.addTracksToPlaylist(plId, resolvedKeys);
      }
      playlistsRestored++;
    }

    // 2. Restore Favorites
    final rawFavs = data['favorites'] as List<dynamic>? ?? [];
    for (final raw in rawFavs) {
      final fMap = raw as Map<String, dynamic>;
      final key = fMap['trackKey'] as String? ?? '';
      final title = fMap['title'] as String? ?? '';
      final path = fMap['path'] as String? ?? '';
      final duration = fMap['durationMs'] as int? ?? 0;

      final matched = resolveTrack(key, title, path, duration);
      if (matched != null) {
        await (db.update(db.tracks)
              ..where((t) => t.trackKey.equals(matched.trackKey)))
            .write(const TracksCompanion(isFavorite: Value(true)));
        favoritesRestored++;
      }
    }

    // 3. Restore Stats
    final rawStats = data['listeningStats'] as List<dynamic>? ?? [];
    for (final raw in rawStats) {
      final sMap = raw as Map<String, dynamic>;
      final key = sMap['trackKey'] as String? ?? '';
      final title = sMap['title'] as String? ?? '';
      final playCount = sMap['playCount'] as int? ?? 0;
      final skipCount = sMap['skipCount'] as int? ?? 0;
      final lastPlayedAt = sMap['lastPlayedAt'] as int?;

      final matched = resolveTrack(key, title, '', 0);
      if (matched != null) {
        await (db.update(
          db.tracks,
        )..where((t) => t.trackKey.equals(matched.trackKey))).write(
          TracksCompanion(
            playCount: Value(playCount),
            skipCount: Value(skipCount),
            lastPlayedAt: Value(lastPlayedAt),
          ),
        );
        statsRestored++;
      }
    }

    // 4. Restore Settings
    final rawSettings = data['settings'] as Map<String, dynamic>? ?? {};
    for (final entry in rawSettings.entries) {
      if (entry.value is String) {
        await db.setSetting(entry.key, entry.value as String);
        settingsRestored++;
      }
    }

    return BackupRestoreResult(
      playlistsRestored: playlistsRestored,
      favoritesRestored: favoritesRestored,
      statsRestored: statsRestored,
      settingsRestored: settingsRestored,
    );
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  final db = ref.watch(databaseProvider);
  return BackupService(db);
});
