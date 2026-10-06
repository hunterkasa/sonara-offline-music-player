import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/shared/waveform/waveform_data.dart';

void main() {
  group('WaveformGenerator Amplitude Profiling Tests', () {
    setUp(() {
      WaveformGenerator.clearCache();
    });

    test('generates expected default sample count with clamped bounds', () {
      final peaks = WaveformGenerator.getWaveformPeaks('test_track_1');

      expect(peaks.length, equals(WaveformGenerator.defaultSamplesCount));
      for (final peak in peaks) {
        expect(peak, greaterThanOrEqualTo(0.08));
        expect(peak, lessThanOrEqualTo(1.0));
      }
    });

    test(
      'deterministically returns identical peaks for identical track key',
      () {
        final peaks1 = WaveformGenerator.getWaveformPeaks(
          'consistent_track_key',
        );
        final peaks2 = WaveformGenerator.getWaveformPeaks(
          'consistent_track_key',
        );

        expect(peaks1, equals(peaks2));
      },
    );

    test('generates different peak contours for different track keys', () {
      final peaksA = WaveformGenerator.getWaveformPeaks('track_alpha');
      final peaksB = WaveformGenerator.getWaveformPeaks('track_beta');

      expect(peaksA, isNot(equals(peaksB)));
    });

    test('supports custom sample sizes', () {
      final peaksCustom = WaveformGenerator.getWaveformPeaks(
        'custom_track',
        samples: 32,
      );

      expect(peaksCustom.length, equals(32));
    });

    test('clearCache purges memory cache', () {
      final peaksBefore = WaveformGenerator.getWaveformPeaks('cached_track');
      WaveformGenerator.clearCache();
      final peaksAfter = WaveformGenerator.getWaveformPeaks('cached_track');

      // Values should still be deterministic
      expect(peaksBefore, equals(peaksAfter));
    });
  });
}
