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
