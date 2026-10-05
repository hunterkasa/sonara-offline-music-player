import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/data/db/app_database.dart';
import 'package:sonara/domain/services/long_audio_service.dart';

void main() {
  late AppDatabase db;
  late LongAudioService service;

  setUp(() {
    db = AppDatabase.inMemory();
    service = LongAudioService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('LongAudioService', () {
    test('isLongAudio accurately detects tracks >= 20 minutes', () {
      expect(service.isLongAudio(19 * 60 * 1000), isFalse);
      expect(service.isLongAudio(20 * 60 * 1000 - 1), isFalse);
      expect(service.isLongAudio(20 * 60 * 1000), isTrue);
      expect(service.isLongAudio(60 * 60 * 1000), isTrue);
    });

    test('savePosition ignores positions less than 10 seconds', () async {
      await service.savePosition('short_pos_track', positionMs: 5000);
      final saved = await service.getSavedPosition('short_pos_track');
      expect(saved, isNull);
    });

    test('savePosition persists and retrieves state accurately', () async {
      const trackKey = 'podcast_track_01';
      await service.savePosition(trackKey, positionMs: 450000, speed: 1.25);

      final state = await service.getSavedPosition(trackKey);
      expect(state, isNotNull);
      expect(state!.positionMs, equals(450000));
      expect(state.speed, equals(1.25));
      expect(state.lastUpdated, greaterThan(0));
    });

    test('clearSavedPosition wipes the entry', () async {
      const trackKey = 'dj_set_02';
      await service.savePosition(trackKey, positionMs: 800000, speed: 1.0);

      var state = await service.getSavedPosition(trackKey);
      expect(state, isNotNull);

      await service.clearSavedPosition(trackKey);
      state = await service.getSavedPosition(trackKey);
      expect(state, isNull);
    });
  });
}
