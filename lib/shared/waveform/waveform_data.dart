import 'dart:math';

/// Generates and caches deterministic normalized waveform amplitude peaks
/// (values from 0.05 to 1.0) for tracks.
class WaveformGenerator {
  static const int defaultSamplesCount = 64;

  static final Map<String, List<double>> _cache = {};

  /// Returns a list of normalized amplitude peaks for a track key.
  /// Generates a realistic audio waveform profile using multi-harmonic sine synthesis
  /// seeded deterministically by the track key so the waveform is consistent across runs.
  static List<double> getWaveformPeaks(
    String trackKey, {
    int samples = defaultSamplesCount,
  }) {
    final cached = _cache[trackKey];
    if (cached != null && cached.length == samples) {
      return cached;
    }

    // Seed Random with deterministic integer hash of trackKey
    final seed = trackKey.hashCode.abs();
    final rng = Random(seed);

    final peaks = <double>[];
    final baseFreq1 = 1.0 + (rng.nextDouble() * 3.0);
    final baseFreq2 = 3.0 + (rng.nextDouble() * 5.0);
    final phase1 = rng.nextDouble() * 2 * pi;
    final phase2 = rng.nextDouble() * 2 * pi;

    for (var i = 0; i < samples; i++) {
      final t = i / samples;

      // Envelope: softer intro and outro, fuller in the body
      final envelope = sin(t * pi);

      // Primary harmonics
      final h1 = (sin(t * 2 * pi * baseFreq1 + phase1) + 1.0) / 2.0;
      final h2 = (sin(t * 2 * pi * baseFreq2 + phase2) + 1.0) / 2.0;
      final noise = rng.nextDouble() * 0.25;

      final combined = (0.5 * h1 + 0.3 * h2 + noise) * envelope;
      // Clamp between 0.08 (minimum bar height) and 1.0
      peaks.add(combined.clamp(0.08, 1.0));
    }

    _cache[trackKey] = peaks;
    return peaks;
  }

  static void clearCache() {
    _cache.clear();
  }
}
