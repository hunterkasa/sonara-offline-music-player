import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/domain/models/audio_settings.dart';

void main() {
  group('AudioSettings Speed, Pitch & Fade Curve Tests', () {
    test('default settings have correct initial values', () {
      const settings = AudioSettings();
      expect(settings.rememberSpeedAndPitch, isTrue);
      expect(settings.playbackSpeed, equals(1.0));
      expect(settings.pitchSemitones, equals(0));
      expect(settings.sleepTimerFadeCurve, equals(SleepTimerFadeCurve.linear));
    });

    test('copyWith updates speed, pitch memory and fade curve', () {
      const settings = AudioSettings();
      final updated = settings.copyWith(
        rememberSpeedAndPitch: true,
        playbackSpeed: 1.25,
        pitchSemitones: 2,
        sleepTimerFadeCurve: SleepTimerFadeCurve.logarithmic,
      );

      expect(updated.rememberSpeedAndPitch, isTrue);
      expect(updated.playbackSpeed, equals(1.25));
      expect(updated.pitchSemitones, equals(2));
      expect(
        updated.sleepTimerFadeCurve,
        equals(SleepTimerFadeCurve.logarithmic),
      );
    });

    test('toMap and fromMap preserve speed, pitch memory and fade curves', () {
      const original = AudioSettings(
        rememberSpeedAndPitch: true,
        playbackSpeed: 1.5,
        pitchSemitones: -3,
        sleepTimerFadeCurve: SleepTimerFadeCurve.exponential,
      );

      final map = original.toMap();
      expect(map['rememberSpeedAndPitch'], isTrue);
      expect(map['playbackSpeed'], equals(1.5));
      expect(map['pitchSemitones'], equals(-3));
      expect(map['sleepTimerFadeCurve'], equals('exponential'));

      final restored = AudioSettings.fromMap(map);
      expect(restored.rememberSpeedAndPitch, isTrue);
      expect(restored.playbackSpeed, equals(1.5));
      expect(restored.pitchSemitones, equals(-3));
      expect(
        restored.sleepTimerFadeCurve,
        equals(SleepTimerFadeCurve.exponential),
      );
    });
  });
}
