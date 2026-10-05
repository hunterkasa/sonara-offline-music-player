import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/data/db/database_provider.dart';

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  final db = ref.watch(databaseProvider);
  return FavoritesService(db);
});

final likedTracksStreamProvider = StreamProvider<List<Track>>((ref) {
  final service = ref.watch(favoritesServiceProvider);
  return service.watchLikedTracks();
});

class FavoritesService {
  final AppDatabase _db;

  FavoritesService(this._db);

  Stream<List<Track>> watchLikedTracks() => _db.watchLikedTracks();

  Future<bool> toggleFavorite(String trackKey) => _db.toggleFavorite(trackKey);

  Future<bool> isFavorite(String trackKey) async {
    final track = await _db.getTrackByKey(trackKey);
    return track?.isFavorite ?? false;
  }
}
