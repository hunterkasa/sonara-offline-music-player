import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';

final playlistServiceProvider = Provider<PlaylistService>((ref) {
  final db = ref.watch(databaseProvider);
  return PlaylistService(db);
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

  PlaylistService(this._db);

  Stream<List<Playlist>> watchPlaylists() => _db.watchAllPlaylists();

  Future<Playlist?> getPlaylist(int id) => _db.getPlaylist(id);

  Stream<Playlist?> watchPlaylist(int id) => _db.watchPlaylist(id);

  Stream<List<Track>> watchPlaylistTracks(int playlistId) =>
      _db.watchPlaylistTracks(playlistId);

  Future<List<String>> getPlaylistTrackKeys(int playlistId) =>
      _db.getPlaylistTrackKeys(playlistId);

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
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return Future.value();
    return _db.renamePlaylist(id, trimmed);
  }

  Future<void> deletePlaylist(int id) => _db.deletePlaylist(id);

  Future<int> duplicatePlaylist(int id) => _db.duplicatePlaylist(id);

  Future<void> addTracksToPlaylist(int playlistId, List<String> trackKeys) =>
      _db.addTracksToPlaylist(playlistId, trackKeys);

  Future<void> removeTrackFromPlaylist(int playlistId, String trackKey) =>
      _db.removeTrackFromPlaylist(playlistId, trackKey);

  Future<void> reorderTracks(int playlistId, int oldIndex, int newIndex) =>
      _db.reorderPlaylistTracks(playlistId, oldIndex, newIndex);
}
