import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/favorites_service.dart';

void main() {
  late AppDatabase db;
  late FavoritesService favoritesService;

  setUp(() async {
    db = AppDatabase.inMemory();
    favoritesService = FavoritesService(db);

    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'track_fav_1',
            contentUri: 'content://audio/fav1',
            path: '/music/fav1.mp3',
            relativeDir: const Value('music'),
            title: 'Favorite Track 1',
            titleSort: 'favorite track 1',
            durationMs: 180000,
            sizeBytes: 3000000,
            isFavorite: const Value(false),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('FavoritesService Tests', () {
    test(
      'toggleFavorite toggles isFavorite state on track and returns new state',
      () async {
        expect(await favoritesService.isFavorite('track_fav_1'), isFalse);

        final newState1 = await favoritesService.toggleFavorite('track_fav_1');
        expect(newState1, isTrue);
        expect(await favoritesService.isFavorite('track_fav_1'), isTrue);

        final trackInDb = await db.getTrackByKey('track_fav_1');
        expect(trackInDb!.isFavorite, isTrue);

        final newState2 = await favoritesService.toggleFavorite('track_fav_1');
        expect(newState2, isFalse);
        expect(await favoritesService.isFavorite('track_fav_1'), isFalse);
      },
    );

    test(
      'watchLikedTracks emits updated list when track is favorited',
      () async {
        final stream = favoritesService.watchLikedTracks();

        expect(await stream.first, isEmpty);

        await favoritesService.toggleFavorite('track_fav_1');
        final updated = await favoritesService.watchLikedTracks().first;
        expect(updated.length, equals(1));
        expect(updated.first.trackKey, equals('track_fav_1'));
      },
    );
  });
}
