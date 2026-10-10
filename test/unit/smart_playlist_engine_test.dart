import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/smart_playlist_engine.dart';

void main() {
  late AppDatabase db;
  late SmartPlaylistEngine engine;

  setUp(() async {
    db = AppDatabase.inMemory();
    engine = SmartPlaylistEngine(db);

    // Insert test tracks
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'track_1',
            contentUri: 'content://1',
            path: '/music/rock_song.mp3',
            relativeDir: const Value('music'),
            title: 'Rock Anthem',
            titleSort: 'rock anthem',
            year: const Value(2020),
            durationMs: 200000,
            sizeBytes: 4000000,
            playCount: const Value(15),
            skipCount: const Value(2),
            isFavorite: const Value(true),
            lastPlayedAt: const Value(1700000000),
            dateAdded: const Value(1690000000),
          ),
        );
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'track_2',
            contentUri: 'content://2',
            path: '/music/pop_hit.mp3',
            relativeDir: const Value('music'),
            title: 'Pop Hit',
            titleSort: 'pop hit',
            year: const Value(2022),
            durationMs: 180000,
            sizeBytes: 3500000,
            playCount: const Value(0),
            skipCount: const Value(0),
            isFavorite: const Value(false),
            dateAdded: const Value(1710000000),
          ),
        );
    await db
        .into(db.tracks)
        .insert(
          TracksCompanion.insert(
            trackKey: 'track_3',
            contentUri: 'content://3',
            path: '/music/jazz_ballad.mp3',
            relativeDir: const Value('music'),
            title: 'Jazz Ballad',
            titleSort: 'jazz ballad',
            year: const Value(2015),
            durationMs: 320000,
            sizeBytes: 7000000,
            playCount: const Value(8),
            skipCount: const Value(5),
            isFavorite: const Value(true),
            lastPlayedAt: const Value(1680000000),
            dateAdded: const Value(1680000000),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('SmartPlaylistEngine Rule Evaluation Tests', () {
    test('filters with contains operator', () async {
      const group = SmartRuleGroup(
        rules: [
          SmartRule(
            field: SmartField.title,
            operator: SmartOperator.contains,
            value: 'Anthem',
          ),
        ],
      );

      final results = await engine.evaluate(group);
      expect(results.length, equals(1));
      expect(results.first.trackKey, equals('track_1'));
    });

    test('filters with numeric comparisons (greaterThan, equals)', () async {
      const group = SmartRuleGroup(
        rules: [
          SmartRule(
            field: SmartField.playCount,
            operator: SmartOperator.greaterThan,
            value: 5,
          ),
        ],
        sortBy: SmartField.playCount,
        sortAscending: false,
      );

      final results = await engine.evaluate(group);
      expect(results.length, equals(2));
      expect(results[0].trackKey, equals('track_1')); // 15 plays
      expect(results[1].trackKey, equals('track_3')); // 8 plays
    });

    test('evaluates matchAny (OR) conjunction correctly', () async {
      const group = SmartRuleGroup(
        matchAll: false, // OR
        rules: [
          SmartRule(
            field: SmartField.year,
            operator: SmartOperator.equals,
            value: 2022,
          ),
          SmartRule(
            field: SmartField.year,
            operator: SmartOperator.equals,
            value: 2015,
          ),
        ],
      );

      final results = await engine.evaluate(group);
      expect(results.length, equals(2));
      final keys = results.map((Track t) => t.trackKey).toSet();
      expect(keys, containsAll(['track_2', 'track_3']));
    });

    test('evaluates boolean isTrue rule', () async {
      const group = SmartRuleGroup(
        rules: [
          SmartRule(
            field: SmartField.isFavorite,
            operator: SmartOperator.isTrue,
          ),
        ],
      );

      final results = await engine.evaluate(group);
      expect(results.length, equals(2));
      final keys = results.map((Track t) => t.trackKey).toSet();
      expect(keys, containsAll(['track_1', 'track_3']));
    });

    test('presets evaluate accurately against data', () async {
      // 1. Most Played preset
      final mostPlayed = await engine.evaluate(
        SmartPlaylistEngine.mostPlayedPreset(),
      );
      expect(mostPlayed.length, equals(2));
      expect(mostPlayed.first.trackKey, equals('track_1'));

      // 2. Never Played preset
      final neverPlayed = await engine.evaluate(
        SmartPlaylistEngine.neverPlayedPreset(),
      );
      expect(neverPlayed.length, equals(1));
      expect(neverPlayed.first.trackKey, equals('track_2'));

      // 3. Forgotten Favorites preset
      final forgotten = await engine.evaluate(
        SmartPlaylistEngine.forgottenFavoritesPreset(),
      );
      expect(forgotten.length, equals(2));

      // 4. Recently Added preset
      final recentAdded = await engine.evaluate(
        SmartPlaylistEngine.recentlyAddedPreset(),
      );
      expect(recentAdded.length, equals(3));
    });

    test('serializes and deserializes SmartRuleGroup and SmartRule', () {
      const group = SmartRuleGroup(
        matchAll: false,
        limit: 25,
        sortBy: SmartField.duration,
        sortAscending: false,
        rules: [
          SmartRule(
            field: SmartField.duration,
            operator: SmartOperator.lessThan,
            value: 250,
          ),
          SmartRule(
            field: SmartField.isFavorite,
            operator: SmartOperator.isFalse,
          ),
        ],
      );

      final json = group.toJson();
      final restored = SmartRuleGroup.fromJson(json);

      expect(restored.matchAll, isFalse);
      expect(restored.limit, equals(25));
      expect(restored.sortBy, equals(SmartField.duration));
      expect(restored.sortAscending, isFalse);
      expect(restored.rules.length, equals(2));
      expect(restored.rules[0].field, equals(SmartField.duration));
      expect(restored.rules[0].operator, equals(SmartOperator.lessThan));
      expect(restored.rules[0].value, equals(250));
      expect(restored.rules[1].operator, equals(SmartOperator.isFalse));
    });

    test('filters by genre correctly', () async {
      final rockGenreId = await db.getOrCreateGenre('Rock');
      final jazzGenreId = await db.getOrCreateGenre('Jazz');

      final track1 = await db.getTrackByKey('track_1');
      final track3 = await db.getTrackByKey('track_3');

      await db
          .into(db.trackGenres)
          .insert(
            TrackGenresCompanion.insert(
              trackId: track1!.id,
              genreId: rockGenreId,
            ),
          );
      await db
          .into(db.trackGenres)
          .insert(
            TrackGenresCompanion.insert(
              trackId: track3!.id,
              genreId: jazzGenreId,
            ),
          );

      const group = SmartRuleGroup(
        rules: [
          SmartRule(
            field: SmartField.genre,
            operator: SmartOperator.equals,
            value: 'Jazz',
          ),
        ],
      );

      final results = await engine.evaluate(group);
      expect(results.length, equals(1));
      expect(results.first.trackKey, equals('track_3'));
    });
  });
}
