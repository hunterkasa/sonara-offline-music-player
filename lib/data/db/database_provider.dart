import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final allTracksStreamProvider = StreamProvider<List<Track>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllTracks();
});

final trackStreamProvider = StreamProvider.family<Track?, String?>((
  ref,
  trackKey,
) {
  if (trackKey == null) return Stream.value(null);
  final db = ref.watch(databaseProvider);
  return db.watchTrack(trackKey);
});

final folderSummariesStreamProvider = StreamProvider<List<FolderSummary>>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return db.watchFolderSummaries();
});

final albumDetailStreamProvider = StreamProvider.family<Album?, int>((
  ref,
  albumId,
) {
  final db = ref.watch(databaseProvider);
  return db.watchAlbum(albumId);
});

final albumTracksStreamProvider = StreamProvider.family<List<Track>, int>((
  ref,
  albumId,
) {
  final db = ref.watch(databaseProvider);
  return db.watchAlbumTracks(albumId);
});

final artistDetailStreamProvider = StreamProvider.family<Artist?, int>((
  ref,
  artistId,
) {
  final db = ref.watch(databaseProvider);
  return db.watchArtist(artistId);
});

final artistTracksStreamProvider = StreamProvider.family<List<Track>, int>((
  ref,
  artistId,
) {
  final db = ref.watch(databaseProvider);
  return db.watchArtistTracks(artistId);
});

final artistAlbumsStreamProvider = StreamProvider.family<List<Album>, int>((
  ref,
  artistId,
) {
  final db = ref.watch(databaseProvider);
  return db.watchArtistAlbums(artistId);
});
