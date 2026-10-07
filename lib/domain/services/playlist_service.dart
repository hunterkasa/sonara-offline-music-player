import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';

import 'daily_mix_service.dart';
import 'smart_playlist_engine.dart';

final playlistServiceProvider = Provider<PlaylistService>((ref) {
  final db = ref.watch(databaseProvider);
  final dailyMix = ref.watch(dailyMixServiceProvider);
  return PlaylistService(db, dailyMix);
});

final allPlaylistsStreamProvider = StreamProvider<List<Playlist>>((ref) {
  final service = ref.watch(playlistServiceProvider);
  return service.watchPlaylists();
});

final playlistTracksStreamProvider = StreamProvider.family<List<Track>, int>((
  ref,
  playlistId,
) {
  final service = ref.watch(playlistServiceProvider);
  return service.watchPlaylistTracks(playlistId);
});

final playlistStreamProvider = StreamProvider.family<Playlist?, int>((
  ref,
  playlistId,
) {
  final service = ref.watch(playlistServiceProvider);
  return service.watchPlaylist(playlistId);
});

class PlaylistService {
  final AppDatabase _db;
  final DailyMixService? _dailyMixService;

  PlaylistService(this._db, [this._dailyMixService]);

  Stream<List<Playlist>> watchPlaylists() => _db.watchAllPlaylists();

  Future<Playlist?> getPlaylist(int id) async {
    if (id == -1) {
      return Future.value(
        Playlist(
          id: -1,
          name: 'Liked Songs',
          description: 'Your favorite tracks',
          isSmart: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    if (id == -2) {
      return Future.value(
        Playlist(
          id: -2,
          name: 'Recently Added',
          description: 'Latest tracks added to your library',
          isSmart: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    if (id == -3) {
      return Future.value(
        Playlist(
          id: -3,
          name: 'On Repeat',
          description: 'Your most listened songs',
          isSmart: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    if (id <= -101 && id >= -110) {
      if (_dailyMixService != null) {
        final mix = await _dailyMixService.getDailyMixById(id);
        if (mix != null) {
          return Playlist(
            id: mix.id,
            name: mix.title,
            description: mix.description,
            isSmart: true,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
        }
      }
      final index = (-id) - 100;
      return Playlist(
        id: id,
        name: 'Daily Mix $index',
        description: 'Personalized mix for you',
        isSmart: true,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }
    return _db.getPlaylist(id);
  }

  Stream<Playlist?> watchPlaylist(int id) {
    if (id == -1) {
      return Stream.value(
        Playlist(
          id: -1,
          name: 'Liked Songs',
          description: 'Your favorite tracks',
          isSmart: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    if (id == -2) {
      return Stream.value(
        Playlist(
          id: -2,
          name: 'Recently Added',
          description: 'Latest tracks added to your library',
          isSmart: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    if (id == -3) {
      return Stream.value(
        Playlist(
          id: -3,
          name: 'On Repeat',
          description: 'Your most listened songs',
          isSmart: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    if (id <= -101 && id >= -110) {
      if (_dailyMixService != null) {
        return _dailyMixService.watchDailyMixById(id).map((mix) {
          if (mix == null) {
            final index = (-id) - 100;
            return Playlist(
              id: id,
              name: 'Daily Mix $index',
              description: 'Personalized mix for you',
              isSmart: true,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            );
          }
          return Playlist(
            id: mix.id,
            name: mix.title,
            description: mix.description,
            isSmart: true,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
        });
      }
    }
    return _db.watchPlaylist(id);
  }

  Stream<List<Track>> watchPlaylistTracks(int playlistId) async* {
    if (playlistId == -1) {
      yield* _db.watchLikedTracks();
      return;
    }
    if (playlistId == -2) {
      yield* _db.watchRecentlyAddedTracks(limit: 50);
      return;
    }
    if (playlistId == -3) {
      yield* _db.watchTopTracks(limit: 50);
      return;
    }
    if (playlistId <= -101 && playlistId >= -110) {
      if (_dailyMixService != null) {
        yield* _dailyMixService.watchDailyMixTracks(playlistId);
        return;
      }
    }

    final playlist = await _db.getPlaylist(playlistId);
    if (playlist != null && playlist.isSmart && playlist.rulesJson != null) {
      try {
        final rulesMap =
            jsonDecode(playlist.rulesJson!) as Map<String, dynamic>;
        final group = SmartRuleGroup.fromJson(rulesMap);
        final engine = SmartPlaylistEngine(_db);
        yield* _db.watchAllTracks().asyncMap((_) => engine.evaluate(group));
        return;
      } catch (e) {
        debugPrint('Error evaluating smart playlist: $e');
      }
    }

    yield* _db.watchPlaylistTracks(playlistId);
  }

  Future<List<String>> getPlaylistTrackKeys(int playlistId) async {
    if (playlistId == -1) {
      final liked = await _db.watchLikedTracks().first;
      return liked.map((t) => t.trackKey).toList();
    }
    if (playlistId == -2) {
      final recent = await _db.watchRecentlyAddedTracks(limit: 50).first;
      return recent.map((t) => t.trackKey).toList();
    }
    if (playlistId == -3) {
      final top = await _db.watchTopTracks(limit: 50).first;
      return top.map((t) => t.trackKey).toList();
    }
    if (playlistId <= -101 && playlistId >= -110) {
      if (_dailyMixService != null) {
        final tracks = await _dailyMixService.getDailyMixTracks(playlistId);
        return tracks.map((t) => t.trackKey).toList();
      }
    }
    final playlist = await _db.getPlaylist(playlistId);
    if (playlist != null && playlist.isSmart && playlist.rulesJson != null) {
      try {
        final rulesMap =
            jsonDecode(playlist.rulesJson!) as Map<String, dynamic>;
        final group = SmartRuleGroup.fromJson(rulesMap);
        final engine = SmartPlaylistEngine(_db);
        final matched = await engine.evaluate(group);
        return matched.map((t) => t.trackKey).toList();
      } catch (_) {}
    }
    return _db.getPlaylistTrackKeys(playlistId);
  }

  Future<int> createPlaylist({
    required String name,
    String? description,
    bool isSmart = false,
    String? rulesJson,
    String? coverUri,
  }) {
    final trimmed = name.trim();
    final effectiveName = trimmed.isEmpty ? 'Untitled Playlist' : trimmed;
    return _db.createPlaylist(
      name: effectiveName,
      description: description,
      isSmart: isSmart,
      rulesJson: rulesJson,
      coverUri: coverUri,
    );
  }

  Future<void> renamePlaylist(int id, String newName) {
    if (id <= 0) return Future.value();
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return Future.value();
    return _db.renamePlaylist(id, trimmed);
  }

  Future<void> deletePlaylist(int id) {
    if (id <= 0) return Future.value();
    return _db.deletePlaylist(id);
  }

  Future<int> duplicatePlaylist(int id) {
    if (id <= 0) return Future.value(0);
    return _db.duplicatePlaylist(id);
  }

  Future<void> addTracksToPlaylist(int playlistId, List<String> trackKeys) {
    if (playlistId <= 0) return Future.value();
    return _db.addTracksToPlaylist(playlistId, trackKeys);
  }

  Future<void> removeTrackFromPlaylist(int playlistId, String trackKey) {
    if (playlistId <= 0) return Future.value();
    return _db.removeTrackFromPlaylist(playlistId, trackKey);
  }

  Future<void> reorderTracks(int playlistId, int oldIndex, int newIndex) {
    if (playlistId <= 0) return Future.value();
    return _db.reorderPlaylistTracks(playlistId, oldIndex, newIndex);
  }
}
