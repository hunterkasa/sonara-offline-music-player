import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/core/utils/track_key.dart';

void main() {
  group('TrackKeyUtil', () {
    test('produces identical SHA-256 for identical normalized metadata', () {
      final key1 = TrackKeyUtil.generate(
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        durationMs: 354000,
        sizeBytes: 8492000,
      );

      final key2 = TrackKeyUtil.generate(
        title: ' bohemian rhapsody ',
        artist: 'QUEEN ',
        album: ' a night at the opera',
        durationMs: 354000,
        sizeBytes: 8492000,
      );

      expect(key1, equals(key2));
      expect(key1.length, equals(64)); // Standard SHA-256 hex string length
    });

    test('produces distinct keys when metadata differs', () {
      final keyA = TrackKeyUtil.generate(
        title: 'Track A',
        artist: 'Artist',
        album: 'Album',
        durationMs: 120000,
        sizeBytes: 3000000,
      );

      final keyB = TrackKeyUtil.generate(
        title: 'Track B',
        artist: 'Artist',
        album: 'Album',
        durationMs: 120000,
        sizeBytes: 3000000,
      );

      expect(keyA, isNot(equals(keyB)));
    });
  });
}
