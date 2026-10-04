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
