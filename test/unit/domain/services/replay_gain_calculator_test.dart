import 'package:flutter_test/flutter_test.dart';
import 'package:sonara/domain/models/audio_settings.dart';
import 'package:sonara/domain/services/replay_gain_calculator.dart';

void main() {
  group('ReplayGainCalculator', () {
    test('mode: off returns 1.0 when preAmpDb is 0.0', () {
      final mult = ReplayGainCalculator.computeVolumeMultiplier(
        trackGainDb: -6.0,
        albumGainDb: -4.0,
        mode: ReplayGainMode.off,
        preAmpDb: 0.0,
        preventClipping: true,
      );
      expect(mult, equals(1.0));
    });

    test('mode: off applies preAmpDb with clipping prevention clamp', () {
      final multClamped = ReplayGainCalculator.computeVolumeMultiplier(
        trackGainDb: 0.0,
        albumGainDb: 0.0,
        mode: ReplayGainMode.off,
        preAmpDb: 6.0,
        preventClipping: true,
      );
      expect(multClamped, equals(1.0));

      final multUnclamped = ReplayGainCalculator.computeVolumeMultiplier(
        trackGainDb: 0.0,
        albumGainDb: 0.0,
        mode: ReplayGainMode.off,
        preAmpDb: 6.0,
        preventClipping: false,
      );
      // 10^(6/20) ~ 1.995
      expect(multUnclamped, closeTo(1.995, 0.01));
    });

    test('mode: track uses trackGainDb', () {
      final mult = ReplayGainCalculator.computeVolumeMultiplier(
        trackGainDb: -6.0,
        albumGainDb: -2.0,
        mode: ReplayGainMode.track,
        preAmpDb: 0.0,
        preventClipping: true,
      );
      // 10^(-6/20) ~ 0.501
      expect(mult, closeTo(0.501, 0.01));
    });

    test('mode: album uses albumGainDb', () {
      final mult = ReplayGainCalculator.computeVolumeMultiplier(
        trackGainDb: -6.0,
        albumGainDb: -3.0,
        mode: ReplayGainMode.album,
        preAmpDb: 0.0,
        preventClipping: true,
      );
      // 10^(-3/20) ~ 0.7079
      expect(mult, closeTo(0.708, 0.01));
    });

    test('mode: album falls back to trackGainDb if albumGainDb is null', () {
      final mult = ReplayGainCalculator.computeVolumeMultiplier(
        trackGainDb: -6.0,
        albumGainDb: null,
        mode: ReplayGainMode.album,
        preAmpDb: 0.0,
        preventClipping: true,
      );
      expect(mult, closeTo(0.501, 0.01));
    });

    test('mode: smart uses trackGainDb during shuffle', () {
      final mult = ReplayGainCalculator.computeVolumeMultiplier(
        trackGainDb: -6.0,
        albumGainDb: -2.0,
        mode: ReplayGainMode.smart,
        preAmpDb: 0.0,
        preventClipping: true,
        isShuffle: true,
      );
      expect(mult, closeTo(0.501, 0.01));
    });

    test('mode: smart uses albumGainDb when sequential', () {
      final mult = ReplayGainCalculator.computeVolumeMultiplier(
        trackGainDb: -6.0,
        albumGainDb: -2.0,
        mode: ReplayGainMode.smart,
        preAmpDb: 0.0,
        preventClipping: true,
        isShuffle: false,
      );
      // 10^(-2/20) ~ 0.794
      expect(mult, closeTo(0.794, 0.01));
    });

    test('preAmpDb is added to total gain', () {
      final mult = ReplayGainCalculator.computeVolumeMultiplier(
        trackGainDb: -6.0,
        albumGainDb: 0.0,
        mode: ReplayGainMode.track,
        preAmpDb: 6.0, // cancels out -6.0
        preventClipping: true,
      );
      // 10^((-6+6)/20) = 1.0
      expect(mult, closeTo(1.0, 0.001));
    });

    test('handles missing null gains gracefully with 0.0 dB fallback', () {
      final mult = ReplayGainCalculator.computeVolumeMultiplier(
        trackGainDb: null,
        albumGainDb: null,
        mode: ReplayGainMode.smart,
        preAmpDb: 0.0,
        preventClipping: true,
      );
      expect(mult, equals(1.0));
    });
  });
}
